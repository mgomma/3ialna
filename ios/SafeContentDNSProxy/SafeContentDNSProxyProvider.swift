import NetworkExtension
import Network

final class SafeContentDNSProxyProvider: NEDNSProxyProvider {
  private let policyStore = SafeContentDNSPolicyStore()

  override func startProxy(options: [String: Any]?, completionHandler: @escaping (Error?) -> Void) {
    policyStore.reload()
    completionHandler(nil)
  }

  override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
    guard let udpFlow = flow as? NEAppProxyUDPFlow else {
      return false
    }

    let handler = SafeContentDNSFlowHandler(flow: udpFlow, policyStore: policyStore)
    handler.start()
    return true
  }
}

private final class SafeContentDNSPolicyStore {
  private(set) var blockedDomains: Set<String> = []
  private(set) var allowedDomains: Set<String> = []

  func reload() {
    let defaults = UserDefaults(suiteName: "group.com.example.muSuperApp")
    blockedDomains = Set((defaults?.array(forKey: "safe_content.blocked_domains") as? [String] ?? []).compactMap(Self.normalize))
    allowedDomains = Set((defaults?.array(forKey: "safe_content.allowed_domains") as? [String] ?? []).compactMap(Self.normalize))
  }

  func shouldBlock(_ domain: String) -> Bool {
    guard let normalized = Self.normalize(domain) else { return false }
    if matches(normalized, in: allowedDomains) { return false }
    return matches(normalized, in: blockedDomains)
  }

  private func matches(_ domain: String, in rules: Set<String>) -> Bool {
    rules.contains { domain == $0 || domain.hasSuffix("." + $0) }
  }

  private static func normalize(_ value: String) -> String? {
    var result = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if let url = URL(string: result), let host = url.host {
      result = host
    }
    result = result.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    guard !result.isEmpty, !result.contains("/"), !result.contains(" ") else { return nil }
    return result
  }
}

private final class SafeContentDNSFlowHandler {
  private let flow: NEAppProxyUDPFlow
  private let policyStore: SafeContentDNSPolicyStore

  init(flow: NEAppProxyUDPFlow, policyStore: SafeContentDNSPolicyStore) {
    self.flow = flow
    self.policyStore = policyStore
  }

  func start() {
    flow.open(withLocalEndpoint: nil) { [weak self] error in
      guard let self, error == nil else { return }
      self.readNextDatagrams()
    }
  }

  private func readNextDatagrams() {
    flow.readDatagrams { [weak self] datagrams, endpoints, error in
      guard let self, error == nil, let datagrams, let endpoints else { return }
      for (index, datagram) in datagrams.enumerated() {
        guard let endpoint = endpoints.indices.contains(index) ? endpoints[index] : nil else { continue }
        self.handle(datagram: datagram, endpoint: endpoint)
      }
      self.readNextDatagrams()
    }
  }

  private func handle(datagram: Data, endpoint: NWEndpoint) {
    guard let query = DNSMessage(data: datagram) else { return }
    if let name = query.firstQuestionName, policyStore.shouldBlock(name) {
      let response = query.nxdomainResponse()
      flow.writeDatagrams([response], sentBy: [endpoint]) { _ in }
      return
    }

    forward(datagram: datagram, replyTo: endpoint)
  }

  private func forward(datagram: Data, replyTo endpoint: NWEndpoint) {
    let resolverHost = NWEndpoint.Host("1.1.1.1")
    let resolverPort = NWEndpoint.Port(rawValue: 53)!
    let connection = NWConnection(host: resolverHost, port: resolverPort, using: .udp)
    connection.stateUpdateHandler = { [weak self, weak connection] state in
      guard let self, let connection else { return }
      switch state {
      case .ready:
        connection.send(content: datagram, completion: .contentProcessed { error in
          guard error == nil else { connection.cancel(); return }
          connection.receiveMessage { data, _, _, error in
            defer { connection.cancel() }
            guard error == nil, let data else { return }
            self.flow.writeDatagrams([data], sentBy: [endpoint]) { _ in }
          }
        })
      case .failed, .cancelled:
        break
      default:
        break
      }
    }
    connection.start(queue: DispatchQueue.global(qos: .utility))
  }
  }
}

private struct DNSMessage {
  let data: Data
  let firstQuestionName: String?

  init?(data: Data) {
    guard data.count >= 12 else { return nil }
    self.data = data
    self.firstQuestionName = DNSMessage.readQuestionName(data: data, offset: 12)?.name
  }

  func nxdomainResponse() -> Data {
    var response = data
    response[2] |= 0x80
    response[3] = (response[3] & 0xF0) | 0x03
    response[6] = 0; response[7] = 0
    response[8] = 0; response[9] = 0
    response[10] = 0; response[11] = 0
    return response
  }

  private static func readQuestionName(data: Data, offset: Int) -> (name: String, nextOffset: Int)? {
    var cursor = offset
    var labels: [String] = []
    while cursor < data.count {
      let length = Int(data[cursor]); cursor += 1
      if length == 0 { return (labels.joined(separator: "."), cursor + 4) }
      guard length < 64, cursor + length <= data.count else { return nil }
      labels.append(String(decoding: data[cursor..<(cursor + length)], as: UTF8.self))
      cursor += length
    }
    return nil
  }
}
