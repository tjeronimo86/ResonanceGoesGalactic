import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'galactic_data.dart';
import 'galactic_style.dart';

const _range = GalacticAnalyzer.maxDb - GalacticAnalyzer.minDb;
double _norm(double db) => ((db - GalacticAnalyzer.minDb) / _range).clamp(0.0, 1.0);

final _textCache = <String, TextPainter>{};

/// Small cached label (the scales repeat every frame).
TextPainter gLabel(String text, double size, Color color, {FontWeight weight = FontWeight.w500}) {
  final key = '$text|$size|${color.toARGB32()}|${weight.value}';
  return _textCache.putIfAbsent(key, () {
    if (_textCache.length > 600) _textCache.clear();
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: galacticFont, fontSize: size, color: color, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  });
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w, {StrokeCap cap = StrokeCap.butt}) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = cap;
Paint _shader(ui.Shader s) => Paint()..shader = s;

ui.Gradient _vertical(List<Color> colors, double top, double bottom, [double x = 0]) =>
    ui.Gradient.linear(Offset(x, top), Offset(x, bottom), colors, _stops(colors.length));
ui.Gradient _horizontal(List<Color> colors, double left, double right, [double y = 0]) =>
    ui.Gradient.linear(Offset(left, y), Offset(right, y), colors, _stops(colors.length));
List<double> _stops(int n) => [for (var i = 0; i < n; i++) n == 1 ? 0 : i / (n - 1)];

String _fmtDb(double v) => v.toStringAsFixed(1);

// ---------------------------------------------------------------- Spectrum

class SpectrumPainter extends CustomPainter {
  SpectrumPainter({
    required this.frame,
    required this.style,
    required this.pal,
    required this.curve,
    required this.stereo,
    required this.outline,
    required this.yTitle,
    required this.xTitle,
  }) : super(repaint: frame);

  final ValueNotifier<GFrame> frame;
  final VizStyle style;
  final GPalette pal;
  final bool curve, stereo, outline;
  final String yTitle, xTitle;

