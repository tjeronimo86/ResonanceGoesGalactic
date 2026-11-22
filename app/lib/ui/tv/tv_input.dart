import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';

import '../../core/desktop.dart';
import '../../core/tv_mode.dart';
import '../../player/player.dart';
import '../../router.dart';
import 'tv_ambient.dart';
import 'tv_focusable.dart';

final tvGamepadEventsProvider = Provider<Stream<NormalizedGamepadEvent>>((ref) => Gamepads.normalizedEvents);

final _directions = {
  LogicalKeyboardKey.arrowUp: TraversalDirection.up,
  LogicalKeyboardKey.arrowDown: TraversalDirection.down,
  LogicalKeyboardKey.arrowLeft: TraversalDirection.left,
  LogicalKeyboardKey.arrowRight: TraversalDirection.right,
};

/// Normalized gamepad input, including held sticks and D-pads. Kept separate for deterministic repeat tests.
class TvControllerInput {
  TvControllerInput(this.onKey);
  final void Function(LogicalKeyboardKey key) onKey;
  final _held = <String, LogicalKeyboardKey>{};
  LogicalKeyboardKey? _repeating;
  Timer? _timer;

  void handle(NormalizedGamepadEvent event) {
    final source = '${event.gamepadId}/${event.button ?? event.axis}';
    final key = switch (event.button) {
      GamepadButton.a => LogicalKeyboardKey.gameButtonA,
      GamepadButton.b => LogicalKeyboardKey.gameButtonB,
      GamepadButton.x => LogicalKeyboardKey.gameButtonX,
      GamepadButton.y => LogicalKeyboardKey.gameButtonY,
      GamepadButton.leftBumper => LogicalKeyboardKey.gameButtonLeft1,
      GamepadButton.rightBumper => LogicalKeyboardKey.gameButtonRight1,
      GamepadButton.start => LogicalKeyboardKey.gameButtonStart,
      GamepadButton.dpadUp => LogicalKeyboardKey.arrowUp,
      GamepadButton.dpadDown => LogicalKeyboardKey.arrowDown,
      GamepadButton.dpadLeft => LogicalKeyboardKey.arrowLeft,
      GamepadButton.dpadRight => LogicalKeyboardKey.arrowRight,
      _ => switch (event.axis) {
        GamepadAxis.leftStickX when event.value.abs() >= 0.5 =>
          event.value < 0 ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
        GamepadAxis.leftStickY when event.value.abs() >= 0.5 =>
          event.value < 0 ? LogicalKeyboardKey.arrowDown : LogicalKeyboardKey.arrowUp,
        _ => null,
      },
    };
    final pressed = key != null && (event.axis != null || event.value >= 0.5);
    final previous = _held[source];
    if (pressed && previous == key) return;
    _held.remove(source);
    if (pressed) {
      _held[source] = key;
      if (!_directions.containsKey(key)) onKey(key);
    }
    _updateRepeat();
  }

  void _updateRepeat() {
    final arrows = _held.values.where(_directions.containsKey);
    final key = arrows.isEmpty ? null : arrows.last;
    if (key == _repeating) return;
    _timer?.cancel();
    _repeating = key;
    if (key == null) return;
    onKey(key);
    _timer = Timer(const Duration(milliseconds: 300), () {
      onKey(key);
      _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => onKey(key));
    });
  }

  void disconnect(String id) {
    _held.removeWhere((source, _) => source.startsWith('$id/'));
    _updateRepeat();
  }

  void clear() {
    _held.clear();
    _timer?.cancel();
    _repeating = null;
  }
}

/// Lives above the router so media keys also work in full-screen playback, dialogs and text fields.
class TvInput extends ConsumerStatefulWidget {
  const TvInput({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<TvInput> createState() => _TvInputState();
}

class _TvInputState extends ConsumerState<TvInput> with WidgetsBindingObserver {
  late final _controller = TvControllerInput((key) => _dispatch(key, controller: true));
  StreamSubscription<NormalizedGamepadEvent>? _events;
  StreamSubscription<GamepadConnectionEvent>? _connections;
  ProviderSubscription<bool>? _mode;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_handleKey);
    WidgetsBinding.instance.addObserver(this);
    _mode = ref.listenManual(tvModeProvider, (_, active) => _setActive(active), fireImmediately: true);
  }

