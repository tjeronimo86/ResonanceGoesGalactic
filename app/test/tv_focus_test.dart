import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:resonance/core/audiobooks.dart';
import 'package:resonance/core/books.dart';
import 'package:resonance/core/library.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/core/session.dart';
import 'package:resonance/core/theme.dart';
import 'package:resonance/core/tv_mode.dart';
import 'package:resonance/l10n/l10n.dart';
import 'package:resonance/player/connect.dart';
import 'package:resonance/player/engine.dart';
import 'package:resonance/player/player.dart';
import 'package:resonance/router.dart';
import 'package:resonance/ui/pages/auth_pages.dart';
import 'package:resonance/ui/tv/tv_focusable.dart';
import 'package:resonance/ui/tv/tv_input.dart';
import 'package:resonance/ui/tv/tv_settings_controls.dart';
import 'package:resonance/ui/tv/tv_shelves.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/idle_connect.dart';

class _Engine implements PlaybackEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Player extends PlayerController {
  _Player() : super(engine: _Engine());
  int toggles = 0;
  int nexts = 0;
  int previouses = 0;
  List<Track>? played;
  int? playedIndex;

  @override
  PlayerView build() {
    ref.onDispose(() {
      userVolume.dispose();
      errors.close();
    });
    return const PlayerView();
  }

  @override
  void togglePlay() => toggles++;
  @override
  Future<void> next() async => nexts++;
  @override
  Future<void> previous() async => previouses++;
  @override
  Future<void> setShuffle(bool enabled) async {}
  @override
  Future<void> playTracks(List<Track> tracks, {int? index, String? context, bool isRadio = false}) async {
    played = tracks;
    playedIndex = index;
  }
}

class _Session extends SessionNotifier {
  @override
  SessionState build() => SessionState(
    serverUrl: 'https://resonance.example',
    token: 'test',
    user: User(
      id: 'user',
      username: 'user',
      displayName: 'User',
      role: 'user',
      accentColor: '#1DB954',
      isDisabled: false,
      createdAt: DateTime(2026),
    ),
  );
}

const _track = Track(
  id: 'track',
  title: 'Song',
  artist: NamedRef('artist', 'Artist'),
  artistCredit: 'Artist',
  album: NamedRef('album', 'Album'),
  duration: 60,
);
const _album = Album(id: 'album', title: 'Album', artist: NamedRef('artist', 'Artist'), hasCover: false, trackCount: 1);

NormalizedGamepadEvent _event({GamepadButton? button, GamepadAxis? axis, double value = 1}) => NormalizedGamepadEvent(
  gamepadId: 'pad',
  timestamp: 0,
  value: value,
  button: button,
  axis: axis,
  rawEvent: GamepadEvent(gamepadId: 'pad', timestamp: 0, type: KeyType.button, key: '', value: value),
);