  static const _hz = [
    (31.5, '31.5'), (63.0, '63'), (125.0, '125'), (250.0, '250'), (500.0, '500'),
    (1000.0, '1 k'), (2000.0, '2 k'), (4000.0, '4 k'), (8000.0, '8 k'), (16000.0, '16 k'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame.value;
    final axes = style != VizStyle.vinyl && style != VizStyle.synth;
    final left = axes ? 34.0 : 6.0;
    final bottomPad = axes ? 22.0 : 6.0;
    final plot = Rect.fromLTRB(left, 8, size.width - 8, size.height - bottomPad);
    if (plot.width <= 0 || plot.height <= 0) return;
    final n = f.bands.length;
    final slot = n == 0 ? plot.width : plot.width / n;
    if (axes) _axes(canvas, size, plot, slot);
    if (n == 0) return;
    final c = _Ctx(canvas, f, plot, slot, pal, stereo, outline);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(plot.left - 2, plot.top - 6, plot.right + 2, plot.bottom + 2));
    switch (style) {
      case VizStyle.fab2m:
        c.bars(glow: false);
      case VizStyle.cosmic:
        c.stars();
        c.bars(glow: true);
      case VizStyle.chrome:
        c.chrome();
      case VizStyle.vinyl:
        c.vinyl();
      case VizStyle.crbrvs:
        c.crbrvs();
      case VizStyle.synth:
        c.synth();
      case VizStyle.aurora:
        c.aurora();
      case VizStyle.octave:
        c.octave();
      case VizStyle.led:
        c.led();
      case VizStyle.mirror:
        c.mirror();
    }
    if (axes && style != VizStyle.octave) {
      final y = c.y(f.avgLine);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), _stroke(pal.accent.withValues(alpha: .85), 1.4));
    }
    if (curve && style != VizStyle.vinyl) c.curve();
    canvas.restore();
  }

  void _axes(Canvas canvas, Size size, Rect plot, double slot) {
    final grid = _stroke(G.grid, 1);
    for (var i = 1; i <= 8; i++) {
      final db = -10.0 * i;
      final y = plot.top + (GalacticAnalyzer.maxDb - db) / _range * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final t = gLabel(db.toStringAsFixed(1), 8, G.faint);
      t.paint(canvas, Offset(plot.left - t.width - 4, y - t.height / 2));
    }
    for (final (hz, label) in _hz) {
      final i = 8 * math.log(hz / 25) / math.ln2;
      final x = plot.left + slot * (i + 0.5);
      if (x >= plot.right) continue;
      final t = gLabel(label, 8, G.faint);
      t.paint(canvas, Offset(x - t.width / 2, plot.bottom + 2));
    }
    final xt = gLabel(xTitle, 8, G.faint);
    xt.paint(canvas, Offset(plot.center.dx - xt.width / 2, size.height - xt.height));
    final yt = gLabel(yTitle, 8, G.faint);
    canvas.save();
    canvas.translate(6, plot.center.dy);
    canvas.rotate(-math.pi / 2);
    yt.paint(canvas, Offset(-yt.width / 2, -yt.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(SpectrumPainter old) =>
      old.style != style || old.pal != pal || old.curve != curve || old.stereo != stereo || old.outline != outline;
}

class _Ctx {
  _Ctx(this.c, this.f, this.plot, this.slot, this.pal, this.stereo, this.outline);
  final Canvas c;
  final GFrame f;
  final Rect plot;
  final double slot;
  final GPalette pal;
  final bool stereo, outline;

  double y(double db) => plot.bottom - _norm(db) * plot.height;
  double x(int i) => plot.left + slot * i;
  double get bw => math.max(1.0, slot * 0.72);
  ui.Gradient get grad =>
      _vertical([pal.high, Color.lerp(pal.low, pal.high, .35)!, pal.low], plot.top, plot.bottom);

  void bar(double x, double w, double top, Paint paint, {double? bottom}) {
    final b = bottom ?? plot.bottom;
    if (b - top < 0.5) return;
    final r = RRect.fromRectAndCorners(
      Rect.fromLTRB(x, top, x + w, b),
      topLeft: Radius.circular(math.min(w / 2, 1.5)),
      topRight: Radius.circular(math.min(w / 2, 1.5)),
    );
    if (outline) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
    }
    c.drawRRect(r, paint);
  }

  void bars({required bool glow}) {
    final g = grad;
    for (var i = 0; i < f.bands.length; i++) {
      final x0 = x(i) + (slot - bw) / 2;
      if (stereo) {
        final hw = bw / 2;
        bar(x0, hw * .92, y(f.bandsL[i]), _shader(_vertical([pal.accent2, pal.low], plot.top, plot.bottom)));
        bar(x0 + hw, hw * .92, y(f.bandsR[i]), _shader(_vertical([pal.high, pal.accent], plot.top, plot.bottom)));
      } else {
        final top = y(f.bands[i]);
        if (glow) {
          c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(x0 - bw * .6, top - 3, x0 + bw * 1.6, plot.bottom), Radius.circular(bw)),
            _shader(g)..color = const Color(0x29FFFFFF),
          );
        }
        bar(x0, bw, top, _shader(g));
      }
      if (f.caps[i] > GalacticAnalyzer.minDb + 1) {
        final cy = y(f.caps[i]) - 2;
        c.drawLine(Offset(x0, cy), Offset(x0 + bw, cy), _stroke(glow ? pal.accent2 : pal.accent.withValues(alpha: .9), 1.3));
      }
    }
  }

  void stars() {
    for (var k = 0; k < 70; k++) {
      final sx = ((k * 7919) % 1000) / 1000;
      final sy = ((k * 104729) % 997) / 997;
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(f.time * (0.6 + (k % 5) * 0.37) + k));
      c.drawCircle(
        Offset(plot.left + sx * plot.width, plot.top + sy * plot.height),
        0.6 + (k % 3) * 0.35,
        _fill(Colors.white.withValues(alpha: tw * .55)),
      );
    }
  }

  void chrome() {
    const dark = Color(0xFF2A3140);
    for (var i = 0; i < f.bands.length; i++) {
      final x0 = x(i) + (slot - bw) / 2;
      final top = y(f.bands[i]);
      bar(x0, bw, top, _shader(_horizontal(
        [dark, pal.high, Colors.white, Color.lerp(pal.low, pal.high, .5)!, dark], x0, x0 + bw, top)));
      if (plot.bottom - top > 2) c.drawLine(Offset(x0, top), Offset(x0 + bw, top), _stroke(Colors.white.withValues(alpha: .9), 1));
      final cy = y(f.caps[i]) - 2;
      c.drawLine(Offset(x0, cy), Offset(x0 + bw, cy), _stroke(pal.accent2.withValues(alpha: .8), 1.2));
    }
  }

  void crbrvs() {
    final split = y(-45);
    final w = math.max(1.0, slot * .42);
    for (var i = 0; i < f.bands.length; i++) {
      final x0 = x(i) + (slot - w) / 2;
      final top = y(f.bands[i]);
      bar(x0, w, math.max(top, split), _fill(pal.low));
      if (top < split) bar(x0, w, top, _fill(pal.high), bottom: split);
      final cy = y(f.caps[i]) - 2;
      c.drawRect(Rect.fromLTWH(x0 - 1, cy - 1.5, w + 2, 1.5), _fill(pal.high));
    }
    final scan = _stroke(Colors.black.withValues(alpha: .28), 1);
    for (var yy = plot.top; yy < plot.bottom; yy += 3) {
      c.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), scan);
    }
  }

  void vinyl() {
    final center = plot.center;
    final short = math.min(plot.width, plot.height);
    final r = short * 0.30;
    final n = f.bands.length;
    final stroke = math.max(1.5, (2 * math.pi * r / (n * 2)) * .7);
    for (var i = 0; i < n; i++) {
      final v = _norm(stereo ? f.bandsL[i] : f.bands[i]);
      final v2 = _norm(stereo ? f.bandsR[i] : f.bands[i]);
      for (final (side, value) in [(1, v), (-1, v2)]) {
        final a = -math.pi / 2 + side * (i + 0.5) / n * math.pi;
        final len = value * short * 0.36;
        final r0 = r * 1.06;
        final col = Color.lerp(pal.low, pal.high, value)!;
        final p0 = center + Offset(math.cos(a) * r0, math.sin(a) * r0);
        final p1 = center + Offset(math.cos(a) * (r0 + len), math.sin(a) * (r0 + len));
        if (outline) {
          c.drawCircle(p1, stroke / 2, _fill(col));
        } else {
          c.drawLine(p0, p1, _stroke(col, stroke, cap: StrokeCap.round));
        }
      }
    }
    c.drawCircle(center, r, _fill(const Color(0xFF0B0B10)));
    final groove = _stroke(Colors.white.withValues(alpha: .05), 1);
    for (var g = r * .42; g < r * .98; g += r * .045) {
      c.drawCircle(center, g, groove);
    }
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(f.time * 200 * math.pi / 180);
    c.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r),
      0,
      70 * math.pi / 180,
      true,
      _shader(ui.Gradient.sweep(Offset.zero, [Colors.transparent, Colors.white.withValues(alpha: .14), Colors.transparent], const [0, .1, .2])),
    );
    c.drawCircle(
      Offset.zero,
      r * .35,
      _shader(ui.Gradient.linear(Offset(-r * .35, -r * .35), Offset(r * .35, r * .35), [pal.low, pal.high])),
    );
    c.drawLine(Offset(0, -r * .3), Offset(0, -r * .18), _stroke(Colors.white.withValues(alpha: .6), 2, cap: StrokeCap.round));
    c.restore();
    c.drawCircle(center, r * .05, _fill(G.bg));
  }

  void synth() {
    final horizon = plot.top + plot.height * .66;
    c.drawRect(Rect.fromLTRB(plot.left, plot.top, plot.right, horizon),
        _shader(_vertical([const Color(0xFF0B0620), pal.low.withValues(alpha: .25)], plot.top, horizon)));
    final sr = plot.height * .42;
    final sc = Offset(plot.center.dx, horizon);
    c.save();
    c.clipRect(Rect.fromLTRB(plot.left, plot.top, plot.right, horizon));
    c.drawCircle(sc, sr, _shader(_vertical([const Color(0xFFFFD86B), pal.low], sc.dy - sr, sc.dy)));
    var k = 0;
    for (var yy = horizon - sr * .5; yy < horizon; yy += sr * .1) {
      c.drawRect(Rect.fromLTWH(sc.dx - sr, yy, 2 * sr, 1 + k * .5), _fill(const Color(0xFF0B0620)));
      k++;
    }
    c.restore();
    c.drawRect(Rect.fromLTRB(plot.left, horizon, plot.right, plot.bottom), _fill(const Color(0xFF07040F)));
    final gridPaint = _stroke(pal.accent2.withValues(alpha: .55), 1);
    final depth = plot.bottom - horizon;
    final shift = (f.time * 0.6) % 1;
    for (var i = 0; i < 8; i++) {
      final t = (i + shift) / 8;
      final yy = horizon + depth * t * t;
      c.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), gridPaint);
    }
    for (var i = -10; i <= 10; i++) {
      c.drawLine(Offset(plot.center.dx + i * plot.width / 40, horizon), Offset(plot.center.dx + i * plot.width / 8, plot.bottom), gridPaint);
    }
    final maxH = horizon - plot.top;
    final g = _vertical([pal.high, pal.low], plot.top, horizon);
    for (var i = 0; i < f.bands.length; i++) {
      final x0 = x(i) + (slot - bw) / 2;
      final h = _norm(f.bands[i]) * maxH;
      bar(x0, bw, horizon - h, _shader(g), bottom: horizon);
      c.drawRect(Rect.fromLTWH(x0, horizon, bw, h * .35), _fill(pal.low.withValues(alpha: .18)));
    }
  }

  Path _smooth(List<double> values, {required bool close}) {
    final p = Path();
    final n = values.length;
    final pts = [for (var i = 0; i < n; i++) Offset(x(i) + slot / 2, y(values[i]))];
    if (close) {
      p.moveTo(plot.left, plot.bottom);
      p.lineTo(pts[0].dx, pts[0].dy);
    } else {
      p.moveTo(pts[0].dx, pts[0].dy);
    }
    for (var i = 1; i < n; i++) {
      final a = pts[i - 1], b = pts[i];
      p.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    p.lineTo(pts.last.dx, pts.last.dy);
    if (close) {
      p.lineTo(plot.right, plot.bottom);
      p.close();
    }
    return p;
  }

  void aurora() {
    final layers = [
      (stereo ? f.bandsL : f.bands, pal.low, 0.0),
      (stereo ? f.bandsR : f.bands, pal.high, 1.7),
      (f.caps, pal.accent2, 3.1),
    ];
    for (var k = 0; k < layers.length; k++) {
      final (vals, col, ph) = layers[k];
      final wob = [for (var i = 0; i < vals.length; i++) vals[i] - 6 * k + 2.5 * math.sin(f.time * 1.3 + i * 0.21 + ph)];
      c.drawPath(
        _smooth(wob, close: true),
        _shader(_vertical([col.withValues(alpha: k == 0 ? .75 : .42), col.withValues(alpha: .03)], plot.top, plot.bottom)),
      );
      if (!outline || k == 0) c.drawPath(_smooth(wob, close: false), _stroke(col.withValues(alpha: .9), 1.4));
    }
  }

  void octave() {
    const centers = [31.5, 63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0];
    final oct = List.filled(10, GalacticAnalyzer.minDb);
    final cap = List.filled(10, GalacticAnalyzer.minDb);
    for (var b = 0; b < f.bands.length; b++) {
      final hz = f.bandFreqs[b];
      var best = 0;
      for (var k = 1; k < 10; k++) {
        if ((math.log(centers[k] / hz)).abs() < (math.log(centers[best] / hz)).abs()) best = k;
      }
      if ((math.log(centers[best] / hz)).abs() > math.ln2 * .55) continue;
      oct[best] = math.max(oct[best], f.bands[b]);
      cap[best] = math.max(cap[best], f.caps[b]);
    }
    final s = plot.width / 10, w = s * .7;
    final g = grad;
    for (var k = 0; k < 10; k++) {
      final x0 = plot.left + s * k + (s - w) / 2;
      bar(x0, w, y(oct[k]), _shader(g));
      final cy = y(cap[k]) - 2;
      c.drawLine(Offset(x0, cy), Offset(x0 + w, cy), _stroke(pal.accent2, 2));
    }
  }

  void led() {
    const segH = 2.6, gap = 1.2;
    final count = (plot.height / (segH + gap)).floor();
    for (var i = 0; i < f.bands.length; i++) {
      final x0 = x(i) + (slot - bw) / 2;
      final lit = (_norm(f.bands[i]) * count).floor();
      final capSeg = (_norm(f.caps[i]) * count).floor();
      for (var s = 0; s < count; s++) {
        final frac = s / count;
        final col = frac < .6 ? pal.low : (frac < .82 ? pal.accent2 : pal.high);
        final yy = plot.bottom - (s + 1) * (segH + gap);
        final on = s < lit || s == capSeg;
        if (on || !outline) c.drawRect(Rect.fromLTWH(x0, yy, bw, segH), _fill(col.withValues(alpha: on ? 1 : .07)));
      }
    }
  }

  void mirror() {
    final mid = plot.center.dy;
    final half = plot.height / 2;
    final up = _vertical([pal.high, pal.low], plot.top, mid);
    final down = _vertical([pal.low, pal.high], mid, plot.bottom);
    for (var i = 0; i < f.bands.length; i++) {
      final x0 = x(i) + (slot - bw) / 2;
      final a = _norm(stereo ? f.bandsL[i] : f.bands[i]) * half;
      final b = _norm(stereo ? f.bandsR[i] : f.bands[i]) * half;
      bar(x0, bw, mid - a, _shader(up), bottom: mid);
      bar(x0, bw, mid, _shader(down), bottom: mid + b);
      final cp = _norm(f.caps[i]) * half;
      final capPaint = _stroke(pal.accent2, 1.2);
      c.drawLine(Offset(x0, mid - cp - 2), Offset(x0 + bw, mid - cp - 2), capPaint);
      c.drawLine(Offset(x0, mid + cp + 2), Offset(x0 + bw, mid + cp + 2), capPaint);
    }
    c.drawLine(Offset(plot.left, mid), Offset(plot.right, mid), _stroke(Colors.white.withValues(alpha: .25), 1));
  }

  void curve() {
    final path = _smooth(f.bands, close: false);
    c.drawPath(path, _stroke(Colors.white.withValues(alpha: .25), 4));
    c.drawPath(path, _stroke(pal.accent2, 1.6, cap: StrokeCap.round));
  }
}

