// Renders the Galactic view at phone and tablet sizes into test/goldens/ so the layout can be looked at
// (run with --update-goldens; the workflow "Galactic Layout" uploads the pictures).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:resonance/core/api.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/core/session.dart';
import 'package:resonance/galactic/galactic_page.dart';
import 'package:resonance/l10n/l10n.dart';
import 'package:resonance/offline/offline_store.dart';
import 'package:resonance/player/connect.dart';
import 'package:resonance/player/engine.dart';
import 'package:resonance/player/player.dart';
import 'package:resonance/player/spectrum.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/idle_connect.dart';

final _tracks = [
  for (final (i, title) in const [
    'Golou l\'mama', 'Fruit de la passion', 'Espera', 'This Is My Life', 'Love of My Life', 'To Love Somebody',
    'Kingston Town', 'Milla (Ao Vivo)',
  ].indexed)
    Track(
      id: 't$i',
      title: title,
      duration: 200.0 + i * 13,
      trackNo: i + 1,
      artist: const NamedRef('artist', 'Artist'),
      artistCredit: 'Artist',
      album: NamedRef('a$i', 'Album $i'),
    ),
];

class _Engine implements PlaybackEngine {
  @override
  final automixing = ValueNotifier(false);
  @override
  Duration get position => const Duration(seconds: 17);
  @override
  Duration? get duration => const Duration(seconds: 241);
  @override
  List<String> get playerIds => const [];
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  bool playing = true;
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
}

class _Offline extends OfflineController {
  _Offline(this.directory);
  final String directory;
  @override
  OfflineState build() => OfflineState(directory: directory);
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final file = File(f);
    if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('galactic-layout-');
    await _loadFont('ChakraPetch', [for (final w in [400, 500, 600, 700]) 'assets/fonts/chakra_$w.ttf']);
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      await _loadFont('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
    }
    PackageInfo.setMockInitialValues(
      appName: 'Resonance Galactic',
      packageName: 'de.knode.resonance.galactic',
      version: '1.7.7',
      buildNumber: '1003',
      buildSignature: '',
    );
  });
  tearDownAll(() => directory.delete(recursive: true));

  Future<void> shoot(WidgetTester tester, String name, Size size, {double top = 0, double bottom = 0, bool eq = false}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'galactic_seen_build': '1003'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        apiProvider.overrideWithValue(ApiClient('https://resonance.example', 'test')),
        connectProvider.overrideWith(IdleConnect.new),
        playerProvider.overrideWith(() => _Player(PlayerView(queue: _tracks, index: 0))),
        offlineProvider.overrideWith(() => _Offline(directory.path)),
        coverColorProvider.overrideWith((ref, image) async => Colors.pink),
        spectrumProvider.overrideWith((ref, id) async => null),
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
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GalacticPage(),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (eq) {
      await tester.tap(find.text('EQ'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(tester.takeException(), isNull, reason: 'layout of $name overflows');
    await expectLater(find.byType(GalacticPage), matchesGoldenFile('goldens/galactic_$name.png'));
  }

  // Phone in landscape (about 2340 x 1080 px at 2.78): status bar on top, gesture bar below.
  testWidgets('phone landscape', (t) => shoot(t, 'phone_landscape', const Size(842, 388), top: 30, bottom: 14));
  testWidgets('phone landscape, equalizer open', (t) => shoot(t, 'phone_landscape_eq', const Size(842, 388), top: 30, bottom: 14, eq: true));
  testWidgets('phone portrait', (t) => shoot(t, 'phone_portrait', const Size(388, 842), top: 30, bottom: 14));
  testWidgets('tablet landscape', (t) => shoot(t, 'tablet_landscape', const Size(1280, 800), top: 24));
}
