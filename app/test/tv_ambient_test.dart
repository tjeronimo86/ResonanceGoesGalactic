import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/core/session.dart';
import 'package:resonance/core/theme.dart';
import 'package:resonance/core/tv_mode.dart';
import 'package:resonance/l10n/l10n.dart';
import 'package:resonance/player/engine.dart';
import 'package:resonance/player/player.dart';
import 'package:resonance/ui/tv/tv_ambient.dart';
import 'package:resonance/ui/tv/tv_focusable.dart';
import 'package:resonance/ui/tv/tv_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Engine implements PlaybackEngine {
  @override
  final automixing = ValueNotifier(false);
  @override
  Duration get position => Duration.zero;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  bool playing = false;
  @override
  double get speed => 1;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Player extends PlayerController {
  _Player(this.initial) : super(engine: _Engine());
  final PlayerView initial;

  @override
  PlayerView build() {
    ref.onDispose(() {
      engine.automixing.dispose();
      userVolume.dispose();
      errors.close();
    });
    return initial;
  }

  void update(PlayerView player) => state = player;
}

class _TvMode extends TvMode {
  _TvMode(this.initial);
  final bool initial;

  @override
  bool build() => initial;

  @override
  void set(bool enabled) => state = enabled;
}

const _station = Station(
  id: 'ambient-radio',
  name: 'Ambient Radio',
  country: 'Germany',
  countryCode: 'DE',
  tags: [],
  codec: 'MP3',
);

NormalizedGamepadEvent _button(GamepadButton button, {bool pressed = true}) => NormalizedGamepadEvent(
  gamepadId: 'test',
  timestamp: 0,
  value: pressed ? 1 : 0,
  button: button,
  rawEvent: GamepadEvent(gamepadId: 'test', timestamp: 0, type: KeyType.button, key: '', value: pressed ? 1 : 0),
);