// ---------------------------------------------------------------- Side meter (L/R peaks, 0 … -60 dB)

class SideMeterPainter extends CustomPainter {
  SideMeterPainter(this.frame, this.pal, {this.compact = false}) : super(repaint: frame);
  final ValueNotifier<GFrame> frame;
  final GPalette pal;

  /// Narrow column (landscape): thinner bars, numbers without "dB".
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame.value;
    final barW = compact ? 4.0 : 5.0, gap = compact ? 1.5 : 2.0, x0 = compact ? 2.0 : 3.0;
    const top = 6.0;
    final bottom = size.height - 14;
    final h = bottom - top;
    double yOf(double db) => top + (-db.clamp(-60.0, 0.0) / 60) * h;
    final brush = _shader(_vertical([pal.high, pal.low, pal.low], top, bottom));
    for (final (k, db) in [(0, f.peakL), (1, f.peakR)]) {
      final x = x0 + k * (barW + gap);
      canvas.drawRect(Rect.fromLTWH(x, top, barW, h), _fill(Colors.white.withValues(alpha: .04)));
      final y = yOf(db);
      if (db > -60) canvas.drawRect(Rect.fromLTRB(x, y, x + barW, bottom), brush);
      final hold = k == 0 ? f.holdL : f.holdR;
      if (hold > -60) canvas.drawRect(Rect.fromLTWH(x, yOf(hold) - 1, barW, 1.5), _fill(pal.accent2));
    }
    final seam = _stroke(G.bg, 1);
    for (var yy = top; yy < bottom; yy += 2.2) {
      canvas.drawLine(Offset(x0, yy), Offset(x0 + 2 * barW + gap, yy), seam);
    }
    for (final m in const [0, -3, -6, -10, -20, -30, -40, -50, -60]) {
      final y = yOf(m.toDouble());
      final t = gLabel(compact ? '$m' : '$m dB', 7, G.faint);
      final lx = x0 + 2 * barW + gap;
      canvas.drawLine(Offset(lx + 2, y), Offset(lx + 5, y), _stroke(G.faint, 1));
      t.paint(canvas, Offset(lx + 6, y - t.height / 2));
    }
    gLabel('L  R', 7, G.faint).paint(canvas, Offset(x0, bottom + 3));
  }

  @override
  bool shouldRepaint(SideMeterPainter old) => old.pal != pal || old.compact != compact;
}

