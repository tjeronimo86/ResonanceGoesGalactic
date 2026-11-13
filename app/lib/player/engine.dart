import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'equalizer.dart';
import 'mix_fx.dart';
import 'mix_lanes.dart';

typedef SourceFactory = AudioSource Function();

(double, double) fadeVolumes({
  required Duration elapsed,
  required Duration crossfade,
  required double outgoingTarget,
  required double incomingTarget,
}) {
  final t = crossfade == Duration.zero ? 1.0 : (elapsed.inMicroseconds / crossfade.inMicroseconds).clamp(0.0, 1.0);
  return (outgoingTarget * (1 - t), incomingTarget * t);
}

bool shouldStartFade({
  required int crossfadeSeconds,
  required bool playing,
  required bool isBook,
  required LoopMode loopMode,
  required int? index,
  required int length,
  required Duration position,
  required Duration? duration,
}) =>
    crossfadeSeconds > 0 &&
    playing &&
    !isBook &&
    loopMode != LoopMode.one &&
    index != null &&
    length > 0 &&
    (index + 1 < length || loopMode == LoopMode.all) &&
    duration != null &&
    duration > Duration(seconds: 2 * crossfadeSeconds) &&
    position >= duration - Duration(seconds: crossfadeSeconds) &&
    position < duration;

/// AutoMix analysis of a song from the server (seconds).
class MixPoints {
  const MixPoints({
    required this.bpm,
    required this.mixIn,
    required this.mixOut,
    required this.end,
    this.key,
    this.keyConfidence,
    this.vocalsIn,
    this.vocalsOut,
    this.introEnd,
    this.downbeat,
    this.phrases,
    this.energy,
  });
  final double? bpm;
  final double mixIn;

  /// Where the intro ends and the song comes in fully (song time, on a bar); [mixIn] when it starts at full strength.
  final double? introEnd;
  final double mixOut;
  final double end;

  /// Musical key as a Camelot code ("8A" = A minor, "8B" = C major), when the server could tell.
  final String? key;
  final double? keyConfidence;
  final double? vocalsIn;
  final double? vocalsOut;

  /// The first beat 1 (song time); phrases are counted from here. Null from analyses before section detection.
  final double? downbeat;

  /// Section starts on the 8-bar grid (song times); null from analyses before section detection.
  final List<double>? phrases;

  /// 0 (calm) to 1 (peak time).
  final double? energy;

  MixPoints withKey(String key) => MixPoints(
    bpm: bpm,
    mixIn: mixIn,
    mixOut: mixOut,
    end: end,
    key: key,
    keyConfidence: keyConfidence,
    vocalsIn: vocalsIn,
    vocalsOut: vocalsOut,
    introEnd: introEnd,
    downbeat: downbeat,
    phrases: phrases,
    energy: energy,
  );

  /// The key only when the analysis was reasonably sure (a wrong key would cause needless filter-outs).
  String? get reliableKey => (keyConfidence ?? 0) >= 0.1 ? key : null;

  factory MixPoints.fromJson(Map<String, dynamic> j) => MixPoints(
    bpm: (j['bpm'] as num?)?.toDouble(),
    mixIn: (j['mix_in'] as num).toDouble(),
    mixOut: (j['mix_out'] as num).toDouble(),
    end: (j['end'] as num).toDouble(),
    key: j['key'] as String?,
    keyConfidence: (j['key_confidence'] as num?)?.toDouble(),
    vocalsIn: (j['vocals_in'] as num?)?.toDouble(),
    vocalsOut: (j['vocals_out'] as num?)?.toDouble(),
    introEnd: (j['intro_end'] as num?)?.toDouble(),
    downbeat: (j['downbeat'] as num?)?.toDouble(),
    phrases: (j['phrases'] as List?)?.map((v) => (v as num).toDouble()).toList(),
    energy: (j['energy'] as num?)?.toDouble(),
  );
}

/// How an AutoMix transition runs: the next song starts at [incomingStart] when the current one reaches [start],
/// both overlap for [duration], and the next song plays at [speed] meanwhile so the beats line up. Like a DJ, larger
/// tempo differences meet in the middle: the current song drifts to [outgoingSpeed] in the seconds before.
class AutomixPlan {
  const AutomixPlan({
    required this.start,
    required this.incomingStart,
    required this.duration,
    required this.speed,
    required this.bassSwap,
    this.outgoingSpeed = 1,
    this.filterOut = false,
    this.intro = false,
    this.fadeOut = false,
    this.lanes,
    this.bars = 4,
  });
  final Duration start;
  final Duration incomingStart;
  final Duration duration;
  final double speed;
  final double outgoingSpeed;

  /// Song time of the incoming song per song time of the outgoing one while both play.
  double get ratio => speed / outgoingSpeed;

  /// When the bass moves from the outgoing to the incoming song (on a beat near the middle of the overlap).
  final Duration bassSwap;

  /// Songs that do not go together (tempo too far apart or clashing keys) do not blend: the current song is
  /// filtered away from the bass up, with an echo on the beat on the desktop, while the next one comes in quickly.
  final bool filterOut;

  /// The next song starts with its (quieter) intro, which ends at [bassSwap]: it can come in fully while the current
  /// song stays up. Without one both songs cross over around the swap.
  final bool intro;

  /// Saved "fade out" transitions: the current song fades over the whole time, the next one comes in after the swap.
  final bool fadeOut;

  /// A transition made in the editor's lanes (volume, EQ, filter, effect, loop); [bars] long.
  final MixLanes? lanes;
  final int bars;

  bool get beatMatched => speed != 1;

  /// Whether the next song's tempo actually changes (equal tempos are beat-matched without a speed change, which
  /// on Android can click).
  bool get changesTempo => (speed - 1).abs() >= 1e-4;
}

Duration _seconds(double s) => Duration(microseconds: (s * 1e6).round());

/// Tempo differences up to this are matched (time-stretched without changing the pitch); above
/// [automixShareTempoChange] both songs move halfway, so neither changes by more than about 4 % – like a DJ's pitch
/// fader at ±8 %, larger changes are heard as a song running too fast or too slow. Songs further apart filter out.
const automixMaxTempoChange = 0.08;
const automixShareTempoChange = 0.04;

/// The song without the bass loses only its low end (bands up to [automixBassCutoff] Hz drop by
/// [automixBassCutDb]): the kick and bass line swap over, the rest of both songs stays as loud as the volume curve
/// says, so the swap is not heard as one song suddenly getting quieter and the other louder.
const automixBassCutoff = 150.0;
const automixBassCutDb = -15.0;

/// The filter AutoMix keeps in every desktop player while it is on, neutral outside transitions. A transition only
/// changes its values (mpv `af-command`, see [AutomixCut.mpvCommands] and [mpvFxCommands]): a new filter chain
/// would interrupt the sound. It also carries the transition editor's effects.
const automixMpvFilter = mixMpvFilter;

/// Camelot codes that mix well: the same key, a neighbour on the wheel (±1, 12 wraps to 1), or the relative
/// major/minor (same number, other letter).
bool camelotCompatible(String a, String b) {
  final ma = RegExp(r'^(1[0-2]|[1-9])([AB])$').firstMatch(a);
  final mb = RegExp(r'^(1[0-2]|[1-9])([AB])$').firstMatch(b);
  if (ma == null || mb == null) return false;
  final na = int.parse(ma[1]!), nb = int.parse(mb[1]!);
  if (ma[2] != mb[2]) return na == nb;
  final distance = (na - nb).abs() % 12;
  return distance <= 1 || distance == 11;
}

/// [code] (Camelot) moved by [semitones]: a semitone up is seven steps around the wheel.
String shiftCamelot(String code, int semitones) {
  final match = RegExp(r'^(1[0-2]|[1-9])([AB])$').firstMatch(code);
  if (match == null) return code;
  final number = (int.parse(match[1]!) - 1 + 7 * semitones) % 12 + 1;
  return '$number${match[2]}';
}

/// Desktop key shift: the fewest semitones (up to two, up first) that make [incoming] fit [outgoing]; 0 when they
/// already fit, a key is unknown, or no small shift helps.
int keyShiftSemitones(String? outgoing, String? incoming) {
  if (outgoing == null || incoming == null || camelotCompatible(outgoing, incoming)) return 0;
  for (final shift in const [1, -1, 2, -2]) {
    if (camelotCompatible(outgoing, shiftCamelot(incoming, shift))) return shift;
  }
  return 0;
}

/// The filter-out transition (tempos too far apart): about sixteen beats, between 6 and 12 seconds.
Duration _filterOutDuration(double? bpm) =>
    _seconds((bpm != null && bpm > 0 ? 16 * 60 / bpm : 8.0).clamp(6.0, 12.0).toDouble());

/// A blend has two halves, like a DJ's: the next song's intro comes in under the current one for up to
/// [automixMaxLeadBeats] beats, the bass swaps the moment the next song comes in fully, and the current one thins
/// out and is gone after [automixMinTailBeats] to [automixMaxTailBeats] beats. Songs without an intro come in over
/// [automixDefaultLeadBeats] beats from their first beat; with clashing keys both halves last only a bar.
const automixMaxLeadBeats = 16;
const automixDefaultLeadBeats = 8;
const automixPhraseBeats = 16;
const automixMinTailBeats = 4;
const automixMaxTailBeats = 8;
const automixMinSeconds = 6.0;

/// After a beat-matched transition the new song returns to its own tempo within this time.
const automixTempoReturn = Duration(seconds: 8);

