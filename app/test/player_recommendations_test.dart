import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/core/api.dart';
import 'package:resonance/core/downloads.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/core/session.dart';
import 'package:resonance/player/engine.dart';
import 'package:resonance/player/equalizer.dart';
import 'package:resonance/player/player.dart';

Map<String, dynamic> trackJson(String id) => {
  'id': id,
  'title': id,
  'duration': 180,
  'artist': {'id': 'artist', 'name': 'Artist'},
  'artist_credit': 'Artist',
  'album': {'id': 'album', 'name': 'Album'},
};

Track track(String id) => Track(
  id: id,
  title: id,
  duration: 180,
  artist: const NamedRef('artist', 'Artist'),
  artistCredit: 'Artist',
  album: const NamedRef('album', 'Album'),
);

class _Api extends ApiClient {
  _Api() : super('https://resonance.example', 'test');
  final recommendationCalls =
      <({List<String> seeds, List<String> excluded, int limit, Completer<List<Track>> response})>[];
  final keyCalls = <List<String>>[];
  final keys = <String, ({String? key, double? bpm})?>{};
  bool failKeys = false;
  Completer<Map<String, ({String? key, double? bpm})?>>? keyResponse;

  @override
  Future<Map<String, ({String? key, double? bpm})?>> mixKeys(List<String> ids) async {
    keyCalls.add(ids);
    if (failKeys) throw ApiException('offline');
    return keyResponse == null ? {for (final id in ids) id: keys[id]} : await keyResponse!.future;
  }

  @override
  Future<List<Track>> recommendations({
    required List<String> trackIds,
    List<String> excludeIds = const [],
    int limit = 20,
  }) {
    final response = Completer<List<Track>>();
    recommendationCalls.add((seeds: trackIds, excluded: excludeIds, limit: limit, response: response));
    return response.future;
  }

  Map<String, dynamic>? lastSaved;
  final saved = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> lastPlayback() async => lastSaved;
  @override
  Future<void> savePlayback(Map<String, dynamic> state) async => saved.add(state);

  @override
  Future<PlaylistDetail> playlist(String id) async => throw ApiException('offline');
  @override
  Future<void> reportPlay(String id, double seconds, {String? context}) async {}
}

class _Engine implements PlaybackEngine {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final indices = StreamController<int?>.broadcast(sync: true);
  final loops = StreamController<LoopMode>.broadcast(sync: true);
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<int?> get currentIndexStream => indices.stream;
  @override
  Stream<LoopMode> get loopModeStream => loops.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<Object> get errorStream => const Stream.empty();
  @override
  int crossfadeSeconds = 0;
  @override
  bool automix = false;
  @override
  bool keyShift = true;
  @override
  bool vocalSwap = true;
  @override
  ({String url, double seconds})? Function(int index)? stemForIndex;
  @override
  void Function(int index)? requestStemForIndex;
  @override
  MixPoints? Function(int)? mixPointsForIndex;
  @override
  AutomixPlan? Function(int, int)? customPlanForIndex;
  @override
  String? Function(int index)? sourceKeyForIndex;
  @override
  Future<void> setEqualizer(EqualizerSettings settings) async {}
  @override
  double Function(int)? targetVolumeForIndex;
  @override
  bool isBook = false;
  @override
  bool playing = false;
  @override
  ProcessingState processingState = ProcessingState.ready;
  @override
  int? currentIndex;
  @override
  Duration position = Duration.zero;
  @override
  LoopMode loopMode = LoopMode.off;
  @override
  double speed = 1;
  @override
  List<SourceFactory> audioSources = [];
  final removed = <int>[];
  bool? preservedCurrent;

  @override
  Future<void> setSources(
    List<SourceFactory> sources, {
    required int initialIndex,
    Duration initialPosition = Duration.zero,
    bool preserveCurrent = false,
  }) async {
    audioSources = [...sources];
    preservedCurrent = preserveCurrent;
    currentIndex = initialIndex;
    if (!preserveCurrent) position = initialPosition;
  }

  @override
  Future<void> insert(int index, SourceFactory source) async => audioSources.insert(index, source);
  @override
  Future<void> removeAt(int index) async {
    removed.add(index);
    audioSources.removeAt(index);
  }