Widget _app(Widget child) => MaterialApp(
  theme: buildTheme(defaultAccent),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('TV focus accepts remote activation and shows the shared focus treatment', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var activations = 0;
    await tester.pumpWidget(
      _app(
        Center(
          child: TvFocusable(focusNode: node, onActivate: () => activations++, child: const Text('Card')),
        ),
      ),
    );
    node.requestFocus();
    await tester.pumpAndSettle();
    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.select, LogicalKeyboardKey.gameButtonA]) {
      await tester.sendKeyEvent(key);
    }
    expect(activations, 3);
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(scale.scale, 1.06);
    expect(scale.duration, const Duration(milliseconds: 150));
    expect((box.decoration! as BoxDecoration).border, Border.all(color: Colors.white, width: 3));
  });

  testWidgets('D-pad traverses shelves, preserves columns and scrolls offscreen cards into view', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        TvShelves(
          title: 'Home',
          shelves: [
            for (var row = 0; row < 3; row++)
              TvShelfData('Shelf $row', [
                for (var column = 0; column < 6; column++)
                  TvCardData(
                    title: '$row/$column',
                    image: const ColoredBox(color: Colors.green),
                    onActivate: () {},
                  ),
              ]),
          ],
        ),
      ),
    );
    final first = tester.widget<TvFocusable>(find.byType(TvFocusable).first);
    first.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'Shelf 0/4');
    expect(tester.getRect(find.text('0/4')).overlaps(const Rect.fromLTWH(0, 0, 800, 600)), true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'Shelf 1/4');
    expect(tester.getRect(find.text('1/4')).overlaps(const Rect.fromLTWH(0, 0, 800, 600)), true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'Shelf 0/4');
  });

  testWidgets('controller deadzone, repeat timing, release, disconnect and buttons are mapped', (tester) async {
    final keys = <LogicalKeyboardKey>[];
    final input = TvControllerInput(keys.add);
    addTearDown(input.clear);
    input.handle(_event(axis: GamepadAxis.leftStickX, value: 0.49));
    expect(keys, isEmpty);
    input.handle(_event(axis: GamepadAxis.leftStickX, value: 0.8));
    expect(keys, [LogicalKeyboardKey.arrowRight]);
    await tester.pump(const Duration(milliseconds: 299));
    expect(keys.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(keys.length, 2);
    await tester.pump(const Duration(milliseconds: 120));
    expect(keys.length, 3);
    input.handle(_event(axis: GamepadAxis.leftStickX, value: 0));
    await tester.pump(const Duration(seconds: 1));
    expect(keys.length, 3);
    input.handle(_event(button: GamepadButton.dpadDown));
    expect(keys.last, LogicalKeyboardKey.arrowDown);
    input.disconnect('pad');
    await tester.pump(const Duration(seconds: 1));
    expect(keys.length, 4);
    for (final button in [
      GamepadButton.a,
      GamepadButton.b,
      GamepadButton.x,
      GamepadButton.y,
      GamepadButton.leftBumper,
      GamepadButton.rightBumper,
      GamepadButton.start,
    ]) {
      input.handle(_event(button: button));
      input.handle(_event(button: button));
      input.handle(_event(button: button, value: 0));
    }
    expect(keys.skip(4), [
      LogicalKeyboardKey.gameButtonA,
      LogicalKeyboardKey.gameButtonB,
      LogicalKeyboardKey.gameButtonX,
      LogicalKeyboardKey.gameButtonY,
      LogicalKeyboardKey.gameButtonLeft1,
      LogicalKeyboardKey.gameButtonRight1,
      LogicalKeyboardKey.gameButtonStart,
    ]);
  });

  testWidgets('settings switches and sliders are reachable and adjustable with a D-pad', (tester) async {
    var enabled = false;
    var volume = 0.5;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => TvSettingsList(
            tvMode: true,
            padding: const EdgeInsets.all(24),
            children: [
              SwitchListTile(
                autofocus: true,
                title: const Text('Switch'),
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
              ),
              Slider(value: volume, onChanged: (value) => setState(() => volume = value)),
              for (var i = 0; i < 12; i++) ListTile(title: Text('Setting $i'), onTap: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(enabled, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(enabled, false);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(volume, greaterThan(0.5));
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(tester.getRect(find.text('Setting 11')).overlaps(const Rect.fromLTWH(0, 0, 800, 600)), true);
  });

  testWidgets('settings horizontal groups keep left and right in the row and exit vertically', (tester) async {
    final before = FocusNode(debugLabel: 'Previous setting');
    final swatches = List.generate(3, (index) => FocusNode(debugLabel: 'Swatch $index'));
    final after = FocusNode(debugLabel: 'Next setting');
    final bubbledDirections = <TraversalDirection>[];
    addTearDown(before.dispose);
    addTearDown(() {
      for (final node in swatches) {
        node.dispose();
      }
    });
    addTearDown(after.dispose);
    await tester.pumpWidget(
      _app(
        Actions(
          actions: {
            TvDirectionIntent: CallbackAction<TvDirectionIntent>(
              onInvoke: (intent) {
                bubbledDirections.add(intent.direction);
                return null;
              },
            ),
          },
          child: TvSettingsList(
            tvMode: true,
            padding: const EdgeInsets.all(24),
            children: [
              TvFocusable(focusNode: before, autofocus: true, onActivate: () {}, child: const Text('Previous setting')),
              TvHorizontalGroup(
                initialFocusIndex: 2,
                child: FocusTraversalGroup(
                  child: Row(
                    children: [
                      for (var index = 0; index < swatches.length; index++)
                        TvFocusable(
                          focusNode: swatches[index],
                          onActivate: () {},
                          child: SizedBox(width: 48, height: 48, child: Text('$index')),
                        ),
                    ],
                  ),
                ),
              ),
              TvFocusable(focusNode: after, onActivate: () {}, child: const Text('Next setting')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, swatches.last);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, swatches[1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, swatches.first);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(bubbledDirections, [TraversalDirection.left]);
    expect(FocusManager.instance.primaryFocus, swatches.first);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, swatches[1]);
    Actions.invoke(FocusManager.instance.primaryFocus!.context!, const TvDirectionIntent(TraversalDirection.left));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, swatches.first);
    Actions.invoke(FocusManager.instance.primaryFocus!.context!, const TvDirectionIntent(TraversalDirection.right));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, swatches[1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, swatches.last);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, after);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(swatches, contains(FocusManager.instance.primaryFocus));
  });

  testWidgets('TV router, rail Back, detail activation, controller and global media keys work', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({'tv_mode': true});
    final prefs = await SharedPreferences.getInstance();
    final events = StreamController<NormalizedGamepadEvent>.broadcast();
    addTearDown(events.close);
    final player = _Player();
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        sessionProvider.overrideWith(_Session.new),
        connectProvider.overrideWith(IdleConnect.new),
        playerProvider.overrideWith(() => player),
        positionProvider.overrideWith((ref) => const Stream.empty()),
        durationProvider.overrideWith((ref) => const Stream.empty()),
        tvGamepadEventsProvider.overrideWithValue(events.stream),
        homeProvider.overrideWith((ref) async => const Home([_album], [], [], [])),
        mixesProvider.overrideWith((ref) async => null),
        worldRadioFavoritesProvider.overrideWith((ref) async => []),
        audiobooksVisibleProvider.overrideWithValue(false),
        ebooksVisibleProvider.overrideWithValue(false),
        albumProvider('album').overrideWith((ref) async => const AlbumDetail(_album, [_track], 60, false)),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildTheme(defaultAccent),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => TvInput(child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'Recently played/0');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV Home');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'Recently played/0');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV Home');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    events.add(_event(button: GamepadButton.a));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/album/album');
    events.add(_event(button: GamepadButton.dpadDown));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<TvFocusable>(), isNotNull);
    events.add(_event(button: GamepadButton.dpadDown, value: 0));
    events.add(_event(button: GamepadButton.dpadDown));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV now playing bar');
    events.add(_event(button: GamepadButton.dpadDown, value: 0));
    events.add(_event(button: GamepadButton.dpadUp));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<TvFocusable>(), isNotNull);
    events.add(_event(button: GamepadButton.dpadUp, value: 0));
    // Y jumps to the bar from anywhere on the page and back to the same spot.
    final inPage = FocusManager.instance.primaryFocus;
    events.add(_event(button: GamepadButton.y));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV now playing bar');
    events.add(_event(button: GamepadButton.y, value: 0));
    events.add(_event(button: GamepadButton.y));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, inPage);
    events.add(_event(button: GamepadButton.y, value: 0));
    events.add(_event(button: GamepadButton.dpadLeft));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV Home');
    events.add(_event(button: GamepadButton.dpadLeft, value: 0));
    // Down past the last rail entry reaches the bar.
    final labels = <String?>[];
    for (var i = 0; i < 6; i++) {
      events
        ..add(_event(button: GamepadButton.dpadDown))
        ..add(_event(button: GamepadButton.dpadDown, value: 0));
      await tester.pumpAndSettle();
      labels.add(FocusManager.instance.primaryFocus!.debugLabel);
    }
    expect(labels, [
      'TV /search',
      'TV /library',
      'TV /world-radio',
      'TV /podcasts',
      'TV /settings',
      'TV now playing bar',
    ]);
    events.add(_event(button: GamepadButton.dpadLeft));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'TV Home');
    events.add(_event(button: GamepadButton.dpadLeft, value: 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(player.played, [_track]);
    expect(router.state.uri.path, '/now-playing');
    events.add(_event(button: GamepadButton.b));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/album/album');
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause, platform: 'android');
    events.add(_event(button: GamepadButton.x));
    await tester.pump();
    events.add(_event(button: GamepadButton.leftBumper));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaTrackNext, platform: 'android');
    expect(player.toggles, 2);
    expect(player.previouses, 1);
    expect(player.nexts, 1);
    events.add(_event(button: GamepadButton.start));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/now-playing');
    events.add(_event(button: GamepadButton.start, value: 0));
    events.add(_event(button: GamepadButton.start));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/album/album');
    router.go('/search');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause, platform: 'android');
    expect(player.toggles, 3);
    const window = MethodChannel('window_manager');
    final fullscreen = <bool>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(window, (call) async {
      if (call.method == 'setFullScreen') fullscreen.add((call.arguments as Map)['isFullScreen'] as bool);
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(window, null),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pumpAndSettle();
    expect(container.read(tvModeProvider), false);
    events.add(_event(button: GamepadButton.x, value: 0));
    events.add(_event(button: GamepadButton.x));
    await tester.pump();
    expect(player.toggles, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pumpAndSettle();
    expect(container.read(tvModeProvider), true);
    expect(fullscreen, [false, true]);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('setup autofocus and Enter advance to the next field', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs), androidTvProvider.overrideWithValue(true)],
        child: _app(const RegisterPage(firstSetup: true)),
      ),
    );
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.first.autofocus, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<TextField>()!.controller,
      fields[1].controller,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<TextField>()!.obscureText, true);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<TextField>()!.controller,
      fields.last.controller,
    );
  });
}
