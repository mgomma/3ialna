import 'package:flutter/services.dart';

import '../../domain/models/child_profile.dart';

class ChildShortcutService {
  static const MethodChannel _channel = MethodChannel('parental_control/children');

  static Future<void> sync(List<ChildProfile> children) async {
    try {
      await _channel.invokeMethod<void>('updateLauncherShortcuts', <String, Object>{
        'children': children
            .map((ChildProfile child) => <String, String>{'id': child.id, 'name': child.name})
            .toList(growable: false),
      });
    } on MissingPluginException {
      // Launcher shortcuts are Android-only.
    }
  }

  static Future<String?> consumeInitialChildId() async {
    try {
      return await _channel.invokeMethod<String>('consumeInitialChildShortcut');
    } on MissingPluginException {
      return null;
    }
  }

  static void listen(Future<void> Function(String childId) onSelected) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onChildShortcut') {
        final String? childId = call.arguments as String?;
        if (childId != null && childId.isNotEmpty) await onSelected(childId);
      }
    });
  }
}
