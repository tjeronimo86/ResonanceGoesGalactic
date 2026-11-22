import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/api.dart';
import 'package:resonance/core/library.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/core/session.dart';
import 'package:resonance/core/theme.dart';
import 'package:resonance/core/tv_mode.dart';
import 'package:resonance/l10n/l10n.dart';
import 'package:resonance/offline/offline_store.dart';
import 'package:resonance/player/connect.dart';
import 'package:resonance/player/engine.dart';
import 'package:resonance/player/player.dart';
import 'package:resonance/player/spectrum.dart';
import 'package:resonance/player/visualizer_themes.dart';
import 'package:resonance/ui/pages/now_playing_page.dart';
import 'package:resonance/ui/tv/tv_now_playing.dart';
import 'package:resonance/ui/tv/tv_focusable.dart';
import 'package:resonance/ui/widgets/catalog.dart';
import 'package:resonance/ui/widgets/common.dart';
import 'package:resonance/ui/widgets/reflection.dart';
import 'package:resonance/ui/widgets/track_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/idle_connect.dart';

import 'package:resonance/core/review.dart';
import 'package:resonance/ui/widgets/credits_sheet.dart';

const _tracks = [
  Track(
    id: 'one',
    title: 'First song',
    duration: 120,
    artist: NamedRef('artist', 'Artist'),
    artistCredit: 'Artist',
    album: NamedRef('one', 'First album'),
  ),
  Track(
    id: 'two',
    title: 'Second song',
    duration: 120,
    artist: NamedRef('artist', 'Artist'),
    artistCredit: 'Artist',
    album: NamedRef('two', 'Second album'),
  ),
  Track(
    id: 'three',
    title: 'Third song',
    duration: 120,
    artist: NamedRef('artist', 'Artist'),
    artistCredit: 'Artist',
    album: NamedRef('three', 'Third album'),
  ),
];

Spectrum _spectrum(List<int> levels) {
  final data = ByteData(13 + levels.length)
    ..setUint32(0, 0x52535031)
    ..setUint8(4, levels.length)
    ..setFloat32(5, 20, Endian.little)
    ..setUint32(9, 1, Endian.little);
  for (var i = 0; i < levels.length; i++) {
    data.setUint8(13 + i, levels[i]);
  }
  return Spectrum.parse(data.buffer.asUint8List())!;
}

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
  final jumps = <int>[];
  final moves = <(int, int)>[];

  @override
  PlayerView build() {
    ref.onDispose(() {
      engine.automixing.dispose();
      userVolume.dispose();
      errors.close();
    });
    return initial;
  }

  void update(PlayerView view) => state = view;

  @override
  Future<void> jumpTo(int index) async {
    jumps.add(index);
    state = PlayerView(queue: state.queue, index: index);
  }

  @override
  Future<void> move(int from, int to) async {
    moves.add((from, to));
    final queue = [...state.queue];
    queue.insert(to, queue.removeAt(from));
    state = PlayerView(queue: queue, index: state.index);
  }
}

class _RadioApi extends ApiClient {
  _RadioApi() : super('https://resonance.example', 'test');
  int added = 0;
  int removed = 0;

  @override
  Future<void> addWorldRadioFavorite(String id) async {
    added++;
  }

  @override
  Future<void> removeWorldRadioFavorite(String id) async {
    removed++;
  }
}

class _Offline extends OfflineController {
  _Offline(this.directory);
  final String directory;
  @override
  OfflineState build() => OfflineState(directory: directory);
}

