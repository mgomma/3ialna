/// Pseudo package used to represent total device usage.
const String totalUsagePackage = '__total_usage__';

/// Map of social media package names to human-readable app names.
const Map<String, String> socialMediaApps = {
  totalUsagePackage: 'All Apps',
  'com.facebook.katana': 'Facebook',
  'com.instagram.android': 'Instagram',
  'com.instagram.barcelona': 'Threads',
  'com.twitter.android': 'Twitter',
  'com.snapchat.android': 'Snapchat',
  'com.zhiliaoapp.musically': 'TikTok',
  'com.ss.android.ugc.trill': 'TikTok',
  'com.reddit.frontpage': 'Reddit',
  'com.discord': 'Discord',
  'com.pinterest': 'Pinterest',
  'com.tumblr': 'Tumblr',
  'com.google.android.youtube': 'YouTube',
};

/// Common Android game packages used as a transparent starter registry.
/// Parents can move any installed app to another category or remove it.
const Map<String, String> gameApps = {
  'com.roblox.client': 'Roblox',
  'com.mojang.minecraftpe': 'Minecraft',
  'com.epicgames.fortnite': 'Fortnite',
  'com.tencent.ig': 'PUBG Mobile',
  'com.dts.freefireth': 'Free Fire',
  'com.mobile.legends': 'Mobile Legends',
  'com.supercell.clashofclans': 'Clash of Clans',
  'com.supercell.clashroyale': 'Clash Royale',
  'com.supercell.brawlstars': 'Brawl Stars',
  'com.king.candycrushsaga': 'Candy Crush Saga',
  'com.kiloo.subwaysurf': 'Subway Surfers',
};