void main() {
  tearDown(() => TvAmbient.consumeNext = false);

  Future<(ProviderContainer, StreamController<NormalizedGamepadEvent>, List<KeyEvent>, List<int>)> mount(
    WidgetTester tester, {
    bool tvMode = true,
    bool ambientMode = true,
    bool playing = true,
    bool loaded = true,
    bool onPlayer = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({'tv_mode': tvMode, 'tv.ambient_mode': ambientMode});
    final prefs = await SharedPreferences.getInstance();
    final events = StreamController<NormalizedGamepadEvent>.broadcast();
    addTearDown(events.close);
    final delivered = <KeyEvent>[];
    final activations = <int>[];
    final player = _Player(PlayerView(station: loaded ? _station : null, playing: playing));
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        tvModeProvider.overrideWith(() => _TvMode(tvMode)),
        playerProvider.overrideWith(() => player),
        tvGamepadEventsProvider.overrideWithValue(events.stream),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(defaultAccent),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TvInput(
            child: Focus(
              autofocus: true,
              onKeyEvent: (_, event) {
                delivered.add(event);
                return KeyEventResult.ignored;
              },
              child: TvFocusable(
                autofocus: true,
                onActivate: () => activations.add(activations.length + 1),
                child: onPlayer ? const TvAmbientZone(child: Text('Focusable target')) : const Text('Focusable target'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, events, delivered, activations);
  }

  testWidgets('ambient mode appears after 10 seconds and swallows the key that wakes it', (tester) async {
    final (container, events, delivered, activations) = await mount(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(const ValueKey('tv-ambient-overlay')), findsOneWidget);
    final visible = tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay')));
    expect(visible.opacity, 1);
    expect(visible.duration, const Duration(milliseconds: 1200));
    expect(tester.getSize(find.byKey(const ValueKey('tv-ambient-artwork'))), const Size(220, 220));
    final title = tester.widget<Text>(find.byKey(const ValueKey('tv-ambient-title')));
    expect(title.data, 'Ambient Radio');
    expect(title.maxLines, 2);
    expect(title.style?.fontSize, 44);
    final artist = tester.widget<Text>(find.byKey(const ValueKey('tv-ambient-artist')));
    expect(artist.data, 'Germany');
    expect(artist.style?.fontSize, 26);
    expect(
      tester.widget<AnimatedContainer>(find.byKey(const ValueKey('tv-ambient-drift'))).duration,
      const Duration(seconds: 3),
    );
    final initialOffset = tester
        .widget<AnimatedContainer>(find.byKey(const ValueKey('tv-ambient-drift')))
        .transform!
        .getTranslation();
    await tester.pump(const Duration(seconds: 60));
    final movedOffset = tester
        .widget<AnimatedContainer>(find.byKey(const ValueKey('tv-ambient-drift')))
        .transform!
        .getTranslation();
    expect(movedOffset.x, inInclusiveRange(-40, 40));
    expect(movedOffset.y, inInclusiveRange(-30, 30));
    expect(movedOffset.x != initialOffset.x || movedOffset.y != initialOffset.y, isTrue);

    const nextStation = Station(
      id: 'ambient-radio-next',
      name: 'Next station',
      country: 'Germany',
      countryCode: 'DE',
      tags: [],
      codec: 'MP3',
    );
    (container.read(playerProvider.notifier) as _Player).update(PlayerView(station: nextStation, playing: true));
    await tester.pump();
    expect(find.byKey(const ValueKey('station:ambient-radio')), findsOneWidget);
    expect(find.byKey(const ValueKey('station:ambient-radio-next')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('station:ambient-radio')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 401));
    expect(find.byKey(const ValueKey('station:ambient-radio')), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    expect(delivered, isEmpty);
    await tester.pump();
    final hidden = tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay')));
    expect(hidden.opacity, 0);
    expect(hidden.duration, const Duration(milliseconds: 250));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    expect(delivered, isEmpty);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('tv-ambient-artwork')), findsNothing);

    await tester.pump(const Duration(seconds: 10));
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    events.add(_button(GamepadButton.a));
    await tester.pump();
    expect(activations, isEmpty);
    expect(TvAmbient.consumeNext, isFalse);
  });

  for (final (tvMode, ambientMode, playing, loaded, name) in [
    (true, true, false, true, 'paused playback'),
    (true, false, true, true, 'ambient preference off'),
    (true, true, true, false, 'no loaded media'),
  ]) {
    testWidgets('ambient mode stays hidden for $name', (tester) async {
      await mount(tester, tvMode: tvMode, ambientMode: ambientMode, playing: playing, loaded: loaded);
      await tester.pump(const Duration(seconds: 11));
      expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
      expect(find.byKey(const ValueKey('tv-ambient-artwork')), findsNothing);
    });
  }

  testWidgets('the desktop player dims outside TV mode as well', (tester) async {
    await mount(tester, tvMode: false);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    expect(find.byKey(const ValueKey('tv-ambient-title')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
  });

  testWidgets('ambient mode stays hidden away from the full-screen player', (tester) async {
    await mount(tester, onPlayer: false);
    await tester.pump(const Duration(seconds: 11));
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
  });

  testWidgets('switching it on in the player dims right away', (tester) async {
    await mount(tester);
    TvAmbient.showNow();
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
  });

  testWidgets('asked for directly it also dims while paused', (tester) async {
    await mount(tester, playing: false);
    TvAmbient.showNow();
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    await tester.pump(TvAmbient.showNowGrace);
  });

  testWidgets('releasing the key or button that switched it on does not wake it again', (tester) async {
    final (_, events, _, _) = await mount(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    TvAmbient.showNow();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    events.add(_button(GamepadButton.a, pressed: false));
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    await tester.pump(TvAmbient.showNowGrace);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
  });

  testWidgets('keyboard input resets the 10-second idle timer', (tester) async {
    final (_, _, _, _) = await mount(tester);
    await tester.pump(const Duration(seconds: 7));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.pump(const Duration(seconds: 7));
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
  });

  testWidgets('a song change does not wake ambient mode, only input does', (tester) async {
    final (container, _, _, _) = await mount(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    final player = container.read(playerProvider.notifier) as _Player;
    player.update(const PlayerView(station: _station, playing: false));
    await tester.pump();
    player.update(const PlayerView(station: _station, playing: true));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
  });

  testWidgets('pointer input wakes the ambient overlay without activating content behind it', (tester) async {
    final (_, _, _, activations) = await mount(tester);
    await tester.pump(const Duration(seconds: 10));
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(activations, isEmpty);
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
  });

  testWidgets('ambient preference setting shows in TV mode, not on phones, and persists changes', (tester) async {
    SharedPreferences.setMockInitialValues({'tv_mode': false});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs), tvModeProvider.overrideWith(() => _TvMode(false))],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TvAmbientModeSetting()),
        ),
      ),
    );
    expect(find.byType(SwitchListTile), findsNothing);
    container.read(tvModeProvider.notifier).set(true);
    await tester.pump();
    expect(find.text('Ambient mode'), findsOneWidget);
    expect(find.text('Show only the cover and title when idle'), findsOneWidget);
    expect(container.read(tvAmbientModeProvider), isTrue);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(container.read(tvAmbientModeProvider), isFalse);
    expect(container.read(prefsProvider).getBool('tv.ambient_mode'), isFalse);
  });

  testWidgets('the desktop app shows the setting and a player button that dims right away', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final (container, _, _, _) = await mount(tester, tvMode: false, ambientMode: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TvInput(
            child: TvAmbientZone(
              child: Scaffold(body: Column(children: [TvAmbientModeSetting(), AmbientModeButton()])),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Ambient mode'), findsOneWidget);
    await tester.tap(find.byTooltip('Ambient mode'));
    await tester.pump();
    expect(container.read(tvAmbientModeProvider), isTrue, reason: 'dimming switches the mode on');
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    // The mouse moving on right after the click must not wake it.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    await gesture.moveTo(const Offset(8, 9));
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 1);
    await tester.pump(TvAmbient.showNowGrace);
    await gesture.moveTo(const Offset(40, 40));
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('tv-ambient-overlay'))).opacity, 0);
    await gesture.removePointer();
    await tester.pump(const Duration(seconds: 1));
    debugDefaultTargetPlatformOverride = null;
  });
}
