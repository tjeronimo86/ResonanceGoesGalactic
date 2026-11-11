import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Everything the displays need for one picture.
class GFrame {
  GFrame({
    required this.bands,
    required this.bandsL,
    required this.bandsR,
    required this.caps,
    required this.bandFreqs,
    required this.avgLine,
    required this.peakL,
    required this.peakR,
    required this.holdL,
    required this.holdR,
    required this.rmsL,
    required this.rmsR,
    required this.vuL,
    required this.vuR,
    required this.ledL,
    required this.ledR,
    required this.momentary,
    required this.shortTerm,
    required this.integrated,
    required this.lra,
    required this.maxPeak,
    required this.truePeak,
    required this.time,
    required this.playing,
  });

  final Float64List bands, bandsL, bandsR, caps, bandFreqs;
  final double avgLine;
  final double peakL, peakR, holdL, holdR, rmsL, rmsR;

  /// VU needle position, 0 = -20 VU, 1 = +3 VU.
  final double vuL, vuR;
  final bool ledL, ledR;

  /// LUFS / LU / dBFS / dBTP; -inf when there is no value yet.
  final double momentary, shortTerm, integrated, lra, maxPeak, truePeak;
  final double time;
  final bool playing;

  static final empty = GFrame(
    bands: Float64List(0),
    bandsL: Float64List(0),
    bandsR: Float64List(0),
    caps: Float64List(0),
    bandFreqs: Float64List(0),
    avgLine: -40,
    peakL: -120,
    peakR: -120,
    holdL: -120,
    holdR: -120,
    rmsL: -120,
    rmsR: -120,
    vuL: 0,
    vuR: 0,
    ledL: false,
    ledR: false,
    momentary: double.negativeInfinity,
    shortTerm: double.negativeInfinity,
    integrated: double.negativeInfinity,
    lra: 0,
    maxPeak: double.negativeInfinity,
    truePeak: double.negativeInfinity,
    time: 0,
    playing: false,
  );
}

/// Asks the player's native analyzer (Android) for the current measurements and smooths them for display.
class GalacticAnalyzer {
  static const minDb = -80.0;
  static const maxDb = -10.0;
  static const _channel = MethodChannel('com.ryanheise.just_audio.galactic');

  bool _busy = false;
  bool available = true;
  Float32List? _raw;

  var _bands = Float64List(0), _bandsL = Float64List(0), _bandsR = Float64List(0);
  var _caps = Float64List(0), _capHold = Float64List(0), _freqs = Float64List(0);
  double _avg = -40, _clock = 0;
  double _peakL = -120, _peakR = -120, _holdL = -120, _holdR = -120, _holdTL = 0, _holdTR = 0;
  double _ledTL = 0, _ledTR = 0;
  double _vuPosL = 0, _vuVelL = 0, _vuPosR = 0, _vuVelR = 0;
  double _rmsL = -120, _rmsR = -120;

  /// Fetches the newest measurements; at most one request at a time.
  Future<void> poll(List<String> ids, {required bool stereo, String? track}) async {
    if (_busy || !available) return;
    _busy = true;
    try {
      final result = await _channel.invokeMethod<Float32List>('frame', {'ids': ids, 'stereo': stereo, 'track': track});
      if (result != null && result.length >= 14) _raw = result;
    } on MissingPluginException {
      available = false;
    } on PlatformException {
      // Try again next frame.
    } finally {
      _busy = false;
    }
  }

  void _resize(int n, double rate) {
    _bands = Float64List(n)..fillRange(0, n, minDb);
    _bandsL = Float64List(n)..fillRange(0, n, minDb);
    _bandsR = Float64List(n)..fillRange(0, n, minDb);
    _caps = Float64List(n)..fillRange(0, n, minDb);
    _capHold = Float64List(n);
    _freqs = Float64List.fromList([for (var i = 0; i < n; i++) 25 * math.pow(2, i / 8).toDouble()]);
  }

  static double _v(double x) => x <= -199 ? double.negativeInfinity : x;

  /// Needle position (0 = -20 VU, 1 = +3 VU), proportional to voltage like a real VU meter.
  static double vuPos(double vu) {
    final v = math.pow(10, vu.clamp(-40.0, 6.0) / 20).toDouble();
    const lo = 0.1;
    final hi = math.pow(10, 3 / 20).toDouble();
    return (v - lo) / (hi - lo);
  }