// ---------------------------------------------------------------- VU meter

class VuPainter extends CustomPainter {
  VuPainter(this.frame, this.pal, this.channel) : super(repaint: frame);
  final ValueNotifier<GFrame> frame;
  final GPalette pal;
  final int channel;

  static const _labels = [
    (-20.0, '20'), (-10.0, '10'), (-7.0, '7'), (-5.0, '5'), (-3.0, '3'), (-2.0, '2'),
    (-1.0, '1'), (0.0, '0'), (1.0, '1'), (2.0, '2'), (3.0, '3'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame.value;
    final r = math.min(size.width * 0.56, size.height * 0.80);
    final pivot = Offset(size.width / 2, math.min(size.height * 0.95, r * 1.12 + 6));
    const span = 100.0;
    double angle(double pos) => (-90 - span / 2 + span * pos) * math.pi / 180;
    Offset pt(double pos, double rad) => pivot + Offset(math.cos(angle(pos)) * rad, math.sin(angle(pos)) * rad);
    final zero = GalacticAnalyzer.vuPos(0);
    const steps = 40;
    for (var i = 0; i < steps; i++) {
      final a = i / steps, b = (i + 1) / steps;
      final col = a >= zero ? pal.accent2 : Color.lerp(pal.low, pal.accent, a / zero)!;
      canvas.drawLine(pt(a, r * .86), pt(b, r * .86), _stroke(col, 2.2));
    }
    for (final (v, label) in _labels) {
      final p = GalacticAnalyzer.vuPos(v);
      final col = v > 0 ? pal.accent2 : G.dim;
      canvas.drawLine(pt(p, r * .8), pt(p, r * .9), _stroke(col, 1.2));
      final t = gLabel(label, 7, col);
      final c = pt(p, r);
      t.paint(canvas, c - Offset(t.width / 2, t.height / 2));
    }
    final vu = gLabel('VU', 10, G.text, weight: FontWeight.w600);
    vu.paint(canvas, Offset(pivot.dx - vu.width / 2, pivot.dy - r * .45));
    final ch = gLabel(channel == 0 ? 'L' : 'R', 7, G.dim);
    ch.paint(canvas, Offset(4, size.height - ch.height));
    final led = channel == 0 ? f.ledL : f.ledR;
    final peak = gLabel('crête', 7, G.dim);
    peak.paint(canvas, Offset(size.width - peak.width - 14, 0));
    canvas.drawCircle(Offset(size.width - 7, peak.height / 2), 3, _fill(led ? G.bad : Colors.white.withValues(alpha: .1)));
    final pos = channel == 0 ? f.vuL : f.vuR;
    canvas.drawLine(pivot + const Offset(2, 2), pt(pos, r * .95) + const Offset(2, 2),
        _stroke(Colors.black.withValues(alpha: .4), 2, cap: StrokeCap.round));
    canvas.drawLine(pivot, pt(pos, r * .95), _stroke(Colors.white, 1.6, cap: StrokeCap.round));
    canvas.drawCircle(pivot, 5, _fill(const Color(0xFF2A2A40)));
    canvas.drawCircle(pivot, 2.5, _fill(const Color(0xFF55557A)));
  }

  @override
  bool shouldRepaint(VuPainter old) => old.pal != pal;
}

// ---------------------------------------------------------------- Loudness bar (-30 … 0 LUFS)

class LoudnessBarPainter extends CustomPainter {
  LoudnessBarPainter(this.integrated, this.momentary, this.pal);
  final double integrated, momentary;
  final GPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    const bh = 5.0;
    double x(double l) => ((l + 30) / 30).clamp(0.0, 1.0) * size.width;
    canvas.drawRRect(RRect.fromLTRBR(0, 0, size.width, bh, const Radius.circular(bh / 2)), _fill(Colors.white.withValues(alpha: .06)));
    if (integrated.isFinite) {
      canvas.drawRRect(
        RRect.fromLTRBR(0, 0, x(integrated), bh, const Radius.circular(bh / 2)),
        _shader(_horizontal([pal.low, pal.high, pal.accent2], 0, size.width)),
      );
    }
    if (momentary.isFinite) canvas.drawRect(Rect.fromLTWH(x(momentary) - 1, -1, 2, bh + 2), _fill(pal.accent2));
    for (final (l, label) in const [(-30.0, '-30'), (-14.0, '-14'), (-9.0, '-9'), (0.0, '0 LUFS')]) {
      final xx = x(l);
      if (l > -30 && l < 0) canvas.drawLine(Offset(xx, -2), Offset(xx, bh + 3), _stroke(G.dim, 1));
      final t = gLabel(label, 7, G.faint);
      t.paint(canvas, Offset((xx - t.width / 2).clamp(0.0, size.width - t.width), bh + 4));
    }
  }