/// How far the current song thins out after the swap (desktop): its high-pass rises to about 600 Hz.
const automixTailSweep = 0.75;

/// Tempos within 8 % (also at double or half time) are matched and blended; tempos further apart filter the current
/// song out. The blend starts at the analyzed mix-out point, earlier by whole bars when the outro is shorter than
/// the blend (never in the first half of the song). [minSeconds] (the crossfade setting) asks for up to 30 seconds.
///
/// Vocals (from the server's song analysis or synced lyrics) are handed over: the next song's voice comes in only
/// after the current one has stopped singing, and the bass swaps at that moment.
/// The players' speeds while two songs overlap: the next one's ([speed]) and the current one's, and whether the
/// tempos are too far apart to match (both then stay at 1).
(double speed, double outgoingSpeed, bool mismatch) automixSpeeds(MixPoints outgoing, MixPoints incoming) {
  var tempoMismatch = false;
  var speed = 1.0;
  var outgoingSpeed = 1.0;
  if (outgoing.bpm != null && incoming.bpm != null && outgoing.bpm! > 0 && incoming.bpm! > 0) {
    var ratio = outgoing.bpm! / incoming.bpm!;
    while (ratio > 1.5) {
      ratio /= 2;
    }
    while (ratio < 0.75) {
      ratio *= 2;
    }
    // A ratio of exactly 1 needs no tempo change but still starts on the beat.
    if ((ratio - 1).abs() <= automixMaxTempoChange) speed = ratio == 1 ? 1.0000001 : ratio;
    tempoMismatch = speed == 1;
    // At double or half time the matched tempo can lie on the other side of the next song's own tempo (a 70 BPM
    // song blends as 140 into a 130 BPM one): the current song then stays at its tempo instead of drifting away
    // from the next one, only the next song adapts.
    final away = (ratio - 1) * (outgoing.bpm! / incoming.bpm! - 1) < 0;
    if ((ratio - 1).abs() > automixShareTempoChange && speed != 1 && !away) {
      outgoingSpeed = 1 / math.sqrt(ratio);
      speed = math.sqrt(ratio);
    }
  }
  return (speed, outgoingSpeed, tempoMismatch);
}

AutomixPlan? automixPlan(MixPoints outgoing, MixPoints incoming, {int minSeconds = 0}) {
  final overlap = outgoing.end - outgoing.mixOut;
  if (outgoing.mixOut <= 0 || overlap < 2) return null;
  final (keyOut, keyIn) = (outgoing.reliableKey, incoming.reliableKey);
  final keysClash = keyOut != null && keyIn != null && !camelotCompatible(keyOut, keyIn);
  final (speed, outgoingSpeed, tempoMismatch) = automixSpeeds(outgoing, incoming);
  final bpm = outgoing.bpm != null && outgoing.bpm! > 0 ? outgoing.bpm : null;
  final beat = bpm == null ? null : 60 / bpm;
  final bar = beat == null ? null : 4 * beat;
  double toBars(double seconds) => bar == null ? seconds : (seconds / bar - 1e-4).ceil() * bar;
  if (tempoMismatch) {
    final short = math.min(_filterOutDuration(bpm).inMicroseconds / 1e6, overlap);
    final lead = math.min(overlap, short + 2);
    return AutomixPlan(
      start: _seconds(math.max(outgoing.mixOut, outgoing.end - lead)),
      incomingStart: _seconds(incoming.mixIn),
      duration: _seconds(short),
      speed: speed,
      outgoingSpeed: outgoingSpeed,
      bassSwap: Duration.zero,
      filterOut: true,
    );
  }
  double beats(int count, double seconds) => beat == null ? seconds : count * beat;
  final ratio = speed / outgoingSpeed;
  // The next song's intro (its song time) plays under the current song, ending where the bass swaps.
  final intro = incoming.introEnd == null ? null : incoming.introEnd! - incoming.mixIn;
  final shortest = keysClash ? beats(4, 3) : beats(automixMaxLeadBeats, 10);
  final fromIntro = intro != null && intro / ratio >= beats(4, 2) - 0.05;
  var leadIn = fromIntro ? math.min(intro / ratio, shortest) : math.min(beats(automixDefaultLeadBeats, 5), shortest);
  // Beat-matched, the intro's beats are the current song's beats: whole ones.
  if (beat != null) leadIn = math.max(1, (leadIn / beat).round()) * beat;
  var tail = keysClash
      ? beats(4, 3)
      : leadIn.clamp(beats(automixMinTailBeats, 3), beats(automixMaxTailBeats, 5)).toDouble();
  // The crossfade setting asks for longer transitions: the current song takes longer to go.
  final wanted = math.min(minSeconds, 30).toDouble();
  if (leadIn + tail < wanted) tail = wanted - leadIn;
  var duration = leadIn + tail;
  // The bass swaps after the analyzed mix-out point (a phrase start), earlier by whole bars when the song would end
  // before the blend does, but the blend never starts in the first half of the song. With section starts (newer
  // analyses, mix-out is where the outro begins) it swaps a full phrase later, so the next song's drop lands on the
  // current song's next phrase and the blend never starts before the outro; otherwise half a phrase after.
  final swapAfter = outgoing.phrases != null && beat != null
      ? beats(automixPhraseBeats, 8)
      : beats(automixDefaultLeadBeats, 5);
  var start = outgoing.mixOut + swapAfter - leadIn;
  if (start + duration > outgoing.end) start -= toBars(start + duration - outgoing.end);
  if (start < outgoing.end / 2) {
    start = math.min(outgoing.mixOut, outgoing.end / 2);
    duration = math.min(duration, outgoing.end - start);
    leadIn = math.min(leadIn, duration / 2);
  }
  final incomingStart = fromIntro ? incoming.introEnd! - leadIn * ratio : incoming.mixIn;
  final latest = outgoing.end - math.min(automixMinSeconds, overlap);
  // Seconds into the blend at which the current song stops singing and the next one starts.
  final voiceEnds = outgoing.vocalsOut == null ? null : outgoing.vocalsOut! - start;
  final voiceStarts = incoming.vocalsIn == null ? null : (incoming.vocalsIn! - incomingStart) / ratio;
  // Both voices known: the next voice must not start before the current one ends. Otherwise the unknown side is
  // assumed to be at the swap.
  final ends = voiceEnds ?? (voiceStarts == null ? null : 0.0);
  final starts = voiceStarts ?? (voiceEnds == null ? null : leadIn);
  // Between these, neither song sings: the bass swaps there.
  (double, double)? quiet;
  if (ends != null && starts != null) {
    var later = 0.0;
    if (ends > starts + 0.01) {
      // Start later by whole bars, as far as the end of the song allows; the blend keeps its length while it can.
      final room = math.max(0.0, latest - start);
      later = toBars(ends - starts);
      if (later > room) later = bar == null ? room : (room / bar).floor() * bar;
      start += later;
      duration = math.min(duration, outgoing.end - start);
    }
    if (ends - later <= starts + 0.01) quiet = (math.max(0.0, ends - later), math.min(starts, duration));
  }
  var swap = quiet == null ? leadIn : leadIn.clamp(quiet.$1, math.max(quiet.$1, quiet.$2)).toDouble();
  if (beat != null) {
    swap = ((swap / beat).round() * beat).clamp(beat, math.max(beat, duration - beat)).toDouble();
  }
  return AutomixPlan(
    start: _seconds(start),
    incomingStart: _seconds(incomingStart),
    duration: _seconds(duration),
    speed: speed,
    outgoingSpeed: outgoingSpeed,
    bassSwap: _seconds(swap),
    intro: fromIntro && (swap - leadIn).abs() < 0.05,
  );
}

/// The presets of a saved transition (the transition editor).
enum TransitionStyle {
  crossfade('crossfade'),
  fadeIn('fade_in'),
  fadeOut('fade_out'),
  filter('filter');

  const TransitionStyle(this.json);
  final String json;

  static TransitionStyle? fromJson(Object? value) => values.where((s) => s.json == value).firstOrNull;
}

/// A transition saved for two songs in a playlist: where in the current song it starts, where the next one comes
/// in (song times in seconds), its length in bars and how it sounds.
class CustomTransition {
  const CustomTransition({
    required this.style,
    required this.bars,
    required this.start,
    required this.incomingStart,
    this.lanes,
  });
  final TransitionStyle style;
  final int bars;
  final double start;
  final double incomingStart;

  /// The editor's lanes; transitions saved before them (or by older apps) only have a [style].
  final MixLanes? lanes;

  static const barChoices = [1, 2, 4, 8, 16];

  static CustomTransition? fromJson(Map<String, dynamic> j) {
    final style = TransitionStyle.fromJson(j['style']);
    if (style == null) return null;
    return CustomTransition(
      style: style,
      bars: (j['bars'] as num).toInt(),
      start: (j['start'] as num).toDouble(),
      incomingStart: (j['incoming_start'] as num).toDouble(),
      lanes: MixLanes.fromJson(j['lanes']),
    );
  }

  Map<String, dynamic> toJson() => {
    'style': style.json,
    'bars': bars,
    'start': start,
    'incoming_start': incomingStart,
    if (lanes != null) 'lanes': lanes!.toJson(),
  };

  /// The lanes this transition plays with: its own, or those of its (older) style.
  MixLanes get effectiveLanes => lanes ?? lanesForStyle(style);