  (double, double) _spring(double pos, double vel, double target, double dt) {
    const w = 2 * math.pi * 2.1, z = 0.78;
    var p = pos, v = vel;
    final h = math.min(dt, 0.1) / 4;
    for (var i = 0; i < 4; i++) {
      final a = w * w * (target - p) - 2 * z * w * v;
      v += a * h;
      p += v * h;
    }
    if (p < -0.02) (p, v) = (-0.02, 0.0);
    if (p > 1.04) (p, v) = (1.04, 0.0);
    return (p, v);
  }

  /// One display step. [boost] adds the equalizer's gain per frequency (it acts after the measurement).
  GFrame tick(double dt, {required double vuRef, double Function(double hz)? boost}) {
    _clock += dt;
    final raw = _raw;
    final n = raw == null ? 0 : raw[1].toInt();
    if (raw != null && n != _bands.length) _resize(n, raw[3].toDouble());
    final playing = raw != null && raw[2] > 0.5;

    // Spectrum: quick rise, smooth fall; caps hold a moment, then sink.
    final release = 28 * dt;
    void smooth(Float64List out, int offset) {
      for (var b = 0; b < n; b++) {
        var db = playing ? raw[offset + b].toDouble() : minDb;
        if (playing && boost != null) db += boost(_freqs[b]);
        final prev = out[b];
        var v = db > prev ? prev + (db - prev) * 0.7 : math.max(db, prev - (playing ? release : 45 * dt));
        if (v < minDb) v = minDb;
        out[b] = v;
      }
    }

    if (n > 0) {
      smooth(_bands, 14);
      smooth(_bandsL, 14 + n);
      smooth(_bandsR, 14 + 2 * n);
    }
    var top = minDb;
    for (var b = 0; b < n; b++) {
      if (_bands[b] >= _caps[b]) {
        _caps[b] = _bands[b];
        _capHold[b] = 0;
      } else {
        _capHold[b] += dt;
        if (_capHold[b] > 0.6) _caps[b] = math.max(_bands[b], _caps[b] - 18 * dt);
      }
      top = math.max(top, _bands[b]);
    }
    _avg += (top - _avg) * (1 - math.exp(-dt / 2.5));

    // Levels
    final pkL = playing ? raw[4].toDouble() : -120.0;
    final pkR = playing ? raw[5].toDouble() : -120.0;
    _peakL = math.max(pkL, _peakL - 20 * dt).clamp(-120.0, 6.0);
    _peakR = math.max(pkR, _peakR - 20 * dt).clamp(-120.0, 6.0);
    _holdTL += dt;
    _holdTR += dt;
    if (_peakL >= _holdL || _holdTL > 1.5) {
      _holdL = _peakL;
      _holdTL = 0;
    }
    if (_peakR >= _holdR || _holdTR > 1.5) {
      _holdR = _peakR;
      _holdTR = 0;
    }
    _ledTL = pkL > -1 ? 0.8 : _ledTL - dt;
    _ledTR = pkR > -1 ? 0.8 : _ledTR - dt;
    _rmsL = playing ? raw[6].toDouble() : math.max(-120.0, _rmsL - 30 * dt);
    _rmsR = playing ? raw[7].toDouble() : math.max(-120.0, _rmsR - 30 * dt);
    final (pl, vl) = _spring(_vuPosL, _vuVelL, vuPos(_rmsL - vuRef), dt);
    final (pr, vr) = _spring(_vuPosR, _vuVelR, vuPos(_rmsR - vuRef), dt);
    _vuPosL = pl;
    _vuVelL = vl;
    _vuPosR = pr;
    _vuVelR = vr;

    return GFrame(
      bands: Float64List.fromList(_bands),
      bandsL: Float64List.fromList(_bandsL),
      bandsR: Float64List.fromList(_bandsR),
      caps: Float64List.fromList(_caps),
      bandFreqs: _freqs,
      avgLine: _avg,
      peakL: _peakL,
      peakR: _peakR,
      holdL: _holdL,
      holdR: _holdR,
      rmsL: _rmsL,
      rmsR: _rmsR,
      vuL: _vuPosL,
      vuR: _vuPosR,
      ledL: _ledTL > 0,
      ledR: _ledTR > 0,
      momentary: raw == null ? double.negativeInfinity : _v(raw[8].toDouble()),
      shortTerm: raw == null ? double.negativeInfinity : _v(raw[9].toDouble()),
      integrated: raw == null ? double.negativeInfinity : _v(raw[10].toDouble()),
      lra: raw == null ? 0 : raw[11].toDouble(),
      maxPeak: raw == null ? double.negativeInfinity : _v(raw[12].toDouble()),
      truePeak: raw == null ? double.negativeInfinity : _v(raw[13].toDouble()),
      time: _clock,
      playing: playing,
    );
  }
}