  @override
  bool shouldRepaint(LoudnessBarPainter old) =>
      old.integrated != integrated || old.momentary != momentary || old.pal != pal;
}

// ---------------------------------------------------------------- Stereo bars (RMS L/R, -60 … 0 dB)

class StereoBarsPainter extends CustomPainter {
  StereoBarsPainter(this.frame, this.pal) : super(repaint: frame);
  final ValueNotifier<GFrame> frame;
  final GPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame.value;
    const left = 12.0;
    final right = size.width - 4;
    const labelH = 12.0;
    final w = right - left;
    double x(double db) => left + ((db + 60) / 60).clamp(0.0, 1.0) * w;
    final barH = (size.height - labelH - 6) / 2;
    final brush = _shader(_horizontal([pal.low, pal.high, pal.accent2], left, right));
    for (var k = 0; k < 2; k++) {
      final y = 2 + k * (barH + 2);
      canvas.drawRect(Rect.fromLTWH(left, y, w, barH), _fill(Colors.white.withValues(alpha: .04)));
      final rms = k == 0 ? f.rmsL : f.rmsR;
      if (rms > -60) canvas.drawRect(Rect.fromLTRB(left, y, x(rms), y + barH), brush);
      final pk = k == 0 ? f.peakL : f.peakR;
      if (pk > -60) canvas.drawRect(Rect.fromLTWH(x(pk) - 1, y, 2, barH), _fill(pal.accent));
      final t = gLabel(k == 0 ? 'L' : 'R', 7, G.faint);
      t.paint(canvas, Offset(2, y + barH / 2 - t.height / 2));
    }
    final seam = _stroke(G.card.withValues(alpha: .55), 1);
    for (var xx = left; xx < right; xx += 2) {
      canvas.drawLine(Offset(xx, 2), Offset(xx, 4 + 2 * barH), seam);
    }
    for (final m in const [-60, -40, -30, -20, -10, -6, -3, 0]) {
      final t = gLabel('$m', 7, G.faint);
      t.paint(canvas, Offset((x(m.toDouble()) - t.width / 2).clamp(0.0, size.width - t.width), size.height - t.height));
    }
  }

  @override
  bool shouldRepaint(StereoBarsPainter old) => old.pal != pal;
}

