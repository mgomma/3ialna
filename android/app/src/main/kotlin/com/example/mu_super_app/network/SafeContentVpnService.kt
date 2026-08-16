package com.example.mu_super_app.network

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.Executors
import org.json.JSONObject

/**
 * Privacy-preserving first VPN slice for safe content.
 *
 * The VPN routes only the configured DNS endpoint through the tunnel. It does
 * not proxy arbitrary application traffic or inspect message/page content.
 * Blocked domains receive NXDOMAIN; allowed DNS queries are forwarded through
 * a protected upstream UDP socket. Direct-IP traffic, encrypted DNS, and
 * traffic from apps that bypass the system resolver are outside this slice.
 */
class SafeContentVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val preferences by lazy {
        getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundWithNotification()
        if (vpnInterface == null) establishVpn()
        return START_STICKY
    }

    override fun onDestroy() {
        stopVpn()
        executor.shutdownNow()
        super.onDestroy()
    }

    override fun onRevoke() {
        stopVpn()
        super.onRevoke()
    }

    override fun onBind(intent: Intent?): IBinder? = super.onBind(intent)

    private fun establishVpn() {
        try {
            vpnInterface = Builder()
                .setSession("3ialna Safe Content")
                .setMtu(1500)
                .addAddress(VPN_CLIENT_IP, 32)
                .addRoute(VPN_DNS_IP, 32)
                .addDnsServer(VPN_DNS_IP)
                .establish()

            val descriptor = vpnInterface ?: return
            setRunning(true)
            executor.execute { processDnsPackets(descriptor) }
        } catch (error: Exception) {
            setRunning(false)
            stopSelf()
        }
    }

    private fun processDnsPackets(descriptor: ParcelFileDescriptor) {
        val input = FileInputStream(descriptor.fileDescriptor)
        val output = FileOutputStream(descriptor.fileDescriptor)
        val packetBuffer = ByteArray(MAX_PACKET_SIZE)

        try {
            while (!Thread.currentThread().isInterrupted) {
                val length = input.read(packetBuffer)
                if (length <= 0) break
                val packet = packetBuffer.copyOf(length)
                val dnsRequest = parseDnsRequest(packet) ?: continue
                val policy = PolicySnapshot.fromPreferences(preferences)
                val blocked = policy.isBlocked(dnsRequest.domain)
                val dnsPayload = if (blocked) {
                    buildNxdomain(dnsRequest.payload)
                } else {
                    forwardDns(dnsRequest.payload)
                } ?: continue

                val response = buildUdpIpv4Packet(
                    sourceIp = dnsRequest.destinationIp,
                    destinationIp = dnsRequest.sourceIp,
                    sourcePort = DNS_PORT,
                    destinationPort = dnsRequest.sourcePort,
                    payload = dnsPayload,
                )
                output.write(response)
                output.flush()
            }
        } catch (_: Exception) {
            // Closing the descriptor during stop is expected.
        } finally {
            setRunning(false)
            try {
                input.close()
            } catch (_: Exception) {
            }
            try {
                output.close()
            } catch (_: Exception) {
            }
        }
    }

    private fun forwardDns(payload: ByteArray): ByteArray? {
        return try {
            val socket = DatagramSocket()
            socket.soTimeout = DNS_TIMEOUT_MS
            protect(socket)
            val upstream = InetAddress.getByName(UPSTREAM_DNS)
            socket.send(DatagramPacket(payload, payload.size, upstream, DNS_PORT))
            val responseBuffer = ByteArray(MAX_DNS_PACKET_SIZE)
            val response = DatagramPacket(responseBuffer, responseBuffer.size)
            socket.receive(response)
            socket.close()
            response.data.copyOf(response.length)
        } catch (_: Exception) {
            null
        }
    }

    private fun startForegroundWithNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Safe content filtering",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("3ialna safe content")
            .setContentText("Domain filtering is active")
            .setSmallIcon(com.example.mu_super_app.R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun stopVpn() {
        setRunning(false)
        try {
            vpnInterface?.close()
        } catch (_: Exception) {
        }
        vpnInterface = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
        stopSelf()
    }

    private fun setRunning(running: Boolean) {
        preferences.edit().putBoolean(PREF_RUNNING, running).apply()
    }

    private data class DnsRequest(
        val sourceIp: ByteArray,
        val destinationIp: ByteArray,
        val sourcePort: Int,
        val payload: ByteArray,
        val domain: String,
    )

    private fun parseDnsRequest(packet: ByteArray): DnsRequest? {
        if (packet.size < IPV4_HEADER_SIZE + UDP_HEADER_SIZE) return null
        val versionAndHeaderLength = packet[0].toInt() and 0xff
        if ((versionAndHeaderLength ushr 4) != 4) return null
        val headerLength = (versionAndHeaderLength and 0x0f) * 4
        if (headerLength < IPV4_HEADER_SIZE || packet.size < headerLength + UDP_HEADER_SIZE) return null
        if ((packet[9].toInt() and 0xff) != UDP_PROTOCOL) return null

        val sourceIp = packet.copyOfRange(12, 16)
        val destinationIp = packet.copyOfRange(16, 20)
        val sourcePort = readUnsignedShort(packet, headerLength)
        val destinationPort = readUnsignedShort(packet, headerLength + 2)
        if (destinationPort != DNS_PORT) return null

        val udpLength = readUnsignedShort(packet, headerLength + 4)
        val payloadStart = headerLength + UDP_HEADER_SIZE
        val payloadLength = minOf(udpLength - UDP_HEADER_SIZE, packet.size - payloadStart)
        if (payloadLength < DNS_HEADER_SIZE) return null
        val payload = packet.copyOfRange(payloadStart, payloadStart + payloadLength)
        val domain = readQueryDomain(payload) ?: return null
        return DnsRequest(sourceIp, destinationIp, sourcePort, payload, domain)
    }

    private fun readQueryDomain(payload: ByteArray): String? {
        if (payload.size < DNS_HEADER_SIZE) return null
        val questionCount = readUnsignedShort(payload, 4)
        if (questionCount < 1) return null
        var offset = DNS_HEADER_SIZE
        val labels = mutableListOf<String>()
        while (offset < payload.size) {
            val length = payload[offset].toInt() and 0xff
            offset++
            if (length == 0) break
            if ((length and 0xc0) != 0 || length > 63 || offset + length > payload.size) return null
            labels += String(payload, offset, length, Charsets.US_ASCII).lowercase()
            offset += length
        }
        return labels.joinToString(".").takeIf { it.isNotEmpty() }
    }

    private fun buildNxdomain(query: ByteArray): ByteArray {
        if (query.size < DNS_HEADER_SIZE) return query
        val response = query.copyOf()
        response[2] = 0x81.toByte()
        response[3] = 0x83.toByte()
        response[6] = 0
        response[7] = 0
        response[8] = 0
        response[9] = 0
        return response
    }

    private fun buildUdpIpv4Packet(
        sourceIp: ByteArray,
        destinationIp: ByteArray,
        sourcePort: Int,
        destinationPort: Int,
        payload: ByteArray,
    ): ByteArray {
        val udpLength = UDP_HEADER_SIZE + payload.size
        val packet = ByteArray(IPV4_HEADER_SIZE + udpLength)
        packet[0] = 0x45
        packet[1] = 0
        writeUnsignedShort(packet, 2, packet.size)
        writeUnsignedShort(packet, 4, 0)
        writeUnsignedShort(packet, 6, 0)
        packet[8] = 64
        packet[9] = UDP_PROTOCOL.toByte()
        sourceIp.copyInto(packet, 12)
        destinationIp.copyInto(packet, 16)
        writeUnsignedShort(packet, 10, checksum(packet, 0, IPV4_HEADER_SIZE))

        writeUnsignedShort(packet, IPV4_HEADER_SIZE, sourcePort)
        writeUnsignedShort(packet, IPV4_HEADER_SIZE + 2, destinationPort)
        writeUnsignedShort(packet, IPV4_HEADER_SIZE + 4, udpLength)
        writeUnsignedShort(packet, IPV4_HEADER_SIZE + 6, 0)
        payload.copyInto(packet, IPV4_HEADER_SIZE + UDP_HEADER_SIZE)
        writeUnsignedShort(
            packet,
            IPV4_HEADER_SIZE + 6,
            udpChecksum(packet, sourceIp, destinationIp, IPV4_HEADER_SIZE, udpLength),
        )
        return packet
    }

    private fun udpChecksum(
        packet: ByteArray,
        sourceIp: ByteArray,
        destinationIp: ByteArray,
        offset: Int,
        length: Int,
    ): Int {
        var sum = 0L
        sum += checksumSum(sourceIp, 0, sourceIp.size)
        sum += checksumSum(destinationIp, 0, destinationIp.size)
        sum += UDP_PROTOCOL
        sum += length
        sum += checksumSum(packet, offset, length)
        while ((sum ushr 16) != 0L) sum = (sum and 0xffff) + (sum ushr 16)
        return (sum.inv() and 0xffff).toInt()
    }

    private fun checksum(data: ByteArray, offset: Int, length: Int): Int {
        var sum = checksumSum(data, offset, length)
        while ((sum ushr 16) != 0L) sum = (sum and 0xffff) + (sum ushr 16)
        return (sum.inv() and 0xffff).toInt()
    }

    private fun checksumSum(data: ByteArray, offset: Int, length: Int): Long {
        var sum = 0L
        var index = offset
        val end = offset + length
        while (index + 1 < end) {
            sum += ((data[index].toInt() and 0xff) shl 8) or (data[index + 1].toInt() and 0xff)
            index += 2
        }
        if (index < end) sum += (data[index].toInt() and 0xff) shl 8
        return sum
    }

    private fun readUnsignedShort(data: ByteArray, offset: Int): Int {
        return ((data[offset].toInt() and 0xff) shl 8) or (data[offset + 1].toInt() and 0xff)
    }

    private fun writeUnsignedShort(data: ByteArray, offset: Int, value: Int) {
        data[offset] = (value ushr 8).toByte()
        data[offset + 1] = value.toByte()
    }

    private data class PolicySnapshot(
        val enabled: Boolean,
        val blockedCategories: Set<String>,
        val blockedDomains: Set<String>,
        val allowedDomains: Set<String>,
        val allowSocialMedia: Boolean,
    ) {
        fun isBlocked(domain: String): Boolean {
            if (!enabled) return false
            if (matches(domain, allowedDomains)) return false
            if (matches(domain, blockedDomains)) return true
            if ("adult" in blockedCategories && matches(domain, ADULT_DOMAINS)) return true
            if ("gambling" in blockedCategories && matches(domain, GAMBLING_DOMAINS)) return true
            if ("violence" in blockedCategories && matches(domain, VIOLENCE_DOMAINS)) return true
            if ("social" in blockedCategories && !allowSocialMedia && matches(domain, SOCIAL_DOMAINS)) return true
            return false
        }

        private fun matches(domain: String, candidates: Set<String>): Boolean {
            return candidates.any { domain == it || domain.endsWith(".$it") }
        }

        companion object {
            fun fromPreferences(preferences: android.content.SharedPreferences): PolicySnapshot {
                val raw = preferences.getString(PREF_POLICY, null) ?: return PolicySnapshot(
                    enabled = false,
                    blockedCategories = emptySet(),
                    blockedDomains = emptySet(),
                    allowedDomains = emptySet(),
                    allowSocialMedia = true,
                )
                return try {
                    val json = JSONObject(raw)
                    PolicySnapshot(
                        enabled = json.optBoolean("enabled", true),
                        blockedCategories = json.optJSONArray("blockedCategories").toStringSet(),
                        blockedDomains = json.optJSONArray("blockedDomains").toDomainSet(),
                        allowedDomains = json.optJSONArray("allowedDomains").toDomainSet(),
                        allowSocialMedia = json.optBoolean("allowSocialMedia", true),
                    )
                } catch (_: Exception) {
                    PolicySnapshot(
                        enabled = false,
                        blockedCategories = emptySet(),
                        blockedDomains = emptySet(),
                        allowedDomains = emptySet(),
                        allowSocialMedia = true,
                    )
                }
            }
        }
    }

    companion object {
        const val PREF_RUNNING = "flutter.safe_content_vpn_running"
        const val PREF_POLICY = "flutter.safe_content_policy"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val VPN_CLIENT_IP = "10.8.0.2"
        private const val VPN_DNS_IP = "10.8.0.1"
        private const val UPSTREAM_DNS = "1.1.1.1"
        private const val DNS_PORT = 53
        private const val DNS_TIMEOUT_MS = 1500
        private const val DNS_HEADER_SIZE = 12
        private const val IPV4_HEADER_SIZE = 20
        private const val UDP_HEADER_SIZE = 8
        private const val UDP_PROTOCOL = 17
        private const val MAX_PACKET_SIZE = 32767
        private const val MAX_DNS_PACKET_SIZE = 4096
        private const val CHANNEL_ID = "safe_content_vpn_channel"
        private const val NOTIFICATION_ID = 3101
        private val ADULT_DOMAINS = setOf("pornhub.com", "xvideos.com", "xhamster.com")
        private val GAMBLING_DOMAINS = setOf("bet365.com", "betway.com", "draftkings.com")
        private val VIOLENCE_DOMAINS = setOf("example-violence.invalid")
        private val SOCIAL_DOMAINS = setOf("facebook.com", "instagram.com", "snapchat.com", "tiktok.com", "x.com", "twitter.com")
    }
}

private fun org.json.JSONArray?.toStringSet(): Set<String> {
    if (this == null) return emptySet()
    return buildSet {
        for (index in 0 until length()) add(optString(index).lowercase())
    }
}

private fun org.json.JSONArray?.toDomainSet(): Set<String> {
    if (this == null) return emptySet()
    return buildSet {
        for (index in 0 until length()) {
            var value = optString(index).trim().lowercase()
            value = value.removePrefix("https://").removePrefix("http://")
            value = value.substringBefore('/').substringBefore('?').substringBefore('#')
            value = value.removePrefix("www.")
            if (value.isNotEmpty()) add(value)
        }
    }
}