  void _setActive(bool active) {
    _active = active;
    _events?.cancel();
    _connections?.cancel();
    _events = null;
    _connections = null;
    _controller.clear();
    if (!active) return;
    try {
      _events = ref
          .read(tvGamepadEventsProvider)
          .listen(
            _handleGamepad,
            onError: (Object error) {
              _controller.clear();
              debugPrint('TV controller unavailable: $error');
            },
          );
      _connections = Gamepads.onDisconnected.listen(
        (event) => _controller.disconnect(event.gamepadId),
        onError: (Object error) => debugPrint('TV controller connection unavailable: $error'),
      );
    } catch (error) {
      debugPrint('TV controller initialization failed: $error');
    }
  }

  void _handleGamepad(NormalizedGamepadEvent event) {
    TvAmbient.noteInput(controller: true);
    try {
      _controller.handle(event);
    } finally {
      TvAmbient.consumeNext = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller.clear();
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (TvAmbient.consumeFocusKeyEvent(event)) return KeyEventResult.handled;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.f11 && isDesktop) {
      unawaited(ref.read(tvModeProvider.notifier).toggleFullscreen());
      return KeyEventResult.handled;
    }
    return _active && _dispatch(event.logicalKey) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  bool _dispatch(LogicalKeyboardKey key, {bool controller = false}) {
    if (TvAmbient.consumeNext) {
      TvAmbient.consumeNext = false;
      _controller.clear();
      return true;
    }
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (controller && _directions.containsKey(key)) {
      final intent = TvDirectionIntent(_directions[key]!);
      if (context != null && Actions.maybeFind<TvDirectionIntent>(context) != null) {
        Actions.invoke(context, intent);
      } else {
        focus?.focusInDirection(intent.direction);
      }
      return true;
    }
    if (controller && key == LogicalKeyboardKey.gameButtonA) {
      if (context != null) Actions.maybeInvoke(context, const ActivateIntent());
      return true;
    }
    if ({LogicalKeyboardKey.escape, LogicalKeyboardKey.goBack, LogicalKeyboardKey.gameButtonB}.contains(key)) {
      if (context != null && Actions.maybeFind<TvBackIntent>(context) != null) {
        Actions.invoke(context, const TvBackIntent());
      } else if (context != null) {
        Navigator.of(context).maybePop();
      }
      return true;
    }
    if (key == LogicalKeyboardKey.gameButtonY) {
      if (context != null) Actions.maybeInvoke(context, const TvNowPlayingBarIntent());
      return true;
    }
    if (key == LogicalKeyboardKey.gameButtonStart) {
      final router = ref.read(routerProvider);
      if (router.state.uri.path != '/now-playing') router.push('/now-playing');
      return true;
    }
    final player = switch (key) {
      LogicalKeyboardKey.mediaPlayPause || LogicalKeyboardKey.gameButtonX => ref.read(playerProvider.notifier),
      LogicalKeyboardKey.mediaPlay || LogicalKeyboardKey.mediaPause => ref.read(playerProvider.notifier),
      LogicalKeyboardKey.mediaTrackNext || LogicalKeyboardKey.gameButtonRight1 => ref.read(playerProvider.notifier),
      LogicalKeyboardKey.mediaTrackPrevious || LogicalKeyboardKey.gameButtonLeft1 => ref.read(playerProvider.notifier),
      _ => null,
    };
    if (player == null) return false;
    switch (key) {
      case LogicalKeyboardKey.mediaPlay:
        player.play();
      case LogicalKeyboardKey.mediaPause:
        player.pause();
      case LogicalKeyboardKey.mediaTrackNext || LogicalKeyboardKey.gameButtonRight1:
        player.next();
      case LogicalKeyboardKey.mediaTrackPrevious || LogicalKeyboardKey.gameButtonLeft1:
        player.previous();
      default:
        player.togglePlay();
    }
    return true;
  }

  @override
  void dispose() {
    _mode?.close();
    _events?.cancel();
    _connections?.cancel();
    _controller.clear();
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKey);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TvAmbient(child: widget.child);
}