  /// The lanes closest to a style (older transitions, and what older apps are told).
  static MixLanes lanesForStyle(TransitionStyle style) => switch (style) {
    TransitionStyle.crossfade => const MixLanes(),
    TransitionStyle.fadeIn => const MixLanes(volume: VolumeLane.fadeInHardOut),
    TransitionStyle.fadeOut => const MixLanes(volume: VolumeLane.fadeInOut, eq: EqLane.bassFadeOut),
    TransitionStyle.filter => const MixLanes(volume: VolumeLane.crossfade, filter: FilterLane.highpassOut),
  };

  /// The style older apps play these lanes as.
  static TransitionStyle styleForLanes(MixLanes lanes) => lanes.filter == FilterLane.highpassOut
      ? TransitionStyle.filter
      : switch (lanes.volume) {
          VolumeLane.fadeInHardOut || VolumeLane.fadeInCutBar || VolumeLane.overlapCutBar => TransitionStyle.fadeIn,
          VolumeLane.fadeInOut || VolumeLane.hardInFadeOut || VolumeLane.fadeInQuickOut => TransitionStyle.fadeOut,
          _ => TransitionStyle.crossfade,
        };

  /// The automatic transition as a starting point for editing.
  static CustomTransition fromPlan(AutomixPlan plan, double? bpm) {
    final bar = 4 * 60 / (bpm != null && bpm > 0 ? bpm : 120);
    final bars = plan.duration.inMicroseconds / 1e6 / bar;
    return CustomTransition(
      style: plan.filterOut
          ? TransitionStyle.filter
          : plan.intro
          ? TransitionStyle.fadeIn
          : plan.fadeOut
          ? TransitionStyle.fadeOut
          : TransitionStyle.crossfade,
      bars: barChoices.reduce((a, b) => (a - bars).abs() <= (b - bars).abs() ? a : b),
      start: plan.start.inMicroseconds / 1e6,
      incomingStart: plan.incomingStart.inMicroseconds / 1e6,
    );
  }

  CustomTransition copyWith({
    TransitionStyle? style,
    int? bars,
    double? start,
    double? incomingStart,
    MixLanes? lanes,
  }) => CustomTransition(
    style: lanes != null ? styleForLanes(lanes) : style ?? this.style,
    bars: bars ?? this.bars,
    start: start ?? this.start,
    incomingStart: incomingStart ?? this.incomingStart,
    lanes: lanes ?? (style != null ? null : this.lanes),
  );

  @override
  bool operator ==(Object other) =>
      other is CustomTransition &&
      other.style == style &&
      other.bars == bars &&
      other.start == start &&
      other.incomingStart == incomingStart &&
      other.lanes == lanes;

  @override
  int get hashCode => Object.hash(style, bars, start, incomingStart, lanes);
}

/// The plan of a saved transition: its own start, entry point, length and sound, beat-matched like AutoMix.
AutomixPlan customAutomixPlan(MixPoints outgoing, MixPoints incoming, CustomTransition transition) {
  final lanes = transition.lanes;
  var (speed, outgoingSpeed, _) = automixSpeeds(outgoing, incoming);
  if (lanes != null && !lanes.beatmatch) (speed, outgoingSpeed) = (1.0, 1.0);
  final beat = outgoing.bpm != null && outgoing.bpm! > 0 ? 60 / outgoing.bpm! : 0.5;
  final start = transition.start.clamp(0.0, math.max(0.0, outgoing.end - 1)).toDouble();
  final duration = math.min(transition.bars * 4 * beat, math.max(1.0, outgoing.end - start));
  if (lanes != null) {
    return AutomixPlan(
      start: _seconds(start),
      incomingStart: _seconds(math.max(0.0, transition.incomingStart)),
      duration: _seconds(duration),
      speed: speed,
      outgoingSpeed: outgoingSpeed,
      bassSwap: _seconds(duration / 2),
      lanes: lanes,
      bars: transition.bars,
    );
  }
  final filter = transition.style == TransitionStyle.filter;
  final swap = filter ? 0.0 : math.max(beat, (duration / 2 / beat).round() * beat).clamp(0.0, duration).toDouble();
  return AutomixPlan(
    start: _seconds(start),
    incomingStart: _seconds(math.max(0.0, transition.incomingStart)),
    duration: _seconds(duration),
    speed: speed,
    outgoingSpeed: outgoingSpeed,
    bassSwap: _seconds(swap),
    filterOut: filter,
    intro: transition.style == TransitionStyle.fadeIn,
    fadeOut: transition.style == TransitionStyle.fadeOut,
  );
}

/// "Fade out" volumes: the current song fades over the whole time, the next one comes in after the swap.
(double, double) fadeOutVolumes({
  required Duration elapsed,
  required Duration duration,
  required Duration swap,
  required double outgoingTarget,
  required double incomingTarget,
}) {
  final total = duration.inMicroseconds / 1e6;
  final t = elapsed.inMicroseconds / 1e6;
  if (total <= 0 || t >= total) return (0, incomingTarget);
  final s = (swap.inMicroseconds / 1e6).clamp(0.0, total);
  final rise = total - s <= 0 ? 1.0 : ((t - s) / (total - s)).clamp(0.0, 1.0);
  return (outgoingTarget * math.cos(t / total * math.pi / 2), incomingTarget * math.sin(rise * math.pi / 2));
}

/// The volumes of [plan] [elapsed] into it.
(double, double) planVolumes(
  AutomixPlan plan, {
  required Duration elapsed,
  required double outgoingTarget,
  required double incomingTarget,
}) => plan.lanes != null
    ? _laneVolumes(plan, elapsed, outgoingTarget, incomingTarget)
    : plan.filterOut
    ? filterOutVolumes(
        elapsed: elapsed,
        duration: plan.duration,
        outgoingTarget: outgoingTarget,
        incomingTarget: incomingTarget,
      )
    : plan.fadeOut
    ? fadeOutVolumes(
        elapsed: elapsed,
        duration: plan.duration,
        swap: plan.bassSwap,
        outgoingTarget: outgoingTarget,
        incomingTarget: incomingTarget,
      )
    : automixVolumes(
        elapsed: elapsed,
        duration: plan.duration,
        swap: plan.bassSwap,
        intro: plan.intro,
        outgoingTarget: outgoingTarget,
        incomingTarget: incomingTarget,
      );

(double, double) _laneVolumes(AutomixPlan plan, Duration elapsed, double outgoingTarget, double incomingTarget) {
  final total = plan.duration.inMicroseconds;
  final u = total <= 0 ? 1.0 : elapsed.inMicroseconds / total;
  final (out, inc) = laneStates(plan.lanes!, u, plan.bars);
  return (outgoingTarget * out.dry, incomingTarget * inc.dry);
}