// ---------------------------------------------------------------- Waveform of the whole song

class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.envelope, required this.progress, required this.durationSeconds, required this.pal})
    : super(repaint: progress);

  /// Level per slice, 0–1 (from the server's spectrum), or null while loading.
  final List<double>? envelope;
  final ValueNotifier<double> progress;
  final double durationSeconds;
  final GPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 12.0;
    final h = size.height - labelH;
    final mid = h / 2;
    final amp = h / 2 * 0.92;
    final lim = math.pow(10, -1 / 20).toDouble();
    final warn = _stroke(G.warn.withValues(alpha: .55), 1);
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, mid - lim * amp), Offset(x + 4, mid - lim * amp), warn);
      canvas.drawLine(Offset(x, mid + lim * amp), Offset(x + 4, mid + lim * amp), warn);
    }
    final ceiling = gLabel('-1.0 dBTP', 7, G.warn.withValues(alpha: .8));
    ceiling.paint(canvas, Offset(size.width - ceiling.width, 0));
    final p = progress.value.clamp(0.0, 1.0);
    final env = envelope;
    if (env != null && env.isNotEmpty) {
      final n = env.length;
      final w = size.width / n;
      final outer = _shader(_vertical(
        [pal.low.withValues(alpha: .7), pal.high.withValues(alpha: .5), pal.low.withValues(alpha: .7)], mid - amp, mid + amp));
      final inner = _fill(pal.accent2.withValues(alpha: .75));
      for (var i = 0; i < n; i++) {
        final played = i / n <= p;
        final a = played ? 1.0 : .5;
        final pk = env[i] * amp;
        canvas.drawRect(Rect.fromLTWH(i * w, mid - pk, w + .5, 2 * pk), outer..color = Colors.white.withValues(alpha: a));
        final rm = pk * .5;
        canvas.drawRect(Rect.fromLTWH(i * w, mid - rm, w + .5, 2 * rm), inner..color = pal.accent2.withValues(alpha: .75 * a));
      }
    } else {
      canvas.drawLine(Offset(0, mid), Offset(size.width, mid), _stroke(G.grid, 1));
    }
    final px = p * size.width;
    canvas.drawLine(Offset(px, 0), Offset(px, h), _stroke(pal.accent, 2));
    if (durationSeconds > 0) {
      for (var m = 1; m * 60 < durationSeconds; m++) {
        final x = m * 60 / durationSeconds * size.width;
        final t = gLabel('$m:00', 7, G.faint);
        if (x > size.width - t.width) break;
        canvas.drawLine(Offset(x, h), Offset(x, h + 2), _stroke(G.faint, 1));
        t.paint(canvas, Offset(x - t.width / 2, h + 2));
      }
    }
  }

  @override
  bool shouldRepaint(WaveformPainter old) =>
      old.envelope != envelope || old.pal != pal || old.durationSeconds != durationSeconds;
}

