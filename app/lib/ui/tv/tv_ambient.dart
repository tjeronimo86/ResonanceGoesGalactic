import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/desktop.dart';
import '../../core/tv_mode.dart';
import '../../l10n/l10n.dart';
import '../../player/player.dart';
import 'tv_now_playing.dart';

class TvAmbient extends ConsumerStatefulWidget {
  const TvAmbient({super.key, required this.child});
  final Widget child;

  static final _inputChanges = ValueNotifier(0);
  static final _focusKeyDowns = <LogicalKeyboardKey>{};
  static final _focusKeyUps = <LogicalKeyboardKey>{};
  static final _focusHeldKeys = <LogicalKeyboardKey>{};
  // How long the full-screen player waits without input before it dims.
  static const idleDelay = Duration(seconds: 10);
  // After it is switched on in the player, input is ignored this long: the release of the key or controller button
  // that pressed the switch, or the mouse moving on after the click, would wake it right away.
  static const showNowGrace = Duration(milliseconds: 1500);
  static bool consumeNext = false;
  static bool _showing = false;
  // How many full-screen players are open: the ambient mode only dims the player, not the rest of the app.
  static final _players = ValueNotifier(0);
  static final _showNowRequests = ValueNotifier(0);

  /// Dims right away (when it is switched on in the player), so it is clear what the mode does.
  static void showNow() => _showNowRequests.value++;

  static void noteInput({bool controller = false}) {
    if (controller && _showing) consumeNext = true;
    _inputChanges.value++;
  }

  static bool consumeFocusKeyEvent(KeyEvent event) => switch (event) {
    KeyDownEvent() => _focusKeyDowns.remove(event.logicalKey),
    KeyUpEvent() => _focusKeyUps.remove(event.logicalKey),
    KeyRepeatEvent() => _focusHeldKeys.contains(event.logicalKey),
    _ => false,
  };

  @override
  ConsumerState<TvAmbient> createState() => _TvAmbientState();
}