/// Filter-out volumes: the current song fades over the whole time while its low end is swept away; the next one
/// comes in from a quarter on, once the current beat is thinning out, and is up at three quarters.
(double, double) filterOutVolumes({
  required Duration elapsed,
  required Duration duration,
  required double outgoingTarget,
  required double incomingTarget,
}) {
  final t = duration == Duration.zero ? 1.0 : (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
  return (
    outgoingTarget * math.pow(1 - t, 1.5).toDouble(),
    incomingTarget * math.sin(((t - 0.25) / 0.5).clamp(0.0, 1.0) * math.pi / 2),
  );
}

/// How one player's sound is cut during an AutoMix transition: how far the blend's bass swap has taken its low end
/// away ([bass], 0 to 1), or how far the filter-out has swept it ([sweep], 0 to 1: the low end fades octave by octave
/// from 150 Hz up to 2.4 kHz). Both move smoothly; they are rounded to about a decibel so only audible steps are sent.
class AutomixCut {
  AutomixCut({double bass = 0, double sweep = 0})
    : bass = (bass.clamp(0.0, 1.0) * 15).round() / 15,
      sweep = (sweep.clamp(0.0, 1.0) * 60).round() / 60;

  /// The blend's bass swap at full depth.
  static final bassSwap = AutomixCut(bass: 1);

  final double bass;
  final double sweep;

  bool get neutral => bass == 0 && sweep == 0;

  /// The reduction (dB) of an equalizer band at [frequency] Hz.
  double reductionAt(double frequency) {
    final low = frequency <= automixBassCutoff ? automixBassCutDb * bass : 0.0;
    // Each octave above 150 Hz starts to fade when the sweep reaches it and is gone an octave later.
    final octave = math.log(math.max(frequency, automixBassCutoff) / automixBassCutoff) / math.ln2;
    return math.min(low, automixBassCutDb * (sweep * 4 - octave).clamp(0.0, 1.0));
  }

  /// The same on the desktop: the values of [automixMpvFilter]'s bass shelf and high-pass (10 Hz is neutral).
  List<List<String>> get mpvCommands => [
    ['af-command', 'automix', 'g', (bass == 0 ? 0.0 : automixBassCutDb * bass).toStringAsFixed(1), 'bass@lo'],
    ['af-command', 'automix', 'f', (10 * math.pow(240, sweep)).toStringAsFixed(0), 'highpass@hp'],
  ];

  @override
  bool operator ==(Object other) => other is AutomixCut && other.bass == bass && other.sweep == sweep;

  @override
  int get hashCode => Object.hash(bass, sweep);
}

/// Blend volumes around the bass swap ([swap]).
///
/// With an [intro] (quieter by the analysis' definition) the next song comes in fully until the swap while the
/// current one stays up, easing off a little; afterwards the current one goes, the last 40 % quickly.
///
/// Without one both songs are loud: they cross over between equal power and linear, with the crossing at the swap.
/// Two beat-matched songs partly add up (their kicks fall together), so equal power would swell by up to 3 dB; this
/// curve stays within about 1.5 dB either way.
(double, double) automixVolumes({
  required Duration elapsed,
  required Duration duration,
  required Duration swap,
  bool intro = false,
  required double outgoingTarget,
  required double incomingTarget,
}) {
  final t = elapsed.inMicroseconds / 1e6;
  final total = duration.inMicroseconds / 1e6;
  if (total <= 0 || t >= total) return (0, incomingTarget);
  final s = (swap.inMicroseconds / 1e6).clamp(0.0, total);
  final tail = total - s;
  if (!intro) {
    // 0 to 0.5 until the swap, 0.5 to 1 after it.
    final u = t < s ? 0.5 * t / s : 0.5 + 0.5 * (t - s) / tail;
    return (
      outgoingTarget * math.pow(math.cos(u * math.pi / 2), 1.5).toDouble(),
      incomingTarget * math.pow(math.sin(u * math.pi / 2), 1.5).toDouble(),
    );
  }
  final rise = s <= 0 ? 1.0 : (t / s).clamp(0.0, 1.0);
  // -1.5 dB at the swap, -5 dB when the last 40 % start, then gone.
  final p = tail <= 0 ? 1.0 : ((t - s) / tail).clamp(0.0, 1.0);
  final outgoing = (1 - 0.16 * rise * rise) * (p < 0.6 ? 1 - 0.55 * p : 0.67 * math.cos((p - 0.6) / 0.4 * math.pi / 2));
  return (outgoingTarget * outgoing, incomingTarget * math.sin(rise * math.pi / 2));
}

List<T> shuffleQueue<T>(List<T> queue, int currentIndex, {math.Random? random}) {
  final rest = [...queue]..removeAt(currentIndex);
  rest.shuffle(random);
  return [queue[currentIndex], ...rest];
}

/// The user's queued block (from, count) after playback moved to [index]: songs it reached are played.
(int, int) queuedAfterIndex(int from, int count, int? index) {
  if (count <= 0) return (0, 0);
  if (index == null || index < from) return (from, count);
  final played = math.min(count, index - from + 1);
  return count == played ? (0, 0) : (from + played, count - played);
}

List<T> interleaveEvery<T>(List<T> upcoming, List<T> extra, int every) {
  if (every < 1) throw ArgumentError.value(every, 'every');
  final result = <T>[];
  var next = 0;
  for (var i = 0; i < upcoming.length; i++) {
    result.add(upcoming[i]);
    if ((i + 1) % every == 0 && next < extra.length) result.add(extra[next++]);
  }
  return result;
}

(bool, bool) nextShuffleMode({required bool shuffle, required bool smartShuffle, required bool allowSmart}) => !shuffle
    ? (true, false)
    : !smartShuffle && allowSmart
    ? (true, true)
    : (false, false);

bool supportsSmartShuffle(String? context, {bool isRadio = false}) =>
    !isRadio &&
    (context == 'liked' ||
        (context?.startsWith('playlist:') ?? false) ||
        (context?.startsWith('album:') ?? false) ||
        (context?.startsWith('mix:') ?? false));

bool shouldAutoplay({
  required bool enabled,
  required int length,
  required int? index,
  required LoopMode loopMode,
  required bool playing,
  required bool isBook,
  required bool isStation,
  required bool inJam,
}) =>
    enabled &&
    playing &&
    length > 0 &&
    index == length - 1 &&
    loopMode == LoopMode.off &&
    !isBook &&
    !isStation &&
    !inJam;

(List<T>, int) unshuffleQueue<T>(List<T> original, T current) => ([...original], original.indexOf(current));

(List<T>, List<T>) replaceUpcomingQueue<T>(
  T current,
  List<T> tracks, {
  required String Function(T) id,
  required bool shuffle,
  math.Random? random,
}) {
  final original = [current, ...tracks.where((track) => id(track) != id(current))];
  return (shuffle ? shuffleQueue(original, 0, random: random) : [...original], original);
}

class _Fade {
  _Fade(this.outgoing, this.incoming, this.index, this.duration, {this.plan})
    : outgoingIndex = outgoing.currentIndex,
      outgoingPosition = outgoing.position;
  final AudioPlayer outgoing;
  final AudioPlayer incoming;
  final int index;
  final Duration duration;
  final int? outgoingIndex;
  final Duration outgoingPosition;
  final clock = Stopwatch();
  late final Future<void> ready;
  Timer? timer;

  /// AutoMix: the next song is loaded ahead and only starts at the plan's mix point.
  final AutomixPlan? plan;
  bool prepared = false;
  Timer? startTimer;
  bool get started => clock.isRunning || clock.elapsed > Duration.zero;
  final corrected = <int>{};

  /// The editor's lanes play through the players' mix effects (otherwise only their volumes are followed).
  bool laneFx = false;
  FxState? lastOut;
  FxState? lastIn;
  double? lastRoll;

  /// Semitones the next song is pitched by to fit the current one's key (desktop and Android).
  int keyShift = 0;
}

/// Two independent playlists built from factories; only the active player drives the UI.
class PlaybackEngine {
  PlaybackEngine() {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    _equalizers = android ? [AndroidEqualizer(), AndroidEqualizer()] : [];
    _players = [
      for (var i = 0; i < 2; i++)
        AudioPlayer(audioPipeline: android ? AudioPipeline(androidAudioEffects: [_equalizers[i]]) : null),
    ];
    // Desktop: a libmpv without the filters (it refused the chain and played nothing) — the plugin has switched the
    // filters off; load the song again where it was so it plays without them.
    if (_desktop) {
      _subs.add(
        JustAudioMediaKit.filterFailures.listen((_) async {
          filtersUnavailable.value = true;
          final index = currentIndex;
          if (_sources.isEmpty || index == null) return;
          final wasPlaying = playing;
          await setSources([..._sources], initialIndex: index, initialPosition: position);
          if (wasPlaying) await _active.play();
        }),
      );
    }
    for (final player in _players) {
      _forward(player, player.playerStateStream, _states);
      _subs.add(
        player.errorStream.listen((error) {
          if (player == _active && !_editing) _errors.add(error);
        }),
      );
      _subs.add(
        player.currentIndexStream.listen((index) {
          if (player != _active || _editing) return;
          final fade = _fade;
          if (fade != null && index != fade.outgoingIndex) {
            finishFade().ignore();
          } else {
            _indices.add(index);
          }
        }),
      );
      _forward(player, player.durationStream, _durations);
      _forward(player, player.loopModeStream, _loops);
      _forward(player, player.playbackEventStream, _events);
      _subs.add(
        player.positionStream.listen((position) {
          if (player != _active || _editing) return;
          final fade = _fade;
          if (fade != null && (player.currentIndex != fade.outgoingIndex || position < fade.outgoingPosition)) {
            finishFade().ignore();
            return;
          }
          // Position updates come every ~200 ms; a timer hits the mix point more precisely.
          if (fade != null && fade.plan != null && fade.prepared && !fade.started && fade.startTimer == null) {
            // Song time to real time at the current (possibly ramped) speed.
            final wait = (fade.plan!.start - position) * (1 / player.speed);
            if (wait <= const Duration(milliseconds: 400)) {
              fade.startTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
                if (_fade == fade && !fade.started && !_disposed) _startAutomix(fade);
              });
            }
          }
          // media_kit reports ~20×/s; the UI, Discord and play counting need ~5×/s. Seeks pass right away.
          final last = _lastPosition;
          if (last == null ||
              _positionClock.elapsedMilliseconds >= 200 ||
              position < last ||
              position - last > const Duration(seconds: 1)) {
            _lastPosition = position;
            _positionClock.reset();
            _positions.add(position);
          }
          _checkFade();
        }),
      );
    }
  }

  late final List<AudioPlayer> _players;

  /// Native ids of both players (Galactic view: measures the one that is heard).
  List<String> get playerIds => [for (final p in _players) ?p.playerId];

  static final _android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether the Android players have the mix processor (unknown until the first lanes transition).
  bool? _androidFx;

  /// AutoMix cuts per player and (desktop) the source key each was sent to.
  final _bassCut = <AutomixCut?>[null, null];
  final _cutKeys = <String?>[null, null];
  // The source each player pitched for a key shift (see [_setKeyShift]).
  final _keyShifted = <String?>[null, null];

  /// Desktop: the player's libmpv cannot run the audio filters (AutoMix's sound effects, the equalizer); playback
  /// goes on without them.
  final filtersUnavailable = ValueNotifier(false);

  /// A next song in a clashing key is pitched by up to two semitones to fit (AutoMix; desktop and Android). Off by
  /// default: the pitch stays for the whole song, which then sounds higher or lower than the original.
  bool keyShift = false;

  /// Desktop vocal swap: the next song comes in without its voice (its instrumental start, separated by the server)
  /// until the bass swaps, so its beat runs under the current song's singing.
  bool vocalSwap = true;

  /// The instrumental start of the song at an index, when the server has it (URL and its length in seconds).
  ({String url, double seconds})? Function(int index)? stemForIndex;

  /// Asks the server to separate the song at an index (early, so it is ready when the transition comes).
  void Function(int index)? requestStemForIndex;
  // The source each player plays with its instrumental start mixed in (mpv lavfi-complex).
  final _stemmed = <String?>[null, null];
  String? _stemRequested;
  static final _desktop =
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows);
  late final List<AndroidEqualizer> _equalizers;
  EqualizerSettings _equalizer = EqualizerSettings();
  Future<void> _equalizerUpdate = Future.value();
  bool _equalizerQueued = false;
  bool _equalizerFull = false;

  /// The band levels (millibel) last set on each Android equalizer, so a transition only touches bands that change.
  final _equalizerLevels = <List<int>?>[null, null];
  int _activeIndex = 0;
  AudioPlayer get _active => _players[_activeIndex];
  AudioPlayer get _inactive => _players[1 - _activeIndex];
  final List<StreamSubscription> _subs = [];
  final _states = StreamController<PlayerState>.broadcast(sync: true);
  final _indices = StreamController<int?>.broadcast(sync: true);
  final _positions = StreamController<Duration>.broadcast(sync: true);
  final _positionClock = Stopwatch()..start();
  Duration? _lastPosition;
  final _durations = StreamController<Duration?>.broadcast(sync: true);
  final _loops = StreamController<LoopMode>.broadcast(sync: true);
  final _events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final _errors = StreamController<Object>.broadcast();
  Stream<Object> get errorStream => _errors.stream;
  List<SourceFactory> _sources = [];
  bool _editing = false;
  bool _disposed = false;
  double _targetVolume = 1;
  _Fade? _fade;
  Future<void>? _finishingFade;
  int? _failedFadeIndex;

  int crossfadeSeconds = 0;
  bool isBook = false;
  double Function(int index)? targetVolumeForIndex;

  /// AutoMix: beat-matched transitions at analyzed mix points; songs without analysis get a plain crossfade.
  bool get automix => _automix;
  set automix(bool value) {
    if (_automix == value) return;
    _automix = value;
    _applyDesktopFilter();
  }

  bool _automix = false;
  MixPoints? Function(int index)? mixPointsForIndex;

  /// A transition saved for the songs at these two queue indices (playlists), used instead of AutoMix's own.
  AutomixPlan? Function(int index, int next)? customPlanForIndex;

  /// Identifies a queue item's media (a part of its URI, e.g. the song id) for per-song desktop filters.
  String? Function(int index)? sourceKeyForIndex;

  /// True while an AutoMix transition plays, for the "AutoMix" badge in the player.
  final automixing = ValueNotifier<bool>(false);
  double _speed = 1;
  Timer? _speedRamp;

  int get _crossfade => crossfadeSeconds > 0 ? crossfadeSeconds : (automix ? 6 : 0);

  void _forward<T>(AudioPlayer player, Stream<T> stream, StreamController<T> controller) {
    _subs.add(
      stream.listen(
        (value) {
          if (player == _active && !_editing && (_fade == null || player.currentIndex == _fade!.outgoingIndex)) {
            controller.add(value);
          }
        },
        onError: (Object error) {
          if (player == _active && !_editing && controller == _events) _errors.add(error);
        },
      ),
    );
  }

  Stream<T> _values<T>(StreamController<T> controller, T Function() current) => Stream<T>.multi((sink) {
    sink.add(current());
    final sub = controller.stream.listen(sink.add, onError: sink.addError, onDone: sink.close);
    sink.onCancel = sub.cancel;
  }, isBroadcast: true);

  late final playerStateStream = _values(_states, () => _active.playerState);
  late final currentIndexStream = _values(_indices, () => currentIndex);
  late final positionStream = _values(_positions, () => position);
  late final durationStream = _values(_durations, () => duration);
  late final loopModeStream = _values(_loops, () => loopMode);
  late final playbackEventStream = _values(_events, () => _active.playbackEvent);

  bool get playing => _active.playing;
  ProcessingState get processingState => _active.processingState;
  Duration get position => _active.position;
  Duration get bufferedPosition => _active.bufferedPosition;
  Duration? get duration => _active.duration;
  int? get currentIndex => _active.currentIndex;
  LoopMode get loopMode => _active.loopMode;
  double get speed => _active.speed;
  bool get hasPrevious => _active.hasPrevious;
  List<SourceFactory> get audioSources => List.unmodifiable(_sources);

  Future<void> setEqualizer(EqualizerSettings settings) {
    _equalizer = settings;
    _applyDesktopFilter();
    return _applyEqualizer();
  }

  /// Desktop: the equalizer and, while AutoMix is on, its (neutral) transition filter.
  void _applyDesktopFilter() {
    if (!_desktop) return;
    final filters = [?mpvEqualizerFilter(_equalizer), if (_automix) automixMpvFilter];
    JustAudioMediaKit.setAudioFilter(filters.isEmpty ? null : filters.join(','));
  }

  /// Writes the equalizer settings and AutoMix cuts to the Android equalizers. [onlyChanges] (AutoMix steps) only
  /// sets the bands whose level changed: each write takes effect at once and can click.
  Future<void> _applyEqualizer({bool onlyChanges = false}) {
    // Serialize writes so a slower parameter lookup cannot overwrite a newer slider change; a transition's steps
    // collapse into the next pending write, which reads the latest values.
    _equalizerFull |= !onlyChanges;
    if (_equalizerQueued) return _equalizerUpdate;
    _equalizerQueued = true;
    _equalizerUpdate = _equalizerUpdate.then((_) async {
      _equalizerQueued = false;
      final full = _equalizerFull;
      _equalizerFull = false;
      if (_disposed) return;
      await Future.wait(
        _equalizers.indexed.map((entry) async {
          final (slot, eq) = entry;
          try {
            final cut = _bassCut[slot];
            // With AutoMix the effect stays on (flat when unused): switching it on and off mid-song stutters.
            final enabled = _equalizer.enabled || cut != null || _automix;
            final previous = full ? null : _equalizerLevels[slot];
            if (previous == null) await eq.setEnabled(enabled);
            // Before the first source, just_audio's parameter future has not completed yet.
            final parameters = await eq.parameters.timeout(const Duration(milliseconds: 100));
            if (_disposed) return;
            final settings = _equalizer;
            final minMb = (parameters.minDecibels * 100).round();
            final maxMb = (parameters.maxDecibels * 100).round();
            final levels = androidBandLevels(
              settings.enabled ? settings.gains : List.filled(equalizerFrequencies.length, 0),
              [for (final band in parameters.bands) (band.centerFrequency * 1000).round()],
              minMb,
              maxMb,
            );
            final applied = <int>[];
            for (var i = 0; i < parameters.bands.length; i++) {
              final reduction = cut?.reductionAt(parameters.bands[i].centerFrequency) ?? 0.0;
              final level = (levels[i] + reduction * 100).round().clamp(minMb, maxMb);
              applied.add(level);
              if (previous == null || previous.length <= i || previous[i] != level) {
                await parameters.bands[i].setGain(level / 100);
              }
            }
            _equalizerLevels[slot] = applied;
            if (previous == null) await eq.setEnabled(enabled);
          } catch (_) {
            // Audio sessions can be absent or replaced; retry the remembered settings after loading.
            _equalizerLevels[slot] = null;
          }
        }),
      );
    });
    return _equalizerUpdate;
  }

  void _emitCurrent() {
    _dropStaleKeyShifts();
    _indices.add(currentIndex);
    _states.add(_active.playerState);
    _positions.add(position);
    _durations.add(duration);
    _loops.add(loopMode);
    _events.add(_active.playbackEvent);
  }

  void _checkFade() {
    if (_disposed || _editing || _fade != null || _finishingFade != null) return;
    // Outside a transition (and its tempo return) every song plays at the chosen speed: a matched tempo left over
    // from AutoMix (a ramp cut short) would make the whole song sound too fast or too slow.
    if (_speedRamp?.isActive != true && (_active.speed - _speed).abs() > 1e-4) _active.setSpeed(_speed).ignore();
    // A song with its instrumental start mixed in that ends without a transition: back to the plain song before
    // the player moves on (the next song has no extra track).
    final length = duration;
    if (_stemmed[_activeIndex] != null && length != null && length - position < const Duration(seconds: 2)) {
      _clearStem(_active);
    }
    if (_failedFadeIndex != null && _failedFadeIndex != currentIndex) _failedFadeIndex = null;
    if (_failedFadeIndex == currentIndex) return;
    if (_checkAutomix()) return;
    if (!shouldStartFade(
      crossfadeSeconds: _crossfade,
      playing: playing,
      isBook: isBook,
      loopMode: loopMode,
      index: currentIndex,
      length: _sources.length,
      position: position,
      duration: duration,
    )) {
      return;
    }
    final next = (currentIndex! + 1) % _sources.length;
    final fade = _Fade(_active, _inactive, next, Duration(seconds: _crossfade));
    _fade = fade;
    fade.ready = _prepareFade(fade);
  }

  /// Load the next song a few seconds before the mix point; true while AutoMix handles this transition.
  bool _checkAutomix() {
    final index = currentIndex;
    final points = mixPointsForIndex;
    if (!automix || points == null || isBook || index == null || _sources.isEmpty) return false;
    if (loopMode == LoopMode.one || (index + 1 >= _sources.length && loopMode != LoopMode.all)) return false;
    final next = (index + 1) % _sources.length;
    // Looked up early in the song so the analysis can arrive in time.
    final outgoing = points(index);
    var incoming = points(next);
    if (outgoing == null || incoming == null || !playing) return false;
    // A next song in a clashing key is pitched to fit, so it can blend as long as a fitting one.
    final shift = (_desktop || _android) && keyShift
        ? keyShiftSemitones(outgoing.reliableKey, incoming.reliableKey)
        : 0;
    if (shift != 0) incoming = incoming.withKey(shiftCamelot(incoming.key!, shift));
    final plan = customPlanForIndex?.call(index, next) ?? automixPlan(outgoing, incoming, minSeconds: crossfadeSeconds);
    if (plan == null) return false;
    final ahead = plan.start - const Duration(seconds: 8);
    if (position < ahead) {
      final nextKey = sourceKeyForIndex?.call(next);
      if (_desktop && vocalSwap && nextKey != null && _stemRequested != nextKey) {
        _stemRequested = nextKey;
        requestStemForIndex?.call(next);
      }
      return true;
    }
    if (position >= plan.start + const Duration(seconds: 1)) return false;
    final fade = _Fade(_active, _inactive, next, plan.duration, plan: plan)..keyShift = shift;
    _fade = fade;
    fade.ready = _prepareAutomix(fade);
    return true;
  }

  Future<void> _prepareAutomix(_Fade fade) async {
    final index = currentIndex;
    try {
      _speedRamp?.cancel();
      await fade.incoming.setVolume(0);
      _clearStem(fade.incoming);
      await fade.incoming.load();
      await _applyEqualizer();
      await fade.incoming.seek(fade.plan!.incomingStart, index: fade.index);
      if (fade.plan!.changesTempo) await fade.incoming.setSpeed(_speed * fade.plan!.speed);
      _setKeyShift(fade.incoming, fade.index, fade.keyShift);
      _setStem(fade);
      // The next song comes in without its bass; the bass swaps over halfway (see [_startAutomix]).
      if (fade.plan!.lanes != null) {
        await _prepareLanes(fade);
      } else if (!fade.plan!.filterOut) {
        await _setCut(fade.incoming, fade.index, AutomixCut.bassSwap, force: true);
      }
      if (_disposed || currentIndex != index || _fade != fade) {
        if (_fade == fade) _fade = null;
        return;
      }
      fade.prepared = true;
      // The current song drifts toward the shared tempo until the mix point.
      final outgoingSpeed = fade.plan!.outgoingSpeed;
      if (outgoingSpeed != 1) {
        final left = fade.plan!.start - fade.outgoing.position;
        _rampSpeed(fade.outgoing, _speed, _speed * outgoingSpeed, left * 0.8);
      }
    } catch (_) {
      _failedFadeIndex = index;
      if (_fade == fade) _fade = null;
    }
  }

  void _startAutomix(_Fade fade) {
    final plan = fade.plan!;
    // Android lanes: the processors follow the volume curves; the players stay at their volumes.
    if (fade.laneFx && !_desktop) fade.incoming.setVolume(_incomingTarget(fade)).ignore();
    fade.incoming.play().ignore();
    fade.clock.start();
    automixing.value = true;
    final outgoingIndex = fade.outgoingIndex;
    final bpm = outgoingIndex == null ? null : mixPointsForIndex?.call(outgoingIndex)?.bpm;
    final beat = bpm != null && bpm > 0 ? 60 / bpm : 0.5;
    var tick = 0;
    fade.timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final elapsed = fade.clock.elapsed;
      if (elapsed >= fade.duration) {
        finishFade().ignore();
        return;
      }
      // Desktop filters can start over when a song's audio starts; the values are sent again now and then.
      final resend = tick++ % 5 == 0;
      final seconds = elapsed.inMicroseconds / 1e6;
      if (plan.lanes != null) {
        _tickLanes(fade, resend: resend);
      } else if (plan.filterOut) {
        // The low end is swept away over the first 80 %.
        final sweep = seconds / (fade.duration.inMicroseconds / 1e6 * 0.8);
        _setCut(fade.outgoing, fade.outgoingIndex, AutomixCut(sweep: sweep), force: resend).ignore();
      } else {
        // The bass swaps over one beat around the swap point; on the desktop the current song then also thins out
        // from the bass up (Android's equalizer would click at every step, so it only swaps the bass there).
        final swapAt = plan.bassSwap.inMicroseconds / 1e6;
        final swap = (seconds - swapAt) / beat + 0.5;
        final tail = fade.duration.inMicroseconds / 1e6 - swapAt;
        final thin = _desktop && tail > 0 ? ((seconds - swapAt) / tail).clamp(0.0, 1.0) * automixTailSweep : 0.0;
        _setCut(
          fade.outgoing,
          fade.outgoingIndex,
          AutomixCut(bass: swap, sweep: thin),
          force: resend,
        ).ignore();
        _setCut(fade.incoming, fade.index, AutomixCut(bass: 1 - swap), force: resend).ignore();
      }
      if (!fade.laneFx || _desktop) _applyAutomixVolumes(fade).ignore();
      // Starting playback takes a moment; while the next song is still quiet, line its beats up once (a later
      // seek would be audible as a hiccup).
      if (!plan.beatMatched) return;
      if (fade.clock.elapsedMilliseconds >= 300 && fade.corrected.add(300)) {
        final expected = plan.incomingStart + (fade.outgoing.position - plan.start) * plan.ratio;
        final error = fade.incoming.position - expected;
        if (error.abs() > const Duration(milliseconds: 30) && error.abs() < const Duration(seconds: 2)) {
          fade.incoming.seek(expected + const Duration(milliseconds: 10)).ignore();
        }
      }
    });
  }

  Future<void> _applyAutomixVolumes(_Fade fade) async {
    final plan = fade.plan!;
    if (fade.laneFx && plan.lanes != null) {
      if (!_desktop) {
        await Future.wait([fade.outgoing.setVolume(_targetVolume), fade.incoming.setVolume(_incomingTarget(fade))]);
        return;
      }
      // Desktop: the players' volumes follow the volume curve, the chain adds the effects' gate.
      final total = plan.duration.inMicroseconds;
      final u = total <= 0 ? 1.0 : fade.clock.elapsed.inMicroseconds / total;
      final (out, inc) = laneStates(plan.lanes!, u, plan.bars);
      await Future.wait([
        fade.outgoing.setVolume(_targetVolume * out.level),
        fade.incoming.setVolume(_incomingTarget(fade) * inc.level),
      ]);
      return;
    }
    final (outgoing, incoming) = planVolumes(
      fade.plan!,
      elapsed: fade.clock.elapsed,
      outgoingTarget: _targetVolume,
      incomingTarget: _incomingTarget(fade),
    );
    await Future.wait([fade.outgoing.setVolume(outgoing), fade.incoming.setVolume(incoming)]);
  }

  /// After a beat-matched transition the new song drifts back to its own tempo.
  /// Moves [player] from [from] to [to] over [duration]. On Android in steps of about 1 %: each speed change makes
  /// its audio output start over, which can click, so a small difference takes few steps (a 3 % one three). mpv
  /// changes speed seamlessly, so the desktop glides (ten small changes a second, eased at both ends); steps of 1 %
  /// there were heard as the song speeding up and slowing down.
  void _rampSpeed(AudioPlayer player, double from, double to, Duration duration) {
    _speedRamp?.cancel();
    final steps = _desktop
        ? math.max(1, duration.inMilliseconds ~/ 100)
        : ((to - from).abs() / 0.01).ceil().clamp(1, 8);
    final interval = duration ~/ steps;
    const minInterval = Duration(seconds: 1);
    var step = 0;
    _speedRamp = Timer.periodic(!_desktop && interval < minInterval ? minInterval : interval, (timer) {
      step++;
      final done = step >= steps || _disposed;
      final t = step / steps;
      final eased = _desktop ? t * t * (3 - 2 * t) : t;
      player.setSpeed(done ? to : from + (to - from) * eased).ignore();
      if (done) timer.cancel();
    });
  }

  Future<void> _prepareFade(_Fade fade) async {
    final index = currentIndex;
    try {
      await fade.incoming.setVolume(0);
      // Loading an idle playlist resets its initial index, so seek after loading.
      await fade.incoming.load();
      await _applyEqualizer();
      await fade.incoming.seek(Duration.zero, index: fade.index);
      // A slow load may have outlived the outgoing item.
      if (_disposed || currentIndex != index) {
        if (_fade == fade) _fade = null;
        if (!_disposed) _emitCurrent();
        return;
      }
      fade.incoming.play().ignore();
      fade.clock.start();
      fade.timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (fade.clock.elapsed >= fade.duration) {
          finishFade().ignore();
        } else {
          _applyFadeVolumes(fade).ignore();
        }
      });
    } catch (_) {
      await fade.incoming.pause();
      _failedFadeIndex = index;
      if (_fade == fade) _fade = null;
    }
  }

  /// Apply or remove ([cut] null) an AutoMix cut on the song at [index] playing on [player]; unchanged cuts are
  /// only sent again with [force].
  Future<void> _setCut(AudioPlayer player, int? index, AutomixCut? cut, {bool force = false}) async {
    final slot = _players.indexOf(player);
    // Android's equalizer clicks on every change: the bass swaps in one step there and the sweep moves in 3 dB steps
    // (the desktop filters change smoothly). Resending only helps the desktop filters, which can start over.
    if (!_desktop && cut != null) {
      cut = AutomixCut(bass: cut.bass.roundToDouble(), sweep: (cut.sweep * 20).round() / 20);
    }
    if (cut != null && cut.neutral) cut = null;
    if (_bassCut[slot] == cut && !(force && _desktop)) return;
    _bassCut[slot] = cut;
    if (_desktop) {
      final key = index == null ? null : sourceKeyForIndex?.call(index);
      if (key == null) return;
      _cutKeys[slot] = key;
      for (final command in (cut ?? AutomixCut()).mpvCommands) {
        JustAudioMediaKit.sourceCommand(key, command);
      }
    } else if (_equalizers.isNotEmpty) {
      await _applyEqualizer(onlyChanges: true);
    }
  }

  Future<void> _clearBassCuts() async {
    for (final (slot, key) in _cutKeys.indexed) {
      if (key == null) continue;
      for (final command in AutomixCut().mpvCommands) {
        JustAudioMediaKit.sourceCommand(key, command);
      }
      _cutKeys[slot] = null;
    }
    if (_bassCut.any((cut) => cut != null)) {
      _bassCut.fillRange(0, 2, null);
      if (_equalizers.isNotEmpty) await _applyEqualizer(onlyChanges: true);
    }
  }

  double _incomingTarget(_Fade fade) => targetVolumeForIndex?.call(fade.index) ?? _targetVolume;

  Future<void> _applyFadeVolumes(_Fade fade) async {
    final (outgoing, incoming) = fadeVolumes(
      elapsed: fade.clock.elapsed,
      crossfade: fade.duration,
      outgoingTarget: _targetVolume,
      incomingTarget: _incomingTarget(fade),
    );
    await Future.wait([fade.outgoing.setVolume(outgoing), fade.incoming.setVolume(incoming)]);
  }

  /// Settle the incoming track before applying an explicit user action. A transition cut short fades the current
  /// song out within a moment instead of breaking off; with [silence] (pause) the next song too.
  Future<void> finishFade() => _settleFade();

  Future<void> _settleFade({bool silence = false}) {
    if (_finishingFade != null) return _finishingFade!;
    final fade = _fade;
    if (fade == null) return Future.value();
    final result = _finishFade(fade, silence: silence);
    _finishingFade = result;
    return result.whenComplete(() => _finishingFade = null);
  }

  Future<void> _finishFade(_Fade fade, {bool silence = false}) async {
    await fade.ready;
    if (_fade != fade || _disposed) return;
    fade.timer?.cancel();
    fade.startTimer?.cancel();
    if (fade.started && fade.clock.elapsed < fade.duration) {
      await _rampVolumes(fade, silence ? 0 : _incomingTarget(fade));
      if (_fade != fade || _disposed) return;
    }
    if (!fade.started) {
      // A user action (or the song ending early) came before the mix point: drop the preloaded next song.
      _fade = null;
      _emitCurrent();
      await fade.incoming.pause();
      await fade.incoming.setSpeed(_speed);
      // The current song may have started drifting toward the next one's tempo.
      _speedRamp?.cancel();
      await fade.outgoing.setSpeed(_speed);
      await _clearBassCuts();
      await _clearLanes(fade);
      return;
    }
    _editing = true;
    try {
      await fade.outgoing.pause();
      await fade.outgoing.setVolume(0);
      _targetVolume = _incomingTarget(fade);
      if (!silence) await fade.incoming.setVolume(_targetVolume);
      _activeIndex = 1 - _activeIndex;
      _fade = null;
      if (fade.plan?.changesTempo ?? false) {
        _rampSpeed(fade.incoming, _speed * fade.plan!.speed, _speed, automixTempoReturn);
      }
    } finally {
      _editing = false;
      automixing.value = false;
      _emitCurrent();
    }
    // Release the old playlist's decoder; its factories remain ready for the next fade.
    await fade.outgoing.stop();
    await fade.outgoing.setSpeed(_speed);
    await _clearBassCuts();
    await _clearLanes(fade);
  }

  /// Sends the lanes' effects to both players ahead of a transition: Android gets the whole automation now (keyed
  /// by song time), the desktop chains their starting values (and the outgoing song its loop).
  Future<void> _prepareLanes(_Fade fade) async {
    final plan = fade.plan!;
    final lanes = plan.lanes!;
    if (!lanes.usesEffects && lanes.eq == EqLane.none) {
      // Volumes alone need no effects.
      fade.laneFx = false;
      return;
    }
    final outgoingIndex = fade.outgoingIndex;
    final bpm = outgoingIndex == null ? null : mixPointsForIndex?.call(outgoingIndex)?.bpm;
    final beat = bpm != null && bpm > 0 ? 60 / bpm : 0.5;
    final duration = plan.duration.inMicroseconds / 1e6;
    final outRate = _speed * plan.outgoingSpeed;
    final inRate = _speed * plan.speed;
    final (out0, in0) = laneStates(lanes, 0, plan.bars);
    if (_desktop) {
      final outKey = outgoingIndex == null ? null : sourceKeyForIndex?.call(outgoingIndex);
      final inKey = sourceKeyForIndex?.call(fade.index);
      if (outKey == null || inKey == null) return;
      fade.laneFx = true;
      _cutKeys[_players.indexOf(fade.outgoing)] = outKey;
      _cutKeys[_players.indexOf(fade.incoming)] = inKey;
      for (final command in [
        ...mpvFxCommands(out0, null, echoFeedback: lanes.effect.echoFeedback),
        if (lanes.effect.echo) ...mpvEchoDelayCommands(lanes.effect.echoBeats * beat / outRate),
      ]) {
        JustAudioMediaKit.sourceCommand(outKey, command);
      }
      for (final command in mpvFxCommands(in0, null)) {
        JustAudioMediaKit.sourceCommand(inKey, command);
      }
      fade.lastOut = out0;
      fade.lastIn = in0;
      // The loop: mpv jumps back by its length whenever it reaches the middle.
      final loop = fittingLoopBeats(lanes, plan.bars);
      if (loop > 0) {
        final middle = plan.start.inMicroseconds / 1e6 + duration / 2 * outRate;
        JustAudioMediaKit.sourceCommand(outKey, ['set', 'ab-loop-a', (middle - loop * beat).toStringAsFixed(3)]);
        JustAudioMediaKit.sourceCommand(outKey, ['set', 'ab-loop-b', middle.toStringAsFixed(3)]);
      }
      return;
    }
    if (!_android || _androidFx == false) return;
    MixAutomation automation(bool outgoing) => buildAutomation(
      lanes: lanes,
      bars: plan.bars,
      outgoing: outgoing,
      duration: duration,
      songStart: (outgoing ? plan.start : plan.incomingStart).inMicroseconds / 1e6,
      rate: outgoing ? outRate : inRate,
      beat: beat,
    );
    final outAutomation = automation(true), inAutomation = automation(false);
    final sent = await Future.wait([
      AndroidMixFx.set(fade.outgoing, outAutomation.shifted(await _positionCorrection(fade.outgoing))),
      AndroidMixFx.set(fade.incoming, inAutomation),
    ]);
    _androidFx = sent.every((ok) => ok);
    fade.laneFx = _androidFx!;
    if (!fade.laneFx) await Future.wait([AndroidMixFx.clear(fade.outgoing), AndroidMixFx.clear(fade.incoming)]);
  }

  /// Song time the processor of [player] is ahead of what is heard should be a fraction of a second; a mapping gone
  /// wrong (far off) is corrected by assuming a quarter second.
  Future<int> _positionCorrection(AudioPlayer player) async {
    final processed = await AndroidMixFx.position(player);
    if (processed == null) return 0;
    final ahead = processed - player.position;
    if (ahead > const Duration(milliseconds: -500) && ahead < const Duration(seconds: 3)) return 0;
    return (ahead - const Duration(milliseconds: 250)).inMicroseconds;
  }

  /// Desktop: moves both chains along the lanes (the Android processors follow their automation by themselves).
  void _tickLanes(_Fade fade, {bool resend = false}) {
    if (!fade.laneFx || !_desktop) return;
    final plan = fade.plan!;
    final total = plan.duration.inMicroseconds;
    final u = total <= 0 ? 1.0 : fade.clock.elapsed.inMicroseconds / total;
    final (out, inc) = laneStates(plan.lanes!, u, plan.bars);
    final outKey = fade.outgoingIndex == null ? null : sourceKeyForIndex?.call(fade.outgoingIndex!);
    final inKey = sourceKeyForIndex?.call(fade.index);
    final effect = plan.lanes!.effect;
    if (outKey != null) {
      final points = mixPointsForIndex?.call(fade.outgoingIndex!);
      final bpm = points?.bpm;
      final beat = bpm != null && bpm > 0 ? 60 / bpm : 0.5;
      // The gate chops on the song's own eighth notes (mpv's filters run on song time).
      if (resend || (fade.lastOut?.gate ?? 0) != out.gate) {
        JustAudioMediaKit.sourceCommand(
          outKey,
          mpvGateCommand(beat: out.gate > 0 ? beat : null, downbeat: points?.downbeat ?? points?.mixIn ?? 0),
        );
      }
      // The brake: mpv's speed falls, with the pitch (no tempo correction), like a turntable stopping.
      if (effect == EffectLane.brake) {
        final brake = brakeSpeed(u, plan.bars);
        if (brake != null) {
          final rate = _speed * plan.outgoingSpeed;
          JustAudioMediaKit.sourceCommand(outKey, ['set', 'audio-pitch-correction', 'no']);
          JustAudioMediaKit.sourceCommand(outKey, ['set', 'speed', (rate * brake).toStringAsFixed(3)]);
        }
      }
      // The beat roll: the loop before the middle halves every beat.
      if (effect == EffectLane.beatRoll) {
        // Set half a beat early: mpv only loops when it reaches the loop's end.
        final roll = beatRollBeats(u + 0.5 / (plan.bars * 4), plan.bars);
        if (roll != fade.lastRoll) {
          fade.lastRoll = roll;
          final middle = plan.start.inMicroseconds / 1e6 + total / 2e6 * _speed * plan.outgoingSpeed;
          for (final command
              in roll == null
                  ? [
                      ['set', 'ab-loop-a', 'no'],
                      ['set', 'ab-loop-b', 'no'],
                    ]
                  : [
                      ['set', 'ab-loop-a', (middle - roll * beat).toStringAsFixed(3)],
                      ['set', 'ab-loop-b', middle.toStringAsFixed(3)],
                    ]) {
            JustAudioMediaKit.sourceCommand(outKey, command);
          }
        }
      }
      for (final command in [
        ...mpvFxCommands(out, resend ? null : fade.lastOut, echoFeedback: effect.echoFeedback),
        // A chain that started over has lost its echo delays.
        if (resend && effect.echo) ...mpvEchoDelayCommands(effect.echoBeats * beat / (_speed * plan.outgoingSpeed)),
      ]) {
        JustAudioMediaKit.sourceCommand(outKey, command);
      }
    }
    if (inKey != null) {
      for (final command in mpvFxCommands(inc, resend ? null : fade.lastIn)) {
        JustAudioMediaKit.sourceCommand(inKey, command);
      }
    }
    fade.lastOut = out;
    fade.lastIn = inc;
  }

  /// Pitches the song at [index] on [player] by [semitones], kept for the rest of the song like a DJ would, or takes
  /// an earlier shift off that player. The desktop uses mpv's rubberband filter on that song, Android the player's
  /// pitch (ExoPlayer's Sonic; it stays with the player, so it is reset once the song leaves it).
  void _setKeyShift(AudioPlayer player, int index, int semitones) {
    if (!_desktop && !_android) return;
    final slot = _players.indexOf(player);
    final key = sourceKeyForIndex?.call(index);
    if (_keyShifted[slot] != null) _unshift(slot, player);
    if (semitones == 0 || key == null) return;
    final scale = math.pow(2, semitones / 12);
    if (_desktop) {
      JustAudioMediaKit.sourceCommand(key, [
        'af',
        'add',
        '@keyshift:rubberband=pitch-scale=${scale.toStringAsFixed(5)}',
      ]);
    } else {
      player.setPitch(scale.toDouble()).ignore();
    }
    _keyShifted[slot] = key;
  }

  void _unshift(int slot, AudioPlayer player) {
    final shifted = _keyShifted[slot];
    _keyShifted[slot] = null;
    if (shifted == null) return;
    if (_desktop) {
      JustAudioMediaKit.sourceCommand(shifted, ['af', 'remove', '@keyshift']);
    } else {
      player.setPitch(1).ignore();
    }
  }

  /// Desktop vocal swap: mixes the next song's instrumental start (an extra audio track) in place of the song until
  /// the bass swaps, switching on the song's own clock (mpv's filters see song time). Only when the next song sings
  /// before the swap and the swap lies within the separated start.
  void _setStem(_Fade fade) {
    if (!_desktop || !vocalSwap) return;
    final plan = fade.plan!;
    final stem = stemForIndex?.call(fade.index);
    final key = sourceKeyForIndex?.call(fade.index);
    final points = mixPointsForIndex?.call(fade.index);
    if (stem == null || key == null || points == null) return;
    final swapAt = (plan.incomingStart + plan.bassSwap * plan.speed).inMicroseconds / 1e6;
    final sings = points.vocalsIn != null && points.vocalsIn! < swapAt;
    if (!sings || swapAt > stem.seconds - 1) return;
    final t = swapAt.toStringAsFixed(3);
    JustAudioMediaKit.sourceCommand(key, ['audio-add', stem.url, 'auto']);
    JustAudioMediaKit.sourceCommand(key, [
      'set',
      'lavfi-complex',
      '[aid1]volume=clip((t-$t)/0.03\\,0\\,1):eval=frame[full];'
          '[aid2]volume=clip(($t-t)/0.03\\,0\\,1):eval=frame[inst];'
          '[full][inst]amix=inputs=2:normalize=0:duration=first[ao]',
    ]);
    _stemmed[_players.indexOf(fade.incoming)] = key;
  }

  /// Takes the instrumental start off [player] again (before it moves to another song: the mix needs that song's
  /// extra track).
  void _clearStem(AudioPlayer player) {
    final slot = _players.indexOf(player);
    final key = _stemmed[slot];
    if (key == null) return;
    _stemmed[slot] = null;
    for (final command in [
      ['set', 'lavfi-complex', ''],
      ['audio-remove', '2'],
      ['set', 'aid', '1'],
    ]) {
      JustAudioMediaKit.sourceCommand(key, command);
    }
  }

  /// A shifted song that is no longer playing on its player (skipped, or the queue moved on) loses its shift.
  void _dropStaleKeyShifts() {
    for (final (slot, player) in _players.indexed) {
      final shifted = _keyShifted[slot];
      if (shifted == null) continue;
      final index = player.currentIndex;
      if (index == null || sourceKeyForIndex?.call(index) != shifted || player == _inactive && _fade == null) {
        _unshift(slot, player);
      }
    }
  }

  /// Takes the lanes' effects off both players.
  Future<void> _clearLanes(_Fade fade) async {
    if (!fade.laneFx) return;
    fade.laneFx = false;
    if (_desktop) {
      final keys = [
        if (fade.outgoingIndex != null) sourceKeyForIndex?.call(fade.outgoingIndex!),
        sourceKeyForIndex?.call(fade.index),
      ];
      for (final key in keys.nonNulls) {
        for (final command in [
          ...mpvFxCommands(FxState.neutral, null),
          mpvGateCommand(),
          // After a brake: the player's own speed and tempo correction again.
          ['set', 'audio-pitch-correction', 'yes'],
          ['set', 'speed', _speed.toStringAsFixed(3)],
          ['set', 'ab-loop-a', 'no'],
          ['set', 'ab-loop-b', 'no'],
        ]) {
          JustAudioMediaKit.sourceCommand(key, command);
        }
      }
      return;
    }
    await Future.wait([AndroidMixFx.clear(fade.outgoing), AndroidMixFx.clear(fade.incoming)]);
  }

  Future<void> play() async {
    await finishFade();
    return _active.play();
  }

  Future<void> pause() async {
    final fading = _fade?.started ?? false;
    await _settleFade(silence: true);
    await _active.pause();
    if (fading) await _active.setVolume(_targetVolume);
  }

  /// Moves both volumes of a transition cut short within 300 ms: the current song out, the next to [incomingTo].
  Future<void> _rampVolumes(_Fade fade, double incomingTo) async {
    final (outgoing, incoming) = (fade.outgoing.volume, fade.incoming.volume);
    for (var step = 1; step <= 6; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_disposed) return;
      await Future.wait([
        fade.outgoing.setVolume(outgoing * (1 - step / 6)),
        fade.incoming.setVolume(incoming + (incomingTo - incoming) * step / 6),
      ]);
    }
  }

  Future<void> stop() async {
    await finishFade();
    _players.forEach(_clearStem);
    await Future.wait(_players.map((p) => p.stop()));
  }

  Future<void> seek(Duration position, {int? index}) async {
    await finishFade();
    if (index != null && index != currentIndex) _clearStem(_active);
    await _active.seek(position, index: index);
  }

  Future<void> seekToNext() async {
    await finishFade();
    _clearStem(_active);
    await _active.seekToNext();
  }

  Future<void> seekToPrevious() async {
    await finishFade();
    _clearStem(_active);
    await _active.seekToPrevious();
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await finishFade();
    await Future.wait(_players.map((p) => p.setLoopMode(mode)));
  }

  Future<void> setSpeed(double speed) {
    _speed = speed;
    _speedRamp?.cancel();
    return Future.wait(_players.map((p) => p.setSpeed(speed)));
  }

  Future<void> setVolume(double volume) async {
    _targetVolume = volume;
    final fade = _fade;
    if (fade == null) {
      await _active.setVolume(volume);
    } else if (fade.clock.isRunning) {
      await (fade.plan == null ? _applyFadeVolumes(fade) : _applyAutomixVolumes(fade));
    }
  }

  Future<void> insert(int index, SourceFactory source) async {
    await finishFade();
    _sources.insert(index, source);
    await Future.wait(_players.map((p) => p.insertAudioSource(index, source())));
  }

  Future<void> removeAt(int index) async {
    await finishFade();
    _sources.removeAt(index);
    await Future.wait(_players.map((p) => p.removeAudioSourceAt(index)));
  }

  Future<void> setSources(
    List<SourceFactory> sources, {
    required int initialIndex,
    Duration initialPosition = Duration.zero,
    bool preserveCurrent = false,
  }) async {
    await finishFade();
    _editing = true;
    _failedFadeIndex = null;
    try {
      await _inactive.stop();
      for (final player in _players) {
        await player.setShuffleModeEnabled(false);
        if (player == _active && preserveCurrent && currentIndex != null) {
          final index = currentIndex!;
          await player.removeAudioSourceRange(index + 1, player.audioSources.length);
          await player.removeAudioSourceRange(0, index);
          await player.insertAudioSources(0, [for (final source in sources.take(initialIndex)) source()]);
          await player.addAudioSources([for (final source in sources.skip(initialIndex + 1)) source()]);
        } else {
          await player.setAudioSources(
            [for (final source in sources) source()],
            initialIndex: initialIndex,
            initialPosition: initialPosition,
            preload: player == _active,
          );
        }
        await _applyEqualizer();
      }
      _sources = [...sources];
    } finally {
      _editing = false;
      _emitCurrent();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _fade?.timer?.cancel();
    _fade?.startTimer?.cancel();
    _speedRamp?.cancel();
    for (final sub in _subs) {
      await sub.cancel();
    }
    await Future.wait(_players.map((p) => p.dispose()));
    automixing.dispose();
    for (final stream in [_states, _indices, _positions, _durations, _loops, _events, _errors]) {
      await stream.close();
    }
  }
}