  @override
  Future<void> move(int from, int to) async => audioSources.insert(to, audioSources.removeAt(from));

  @override
  Future<void> play() async {
    playing = true;
    states.add(PlayerState(true, processingState));
  }

  @override
  Future<void> pause() async {
    playing = false;
    states.add(PlayerState(false, processingState));
  }

  @override
  Future<void> stop() => pause();
  @override
  Future<void> finishFade() async {}
  @override
  Future<void> setLoopMode(LoopMode mode) async {
    loopMode = mode;
    loops.add(mode);
  }

  @override
  Future<void> setSpeed(double value) async => speed = value;
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> seek(Duration value, {int? index}) async {
    position = value;
    currentIndex = index ?? currentIndex;
    indices.add(currentIndex);
  }

  @override
  Future<void> dispose() async {
    await states.close();
    await indices.close();
    await loops.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session extends SessionNotifier {
  @override
  SessionState build() => SessionState(
    user: User(
      id: 'user',
      username: 'lisa',
      displayName: 'Lisa',
      role: 'user',
      accentColor: '#1db954',
      isDisabled: false,
      createdAt: DateTime.utc(2026),
    ),
  );
}

Future<void> settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late _Api api;
  late _Engine engine;
  late SharedPreferences prefs;
  late PlayerController player;
  PlayerView view() => container.read(playerProvider);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = _Api();
    engine = _Engine();
    container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        apiProvider.overrideWithValue(api),
        downloadSummaryProvider.overrideWith((ref) async => const DownloadSummary()),
        playerProvider.overrideWith(() => PlayerController(engine: engine)),
      ],
    );
    player = container.read(playerProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('autoplay requests once when the last song starts and appends through the engine', () async {
    final context = List.generate(25, (i) => track('$i'));
    await player.playTracks(context, index: 24, context: 'album:first');
    expect(api.recommendationCalls, hasLength(1));
    expect(api.recommendationCalls.single.seeds, context.skip(5).map((t) => t.id));
    expect(api.recommendationCalls.single.excluded, context.map((t) => t.id));
    expect(api.recommendationCalls.single.limit, 20);
    await engine.play();
    await engine.play();
    expect(api.recommendationCalls, hasLength(1));
    api.recommendationCalls.single.response.complete([context.last, track('extra'), track('extra'), track('another')]);
    await settle();
    expect(view().queue.map((t) => t.id), [...context.map((t) => t.id), 'extra', 'another']);
    expect(view().autoplayIds, {'extra', 'another'});
    expect(engine.audioSources, hasLength(27));
    await player.setShuffle(true);
    await player.setShuffle(false);
    expect(view().queue.last.id, 'another');
    await player.playTracks(context.take(2).toList(), context: 'album:second');
    expect(view().autoplayIds, isEmpty);
  });

  for (final fail in [false, true]) {
    test('autoplay does not retry after ${fail ? 'failure' : 'an empty result'}', () async {
      await player.playTracks([track('only')]);
      if (fail) {
        api.recommendationCalls.single.response.completeError(ApiException('offline'));
      } else {
        api.recommendationCalls.single.response.complete([]);
      }
      await settle();
      await engine.play();
      await player.pause();
      await player.play();
      expect(api.recommendationCalls, hasLength(1));
      expect(view().queue, hasLength(1));
    });
  }

  test('late autoplay results do not enter a replacement context', () async {
    await player.playTracks([track('old')], context: 'album:same');
    await player.playTracks([track('new'), track('next')], context: 'album:same');
    api.recommendationCalls.single.response.complete([track('stale')]);
    await settle();
    expect(view().queue.map((t) => t.id), ['new', 'next']);
    expect(view().autoplayIds, isEmpty);
  });

  test('autoplay defaults on and persists the setting', () async {
    expect(player.autoplay, isTrue);
    player.setAutoplay(false);
    expect(prefs.getBool('autoplay'), isFalse);
    await player.playTracks([track('only')]);
    expect(api.recommendationCalls, isEmpty);
    player.setAutoplay(true);
    expect(api.recommendationCalls, hasLength(1));
  });

  test('autoplay waits until the last song is ready', () async {
    engine.processingState = ProcessingState.buffering;
    await player.playTracks([track('only')]);
    expect(api.recommendationCalls, isEmpty);
    engine.processingState = ProcessingState.ready;
    await engine.play();
    expect(api.recommendationCalls, hasLength(1));
  });

  test('autoplay preferences belong to each signed-in user', () async {
    User user(String id) => User(
      id: id,
      username: id,
      displayName: id,
      role: 'user',
      accentColor: '#ffffff',
      isDisabled: false,
      createdAt: DateTime.utc(2026),
    );
    final session = container.read(sessionProvider.notifier);
    await session.signedIn('first-token', user('first'));
    player.setAutoplay(false);
    await session.signedIn('second-token', user('second'));
    expect(player.autoplay, isTrue);
    await session.signedIn('first-token', user('first'));
    expect(player.autoplay, isFalse);
  });

  Future<List<Track>> enableSmart() async {
    player.setAutoplay(false);
    final context = List.generate(7, (i) => track('$i'));
    await player.playTracks(context, context: 'album:first');
    await player.toggleShuffle();
    expect(view().shuffle, isTrue);
    expect(view().smartShuffle, isFalse);
    await player.toggleShuffle();
    expect(view().smartShuffle, isTrue);
    expect(api.recommendationCalls.single.limit, 3);
    expect(api.recommendationCalls.single.seeds, unorderedEquals(context.map((t) => t.id)));
    api.recommendationCalls.single.response.complete([track('smart-a'), track('smart-b')]);
    await settle();
    return context;
  }

  test('queued songs play next in the order added, ahead of the context, and survive shuffle', () async {
    final context = List.generate(6, (i) => track('$i'));
    await player.playTracks(context, context: 'album:first');
    await player.addToQueue(track('q1'));
    await player.addToQueue(track('q2'));
    expect(view().queue.map((t) => t.id), ['0', 'q1', 'q2', '1', '2', '3', '4', '5']);
    expect(
      [for (var i = 0; i < view().queue.length; i++) view().isQueued(i)],
      [
        false, true, true, false, false, false, false, false, //
      ],
    );
    await player.playNext(track('n'));
    expect(view().queue.take(4).map((t) => t.id), ['0', 'n', 'q1', 'q2']);
    expect(view().queuedCount, 3);
    await player.removeAt(2);
    expect(view().queue.take(3).map((t) => t.id), ['0', 'n', 'q2']);
    expect(view().queuedCount, 2);
    await player.setShuffle(true);
    expect(view().queue.take(3).map((t) => t.id), ['0', 'n', 'q2']);
    expect(view().queuedCount, 2);
    await player.setShuffle(false);
    expect(view().queue.map((t) => t.id), ['0', 'n', 'q2', '1', '2', '3', '4', '5']);
    expect(view().queuedCount, 2);
    engine.indices.add(1);
    await settle();
    expect(view().queuedFrom, 2);
    expect(view().queuedCount, 1);
    await player.addToQueue(track('q3'));
    expect(view().queue.take(4).map((t) => t.id), ['0', 'n', 'q2', 'q3']);
    engine.indices.add(4);
    await settle();
    expect(view().queuedCount, 0);
  });

  test('dragging an upcoming song moves it, and in or out of the songs the user queued', () async {
    final context = List.generate(5, (i) => track('$i'));
    await player.playTracks(context, context: 'album:first');
    await player.addToQueue(track('q1'));
    await player.addToQueue(track('q2'));
    final sources = [...engine.audioSources];
    String ids() => view().queue.map((t) => t.id).join(' ');

    await player.move(5, 3);
    expect(ids(), '0 q1 q2 3 1 2 4');
    expect(engine.audioSources, [sources[0], sources[1], sources[2], sources[5], sources[3], sources[4], sources[6]]);
    expect((view().queuedFrom, view().queuedCount), (1, 2));
    // Dropped between the queued songs: queued too.
    await player.move(6, 2);
    expect(ids(), '0 q1 4 q2 3 1 2');
    expect((view().queuedFrom, view().queuedCount), (1, 3));
    // Dragged behind them: part of the rest again.
    await player.move(1, 5);
    expect(ids(), '0 4 q2 3 1 q1 2');
    expect((view().queuedFrom, view().queuedCount), (1, 2));
    expect([for (var i = 0; i < 7; i++) view().isQueued(i)], [false, true, true, false, false, false, false]);
    // The playing song and songs before it stay where they are.
    await player.move(0, 3);
    await player.move(3, 0);
    expect(ids(), '0 4 q2 3 1 q1 2');
    // Switching shuffle off again keeps the dragged order.
    await player.setShuffle(true);
    await player.setShuffle(false);
    expect(ids().startsWith('0 4 q2'), isTrue);
  });

  test('queuedAfterIndex counts reached songs as played', () {
    expect(queuedAfterIndex(3, 2, 2), (3, 2));
    expect(queuedAfterIndex(3, 2, 3), (4, 1));
    expect(queuedAfterIndex(3, 2, 7), (0, 0));
    expect(queuedAfterIndex(0, 0, 1), (0, 0));
  });

  test('smart shuffle interleaves, marks and removes upcoming extras when switched off', () async {
    final original = await enableSmart();
    expect(view().queue[4].id, 'smart-a');
    expect(view().queue[8].id, 'smart-b');
    expect(view().smartIds, {'smart-a', 'smart-b'});
    expect(engine.audioSources, hasLength(9));
    engine.position = const Duration(seconds: 42);
    await player.toggleShuffle();
    expect(view().shuffle, isFalse);
    expect(view().smartShuffle, isFalse);
    expect(view().queue.map((t) => t.id), original.map((t) => t.id));
    expect(view().current!.id, original.first.id);
    expect(engine.removed, isEmpty, reason: "the extras go in one engine call, not one by one");
    expect(engine.playing, isTrue);
    expect(engine.position, const Duration(seconds: 42));
  });

  test('disabling smart shuffle keeps a currently playing recommendation', () async {
    await enableSmart();
    await player.jumpTo(4);
    engine.position = const Duration(seconds: 25);
    await player.toggleShuffle();
    expect(view().current!.id, 'smart-a');
    expect(view().smartIds, {'smart-a'});
    expect(view().queue.any((t) => t.id == 'smart-b'), isFalse);
    expect(engine.playing, isTrue);
    expect(engine.position, const Duration(seconds: 25));
  });

  test('media shuffle all selects normal shuffle even from smart shuffle', () async {
    await enableSmart();
    await player.setShuffle(true);
    expect(view().shuffle, isTrue);
    expect(view().smartShuffle, isFalse);
    expect(view().smartIds, isEmpty);
    expect(engine.audioSources, hasLength(7));
  });

  test('smart shuffle carries to new eligible contexts and skips radio playlists', () async {
    await enableSmart();
    final next = List.generate(10, (i) => track('new-$i'));
    await player.playTracks(next, context: 'album:second');
    expect(view().smartShuffle, isTrue);
    expect(view().smartIds, isEmpty);
    expect(api.recommendationCalls, hasLength(2));
    expect(api.recommendationCalls.last.seeds, unorderedEquals(next.map((t) => t.id)));
    api.recommendationCalls.last.response.complete([track('new-smart')]);
    await settle();
    expect(view().smartIds, {'new-smart'});
    await player.playTracks(next, context: 'playlist:radio', isRadio: true);
    expect(view().smartShuffle, isFalse);
    expect(view().smartIds, isEmpty);
    await player.toggleShuffle();
    expect(view().shuffle, isFalse);
    await player.toggleShuffle();
    expect(view().shuffle, isTrue);
    expect(view().smartShuffle, isFalse);
    expect(api.recommendationCalls, hasLength(2));
  });

  test('late smart shuffle responses are discarded after switching off', () async {
    player.setAutoplay(false);
    await player.playTracks(List.generate(7, (i) => track('$i')), context: 'liked');
    await player.toggleShuffle();
    await player.toggleShuffle();
    await player.toggleShuffle();
    api.recommendationCalls.single.response.complete([track('late')]);
    await settle();
    expect(view().queue, hasLength(7));
    expect(view().smartIds, isEmpty);
  });

  test('smart shuffle samples at most 100 context tracks and requests at most 50', () async {
    player.setAutoplay(false);
    await player.playTracks(List.generate(180, (i) => track('$i')), context: 'liked');
    await player.toggleShuffle();
    await player.toggleShuffle();
    expect(api.recommendationCalls.single.seeds, hasLength(100));
    expect(api.recommendationCalls.single.excluded, hasLength(180));
    expect(api.recommendationCalls.single.limit, 50);
  });

  test('AutoMix orders autoplay tracks once from the current track, including with shuffle off', () async {
    player.setAutomix(true);
    api.keys.addAll({
      'start': (key: '8A', bpm: 120),
      'bad': (key: '3B', bpm: 120),
      'good': (key: '9A', bpm: 120),
      'relative': (key: '9B', bpm: 120),
    });
    await player.playTracks([track('start')]);
    api.recommendationCalls.single.response.complete([track('bad'), track('good'), track('relative'), track('good')]);
    await settle();
    expect(view().shuffle, isFalse);
    expect(view().queue.map((t) => t.id), ['start', 'good', 'relative', 'bad']);
    expect(api.keyCalls, [
      ['start', 'bad', 'good', 'relative'],
    ]);
    expect(view().autoplayIds, {'good', 'relative', 'bad'});
  });

  test('AutoMix key failures keep autoplay recommendation order', () async {
    player.setAutomix(true);
    api.failKeys = true;
    await player.playTracks([track('start')]);
    api.recommendationCalls.single.response.complete([track('first'), track('second')]);
    await settle();
    expect(view().queue.map((t) => t.id), ['start', 'first', 'second']);
    expect(api.keyCalls, hasLength(1));
  });

  test('late autoplay keys do not enter a replacement context', () async {
    player.setAutomix(true);
    api.keyResponse = Completer();
    await player.playTracks([track('old')]);
    api.recommendationCalls.single.response.complete([track('stale')]);
    await settle();
    expect(api.keyCalls, hasLength(1));
    player.setAutoplay(false);
    final replacement = player.playTracks([track('new'), track('next')]);
    api.keyResponse!.complete({'old': (key: '8A', bpm: 120), 'stale': (key: '8A', bpm: 120)});
    await replacement;
    expect(view().queue.map((t) => t.id), ['new', 'next']);
    expect(view().autoplayIds, isEmpty);
  });

  test('AutoMix smart shuffle chooses extras for the context tracks they follow', () async {
    player.setAutoplay(false);
    await player.playTracks(List.generate(7, (i) => track('$i')), context: 'liked');
    await player.toggleShuffle();
    final shuffled = [...view().queue];
    player.setAutomix(true);
    api.keys.addAll({
      shuffled[3].id: (key: '8A', bpm: 120),
      shuffled[6].id: (key: '3B', bpm: 120),
      'bad': (key: '3B', bpm: 120),
      'good': (key: '8A', bpm: 120),
    });
    await player.toggleShuffle();
    api.recommendationCalls.single.response.complete([track('bad'), track('good')]);
    await settle();
    expect(api.keyCalls, [
      ['bad', 'good', shuffled[3].id, shuffled[6].id],
    ]);
    expect(view().queue[4].id, 'good');
    expect(view().queue[8].id, 'bad');
    expect(view().queue.where((t) => !view().smartIds.contains(t.id)), shuffled);
  });

  test('AutoMix shuffle keeps the current track playing and restores the original order', () async {
    player.setAutoplay(false);
    final original = [track('start'), track('bad'), track('good')];
    api.keys.addAll({'start': (key: '8A', bpm: 120), 'bad': (key: '3B', bpm: 120), 'good': (key: '9A', bpm: 120)});
    player.setAutomix(true);
    await player.playTracks(original);
    expect(api.keyCalls, isEmpty);
    engine.position = const Duration(seconds: 42);
    await player.setShuffle(true);
    expect(view().queue.map((t) => t.id), ['start', 'good', 'bad']);
    expect(view().current!.id, 'start');
    expect(engine.preservedCurrent, isTrue);
    expect(engine.playing, isTrue);
    expect(engine.position, const Duration(seconds: 42));
    expect(api.keyCalls.single, unorderedEquals(['start', 'bad', 'good']));
    await player.setShuffle(false);
    expect(view().queue, original);
    expect(api.keyCalls, hasLength(1));
  });

  test('AutoMix orders a new shuffled context and preserves its unshuffled list', () async {
    player.setAutoplay(false);
    player.setAutomix(true);
    await player.setShuffle(true);
    api.keys.addAll({'start': (key: '8A', bpm: 120), 'bad': (key: '3B', bpm: 120), 'good': (key: '9A', bpm: 120)});
    final original = [track('start'), track('bad'), track('good')];
    await player.playTracks(original, index: 0, context: 'album:new');
    expect(view().queue.map((t) => t.id), ['start', 'good', 'bad']);
    expect(api.keyCalls, hasLength(1));
    await player.setShuffle(false);
    expect(view().queue, original);
  });

  for (final fail in [false, true]) {
    test('AutoMix keeps plain shuffle when keys are ${fail ? 'unavailable' : 'unknown'}', () async {
      player.setAutoplay(false);
      player.setAutomix(true);
      api.failKeys = fail;
      final original = List.generate(10, (i) => track('$i'));
      await player.playTracks(original, index: 3);
      await player.setShuffle(true);
      expect(view().shuffle, isTrue);
      expect(view().current!.id, '3');
      expect(view().queue, unorderedEquals(original));
      expect(engine.preservedCurrent, isTrue);
      expect(api.keyCalls, hasLength(1));
    });
  }

  test('regular shuffle and excluded contexts never fetch harmonic keys', () async {
    player.setAutoplay(false);
    final tracks = List.generate(3, (i) => track('$i'));
    await player.playTracks(tracks);
    await player.setShuffle(true);
    expect(api.keyCalls, isEmpty);
    player.setAutomix(true);
    for (final context in ['jam:id', 'book:id', 'station:id']) {
      await player.playTracks(tracks, index: 0, context: context);
    }
    expect(api.keyCalls, isEmpty);
  });

  group('last playback', () {
    late ProviderContainer remembering;
    setUp(() {
      PlayerController.rememberPlayback = true;
      engine = _Engine();
      api.lastSaved = {
        'kind': 'tracks',
        'tracks': [
          for (final id in ['a', 'b', 'c']) trackJson(id),
        ],
        'index': 1,
        'position': 42.5,
        'context': 'album:x',
        'is_radio': false,
      };
      remembering = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          apiProvider.overrideWithValue(api),
          sessionProvider.overrideWith(_Session.new),
          downloadSummaryProvider.overrideWith((ref) async => const DownloadSummary()),
          playerProvider.overrideWith(() => PlayerController(engine: engine)),
        ],
      );
    });
    tearDown(() {
      PlayerController.rememberPlayback = false;
      remembering.dispose();
    });

    test('comes back paused after a restart, at the song and position', () async {
      remembering.read(playerProvider);
      await settle();
      final restored = remembering.read(playerProvider);
      expect(restored.queue.map((t) => t.id), ['a', 'b', 'c']);
      expect(restored.index, 1);
      expect(restored.context, 'album:x');
      expect(engine.position, const Duration(milliseconds: 42500));
      expect(engine.playing, isFalse);
      // Bringing it back does not send it straight back to the server.
      expect(api.saved, isEmpty);
    });

    test('is saved when the song changes and when pausing', () async {
      api.lastSaved = null;
      final controller = remembering.read(playerProvider.notifier);
      await settle();
      await controller.playTracks([track('x'), track('y')], context: 'playlist:p');
      expect(api.saved.last, {
        'kind': 'tracks',
        'track_ids': ['x', 'y'],
        'index': 0,
        'position': 0.0,
        'context': 'playlist:p',
        'is_radio': false,
      });
      engine.position = const Duration(seconds: 70);
      await engine.pause();
      expect(api.saved.last['position'], 70.0);
    });
  });
}
