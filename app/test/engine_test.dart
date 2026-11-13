import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/player/engine.dart';

void main() {
  group('linear crossfade volumes', () {
    (double, double) volumes(int milliseconds, {int seconds = 4}) => fadeVolumes(
      elapsed: Duration(milliseconds: milliseconds),
      crossfade: Duration(seconds: seconds),
      outgoingTarget: 0.4,
      incomingTarget: 0.8,
    );

    test('each track uses its own ReplayGain and user volume target', () {
      expect(volumes(0), (0.4, 0.0));
      final (outgoing, incoming) = volumes(1000);
      expect(outgoing, closeTo(0.3, 1e-10));
      expect(incoming, closeTo(0.2, 1e-10));
      expect(volumes(2000), (0.2, 0.4));
      expect(volumes(4000), (0.0, 0.8));
    });

    test('times outside the fade clamp to the endpoints', () {
      expect(volumes(-100), (0.4, 0.0));
      expect(volumes(5000), (0.0, 0.8));
      expect(volumes(0, seconds: 0), (0.0, 0.8));
    });
  });

  group('start fade decision', () {
    bool start({
      int crossfade = 4,
      bool playing = true,
      bool book = false,
      LoopMode loop = LoopMode.off,
      int? index = 0,
      int length = 2,
      int position = 96000,
      int? duration = 100000,
    }) => shouldStartFade(
      crossfadeSeconds: crossfade,
      playing: playing,
      isBook: book,
      loopMode: loop,
      index: index,
      length: length,
      position: Duration(milliseconds: position),
      duration: duration == null ? null : Duration(milliseconds: duration),
    );

    test('starts at the threshold, including a late position tick', () {
      expect(start(position: 95999), false);
      expect(start(), true);
      expect(start(position: 96050), true);
    });

    test('disabled crossfade preserves playlist gapless playback', () {
      expect(start(crossfade: 0), false);
    });

    test('paused playback and audiobooks never fade', () {
      expect(start(playing: false), false);
      expect(start(book: true), false);
    });

    test('repeat one never fades', () {
      expect(start(loop: LoopMode.one), false);
    });

    test('last item fades only when repeat all wraps the queue', () {
      expect(start(index: 1), false);
      expect(start(index: 1, loop: LoopMode.all), true);
      expect(start(length: 1, loop: LoopMode.all), true);
    });

    test('short tracks need more than twice the fade duration', () {
      expect(start(duration: 7999, position: 4000), false);
      expect(start(duration: 8000, position: 4000), false);
      expect(start(duration: 8001, position: 4001), true);
    });

    test('unknown duration, empty queue and completed tracks do not fade', () {
      expect(start(duration: null), false);
      expect(start(index: null), false);
      expect(start(length: 0), false);
      expect(start(position: 100000), false);
    });
  });

  group('shuffle and original queue order', () {
    test('keeps the selected track first and every other entry exactly once', () {
      final original = List.generate(20, (index) => 'track-$index');
      final shuffled = shuffleQueue(original, 7, random: Random(42));
      expect(shuffled.first, original[7]);
      expect(shuffled, unorderedEquals(original));
      expect(shuffled.skip(1), isNot(original.where((track) => track != original[7])));
      expect(original[7], 'track-7');
    });

    test('unshuffle restores the original order and current track index', () {
      final original = ['a', 'b', 'c', 'd'];
      final shuffled = shuffleQueue(original, 2, random: Random(1));
      final (restored, index) = unshuffleQueue(original, shuffled[2]);
      expect(restored, original);
      expect(restored[index], shuffled[2]);
      expect(identical(restored, original), false);
    });

    test('single-track queues work in both directions', () {
      expect(shuffleQueue(['a'], 0), ['a']);
      final (restored, index) = unshuffleQueue(['a'], 'a');
      expect(restored, ['a']);
      expect(index, 0);
    });

    test('duplicate tracks retain distinct queue entries', () {
      final a = Object();
      final b = Object();
      final original = [a, b, a];
      final shuffled = shuffleQueue(original, 1, random: Random(1));
      expect(shuffled.first, same(b));
      expect(shuffled.where((track) => identical(track, a)).length, 2);
      final (restored, index) = unshuffleQueue(original, b);
      expect(restored, orderedEquals(original));
      expect(index, 1);
    });
  });

  group('replace upcoming queue', () {
    test('keeps the current object and removes every matching seed id', () {
      const current = (id: 'seed', title: 'Playing');
      final tracks = [
        (id: 'a', title: 'First'),
        (id: 'seed', title: 'Other metadata'),
        (id: 'b', title: 'Second'),
        current,
      ];
      final (queue, original) = replaceUpcomingQueue(current, tracks, id: (track) => track.id, shuffle: false);
      expect(queue, [current, tracks[0], tracks[2]]);
      expect(original, queue);
      expect(identical(queue, original), false);
      expect(tracks, hasLength(4));
    });

    test('shuffles only upcoming songs and retains the order for unshuffle', () {
      final tracks = ['seed', ...List.generate(20, (index) => 'track-$index')];
      final (queue, original) = replaceUpcomingQueue(
        'seed',
        tracks,
        id: (track) => track,
        shuffle: true,
        random: Random(42),
      );
      expect(queue.first, 'seed');
      expect(queue.skip(1), unorderedEquals(tracks.skip(1)));
      expect(queue.skip(1), isNot(orderedEquals(tracks.skip(1))));
      expect(original, tracks);
      final (restored, index) = unshuffleQueue(original, queue[4]);
      expect(restored, tracks);
      expect(restored[index], queue[4]);
    });

    test('an empty radio leaves the seed as the sole item with either shuffle setting', () {
      for (final shuffle in [false, true]) {
        final (queue, original) = replaceUpcomingQueue('seed', <String>[], id: (track) => track, shuffle: shuffle);
        expect(queue, ['seed']);
        expect(original, ['seed']);
      }
    });
  });

  group('automix plan', () {
    MixPoints points({
      double? bpm,
      double mixIn = 0.5,
      double mixOut = 200,
      double end = 210,
      double? vocalsIn,
      double? vocalsOut,
      double? introEnd,
    }) => MixPoints(
      bpm: bpm,
      mixIn: mixIn,
      mixOut: mixOut,
      end: end,
      vocalsIn: vocalsIn,
      vocalsOut: vocalsOut,
      introEnd: introEnd,
    );

    test('parses optional vocal bounds as doubles', () {
      final json = <String, dynamic>{'bpm': 120, 'mix_in': 0.5, 'mix_out': 200, 'end': 210};
      final missing = MixPoints.fromJson(json);
      expect((missing.vocalsIn, missing.vocalsOut), (null, null));
      final vocals = MixPoints.fromJson({...json, 'vocals_in': 8, 'vocals_out': 204.25});
      expect((vocals.vocalsIn, vocals.vocalsOut), (8.0, 204.25));
      final absent = MixPoints.fromJson({...json, 'vocals_in': null, 'vocals_out': null});
      expect((absent.vocalsIn, absent.vocalsOut), (null, null));
    });

    Duration secs(double s) => Duration(microseconds: (s * 1e6).round());

    test('with section starts the bass swaps a phrase after the outro starts, never before it', () {
      final json = <String, dynamic>{
        'bpm': 120,
        'mix_in': 0.5,
        'mix_out': 160.5,
        'end': 200,
        'downbeat': 0.5,
        'phrases': [64.5, 160.5],
        'energy': 0.7,
      };
      final outgoing = MixPoints.fromJson(json);
      expect((outgoing.downbeat, outgoing.energy), (0.5, 0.7));
      expect(outgoing.phrases, [64.5, 160.5]);
      final plan = automixPlan(outgoing, points(bpm: 120, mixIn: 0.5))!;
      // 16 beats at 120 BPM = 8 s: the swap lands on 168.5, a phrase of the current song.
      expect(plan.start + plan.bassSwap, secs(168.5));
      expect(plan.start >= secs(160.5), isTrue);
      final old = automixPlan(points(bpm: 120, mixOut: 160.5, end: 200), points(bpm: 120, mixIn: 0.5))!;
      expect(old.start + old.bassSwap, secs(164.5), reason: 'older analyses keep half a phrase');
    });

    test('matches close tempos and starts the next song at its first beat', () {
      final plan = automixPlan(points(bpm: 120, mixOut: 200.25), points(bpm: 120, mixIn: 1.5))!;
      expect(plan.incomingStart, const Duration(milliseconds: 1500));
      expect(plan.speed, closeTo(1, 1e-6));
      expect(plan.beatMatched, isTrue);
      expect(automixPlan(points(bpm: 124), points(bpm: 120))!.speed, closeTo(124 / 120, 1e-9));
    });

    test('folds double and half time', () {
      expect(automixPlan(points(bpm: 172), points(bpm: 86))!.speed, closeTo(1, 1e-6));
      expect(automixPlan(points(bpm: 90), points(bpm: 176))!.speed, closeTo(180 / 176, 1e-9));
      expect(automixPlan(points(bpm: 120), points(bpm: 120))!.beatMatched, isTrue);
    });

    test('blends without tempo change when tempos are too far apart or unknown', () {
      expect(automixPlan(points(bpm: 128), points(bpm: 100))!.beatMatched, isFalse);
      expect(automixPlan(points(), points(bpm: 100))!.speed, 1);
    });

    test('blends run 16 beats, the bass swapping halfway, half a phrase after the mix-out point', () {
      // 120 BPM: 16 beats are 8 s, one bar 2 s.
      final plan = automixPlan(points(bpm: 120, mixOut: 200, end: 210), points(bpm: 120))!;
      expect(plan.start, const Duration(seconds: 200));
      expect(plan.duration, const Duration(seconds: 8));
      expect(plan.bassSwap, const Duration(seconds: 4));
      expect(plan.intro, isFalse);
      // A short outro: earlier by whole bars.
      expect(automixPlan(points(bpm: 120, end: 205), points(bpm: 120))!.start, const Duration(seconds: 196));
      // Slow songs take longer; without a tempo 10 s.
      expect(automixPlan(points(bpm: 70, mixOut: 150), points(bpm: 70))!.duration, secs(16 * 60 / 70));
      expect(automixPlan(points(mixOut: 150), points())!.duration, const Duration(seconds: 10));
    });

    test('the next song\'s intro plays under the current one and comes in fully at the bass swap', () {
      // Eight bars of intro (16 s): the last four bars play under the current song, then the bass swaps.
      final plan = automixPlan(points(bpm: 120), points(bpm: 120, mixIn: 0.5, introEnd: 16.5))!;
      expect(plan.intro, isTrue);
      expect(plan.incomingStart.inMicroseconds / 1e6, closeTo(8.5, 1e-4));
      expect(plan.bassSwap, const Duration(seconds: 8));
      expect(plan.duration, const Duration(seconds: 12));
      // The swap still lands half a phrase after the mix-out point.
      expect(plan.start + plan.bassSwap, const Duration(seconds: 204));
      // A two-bar intro plays whole.
      final short = automixPlan(points(bpm: 120), points(bpm: 120, mixIn: 0.5, introEnd: 4.5))!;
      expect(short.incomingStart.inMicroseconds / 1e6, closeTo(0.5, 1e-4));
      expect((short.bassSwap, short.duration), (secs(4), secs(8)));
      // No intro (full strength from the first beat): the default crossing.
      final none = automixPlan(points(bpm: 120), points(bpm: 120, introEnd: 0.5))!;
      expect((none.intro, none.incomingStart), (false, secs(0.5)));
      // A slower next song is sped up: its intro is shorter in the current song's time.
      final faster = automixPlan(points(bpm: 120), points(bpm: 115, mixIn: 0.5, introEnd: 0.5 + 32 * 60 / 115))!;
      expect(faster.intro, isTrue);
      expect(faster.bassSwap, const Duration(seconds: 8));
      final incomingTime = (0.5 + 32 * 60 / 115) - faster.incomingStart.inMicroseconds / 1e6;
      expect(incomingTime / faster.ratio, closeTo(8, 1e-3));
    });

    test('skips songs without a usable outro and never starts in the first half', () {
      expect(automixPlan(points(mixOut: 100, end: 101), points()), isNull);
      expect(automixPlan(points(mixOut: 0, end: 5), points()), isNull);
      // Three bars earlier would be before the middle: it starts there and gets shorter.
      final early = automixPlan(points(bpm: 120, mixOut: 12, end: 15), points(bpm: 120))!;
      expect(early.start, const Duration(milliseconds: 7500));
      expect(early.duration, const Duration(milliseconds: 7500));
      // A short outro: the blend reaches back into the song.
      final short = automixPlan(points(mixOut: 100, end: 102), points())!;
      expect((short.start, short.duration), (const Duration(seconds: 92), const Duration(seconds: 10)));
    });

    test('the crossfade setting asks for longer blends, up to 30 seconds', () {
      final plan = automixPlan(points(bpm: 120, mixOut: 200, end: 210), points(bpm: 120), minSeconds: 24)!;
      expect(plan.start, const Duration(seconds: 186));
      expect(plan.duration, const Duration(seconds: 24));
      expect(plan.bassSwap, const Duration(seconds: 4));
      expect(
        automixPlan(points(mixOut: 100, end: 130), points(), minSeconds: 40)!.duration,
        const Duration(seconds: 30),
      );
      expect(automixPlan(points(bpm: 120), points(bpm: 120), minSeconds: 5)!.duration, const Duration(seconds: 8));
    });

    test('the next voice comes in after the current one stopped, starting later by whole bars', () {
      // The current voice ends 7 s in, the next one starts 5 s in: one bar later they follow each other and the
      // bass swaps between them.
      final plan = automixPlan(points(bpm: 120, vocalsOut: 207), points(bpm: 120, mixIn: 1, vocalsIn: 6))!;
      expect(plan.start, const Duration(seconds: 202));
      expect(plan.duration, const Duration(seconds: 8));
      expect(plan.bassSwap, const Duration(seconds: 5));
    });

    test('voices that already follow each other keep the blend and swap the bass between them', () {
      final plan = automixPlan(points(bpm: 120, vocalsOut: 195), points(bpm: 120, vocalsIn: 14.5))!;
      expect(plan.start, const Duration(seconds: 200));
      expect(plan.duration, const Duration(seconds: 8));
      expect(plan.bassSwap, const Duration(seconds: 4));
      final late = automixPlan(points(bpm: 120, vocalsOut: 205), points(bpm: 120, vocalsIn: 30))!;
      // Not before the current voice has ended (5 s in).
      expect(late.bassSwap, const Duration(seconds: 5));
    });

    test('when the voices cannot be separated the blend moves as late as the song allows', () {
      final plan = automixPlan(points(bpm: 120, vocalsOut: 209), points(bpm: 120, vocalsIn: 0.5))!;
      // At most until six seconds before the end, on a bar.
      expect(plan.start, const Duration(seconds: 204));
      expect(plan.duration, const Duration(seconds: 6));
      final unknownTempo = automixPlan(points(vocalsOut: 209.5), points(vocalsIn: 0.5))!;
      expect(unknownTempo.start, const Duration(seconds: 204));
      expect(unknownTempo.duration, const Duration(seconds: 6));
    });

    test('with only one voice known the other is assumed at the swap', () {
      // The current voice ends 6 s into the blend, 2 s after the swap: start a bar later.
      final outgoing = automixPlan(points(bpm: 120, vocalsOut: 206), points(bpm: 120))!;
      expect(outgoing.start, const Duration(seconds: 202));
      expect(outgoing.bassSwap, const Duration(seconds: 4));
      // The next voice right at the start is fine when nothing is known about the current one.
      final incoming = automixPlan(points(bpm: 120), points(bpm: 120, vocalsIn: 0.5))!;
      expect(incoming.duration, const Duration(seconds: 8));
      expect(incoming.bassSwap, const Duration(milliseconds: 500));
    });

    test('null vocal bounds keep the blend', () {
      final outgoing = MixPoints.fromJson({
        'bpm': 120,
        'mix_in': 0.5,
        'mix_out': 200.25,
        'end': 210.25,
        'vocals_in': null,
        'vocals_out': null,
      });
      final incoming = MixPoints.fromJson({
        'bpm': 120,
        'mix_in': 1.5,
        'mix_out': 200,
        'end': 210,
        'vocals_in': null,
        'vocals_out': null,
      });
      final plan = automixPlan(outgoing, incoming)!;
      expect(plan.start, const Duration(milliseconds: 200250));
      expect(plan.incomingStart, const Duration(milliseconds: 1500));
      expect(plan.duration, const Duration(seconds: 8));
      expect(plan.bassSwap, const Duration(seconds: 4));
      expect(plan.filterOut, isFalse);
    });

    test('vocal bounds leave the filter-out transition unchanged', () {
      final plan = automixPlan(points(bpm: 128, vocalsOut: 210), points(bpm: 100, vocalsIn: 0), minSeconds: 20)!;
      expect(plan.filterOut, isTrue);
      // Sixteen beats at 128 BPM = 7.5 s, ending two seconds before the song does.
      expect(plan.duration, const Duration(milliseconds: 7500));
      expect(plan.start, const Duration(milliseconds: 200500));
      expect(plan.bassSwap, Duration.zero);
    });

    test('swaps the bass on a beat in the middle of the blend', () {
      final plan = automixPlan(points(bpm: 124, mixOut: 200.25), points(bpm: 120, mixIn: 1.5))!;
      final beat = 60 / 124;
      expect(plan.duration, secs(16 * beat));
      expect(plan.bassSwap.inMicroseconds / 1e6, closeTo(8 * beat, 1e-3));
      expect(automixPlan(points(mixOut: 100, end: 110), points())!.bassSwap, const Duration(seconds: 5));
      // Up to 8 % tempo difference is matched.
      expect(automixPlan(points(bpm: 107), points(bpm: 100))!.beatMatched, isTrue);
      expect(automixPlan(points(bpm: 110), points(bpm: 100))!.beatMatched, isFalse);
    });

    test('larger tempo differences meet in the middle', () {
      final small = automixPlan(points(bpm: 103), points(bpm: 100))!;
      expect(small.outgoingSpeed, 1);
      expect(small.speed, closeTo(1.03, 1e-9));
      final large = automixPlan(points(bpm: 107), points(bpm: 100))!;
      // Both move about 3.4 %, and the incoming song still follows the outgoing beat.
      expect(large.outgoingSpeed, closeTo(1 / sqrt(1.07), 1e-9));
      expect(large.speed, closeTo(sqrt(1.07), 1e-9));
      expect(large.ratio, closeTo(1.07, 1e-9));
      expect(107 * large.outgoingSpeed, closeTo(100 * large.speed, 1e-9));
    });

    test('equal tempos start on the beat without a speed change', () {
      final same = automixPlan(points(bpm: 120), points(bpm: 120))!;
      expect(same.beatMatched, isTrue);
      expect(same.changesTempo, isFalse);
      expect(automixPlan(points(bpm: 121), points(bpm: 120))!.changesTempo, isTrue);
    });

    test('the current song never drifts away from the next one\'s own tempo', () {
      // 70 BPM blends at double time (140) into 130: the current song must not speed up toward a slower song.
      final half = automixPlan(points(bpm: 130), points(bpm: 70))!;
      expect(half.outgoingSpeed, 1);
      expect(half.speed, closeTo(130 / 140, 1e-9));
      expect(half.beatMatched, isTrue);
      // The other way round: a fast song after a slow one does not slow the current song down.
      final faster = automixPlan(points(bpm: 70), points(bpm: 130))!;
      expect(faster.outgoingSpeed, 1);
      expect(faster.speed, closeTo(140 / 130, 1e-9));
      // Without the octave the tempos still meet in the middle, toward the next song.
      final slower = automixPlan(points(bpm: 107), points(bpm: 100))!;
      expect(slower.outgoingSpeed, lessThan(1));
    });

    test('camelot compatibility', () {
      expect(camelotCompatible('8A', '8A'), isTrue);
      expect(camelotCompatible('8A', '9A'), isTrue);
      expect(camelotCompatible('12B', '1B'), isTrue);
      expect(camelotCompatible('8A', '8B'), isTrue);
      expect(camelotCompatible('8A', '10A'), isFalse);
      expect(camelotCompatible('8A', '9B'), isFalse);
    });

    test('clashing keys blend for only two bars, clashing tempos filter out', () {
      MixPoints keyed({double? bpm, String? key}) =>
          MixPoints(bpm: bpm, mixIn: 0.5, mixOut: 190, end: 210, key: key, keyConfidence: 0.3);
      final clash = automixPlan(keyed(bpm: 120, key: '8A'), keyed(bpm: 121, key: '3B'))!;
      expect(clash.filterOut, isFalse);
      expect(clash.beatMatched, isTrue);
      expect(clash.duration, const Duration(seconds: 4));
      expect(clash.bassSwap, const Duration(seconds: 2));
      final tempo = automixPlan(keyed(bpm: 128), keyed(bpm: 100))!;
      expect((tempo.filterOut, tempo.beatMatched), (true, false));
      // Sixteen beats (7.5 s at 128 BPM), ending two seconds before the song does.
      expect(tempo.duration, const Duration(milliseconds: 7500));
      expect(tempo.start, const Duration(milliseconds: 200500));
      expect(automixPlan(keyed(bpm: 120, key: '8A'), keyed(bpm: 120, key: '9A'))!.duration, const Duration(seconds: 8));
      expect(automixPlan(keyed(), keyed())!.filterOut, isFalse);
    });

    test('filter-out volumes and a smooth sweep', () {
      const d = Duration(seconds: 8);
      (double, double) at(int ms) => filterOutVolumes(
        elapsed: Duration(milliseconds: ms),
        duration: d,
        outgoingTarget: 1,
        incomingTarget: 1,
      );
      expect(at(0), (1.0, 0.0));
      // The next song waits for the first quarter, then comes in and is up at three quarters.
      expect(at(2000).$2, 0);
      expect(at(4000).$2, closeTo(sin(pi / 4), 1e-9));
      expect(at(6000).$2, closeTo(1, 1e-9));
      expect(at(4000).$1, lessThan(at(2000).$1));
      // The low end fades octave by octave; nothing jumps by more than about a decibel per step.
      expect(AutomixCut(sweep: 0).reductionAt(60), 0);
      expect(AutomixCut(sweep: 0.25).reductionAt(60), automixBassCutDb);
      expect(AutomixCut(sweep: 0.25).reductionAt(910), 0);
      expect(AutomixCut(sweep: 1).reductionAt(910), automixBassCutDb);
      expect(AutomixCut(sweep: 1).reductionAt(14000), 0);
      var previous = 0.0;
      for (var i = 1; i <= 100; i++) {
        final now = AutomixCut(sweep: i / 100).reductionAt(230);
        expect((now - previous).abs(), lessThanOrEqualTo(1.6));
        previous = now;
      }
      expect(AutomixCut(sweep: 0.5), AutomixCut(sweep: 0.501));
      expect(AutomixCut().mpvCommands, [
        ['af-command', 'automix', 'g', '0.0', 'bass@lo'],
        ['af-command', 'automix', 'f', '10', 'highpass@hp'],
      ]);
      expect(AutomixCut(sweep: 1).mpvCommands.last[3], '2400');
      // Only the low end swaps; mids and highs stay with the volume curve (no sudden drop or jump).
      expect(AutomixCut.bassSwap.reductionAt(60), automixBassCutDb);
      expect(AutomixCut.bassSwap.reductionAt(230), 0);
      expect(AutomixCut.bassSwap.reductionAt(910), 0);
      expect(AutomixCut(bass: 0.4).mpvCommands.first[3], '-6.0');
    });

    test('blend volumes without an intro cross at the swap and stay within about 1.5 dB', () {
      (double, double) at(double seconds, {double incomingTarget = 1}) => automixVolumes(
        elapsed: secs(seconds),
        duration: const Duration(seconds: 10),
        swap: const Duration(seconds: 4),
        outgoingTarget: 1,
        incomingTarget: incomingTarget,
      );
      expect(at(0, incomingTarget: 0.5), (1.0, 0.0));
      final (out, inc) = at(4);
      expect(out, closeTo(inc, 1e-9));
      // Beat-matched (adding amplitudes) and unrelated (adding power) both stay near the level of one song.
      for (final t in [1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 9.0]) {
        final (o, i) = at(t);
        expect(20 * log(o + i) / ln10, inInclusiveRange(0, 1.6), reason: '$t s');
        expect(10 * log(o * o + i * i) / ln10, inInclusiveRange(-1.6, 0), reason: '$t s');
      }
      expect(at(11, incomingTarget: 0.5), (0.0, 0.5));
    });

    test('with an intro the next song is fully in at the swap while the current one stays up, then goes', () {
      (double, double) at(double seconds) => automixVolumes(
        elapsed: secs(seconds),
        duration: const Duration(seconds: 12),
        swap: const Duration(seconds: 8),
        intro: true,
        outgoingTarget: 1,
        incomingTarget: 1,
      );
      expect(at(0), (1.0, 0.0));
      expect(at(4).$2, closeTo(sin(pi / 4), 1e-9));
      expect(at(4).$1, greaterThan(0.95));
      // -1.5 dB at the swap, the next song fully in.
      expect(20 * log(at(8).$1) / ln10, closeTo(-1.5, 0.1));
      expect(at(8).$2, 1);
      // The current song eases off and its last 40 % fade out, without jumps.
      var previous = at(8).$1;
      for (var t = 8.05; t < 12; t += 0.05) {
        final now = at(t).$1;
        expect(now, lessThanOrEqualTo(previous + 1e-9));
        expect(previous - now, lessThan(0.05));
        previous = now;
      }
      expect(at(11.99).$1, lessThan(0.01));
      expect(at(12), (0.0, 1.0));
    });

    test('a saved transition keeps its own start, entry point, length and sound, beat-matched', () {
      const saved = CustomTransition(style: TransitionStyle.fadeIn, bars: 4, start: 180, incomingStart: 12.5);
      final plan = customAutomixPlan(points(bpm: 124), points(bpm: 120), saved);
      final beat = 60 / 124;
      expect(plan.start, secs(180));
      expect(plan.incomingStart, secs(12.5));
      expect(plan.duration, secs(16 * beat));
      expect(plan.bassSwap.inMicroseconds / 1e6, closeTo(8 * beat, 1e-3));
      expect((plan.intro, plan.fadeOut, plan.filterOut), (true, false, false));
      expect(plan.speed, closeTo(124 / 120, 1e-9));
      // The other presets, and a transition that would run past the end of the song.
      final fadeOut = customAutomixPlan(
        points(bpm: 120),
        points(bpm: 120),
        saved.copyWith(style: TransitionStyle.fadeOut),
      );
      expect((fadeOut.fadeOut, fadeOut.intro), (true, false));
      final filter = customAutomixPlan(
        points(bpm: 120),
        points(bpm: 120),
        saved.copyWith(style: TransitionStyle.filter),
      );
      expect((filter.filterOut, filter.bassSwap), (true, Duration.zero));
      final late = customAutomixPlan(points(bpm: 120), points(bpm: 120), saved.copyWith(start: 205, bars: 8));
      expect(late.duration, secs(5));
    });

    test('saved transitions round-trip as json and start from the automatic plan', () {
      const saved = CustomTransition(style: TransitionStyle.fadeOut, bars: 8, start: 190.5, incomingStart: 3);
      expect(CustomTransition.fromJson(saved.toJson()), saved);
      expect(saved.toJson()['style'], 'fade_out');
      expect(CustomTransition.fromJson({...saved.toJson(), 'style': 'unknown'}), isNull);
      final auto = automixPlan(points(bpm: 120), points(bpm: 120, mixIn: 0.5, introEnd: 16.5))!;
      final edited = CustomTransition.fromPlan(auto, 120);
      expect(edited.style, TransitionStyle.fadeIn);
      // 12 s at 120 BPM are six bars: the nearest choice.
      expect(edited.bars, anyOf(4, 8));
      expect(edited.start, closeTo(auto.start.inMicroseconds / 1e6, 1e-6));
    });

    test('fade-out volumes: the current song fades all along, the next one comes in after the swap', () {
      (double, double) at(double s) => fadeOutVolumes(
        elapsed: secs(s),
        duration: const Duration(seconds: 8),
        swap: const Duration(seconds: 4),
        outgoingTarget: 1,
        incomingTarget: 1,
      );
      expect(at(0), (1.0, 0.0));
      expect(at(4).$1, closeTo(cos(pi / 4), 1e-9));
      expect(at(4).$2, 0);
      expect(at(6).$2, closeTo(sin(pi / 4), 1e-9));
      expect(at(8), (0.0, 1.0));
    });

    test('reads where the intro ends', () {
      final p = MixPoints.fromJson({'bpm': 120, 'mix_in': 1, 'mix_out': 200, 'end': 210, 'intro_end': 17});
      expect(p.introEnd, 17.0);
      expect(MixPoints.fromJson({'bpm': 120, 'mix_in': 1, 'mix_out': 200, 'end': 210}).introEnd, isNull);
    });

    test('reads server json', () {
      final p = MixPoints.fromJson({'bpm': null, 'mix_in': 1, 'mix_out': 200.5, 'end': 210});
      expect((p.bpm, p.mixIn, p.mixOut, p.end), (null, 1.0, 200.5, 210.0));
    });
  });
}