// ---------------------------------------------------------------- Equalizer response

class EqCurvePainter extends CustomPainter {
  EqCurvePainter(this.response, this.pal);
  final List<double> response;
  final GPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    const left = 22.0;
    canvas.drawLine(Offset(left, mid), Offset(size.width, mid), _stroke(G.grid, 1));
    gLabel('+12', 7, G.faint).paint(canvas, Offset.zero);
    final z = gLabel('0 dB', 7, G.faint);
    z.paint(canvas, Offset(0, mid - z.height / 2));
    final m = gLabel('-12', 7, G.faint);
    m.paint(canvas, Offset(0, size.height - m.height));
    if (response.isEmpty) return;
    final path = Path();
    for (var i = 0; i < response.length; i++) {
      final x = left + i / (response.length - 1) * (size.width - left);
      final y = mid - (response[i] / 12).clamp(-1.0, 1.0) * (mid - 1);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, _stroke(pal.accent.withValues(alpha: .35), 4));
    canvas.drawPath(path, _stroke(pal.accent, 1.5));
  }

  @override
  bool shouldRepaint(EqCurvePainter old) => old.response != response || old.pal != pal;
}

String gFmt(double v, [int digits = 1]) => v.isFinite ? v.toStringAsFixed(digits) : '–';
String gFmtDb(double v) => _fmtDb(v);
