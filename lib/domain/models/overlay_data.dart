/// Simple value object describing what the overlay should display.
class OverlayData {
  const OverlayData({
    required this.appName,
    required this.usedMinutes,
    required this.limitMinutes,
  });

  final String appName;
  final int usedMinutes;
  final int limitMinutes;
}