void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('resonance-now-playing-');
    await Directory('${directory.path}/covers').create();
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    );
    for (final track in _tracks) {
      await File('${directory.path}/covers/${track.album.id}.jpg').writeAsBytes(png);
    }
  });
  tearDownAll(() => directory.delete(recursive: true));

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    Size size = const Size(450, 800),
    bool coverflow = false,
    bool flip = false,
    bool visualizer = true,
    bool reflection = true,
    String theme = 'retro',
    Locale locale = const Locale('en'),
    PlayerView view = const PlayerView(queue: _tracks, index: 1),
    Color? color = Colors.orange,
    Spectrum? spectrum,
    Lyrics? lyrics,
    Widget? child,
    List<Station> radioFavorites = const [],
    ApiClient? api,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({
      'coverflow': coverflow,
      'coverflow_flip': flip,
      'visualizer_theme': theme,
      'visualizer_reflection': reflection,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        apiProvider.overrideWithValue(api ?? ApiClient('https://resonance.example', 'test')),
        connectProvider.overrideWith(IdleConnect.new),
        playerProvider.overrideWith(() => _Player(view)),
        offlineProvider.overrideWith(() => _Offline(directory.path)),
        visualizerEnabledProvider.overrideWithBuild((ref, notifier) => visualizer),
        coverColorProvider.overrideWith(
          (ref, image) async => image == FileImage(File('${directory.path}/covers/three.jpg')) ? Colors.blue : color,
        ),
        spectrumProvider.overrideWith((ref, id) async => spectrum),
        lyricsProvider.overrideWith(
          (ref, id) async => lyrics ?? const Lyrics(synced: false, instrumental: false, source: null, lines: []),
        ),
        creditsProvider.overrideWith((ref, id) async => const Credits()),
        positionProvider.overrideWith((ref) => const Stream.empty()),
        durationProvider.overrideWith((ref) => const Stream.empty()),
        worldRadioFavoritesProvider.overrideWith((ref) async => radioFavorites),
        albumProvider.overrideWith(
          (ref, id) async => AlbumDetail(
            Album(
              id: id,
              title: 'Album $id',
              artist: const NamedRef('artist', 'Artist'),
              hasCover: true,
              trackCount: 2,
            ),
            [_tracks[1], _tracks[2]],
            240,
            false,
          ),
        ),
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
          theme: ThemeData.dark(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child ?? const NowPlayingPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return container;
  }

  Finder coverflowArea() => find.byKey(const ValueKey('coverflow'));

  AnimationController coverflowPosition(WidgetTester tester) {
    final builder = tester.widget<AnimatedBuilder>(
      find.descendant(of: coverflowArea(), matching: find.byType(AnimatedBuilder)).first,
    );
    return builder.animation as AnimationController;
  }

  Finder flowArtwork(int index) =>
      find.descendant(of: find.byKey(ValueKey('coverflow-cover-$index')), matching: find.byType(CoverImage)).last;

  Rect paintedBounds(WidgetTester tester, Finder finder) {
    final box = tester.renderObject<RenderBox>(finder);
    return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
  }

  LinearGradient background(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(TweenAnimationBuilder<Color?>), matching: find.byType(DecoratedBox)).first,
    );
    return (box.decoration as BoxDecoration).gradient! as LinearGradient;
  }

  for (final size in [const Size(360, 640), const Size(1280, 800)]) {
    for (final coverflow in [false, true]) {
      testWidgets('covers and reflections fit $size with coverflow $coverflow', (tester) async {
        await mount(tester, size: size, coverflow: coverflow, visualizer: size.width < 900);
        expect(find.byType(CoverReflection), findsWidgets);
        for (final element in find.byType(CoverReflection).evaluate()) {
          final finder = find.byWidget(element.widget);
          final rect = tester.getRect(finder);
          final rendered = tester.getSize(finder);
          expect(rendered.height, closeTo(rendered.width * 0.22, 0.001));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final size in [const Size(714, 321), const Size(900, 400)]) {
    for (final flow in [false, true]) {
      testWidgets('landscape track playback fits $size with coverflow $flow', (tester) async {
        final container = await mount(
          tester,
          size: size,
          coverflow: flow,
          lyrics: const Lyrics(
            synced: false,
            instrumental: false,
            source: null,
            lines: [LyricLine(timeMs: null, text: 'Landscape lyrics')],
          ),
        );
        final cover = tester.getRect(find.byType(CoverImage));
        final header = tester.getRect(find.ancestor(of: find.text('Second album'), matching: find.byType(Row)).first);
        final title = tester.getRect(find.text('Second song'));
        expect(cover.width, cover.height);
        expect(cover.width, greaterThanOrEqualTo(0.8 * (size.height - header.height)));
        expect(cover.width, lessThanOrEqualTo(0.45 * (size.width - 48)));
        expect(cover.top, closeTo(header.bottom + 12, 0.001));
        expect(cover.bottom, lessThanOrEqualTo(size.height - 16));
        expect(title.left, greaterThanOrEqualTo(cover.right + 24));
        expect(find.byType(CoverReflection), findsNothing);
        expect(coverflowArea(), findsNothing);
        expect(tester.widget<SpectrumVisualizer>(find.byType(SpectrumVisualizer)).reflection, 0);
        expect(background(tester).stops, [0.0, 0.85]);
        await tester.tap(find.byType(CoverImage));
        await tester.pump();
        expect(container.read(visualizerPeaksProvider), isFalse);
        expect(container.read(prefsProvider).getBool('visualizer_peaks'), isFalse);
        await tester.timedDrag(find.byType(ListView), const Offset(0, -250), const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Landscape lyrics').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the cover fills a 450 by 1000 phone and has sixteen-pixel vertical margins', (tester) async {
    await mount(tester, size: const Size(450, 1000));
    final cover = find.descendant(of: find.byType(Material), matching: find.byType(CoverImage)).last;
    final rect = tester.getRect(cover);
    final header = tester.getRect(find.byIcon(Icons.keyboard_arrow_down));
    final title = tester.getRect(find.text('Second song'));
    final reflection = tester.getRect(find.byType(CoverReflection));
    expect(rect.width, greaterThanOrEqualTo(400));
    expect(rect.size.height, rect.size.width);
    expect(rect.top - header.bottom, greaterThanOrEqualTo(16));
    expect(title.top - reflection.bottom, greaterThanOrEqualTo(16));
    expect(tester.takeException(), isNull);
  });

  for (final coverflow in [false, true]) {
    testWidgets('disabling reflection gives the cover its space back with coverflow $coverflow', (tester) async {
      final container = await mount(tester, size: const Size(360, 640), coverflow: coverflow);
      double coverSide() => tester.getSize(find.byType(SpectrumVisualizer)).width + 24;
      final reflectedSide = coverSide();
      container.read(visualizerReflectionProvider.notifier).set(false);
      await tester.pump();
      expect(find.byType(CoverReflection), findsNothing);
      expect(tester.widget<SpectrumVisualizer>(find.byType(SpectrumVisualizer)).reflection, 0);
      expect(coverSide(), greaterThan(reflectedSide));
      expect(container.read(prefsProvider).getBool('visualizer_reflection'), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cover tint uses capped HSL and animates track changes over 600 milliseconds', (tester) async {
    final container = await mount(tester);
    final expected = HSLColor.fromColor(Colors.orange).withLightness(0.22).withSaturation(0.65).toColor();
    expect(background(tester).colors, [expected, Palette.background]);
    expect(background(tester).stops, [0.0, 0.85]);
    (container.read(playerProvider.notifier) as _Player).update(const PlayerView(queue: _tracks, index: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final blue = HSLColor.fromColor(Colors.blue).withLightness(0.22).withSaturation(0.65).toColor();
    expect(background(tester).colors.first, isNot(expected));
    expect(background(tester).colors.first, isNot(blue));
    await tester.pump(const Duration(milliseconds: 300));
    expect(background(tester).colors.first, blue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final (visualizer, color) in [(true, null), (false, null), (false, Colors.orange)]) {
    testWidgets('accent gradient is kept with visualizer $visualizer and cover color $color', (tester) async {
      await mount(tester, visualizer: visualizer, color: color);
      final context = tester.element(find.byType(NowPlayingPage));
      expect(background(tester).colors.first, Theme.of(context).colorScheme.primary.withValues(alpha: 0.45));
      expect(background(tester).stops, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('cover tint preserves darker muted colors and makes them opaque', (tester) async {
    final color = const HSLColor.fromAHSL(0.4, 100, 0.2, 0.1).toColor();
    await mount(tester, color: color);
    expect(background(tester).colors.first, HSLColor.fromColor(color).withAlpha(1).toColor());
  });

  for (final theme in visualizerThemes.map((theme) => theme.id)) {
    testWidgets('$theme reflects the requested artwork and toggles dots for peak themes', (tester) async {
      final container = await mount(tester, theme: theme, locale: const Locale('de'));
      final peaks = theme == 'retro' || theme == 'matrix';
      expect(
        find.descendant(of: find.byType(CoverReflection), matching: find.byType(SpectrumVisualizer)),
        findsNothing,
      );
      expect(find.byType(SpectrumVisualizer), findsOneWidget);
      final visualizer = tester.widget<SpectrumVisualizer>(find.byType(SpectrumVisualizer));
      expect(visualizer.reflection, greaterThan(0));
      final cover = find.descendant(of: find.byType(Material), matching: find.byType(CoverImage)).last;
      await tester.tap(cover);
      await tester.pump();
      expect(container.read(visualizerPeaksProvider), !peaks);
      if (peaks) {
        expect(container.read(prefsProvider).getBool('visualizer_peaks'), isFalse);
        await tester.tap(cover);
        await tester.pump();
        expect(container.read(visualizerPeaksProvider), isTrue);
        expect(find.byType(SnackBar), findsNothing, reason: 'the dots themselves show the change');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('the last bubble repaints when it expires after playback stops', (tester) async {
    final data = ByteData(14)
      ..setUint32(0, 0x52535031)
      ..setUint8(4, 1)
      ..setFloat32(5, 20, Endian.little)
      ..setUint32(9, 1, Endian.little)
      ..setUint8(13, 204);
    final container = await mount(tester, spectrum: Spectrum.parse(data.buffer.asUint8List()));
    final engine = container.read(playerProvider.notifier).engine as _Engine;
    engine.playing = true;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    engine.playing = false;
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(of: find.byType(SpectrumVisualizer).first, matching: find.byType(CustomPaint)),
        )
        .painter!;
    var repaints = 0;
    void onRepaint() => repaints++;
    painter.addListener(onRepaint);
    await tester.pump(const Duration(milliseconds: 800));
    expect(repaints, 1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(repaints, 1);
    painter.removeListener(onRepaint);
    expect(tester.takeException(), isNull);
  });

  for (final theme in ['synthwave', 'fire', 'neon', 'aurora']) {
    testWidgets('$theme draws one combined glow and no blurred reflection', (tester) async {
      final container = await mount(tester, theme: theme, spectrum: _spectrum([255, 128]));
      (container.read(playerProvider.notifier).engine as _Engine).playing = true;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      final visualizer = tester.widget<SpectrumVisualizer>(find.byType(SpectrumVisualizer));
      final painter = tester
          .widget<CustomPaint>(find.descendant(of: find.byType(SpectrumVisualizer), matching: find.byType(CustomPaint)))
          .painter!;
      final canvas = TestRecordingCanvas();
      painter.paint(canvas, Size(200, 103 + visualizer.reflection));
      final blurred = canvas.invocations
          .map((record) => record.invocation)
          .where(
            (call) => call.positionalArguments.any((argument) => argument is Paint && argument.maskFilter != null),
          );
      expect(blurred, hasLength(1));
      expect(blurred.single.memberName, #drawPath);
      final path = blurred.single.positionalArguments.first as Path;
      expect(path.getBounds().width, greaterThan(150));
      expect(canvas.invocations.any((record) => record.invocation.memberName == #saveLayer), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('spectrum reflection paints below its box with a gap, fading opacity and sixty-percent height', (
    tester,
  ) async {
    final container = await mount(tester, spectrum: _spectrum([128]));
    final key = GlobalKey();
    (container.read(playerProvider.notifier).engine as _Engine).playing = true;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 200,
                height: 163,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: SpectrumVisualizer(
                        trackId: 'two',
                        color: const Color(0xFFFF0000),
                        theme: const VisualizerTheme(
                          id: 'test',
                          style: VisualizerStyle.bars,
                          colors: [Color(0xFFFF0000)],
                        ),
                        gap: 0,
                        minHeight: 0,
                        reflection: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(find.byType(SpectrumVisualizer)).height, 100);
    expect(tester.getSize(find.byType(CustomPaint)).height, 163);
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(() => boundary.toImage()))!;
    final pixels = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba)))!;
    int channel(int y, int channel) => pixels.getUint8((y * image.width + 100) * 4 + channel);
    expect(channel(101, 3), 0);
    expect(channel(102, 3), 0);
    expect(channel(104, 0), 255);
    expect(channel(104, 3), closeTo(0.35 * (1 - 1.5 / 60) * 255, 2));
    expect(channel(127, 3), greaterThan(0));
    expect(channel(127, 3), lessThan(channel(104, 3)));
    expect(channel(135, 3), 0);
    image.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the centered coverflow item has visualizers and responds to peak-dot taps', (tester) async {
    final container = await mount(tester, size: const Size(360, 640), coverflow: true);
    final visualizers = tester.widgetList<SpectrumVisualizer>(find.byType(SpectrumVisualizer));
    expect(visualizers, hasLength(1));
    expect(visualizers.every((visualizer) => visualizer.trackId == 'two'), isTrue);
    expect(find.byType(CoverReflection), findsAtLeastNWidgets(2));
    final center = paintedBounds(tester, flowArtwork(1));
    await tester.tapAt(Offset(center.left - 8, center.center.dy));
    await tester.pump();
    expect(container.read(visualizerPeaksProvider), isTrue);
    await tester.tap(flowArtwork(1));
    await tester.pump();
    expect(container.read(visualizerPeaksProvider), isFalse);
  });

  testWidgets('a tapped coverflow cover turns over to its album and plays a song from there', (tester) async {
    final container = await mount(
      tester,
      size: const Size(360, 640),
      coverflow: true,
      flip: true,
      view: const PlayerView(queue: _tracks, index: 1, context: 'album:two'),
    );
    final player = container.read(playerProvider.notifier) as _Player;
    expect(find.text('Album two'), findsNothing);
    await tester.tap(flowArtwork(1));
    await tester.pumpAndSettle();
    expect(find.text('Album two'), findsOneWidget);
    expect(find.byKey(const ValueKey('coverflow-back-track-1')), findsOneWidget);
    // The visualizer's peaks moved to a long press.
    expect(container.read(visualizerPeaksProvider), isTrue);

    await tester.tap(find.byKey(const ValueKey('coverflow-back-track-1')));
    await tester.pump();
    expect(player.jumps, [2]);

    player.update(const PlayerView(queue: _tracks, index: 2, context: 'album:two'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Album two'), findsNothing);
    await tester.longPress(flowArtwork(2));
    await tester.pump();
    expect(container.read(visualizerPeaksProvider), isFalse);
  });

  testWidgets('coverflow starts at the queue index, jumps once after a swipe and follows external changes', (
    tester,
  ) async {
    final container = await mount(tester, coverflow: true, visualizer: false);
    final player = container.read(playerProvider.notifier) as _Player;
    final pages = coverflowArea();
    final controller = coverflowPosition(tester);
    await tester.pumpAndSettle();
    expect(controller.value, 1);
    await tester.drag(pages, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(controller.value, 2);
    expect(player.jumps, [2]);
    player.update(const PlayerView(queue: _tracks, index: 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.value, greaterThan(0));
    await tester.pumpAndSettle();
    expect(controller.value, 0);
    expect(player.jumps, [2]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('coverflow centers index one and animates external index two without a player jump', (tester) async {
    final container = await mount(tester, coverflow: true, visualizer: false);
    final player = container.read(playerProvider.notifier) as _Player;
    final controller = coverflowPosition(tester);
    await tester.pumpAndSettle();
    expect(controller.value, 1);
    expect(player.jumps, isEmpty);
    player.update(const PlayerView(queue: _tracks, index: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.value, greaterThan(1));
    expect(controller.value, lessThan(2));
    await tester.pumpAndSettle();
    expect(controller.value, 2);
    expect(player.jumps, isEmpty);
  });

  testWidgets('coverflow jumps to the current index when queue length or the current track changes', (tester) async {
    final container = await mount(tester, coverflow: true, visualizer: false);
    final player = container.read(playerProvider.notifier) as _Player;
    final controller = coverflowPosition(tester);
    for (final queue in [
      [_tracks[2], _tracks[0], _tracks[1]],
      [_tracks[0], _tracks[1]],
    ]) {
      controller.value = 0;
      player.update(PlayerView(queue: queue, index: 1));
      await tester.pump();
      expect(controller.value, 1);
      await tester.pumpAndSettle();
      expect(controller.value, 1);
      expect(player.jumps, isEmpty);
    }
  });

  testWidgets('coverflow keeps the visualizer on a rounded page and shows both neighbors', (tester) async {
    await mount(tester, size: const Size(450, 1000), coverflow: true);
    final controller = coverflowPosition(tester);
    controller.value += 0.0001;
    await tester.pump();
    final visualizer = tester.widget<SpectrumVisualizer>(find.byType(SpectrumVisualizer));
    expect(visualizer.trackId, 'two');
    final viewport = tester.getRect(coverflowArea());
    for (final id in ['one', 'three']) {
      final cover = find.byWidgetPredicate((widget) => widget is CoverImage && widget.albumId == id).last;
      final rect = tester.getRect(cover);
      expect(rect.overlaps(viewport), isTrue);
      expect(tester.getSize(cover).width, greaterThanOrEqualTo(300));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('coverflow keeps most of the cover size and shows neighbors no taller than it', (tester) async {
    final container = await mount(tester, size: const Size(450, 1000));
    final singleSide = tester.getSize(find.byType(SpectrumVisualizer)).width + 24;
    expect(singleSide, closeTo(402, 0.001));
    container.read(coverflowProvider.notifier).set(true);
    await tester.pump();
    final center = paintedBounds(tester, flowArtwork(1));
    final previous = paintedBounds(tester, flowArtwork(0));
    final next = paintedBounds(tester, flowArtwork(2));
    expect(center.width, closeTo(0.78 * singleSide, 0.001));
    expect(center.left - previous.left, greaterThanOrEqualTo(0.15 * center.width));
    expect(next.right - center.right, greaterThanOrEqualTo(0.15 * center.width));
    for (final neighbor in [previous, next]) {
      expect(neighbor.height, lessThanOrEqualTo(center.height));
      expect(neighbor.left, greaterThanOrEqualTo(0));
      expect(neighbor.right, lessThanOrEqualTo(450));
    }
    expect(find.byType(CoverReflection), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide now-playing coverflow grows while keeping the phone size unchanged', (tester) async {
    await mount(tester, size: const Size(1920, 1080), coverflow: true, visualizer: false);
    final center = paintedBounds(tester, flowArtwork(1));
    final area = tester.getSize(coverflowArea());
    final side = TrackCover.sideFor(BoxConstraints(maxWidth: area.width, maxHeight: area.height), true, maxSide: 720);
    expect(center.width, greaterThan(480 * 0.78));
    expect(center.width, closeTo(0.85 * side, 1));
    expect(center.left, greaterThanOrEqualTo(0));
    expect(center.right, lessThanOrEqualTo(1920));
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-interactive coverflow ignores pointer input and follows the queue index', (tester) async {
    final container = await mount(
      tester,
      visualizer: true,
      child: const Center(child: SizedBox(width: 450, height: 640, child: Coverflow(interactive: false))),
    );
    final player = container.read(playerProvider.notifier) as _Player;
    final controller = coverflowPosition(tester);
    final peaks = container.read(visualizerPeaksProvider);
    await tester.drag(coverflowArea(), const Offset(-400, 0), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(tester.getCenter(coverflowArea()));
    await tester.pump();
    expect(controller.value, 1);
    expect(player.jumps, isEmpty);
    expect(container.read(visualizerPeaksProvider), peaks);
    expect(find.byType(SpectrumVisualizer), findsOneWidget);
    player.update(const PlayerView(queue: _tracks, index: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.value, greaterThan(1));
    expect(controller.value, lessThan(2));
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.value, 2);
    expect(player.jumps, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coverflow tracks a continuous drag and selects only after its 300 ms snap', (tester) async {
    final container = await mount(tester, coverflow: true);
    final player = container.read(playerProvider.notifier) as _Player;
    final controller = coverflowPosition(tester);
    final side = tester.getSize(flowArtwork(1)).width;
    final gesture = await tester.startGesture(tester.getCenter(coverflowArea()));
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    final start = controller.value;
    await gesture.moveBy(Offset(-0.42 * side * 0.6, 0));
    await tester.pump();
    expect(controller.value, closeTo(start + 0.6, 0.001));
    expect(tester.widget<SpectrumVisualizer>(find.byType(SpectrumVisualizer)).trackId, 'three');
    expect(player.jumps, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.value, greaterThan(1.6));
    expect(controller.value, lessThan(2));
    expect(player.jumps, isEmpty);
    await tester.pump(const Duration(milliseconds: 151));
    expect(controller.value, 2);
    expect(player.jumps, [2]);
  });

  testWidgets('neighbor pivots stay continuous at a one-item offset', (tester) async {
    await mount(tester, coverflow: true, visualizer: false);
    final controller = coverflowPosition(tester);
    controller.value = 0.9999;
    await tester.pump();
    final before = paintedBounds(tester, flowArtwork(2));
    controller.value = 1.0001;
    await tester.pump();
    final after = paintedBounds(tester, flowArtwork(2));
    final tolerance = tester.getSize(flowArtwork(1)).width * 0.001;
    expect(after.left, closeTo(before.left, tolerance));
    expect(after.right, closeTo(before.right, tolerance));
    expect(after.top, closeTo(before.top, tolerance));
    expect(after.bottom, closeTo(before.bottom, tolerance));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an external index change cancels a pending swipe selection', (tester) async {
    final container = await mount(tester, coverflow: true, visualizer: false);
    final player = container.read(playerProvider.notifier) as _Player;
    final controller = coverflowPosition(tester);
    await tester.fling(coverflowArea(), const Offset(-70, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.value, greaterThan(1));
    expect(player.jumps, isEmpty);
    player.update(const PlayerView(queue: _tracks, index: 0));
    await tester.pumpAndSettle();
    expect(controller.value, 0);
    expect(player.jumps, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final direction in [-1.0, 1.0]) {
    testWidgets('a short coverflow fling in direction $direction moves one item', (tester) async {
      final container = await mount(tester, coverflow: true, visualizer: false);
      final player = container.read(playerProvider.notifier) as _Player;
      final controller = coverflowPosition(tester);
      await tester.fling(coverflowArea(), Offset(70 * direction, 0), 1000);
      await tester.pumpAndSettle();
      final target = direction < 0 ? 2 : 0;
      expect(controller.value, target);
      expect(player.jumps, [target]);
    });
  }

  testWidgets('station identity appears above song artwork only and has no reflection', (tester) async {
    const station = Station(
      id: 'radio',
      name: 'Radio One',
      country: 'Germany',
      countryCode: 'DE',
      tags: [],
      codec: 'MP3',
    );
    final container = await mount(tester, view: const PlayerView(station: station));
    expect(find.byType(NetworkCover), findsOneWidget);
    expect(find.byType(CoverReflection), findsNothing);
    (container.read(playerProvider.notifier) as _Player).update(
      const PlayerView(
        station: station,
        stationNow: StationNowPlaying(raw: 'Artist - Song', title: 'Song', coverUrl: 'https://cover.example/song'),
      ),
    );
    await tester.pump();
    final covers = find.byType(NetworkCover);
    expect(covers, findsNWidgets(2));
    final favicon = tester.getRect(covers.first);
    final song = tester.getRect(covers.last);
    expect(favicon.size, const Size(28, 28));
    expect(song.top - favicon.bottom, closeTo(12, 0.001));
    expect(find.byType(CoverReflection), findsNothing);
    expect(background(tester).stops, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reflection mirrors the bottom first, fades downward and ignores taps', (tester) async {
    final key = GlobalKey();
    var tapped = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 200,
              child: CoverReflection(
                child: GestureDetector(
                  onTap: () => tapped = true,
                  child: Column(
                    children: [
                      Expanded(flex: 9, child: Container(color: const Color(0xFFFF0000))),
                      Expanded(child: Container(color: const Color(0xFF0000FF))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(() => boundary.toImage()))!;
    final pixels = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba)))!;
    final top = (2 * image.width + 100) * 4;
    final lower = (30 * image.width + 100) * 4;
    expect(pixels.getUint8(top + 2), greaterThan(200));
    expect(pixels.getUint8(top), 0);
    expect(pixels.getUint8(lower), greaterThan(200));
    expect(pixels.getUint8(lower + 2), 0);
    expect(pixels.getUint8(top + 3), greaterThan(pixels.getUint8(lower + 3)));
    image.dispose();
    await tester.tap(find.byType(CoverReflection), warnIfMissed: false);
    expect(tapped, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV now-playing uses a blurred cross-fading backdrop and decorative queue coverflow', (tester) async {
    final container = await mount(
      tester,
      size: const Size(1920, 1080),
      visualizer: true,
      color: Colors.orange,
      child: const TvNowPlayingPage(),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ImageFiltered), findsOneWidget);
    final filter = tester.widget<ImageFiltered>(find.byType(ImageFiltered));
    expect(filter.imageFilter, isA<ui.ImageFilter>());
    expect(find.byType(Coverflow), findsOneWidget);
    final coverflow = tester.widget<Coverflow>(find.byType(Coverflow));
    expect(coverflow.interactive, isFalse);
    expect(coverflow.maxSide, 620);
    expect(tester.getSize(find.byKey(const ValueKey('tv-now-playing-cover'))).width, 900);
    final gradient = tester.widget<DecoratedBox>(find.byKey(const ValueKey('tv-now-playing-gradient')));
    final colors = (gradient.decoration as BoxDecoration).gradient! as LinearGradient;
    final expected = HSLColor.fromColor(Colors.orange)
        .withLightness(0.25)
        .withSaturation(0.7)
        .toColor()
        .withValues(alpha: 0.6);
    expect(colors.colors.first, expected);
    expect(colors.colors.last, Palette.background.withValues(alpha: 0.92));
    expect(find.byKey(const ValueKey('tv-now-playing-artwork-track:two')), findsOneWidget);
    (container.read(playerProvider.notifier) as _Player).update(const PlayerView(queue: _tracks, index: 2));
    await tester.pump();
    expect(find.byKey(const ValueKey('tv-now-playing-artwork-track:two')), findsOneWidget);
    expect(find.byKey(const ValueKey('tv-now-playing-artwork-track:three')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('tv-now-playing-artwork-track:two')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('tv-now-playing-artwork-track:two')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV now-playing keeps the single-cover artwork and shows a plain background when empty', (tester) async {
    await mount(
      tester,
      size: const Size(1920, 1080),
      view: PlayerView(queue: [_tracks[1]], index: 0),
      child: const TvNowPlayingPage(),
    );
    expect(find.byType(Coverflow), findsNothing);
    expect(find.byType(TrackCover), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, size: const Size(1920, 1080), view: const PlayerView(), child: const TvNowPlayingPage());
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byKey(const ValueKey('tv-now-playing-gradient')), findsNothing);
    expect(find.byKey(const ValueKey('tv-now-playing-bottom-gradient')), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => widget is ColoredBox && widget.color == Palette.background),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV radio favourites and ambient mode buttons use the expected labels and actions', (tester) async {
    const station = Station(
      id: 'radio',
      name: 'Radio One',
      country: 'Germany',
      countryCode: 'DE',
      tags: [],
      codec: 'MP3',
    );
    final api = _RadioApi();
    final container = await mount(
      tester,
      size: const Size(1920, 1080),
      view: const PlayerView(station: station),
      child: const TvNowPlayingPage(),
      radioFavorites: const [station],
      api: api,
    );
    final buttons = tester.widgetList<TvButton>(find.byType(TvButton)).toList();
    final labels = buttons.map((button) => button.label).toList();
    expect(labels, ['Back', 'Previous', 'Play', 'Next', 'Remove from favourites', 'Ambient mode on']);
    final favourite = buttons.singleWhere((button) => button.label == 'Remove from favourites');
    expect(favourite.icon, Icons.star);
    favourite.onPressed!();
    await tester.pump();
    expect(api.removed, 1);
    final ambient = buttons.last;
    expect(ambient.icon, Icons.dark_mode);
    ambient.onPressed!();
    await tester.pump();
    expect(container.read(tvAmbientModeProvider), isFalse);
    expect(container.read(prefsProvider).getBool('tv.ambient_mode'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the queue reorders upcoming songs by dragging their handle', (tester) async {
    const songs = [
      ..._tracks,
      Track(
        id: 'four',
        title: 'Fourth song',
        duration: 120,
        artist: NamedRef('artist', 'Artist'),
        artistCredit: 'Artist',
        album: NamedRef('four', 'Fourth album'),
      ),
    ];
    final container = await mount(
      tester,
      view: const PlayerView(queue: songs, index: 0),
      child: const QueuePage(),
    );
    final player = container.read(playerProvider.notifier) as _Player;
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3), reason: 'only upcoming songs, not the playing one');
    double top(String title) => tester.getTopLeft(find.text(title)).dy;
    expect(top('Second song') < top('Third song') && top('Third song') < top('Fourth song'), isTrue);

    final handle = find.descendant(
      of: find.ancestor(of: find.text('Fourth song'), matching: find.byType(TrackRow)),
      matching: find.byIcon(Icons.drag_handle),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, (top('Second song') - top('Fourth song') - 80) / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(player.moves, [(3, 1)]);
    expect(top('Fourth song') < top('Second song'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