class _TvAmbientState extends ConsumerState<TvAmbient> {
  final _random = math.Random();
  final _swallowedKeys = <LogicalKeyboardKey>{};
  Timer? _idleTimer;
  Timer? _fadeTimer;
  Timer? _driftTimer;
  Timer? _grace;
  ProviderSubscription<bool>? _mode;
  ProviderSubscription<bool>? _setting;
  ProviderSubscription<PlayerView>? _player;
  bool _eligible = false;
  bool _visible = false;
  bool _mountedOverlay = false;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    TvAmbient._inputChanges.addListener(_onInput);
    TvAmbient._players.addListener(_syncEligibility);
    TvAmbient._showNowRequests.addListener(_showNow);
    _mode = ref.listenManual(tvModeProvider, (_, _) => _syncEligibility());
    _setting = ref.listenManual(tvAmbientModeProvider, (_, _) => _syncEligibility());
    _player = ref.listenManual(playerProvider, (_, _) => _syncEligibility());
    _syncEligibility();
  }

  void _syncEligibility() {
    final player = ref.read(playerProvider);
    final loaded = player.current != null || player.book != null || player.station != null;
    // Only full-screen players mark a zone: the TV player, and the desktop app's player.
    final allowed = ref.read(tvAmbientModeProvider) && TvAmbient._players.value > 0;
    // Once dimmed it stays until the remote is used: a song change briefly is not "playing" and must not wake it.
    if (_visible && allowed && loaded) return;
    final eligible = allowed && player.playing && loaded;
    if (_eligible == eligible) return;
    _eligible = eligible;
    _idleTimer?.cancel();
    if (eligible) {
      _scheduleIdle();
    } else {
      _setVisible(false);
    }
  }

  void _showNow() {
    final player = ref.read(playerProvider);
    final loaded = player.current != null || player.book != null || player.station != null;
    // Asked for directly, it also dims while paused; it then stays until the next input like after a pause.
    if (!ref.read(tvAmbientModeProvider) || TvAmbient._players.value == 0 || !loaded) return;
    _idleTimer?.cancel();
    _setVisible(true);
    _grace?.cancel();
    _grace = Timer(TvAmbient.showNowGrace, () => _grace = null);
  }

  void _scheduleIdle() {
    _idleTimer?.cancel();
    if (!_eligible) return;
    _idleTimer = Timer(TvAmbient.idleDelay, () {
      if (mounted && _eligible) _setVisible(true);
    });
  }

  void _onInput() {
    if (_visible && _grace != null) return;
    if (_visible) {
      _setVisible(false);
      // It may have stayed dimmed through a pause: decide afresh whether to dim again later.
      _eligible = false;
      _syncEligibility();
      return;
    }
    if (!_eligible) return;
    _scheduleIdle();
  }

  void _setVisible(bool visible) {
    _fadeTimer?.cancel();
    TvAmbient._showing = visible;
    if (visible) {
      _driftTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
        if (!mounted || !_visible) return;
        setState(() {
          _offset = Offset(_random.nextDouble() * 80 - 40, _random.nextDouble() * 60 - 30);
        });
      });
      setState(() {
        _visible = true;
        _mountedOverlay = true;
      });
    } else {
      if (!_visible && !_mountedOverlay) return;
      _driftTimer?.cancel();
      _driftTimer = null;
      setState(() => _visible = false);
      _fadeTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted && !_visible) setState(() => _mountedOverlay = false);
      });
    }
  }

  bool _handleHardwareKey(KeyEvent event) {
    final showing = _visible;
    if (event is KeyDownEvent) {
      TvAmbient.noteInput();
      if (!showing) return false;
      _swallowedKeys.add(event.logicalKey);
      TvAmbient._focusKeyDowns.add(event.logicalKey);
      TvAmbient._focusHeldKeys.add(event.logicalKey);
      return true;
    }
    if (event is KeyUpEvent) {
      TvAmbient.noteInput();
      if (!_swallowedKeys.remove(event.logicalKey)) return false;
      TvAmbient._focusHeldKeys.remove(event.logicalKey);
      TvAmbient._focusKeyUps.add(event.logicalKey);
      return true;
    }
    if (event is KeyRepeatEvent) {
      TvAmbient.noteInput();
      return _swallowedKeys.contains(event.logicalKey);
    }
    TvAmbient.noteInput();
    return false;
  }

  @override
  void dispose() {
    _mode?.close();
    _setting?.close();
    _player?.close();
    _idleTimer?.cancel();
    _fadeTimer?.cancel();
    _driftTimer?.cancel();
    _grace?.cancel();
    TvAmbient._inputChanges.removeListener(_onInput);
    TvAmbient._players.removeListener(_syncEligibility);
    TvAmbient._showNowRequests.removeListener(_showNow);
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    TvAmbient._showing = false;
    TvAmbient.consumeNext = false;
    TvAmbient._focusKeyDowns.clear();
    TvAmbient._focusKeyUps.clear();
    TvAmbient._focusHeldKeys.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => TvAmbient.noteInput(),
      onPointerMove: (_) => TvAmbient.noteInput(),
      onPointerUp: (_) => TvAmbient.noteInput(),
      onPointerHover: (_) => TvAmbient.noteInput(),
      onPointerSignal: (_) => TvAmbient.noteInput(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned.fill(
            child: AnimatedOpacity(
              key: const ValueKey('tv-ambient-overlay'),
              opacity: _visible ? 1 : 0,
              duration: Duration(milliseconds: _visible ? 1200 : 250),
              child: _mountedOverlay
                  ? AbsorbPointer(
                      absorbing: _visible,
                      // Above the router's Navigator there is no Material, so text would get the debug underline.
                      child: Material(
                        color: Colors.black,
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              Positioned(
                                left: constraints.maxWidth * 0.06,
                                bottom: constraints.maxHeight * 0.06,
                                width: constraints.maxWidth * 0.88,
                                child: AnimatedContainer(
                                  key: const ValueKey('tv-ambient-drift'),
                                  duration: const Duration(seconds: 3),
                                  curve: Curves.easeInOut,
                                  transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 800),
                                    child: _ambientContent(context, player),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientContent(BuildContext context, PlayerView player) => Row(
    key: ValueKey(_mediaKey(player)),
    children: [
      ClipRRect(
        key: const ValueKey('tv-ambient-artwork'),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 220, height: 220, child: TvPlaybackArtwork(player: player)),
      ),
      const SizedBox(width: 32),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tvPlaybackTitle(context, player),
              key: const ValueKey('tv-ambient-title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              tvPlaybackArtist(player),
              key: const ValueKey('tv-ambient-artist'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 26, color: Colors.white70),
            ),
          ],
        ),
      ),
    ],
  );

  String _mediaKey(PlayerView player) => player.station != null
      ? 'station:${player.station!.id}'
      : player.book != null
      ? 'book:${player.book!.itemId}'
      : player.current?.id ?? '';
}

class TvAmbientModeSetting extends ConsumerWidget {
  const TvAmbientModeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(tvModeProvider) && !isDesktop) return const SizedBox.shrink();
    return SwitchListTile(
      title: Text(context.l10n.settingsTvAmbient),
      subtitle: Text(context.l10n.settingsTvAmbientHint),
      value: ref.watch(tvAmbientModeProvider),
      onChanged: ref.read(tvAmbientModeProvider.notifier).set,
    );
  }
}

/// Desktop player: dims right away (switching the ambient mode on if it was off). Switching it off is in the
/// settings: a toggle here was on by default, so its first click turned it off and seemed to do nothing.
class AmbientModeButton extends ConsumerWidget {
  const AmbientModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: context.l10n.settingsTvAmbient,
    icon: const Icon(Icons.dark_mode_outlined),
    onPressed: () {
      if (!ref.read(tvAmbientModeProvider)) ref.read(tvAmbientModeProvider.notifier).set(true);
      TvAmbient.showNow();
    },
  );
}

/// Marks its subtree as the full-screen player, the only place the ambient mode dims.
class TvAmbientZone extends StatefulWidget {
  const TvAmbientZone({super.key, required this.child});
  final Widget child;

  @override
  State<TvAmbientZone> createState() => _TvAmbientZoneState();
}

class _TvAmbientZoneState extends State<TvAmbientZone> {
  @override
  void initState() {
    super.initState();
    TvAmbient._players.value++;
  }

  @override
  void dispose() {
    // Deferred: the ambient overlay may be torn down at the same time and must not react mid-teardown.
    scheduleMicrotask(() => TvAmbient._players.value--);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
