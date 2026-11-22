import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop.dart';
import 'session.dart';

/// Resolved before runApp so Android TV never briefly displays the touch shell.
final androidTvProvider = Provider<bool>((ref) => false);

Future<bool> detectAndroidTv() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await const MethodChannel('resonance/device').invokeMethod<bool>('isTv') ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

final tvModeProvider = NotifierProvider<TvMode, bool>(TvMode.new);
final tvAmbientModeProvider = NotifierProvider<TvAmbientMode, bool>(TvAmbientMode.new);

class TvAmbientMode extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsProvider).getBool('tv.ambient_mode') ?? true;

  void set(bool enabled) {
    ref.read(prefsProvider).setBool('tv.ambient_mode', enabled);
    state = enabled;
  }
}

class TvMode extends Notifier<bool> {
  @override
  bool build() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return ref.watch(androidTvProvider);
    return isDesktop && (ref.read(prefsProvider).getBool('tv_mode') ?? isGamescope);
  }

  void set(bool enabled) {
    if (!isDesktop) return;
    ref.read(prefsProvider).setBool('tv_mode', enabled);
    state = enabled;
  }

  Future<void> toggleFullscreen() async {
    if (!isDesktop) return;
    set(!state);
    try {
      // Under gamescope the window stays fullscreen; only the interface changes.
      await windowManager.setFullScreen(state || isGamescope);
    } on PlatformException catch (error) {
      debugPrint('TV fullscreen unavailable: $error');
    } on MissingPluginException {
      // A missing window host must not prevent switching the interface.
    }
  }
}

/// The TV interface is laid out for a 1920 px wide screen and scaled to the real one: Android TVs report 960x540
/// logical pixels at 1080p, desktop windows anything.
class TvCanvas extends StatelessWidget {
  const TvCanvas({super.key, required this.child});
  final Widget child;

  static const width = 1920.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight || constraints.maxWidth == 0) return child;
      final scale = constraints.maxWidth / width;
      final size = Size(width, constraints.maxHeight / scale);
      final media = MediaQuery.of(context);
      return FittedBox(
        fit: BoxFit.fill,
        child: SizedBox.fromSize(
          size: size,
          child: MediaQuery(
            data: media.copyWith(
              size: size,
              devicePixelRatio: media.devicePixelRatio * scale,
              padding: media.padding / scale,
              viewPadding: media.viewPadding / scale,
              viewInsets: media.viewInsets / scale,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}
