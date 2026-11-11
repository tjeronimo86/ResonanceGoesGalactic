import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/session.dart';
import '../player/equalizer.dart';
import '../player/equalizer_controller.dart';
import '../player/player.dart';
import '../player/spectrum.dart';
import '../ui/widgets/common.dart';
import 'galactic_data.dart';
import 'galactic_paint.dart';
import 'galactic_style.dart';

/// The Galactic view: spectrum in ten styles, equalizer, queue, VU meters, loudness, waveform and stereo levels,
/// measured live from what the player outputs (Android).
class GalacticPage extends ConsumerStatefulWidget {
  const GalacticPage({super.key});

  @override
  ConsumerState<GalacticPage> createState() => _GalacticPageState();
}

class _GalacticPageState extends ConsumerState<GalacticPage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _analyzer = GalacticAnalyzer();
  final _frame = ValueNotifier<GFrame>(GFrame.empty);
  final _slow = ValueNotifier<GFrame>(GFrame.empty);
  final _progress = ValueNotifier<double>(0);
  final _position = ValueNotifier<Duration>(Duration.zero);
  Duration _last = Duration.zero;
  double _slowT = 0;
  Timer? _random;
  /// Landscape: the equalizer lies over the spectrum while open.
  bool _eqOverlay = false;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNews());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _random?.cancel();
    super.dispose();
  }

  Future<void> _maybeShowNews() async {
    final prefs = ref.read(prefsProvider);
    final build = (await PackageInfo.fromPlatform()).buildNumber;
    final seen = prefs.getString('galactic_seen_build');
    await prefs.setString('galactic_seen_build', build);
    if (seen != null && seen != build && mounted) _showNews(context);
  }

  /// 0 VU: the song's loudness (ReplayGain, else the live measurement), or the fixed level from the settings.
  double _vuRef(PlayerView p, GalacticLook look) {
    if (look.vuRef != 0) return look.vuRef.toDouble();
    final rg = p.current?.replayGainTrack;
    if (rg != null) return (-18 - rg).roundToDouble();
    final live = _slow.value.integrated;
    return live.isFinite ? live.roundToDouble() : -18;
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = now;
    final p = ref.read(playerProvider);
    final look = ref.read(galacticLookProvider);
    final eq = ref.read(equalizerProvider);
    final engine = ref.read(playerProvider.notifier).engine;
    _analyzer.poll(engine.playerIds, stereo: look.stereo, track: p.current?.id);
    // The equalizer runs after the measurement: add its curve so the bars show its effect.
    final preamp = eq.gains.fold<double>(0, math.max);
    final boost = eq.enabled ? (double hz) => equalizerGainAt(eq.gains, hz) - preamp : null;
    final f = _analyzer.tick(dt, vuRef: _vuRef(p, look), boost: boost);
    _frame.value = f;
    _slowT += dt;
    if (_slowT > 0.12) {
      _slowT = 0;
      _slow.value = f;
    }
    final pos = engine.position;
    final dur = engine.duration ?? Duration(milliseconds: ((p.current?.duration ?? 0) * 1000).round());
    _position.value = pos;
    _progress.value = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0;
  }

  void _scheduleRandom(GalacticLook look) {
    _random?.cancel();
    if (!look.random) return;
    _random = Timer.periodic(Duration(seconds: look.randomSeconds), (_) {
      final current = ref.read(galacticLookProvider);
      if (!current.random) return;
      final others = VizStyle.values.where((s) => s != current.style).toList();
      ref.read(galacticLookProvider.notifier).pick(others[math.Random().nextInt(others.length)], fromRandom: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(galacticLookProvider);
    ref.listen(galacticLookProvider.select((l) => (l.random, l.randomSeconds)), (_, _) => _scheduleRandom(ref.read(galacticLookProvider)));
    if (_random == null && look.random) _scheduleRandom(look);
    final t = GText.of(context);
    // Colours glide to the new style's palette (the page itself stays, so lists keep their state).
    return TweenAnimationBuilder<GPalette>(
      tween: _PalTween(end: look.style.palette),
      duration: const Duration(milliseconds: 1200),
      builder: (context, pal, _) {
        return _PalScope(
          pal: pal,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: G.bg,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, c) => c.maxWidth > c.maxHeight
                        ? _landscape(context, t, look, c)
                        : _portrait(context, t, look, c),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _spectrum(BuildContext context, GText t, GalacticLook look) {
    final pal = _PalScope.of(context);
    final track = ref.watch(playerProvider.select((p) => p.current));
    var dx = 0.0;
    return GestureDetector(
      onHorizontalDragStart: (_) => dx = 0,
      onHorizontalDragUpdate: (d) => dx += d.delta.dx,
      onHorizontalDragEnd: (_) {
        if (dx.abs() > 60) ref.read(galacticLookProvider.notifier).next(dx < 0 ? 1 : -1);
      },
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (look.cover && track != null)
              Opacity(
                opacity: .38,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(width: 300, height: 300, child: CoverImage(albumId: track.album.id, radius: 0)),
                  ),
                ),
              ),
            CustomPaint(
              painter: SpectrumPainter(
                frame: _frame,
                style: look.style,
                pal: pal,
                curve: look.curve,
                stereo: look.stereo,
                outline: look.outline,
                yTitle: t.axisLevel,
                xTitle: t.axisFreq,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rightColumn(BuildContext context, GText t, GalacticLook look, {required bool landscape}) => Column(
    children: [
      Expanded(child: _VuCard(frame: _frame, slow: _slow, vuRef: _vuRef(ref.watch(playerProvider), look))),
      if (!landscape) ...[const SizedBox(height: 5), SizedBox(height: 74, child: _WaveCard(progress: _progress, slow: _slow))],
      const SizedBox(height: 5),
      SizedBox(
        height: landscape ? 40 : 44,
        child: _GCard(padding: 3, child: CustomPaint(painter: StereoBarsPainter(_frame, _PalScope.of(context)), size: Size.infinite)),
      ),
    ],
  );

  Widget _portrait(BuildContext context, GText t, GalacticLook look, BoxConstraints c) {
    final specH = (c.maxHeight * 0.17).clamp(110.0, 240.0);
    return Column(
      children: [
        _Header(onSettings: () => _showSettings(context)),
        const SizedBox(height: 5),
        _GCard(
          child: Column(
            children: [
              SizedBox(height: specH, child: _spectrum(context, t, look)),
              const SizedBox(height: 3),
              const _StyleChips(),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 44, child: _GCard(padding: 2, child: CustomPaint(painter: SideMeterPainter(_frame, _PalScope.of(context)), size: Size.infinite))),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  children: [
                    const _EqPanel(),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(child: _QueuePanel()),
                          const SizedBox(width: 5),
                          Expanded(child: _rightColumn(context, t, look, landscape: false)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _PlayerBar(position: _position, wide: false),
      ],
    );
  }

  /// Landscape: the spectrum gets the large area on the left (the equalizer opens over it), the waveform below it;
  /// a slim L/R meter; on the right VU + loudness above the queue.
  Widget _landscape(BuildContext context, GText t, GalacticLook look, BoxConstraints c) => Column(
    children: [
      _Header(onSettings: () => _showSettings(context), compact: true),
      const SizedBox(height: 4),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 60,
              child: Column(
                children: [
                  Expanded(
                    child: _GCard(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Column(
                            children: [
                              Expanded(child: _spectrum(context, t, look)),
                              const SizedBox(height: 3),
                              const _StyleChips(singleRow: true),
                            ],
                          ),
                          if (_eqOverlay)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SingleChildScrollView(
                                child: _EqPanel(overlay: true, onClose: () => setState(() => _eqOverlay = false)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 64,
                    child: _WaveCard(
                      progress: _progress,
                      slow: _slow,
                      eqOpen: _eqOverlay,
                      onEq: () => setState(() => _eqOverlay = !_eqOverlay),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 34,
              child: _GCard(padding: 2, child: CustomPaint(painter: SideMeterPainter(_frame, _PalScope.of(context), compact: true), size: Size.infinite)),
            ),
            const SizedBox(width: 5),
            Expanded(flex: 40, child: _landscapeRight(context, look)),
          ],
        ),
      ),
      const SizedBox(height: 4),
      _PlayerBar(position: _position, wide: true),
    ],
  );

  /// Right column in landscape. On phones (little height) the VU card gets a compact loudness block and the
  /// stereo bars are left out (the L/R meter beside it shows the same levels), so the queue keeps a few rows.
  Widget _landscapeRight(BuildContext context, GalacticLook look) => LayoutBuilder(
    builder: (context, c) {
      final roomy = c.maxHeight >= 330;
      final vuH = roomy ? c.maxHeight * .5 : (c.maxHeight * .54).clamp(120.0, 230.0);
      return Column(
        children: [
          SizedBox(height: vuH, child: _VuCard(frame: _frame, slow: _slow, vuRef: _vuRef(ref.watch(playerProvider), look), compact: !roomy)),
          if (roomy) ...[
            const SizedBox(height: 5),
            SizedBox(
              height: 40,
              child: _GCard(padding: 3, child: CustomPaint(painter: StereoBarsPainter(_frame, _PalScope.of(context)), size: Size.infinite)),
            ),
          ],
          const SizedBox(height: 5),
          const Expanded(child: _QueuePanel(compact: true)),
        ],
      );
    },
  );

  void _showSettings(BuildContext context) {
    final t = GText.of(context);
    final pal = _PalScope.peek(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: G.card,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final look = ref.watch(galacticLookProvider);
          final ctrl = ref.read(galacticLookProvider.notifier);
          return _PalScope(
            pal: pal,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _txt(t.settings, 20, G.text, FontWeight.w700),
                    const SizedBox(height: 12),
                    _SettingRow(title: t.whatsNew, onTap: () => _showNews(context)),
                    const SizedBox(height: 14),
                    _txt(t.randomEvery, 12, G.dim, FontWeight.w600),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final s in const [4, 8, 15, 30, 60])
                        _Pill('$s s', selected: look.randomSeconds == s, onTap: () => ctrl.set(look.copyWith(randomSeconds: s))),
                    ]),
                    const SizedBox(height: 14),
                    _txt(t.vuCal, 12, G.dim, FontWeight.w600),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final v in const [0, -20, -18, -16, -14, -12])
                        _Pill(v == 0 ? t.vuAuto : '$v dBFS', selected: look.vuRef == v, onTap: () => ctrl.set(look.copyWith(vuRef: v))),
                    ]),
                    const SizedBox(height: 14),
                    _txt(t.swipeHint, 11, G.dim, FontWeight.w500, maxLines: 3),
                    const SizedBox(height: 6),
                    _txt(t.eqNote, 11, G.faint, FontWeight.w500, maxLines: 4),
                    const SizedBox(height: 6),
                    _txt(t.about, 11, G.faint, FontWeight.w500, maxLines: 5),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- What's new (Galactic)

Future<void> _showNews(BuildContext context) async {
  final t = GText.of(context);
  final raw = await rootBundle.loadString('assets/galactic_changelog.json');
  final entries = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  if (!context.mounted) return;
  final pal = _PalScope.peek(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: G.bg,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(child: _txt(t.whatsNew, 24, G.text, FontWeight.w700)),
                  TextButton(onPressed: () => Navigator.pop(context), child: _txt(t.done, 15, pal.accent, FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  for (final e in entries)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: G.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: G.cardEdge),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _txt('${e['title']}', 16, pal.accent, FontWeight.w700),
                          const SizedBox(height: 6),
                          for (final item in (e[t.de ? 'de' : 'en'] as List).cast<String>())
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _txt('•', 14, G.dim, FontWeight.w500),
                                  const SizedBox(width: 8),
                                  Expanded(child: _txt(item, 14, G.text.withValues(alpha: .88), FontWeight.w400, maxLines: 6)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- building blocks

class _PalScope extends InheritedWidget {
  const _PalScope({required this.pal, required super.child});
  final GPalette pal;

  static GPalette of(BuildContext context) => maybeOf(context) ?? VizStyle.fab2m.palette;
  static GPalette? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_PalScope>()?.pal;

  /// For callbacks outside build: reads without depending.
  static GPalette peek(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PalScope>()?.pal ?? VizStyle.fab2m.palette;

  @override
  bool updateShouldNotify(_PalScope old) => old.pal != pal;
}

Text _txt(String s, double size, Color color, FontWeight weight, {int maxLines = 1}) => Text(
  s,
  maxLines: maxLines,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(fontFamily: galacticFont, fontSize: size, color: color, fontWeight: weight, height: 1.15),
);

class _GCard extends StatelessWidget {
  const _GCard({required this.child, this.padding = 6});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: G.card,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: G.cardEdge),
    ),
    child: child,
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.selected = false, this.badge, this.icon, required this.onTap});
  final String text;
  final bool selected;
  final String? badge;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = _PalScope.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? pal.accent.withValues(alpha: .22) : G.chip,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? pal.accent : G.chipEdge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 11, color: selected ? pal.accent : G.text), const SizedBox(width: 4)],
            _txt(text, 10, G.text.withValues(alpha: selected ? 1 : .85), FontWeight.w600),
            if (badge != null) ...[const SizedBox(width: 3), _txt(badge!, 8, G.faint, FontWeight.w500)],
          ],
        ),
      ),
    );
  }
}

class _GIconButton extends StatelessWidget {
  const _GIconButton(this.icon, {required this.onTap, this.size = 20, this.color = G.text, this.selected = false});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final pal = _PalScope.of(context);
    final box = math.max(size + 18, 40.0);
    return InkResponse(
      onTap: onTap,
      radius: box / 2,
      child: Container(
        width: box,
        height: box,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? pal.accent.withValues(alpha: .14) : null),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: G.tile, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [Expanded(child: _txt(title, 14, G.text, FontWeight.w600)), const Icon(Icons.chevron_right, color: G.dim)]),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings, this.compact = false});
  final VoidCallback onSettings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pal = _PalScope.of(context);
    final size = compact ? 16.0 : 19.0;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (r) => LinearGradient(colors: [pal.accent2, pal.accent, pal.low]).createShader(r),
          child: _txt('Resonance Galactic ', size, Colors.white, FontWeight.w700),
        ),
        _txt('Player', size, G.text, FontWeight.w700),
      ],
    );
    final sub = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _txt('BY TJMJS', 9, G.dim, FontWeight.w600),
        Container(margin: const EdgeInsets.symmetric(horizontal: 6), width: 1, height: 9, color: G.faint),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (_, s) => _txt(s.hasData ? 'v${s.data!.version} · Build ${s.data!.buildNumber}' : '', 9, pal.accent, FontWeight.w600),
        ),
      ],
    );
    return Row(
      children: [
        _GIconButton(Icons.keyboard_arrow_down, onTap: () => context.pop(), size: 26),
        Expanded(
          child: compact
              ? Row(children: [Flexible(child: title), const SizedBox(width: 12), sub])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, sub]),
        ),
        _GIconButton(Icons.settings, onTap: onSettings, size: 20, color: G.text.withValues(alpha: .85)),
      ],
    );
  }
}

class _StyleChips extends ConsumerWidget {
  const _StyleChips({this.singleRow = false});
  final bool singleRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(galacticLookProvider);
    final ctrl = ref.read(galacticLookProvider.notifier);
    final t = GText.of(context);
    Widget row(List<Widget> children) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [for (final c in children) Padding(padding: const EdgeInsets.only(right: 4), child: c)]),
    );
    final styles = [
      for (final s in VizStyle.values)
        _Pill(s.label, badge: s.key, selected: look.style == s && !look.random, onTap: () => ctrl.pick(s)),
    ];
    final toggles = [
      _Pill(t.curve, selected: look.curve, onTap: () => ctrl.set(look.copyWith(curve: !look.curve))),
      _Pill(t.stereo, selected: look.stereo, onTap: () => ctrl.set(look.copyWith(stereo: !look.stereo))),
      _Pill(t.outline, selected: look.outline, onTap: () => ctrl.set(look.copyWith(outline: !look.outline))),
      _Pill(t.cover, selected: look.cover, onTap: () => ctrl.set(look.copyWith(cover: !look.cover))),
      _Pill(t.random, icon: Icons.auto_awesome, selected: look.random, onTap: () => ctrl.set(look.copyWith(random: !look.random))),
    ];
    if (singleRow) {
      return row([...styles, Container(width: 1, height: 18, color: G.cardEdge), ...toggles]);
    }
    return Column(children: [row(styles), const SizedBox(height: 4), row(toggles)]);
  }
}

// ---------------------------------------------------------------- Equalizer (Resonance's own)

String _presetName(String key, GText t) => switch (key) {
  'flat' => t.de ? 'Linear' : 'Flat',
  'bass' => 'Bass Boost',
  'treble' => 'Treble Boost',
  'vocal' => 'Vocal',
  'rock' => 'Rock',
  'pop' => 'Pop',
  'hiphop' => 'Hip-Hop',
  'electronic' => 'Electro',
  'acoustic' => 'Acoustic',
  'loudness' => 'Loudness',
  _ => t.eqCustom,
};

/// Shape of the equalizer: bell curves per band in log frequency (like the bars' boost).
List<double> _eqResponse(EqualizerSettings eq, int points) {
  if (!eq.enabled) return List.filled(points, 0);
  return [
    for (var i = 0; i < points; i++)
      () {
        final f = 20 * math.pow(1000, i / (points - 1));
        var sum = 0.0;
        for (var b = 0; b < equalizerFrequencies.length; b++) {
          final d = math.log(f / equalizerFrequencies[b]) / math.ln2;
          sum += eq.gains[b] * math.exp(-d * d / (2 * .42 * .42));
        }
        return sum.clamp(-12.0, 12.0);
      }(),
  ];
}

class _EqPanel extends ConsumerWidget {
  const _EqPanel({this.overlay = false, this.onClose});

  /// Over the spectrum (landscape): sliders always shown, a close button instead of "Sliders".
  final bool overlay;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = _PalScope.of(context);
    final t = GText.of(context);
    final eq = ref.watch(equalizerProvider);
    final eqCtrl = ref.read(equalizerProvider.notifier);
    final look = ref.watch(galacticLookProvider);
    final lookCtrl = ref.read(galacticLookProvider.notifier);
    const labels = ['31', '62', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];
    final open = overlay || look.eqOpen;
    return _GCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _PresetMenu(),
              const SizedBox(width: 5),
              _Pill(eq.enabled ? t.eqOn : t.eqOff, selected: eq.enabled, onTap: () => eqCtrl.set(eq.copyWith(enabled: !eq.enabled))),
              const SizedBox(width: 5),
              _Pill(t.eqReset, onTap: () => eqCtrl.set(eq.withPreset('flat'))),
              const Spacer(),
              if (overlay)
                _GIconButton(Icons.close, size: 16, color: G.dim, onTap: onClose)
              else
                _Pill(t.eqSliders, icon: look.eqOpen ? Icons.expand_less : Icons.expand_more, selected: look.eqOpen,
                    onTap: () => lookCtrl.set(look.copyWith(eqOpen: !look.eqOpen))),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: overlay ? null : () => lookCtrl.set(look.copyWith(eqOpen: !look.eqOpen)),
            child: SizedBox(height: 26, child: CustomPaint(painter: EqCurvePainter(_eqResponse(eq, 120), pal), size: Size.infinite)),
          ),
          if (open) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                for (var i = 0; i < 10; i++)
                  Expanded(
                    child: Column(
                      children: [
                        _txt(_gainText(eq.gains[i]), 9, eq.gains[i] != 0 ? pal.accent : G.dim, FontWeight.w600),
                        _VSlider(
                          value: eq.gains[i],
                          onChanged: (v) => eqCtrl.set(eq.withGain(i, v).copyWith(enabled: true)),
                        ),
                        _txt(labels[i], 8, G.dim, FontWeight.w600),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _gainText(double v) {
    if (v == v.roundToDouble()) return v > 0 ? '+${v.toInt()}' : '${v.toInt()}';
    return v > 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);
  }
}

/// The equalizer's preset (Linear, Bass Boost, …) as a small drop-down.
class _PresetMenu extends ConsumerWidget {
  const _PresetMenu({this.small = false});
  final bool small;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GText.of(context);
    final eq = ref.watch(equalizerProvider);
    final eqCtrl = ref.read(equalizerProvider.notifier);
    return PopupMenuButton<String>(
      color: G.card,
      onSelected: (key) => eqCtrl.set(eq.withPreset(key).copyWith(enabled: true)),
      itemBuilder: (_) => [
        for (final key in equalizerPresets.keys)
          PopupMenuItem(value: key, child: _txt(_presetName(key, t), 13, G.text, FontWeight.w500)),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 3 : 4),
        decoration: BoxDecoration(color: G.chip, borderRadius: BorderRadius.circular(6), border: Border.all(color: G.chipEdge)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _txt(eq.enabled || !small ? _presetName(eq.preset, t) : t.eqOff, small ? 9 : 10, G.text, FontWeight.w600),
          const SizedBox(width: 3),
          Icon(Icons.expand_more, size: small ? 11 : 13, color: G.text),
        ]),
      ),
    );
  }
}

class _VSlider extends StatelessWidget {
  const _VSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = _PalScope.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        const h = 52.0, pad = 6.0;
        double toValue(double y) => ((12 - ((y - pad) / (h - 2 * pad)).clamp(0.0, 1.0) * 24) * 2).round() / 2;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) => onChanged(toValue(d.localPosition.dy)),
          onVerticalDragUpdate: (d) => onChanged(toValue(d.localPosition.dy)),
          onDoubleTap: () => onChanged(0),
          child: SizedBox(
            width: c.maxWidth,
            height: h,
            child: CustomPaint(painter: _VSliderPainter(value, pal)),
          ),
        );
      },
    );
  }
}

class _VSliderPainter extends CustomPainter {
  _VSliderPainter(this.value, this.pal);
  final double value;
  final GPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 6.0;
    final cx = size.width / 2;
    final h = size.height - 2 * pad;
    double y(double v) => pad + (12 - v) / 24 * h;
    canvas.drawRRect(RRect.fromLTRBR(cx - 1.5, pad, cx + 1.5, pad + h, const Radius.circular(2)), Paint()..color = Colors.white.withValues(alpha: .08));
    final y0 = y(0), yv = y(value);
    canvas.drawRect(Rect.fromLTRB(cx - 1.5, math.min(y0, yv), cx + 1.5, math.max(y0, yv)), Paint()..color = pal.accent.withValues(alpha: .55));
    const tw = 14.0, th = 7.0;
    canvas.drawRRect(RRect.fromLTRBR(cx - tw / 2 - 2, yv - th / 2 - 2, cx + tw / 2 + 2, yv + th / 2 + 2, const Radius.circular(4)),
        Paint()..color = pal.accent.withValues(alpha: .35));
    canvas.drawRRect(RRect.fromLTRBR(cx - tw / 2, yv - th / 2, cx + tw / 2, yv + th / 2, const Radius.circular(3)), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(cx - tw / 2 + 2, yv - .5, tw - 4, 1), Paint()..color = pal.accent);
  }

  @override
  bool shouldRepaint(_VSliderPainter old) => old.value != value || old.pal != pal;
}

// ---------------------------------------------------------------- Queue

class _QueuePanel extends ConsumerStatefulWidget {
  const _QueuePanel({this.compact = false});

  /// Landscape: no filter field, slimmer rows, the queue button floats over the list.
  final bool compact;

  @override
  ConsumerState<_QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends ConsumerState<_QueuePanel> {
  String _filter = '';
  final _scroll = ScrollController();
  int? _scrolledTo;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _time(double seconds) {
    final s = seconds.round();
    return s >= 3600
        ? '${s ~/ 3600}:${(s ~/ 60 % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}'
        : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pal = _PalScope.of(context);
    final t = GText.of(context);
    final p = ref.watch(playerProvider);
    final ctrl = ref.read(playerProvider.notifier);
    final q = _filter.trim().toLowerCase();
    final shown = [
      for (final (i, track) in p.queue.indexed)
        if (q.isEmpty ||
            track.title.toLowerCase().contains(q) ||
            track.artistCredit.toLowerCase().contains(q) ||
            track.album.name.toLowerCase().contains(q))
          (i, track),
    ];
    final total = p.queue.fold<double>(0, (a, b) => a + b.duration);
    final compact = widget.compact;
    final extent = compact ? 36.0 : 44.0;
    // Keep the playing song in view.
    if (p.index != null && p.index != _scrolledTo && q.isEmpty) {
      _scrolledTo = p.index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          final target = (p.index! * extent).clamp(0.0, _scroll.position.maxScrollExtent);
          _scroll.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
    final list = ListView.builder(
      controller: _scroll,
      itemCount: shown.length,
      itemExtent: extent,
      itemBuilder: (_, k) {
        final (i, track) = shown[k];
        final current = i == p.index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () => ctrl.jumpTo(i),
            onLongPress: () => ctrl.removeAt(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: current ? pal.accent.withValues(alpha: .16) : null,
                borderRadius: BorderRadius.circular(5),
                border: current ? Border.all(color: pal.accent.withValues(alpha: .35)) : null,
              ),
              child: Row(
                children: [
                  if (current) ...[
                    Container(width: 2, height: compact ? 18 : 22, color: pal.accent),
                    const SizedBox(width: 3),
                    Icon(Icons.play_arrow, size: 10, color: pal.accent),
                    const SizedBox(width: 3),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _txt(track.title, compact ? 10.5 : 11, current ? pal.accent : G.text, FontWeight.w600),
                        _txt(
                          [if (track.trackNo != null) '${track.trackNo}', track.album.name.isNotEmpty ? track.album.name : track.artistCredit]
                              .join(' · '),
                          compact ? 8.5 : 9, G.dim, FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _txt(_time(track.duration), 9, G.dim, FontWeight.w500),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (compact) {
      // Room for the queue button at the top right; the playing song is scrolled to the top.
      return _GCard(
        padding: 4,
        child: Stack(
          children: [
            if (p.queue.isEmpty)
              Padding(padding: const EdgeInsets.fromLTRB(4, 6, 36, 0), child: _txt(t.empty, 10, G.faint, FontWeight.w500, maxLines: 3)),
            Padding(padding: const EdgeInsets.only(right: 30), child: list),
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                children: [
                  InkResponse(
                    onTap: () => context.push('/queue'),
                    radius: 18,
                    child: SizedBox(width: 28, height: 28, child: Icon(Icons.queue_music, size: 16, color: G.text.withValues(alpha: .85))),
                  ),
                  _txt('${p.queue.length}', 8, G.dim, FontWeight.w600),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _txt('${p.queue.length} · ${_time(total)}', 10, G.dim, FontWeight.w500)),
              _GIconButton(Icons.queue_music, size: 16, onTap: () => context.push('/queue')),
            ],
          ),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: G.cardEdge),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _filter = v),
              cursorColor: pal.accent,
              style: const TextStyle(fontFamily: galacticFont, fontSize: 11, color: G.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: t.filter,
                hintStyle: const TextStyle(fontFamily: galacticFont, fontSize: 10, color: G.faint),
              ),
            ),
          ),
          const SizedBox(height: 5),
          if (p.queue.isEmpty) _txt(t.empty, 10, G.faint, FontWeight.w500, maxLines: 3),
          Expanded(child: list),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- VU + loudness

class _VuCard extends ConsumerWidget {
  const _VuCard({required this.frame, required this.slow, required this.vuRef, this.compact = false});
  final ValueNotifier<GFrame> frame, slow;
  final double vuRef;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = _PalScope.of(context);
    final t = GText.of(context);
    final look = ref.watch(galacticLookProvider);
    final ctrl = ref.read(galacticLookProvider.notifier);
    return _GCard(
      padding: compact ? 5 : 6,
      child: Column(
        children: [
          Row(
            children: [
              _txt('0 VU =', 9, G.dim, FontWeight.w500),
              const SizedBox(width: 4),
              PopupMenuButton<int>(
                color: G.card,
                onSelected: (v) => ctrl.set(look.copyWith(vuRef: v)),
                itemBuilder: (_) => [
                  for (final v in const [0, -20, -18, -16, -14, -12])
                    PopupMenuItem(value: v, child: _txt(v == 0 ? t.vuAuto : '$v dBFS', 13, G.text, FontWeight.w500)),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: G.chip, borderRadius: BorderRadius.circular(5), border: Border.all(color: G.chipEdge)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _txt(look.vuRef == 0 ? 'Auto' : '${look.vuRef} dBFS', 9, G.text, FontWeight.w500),
                    const Icon(Icons.expand_more, size: 11, color: G.text),
                  ]),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(child: _txt('→ ${vuRef.round()} dBFS', 9, pal.accent, FontWeight.w600)),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: CustomPaint(painter: VuPainter(frame, pal, 0), size: Size.infinite)),
                const SizedBox(width: 4),
                Expanded(child: CustomPaint(painter: VuPainter(frame, pal, 1), size: Size.infinite)),
              ],
            ),
          ),
          ValueListenableBuilder<GFrame>(
            valueListenable: slow,
            builder: (context, f, _) => _Loudness(f: f, compact: compact),
          ),
        ],
      ),
    );
  }
}

class _Loudness extends StatelessWidget {
  const _Loudness({required this.f, this.compact = false});
  final GFrame f;

  /// One line for the integrated loudness and its bar, one row of six tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pal = _PalScope.of(context);
    final t = GText.of(context);
    final vsStreaming = f.integrated.isFinite ? f.integrated + 14 : double.negativeInfinity;
    final plr = f.integrated.isFinite && f.maxPeak.isFinite ? f.maxPeak - f.integrated : double.negativeInfinity;
    Widget tile(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(color: G.tile, borderRadius: BorderRadius.circular(6), border: Border.all(color: G.cardEdge)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_txt(label, 8, G.dim, FontWeight.w500), _txt(value, 11, G.text, FontWeight.w700)],
        ),
      ),
    );
    if (compact) {
      Widget small(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: G.tile, borderRadius: BorderRadius.circular(5), border: Border.all(color: G.cardEdge)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_txt(label, 7, G.dim, FontWeight.w500), _txt(value, 9.5, G.text, FontWeight.w700)],
          ),
        ),
      );
      const gap = SizedBox(width: 2);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _txt(gFmt(f.integrated), 16, G.text, FontWeight.w700),
              const SizedBox(width: 3),
              _txt('LUFS', 9, pal.accent, FontWeight.w700),
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 18, child: CustomPaint(painter: LoudnessBarPainter(f.integrated, f.momentary, pal), size: Size.infinite))),
            ],
          ),
          const SizedBox(height: 3),
          Row(children: [
            small(t.momentary, gFmt(f.momentary)),
            gap,
            small(t.shortTerm, gFmt(f.shortTerm)),
            gap,
            small('LRA', '${gFmt(f.lra)} LU'),
            gap,
            small(t.maxPeak, f.maxPeak.isFinite ? '${gFmt(f.maxPeak)} dB' : '–'),
            gap,
            small('PLR', '${gFmt(plr)} LU'),
            gap,
            small('Streaming', '${gFmt(vsStreaming)} dB'),
          ]),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(padding: const EdgeInsets.only(bottom: 3), child: _txt(t.integrated, 10, G.dim, FontWeight.w500)),
            const SizedBox(width: 6),
            _txt(gFmt(f.integrated), 20, G.text, FontWeight.w700),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 3), child: _txt('LUFS', 11, pal.accent, FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(height: 18, child: CustomPaint(painter: LoudnessBarPainter(f.integrated, f.momentary, pal), size: Size.infinite)),
        Row(children: [
          tile(t.momentary, gFmt(f.momentary)),
          const SizedBox(width: 3),
          tile(t.shortTerm, gFmt(f.shortTerm)),
          const SizedBox(width: 3),
          tile(t.lra, '${gFmt(f.lra)} LU'),
        ]),
        const SizedBox(height: 3),
        Row(children: [
          tile(t.maxPeak, f.maxPeak.isFinite ? '${gFmt(f.maxPeak)} dB' : '–'),
          const SizedBox(width: 3),
          tile('PLR', '${gFmt(plr)} LU'),
          const SizedBox(width: 3),
          tile(t.vsStreaming, '${gFmt(vsStreaming)} dB'),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- Waveform

final _envelopes = Expando<List<double>>();

/// The song's level over time, from the server's spectrum (48 dB mapped onto 0–1 per band).
List<double> _envelope(Spectrum s, double seconds) {
  return _envelopes[s] ??= () {
    const slices = 600;
    final levels = List<double>.filled(s.bands, 0);
    final raw = <double>[];
    for (var i = 0; i < slices; i++) {
      s.levelsAt(Duration(microseconds: (seconds * 1e6 * i / slices).round()), levels);
      final mean = levels.fold<double>(0, (a, b) => a + b) / s.bands;
      raw.add(math.pow(10, (mean - 1) * Spectrum.rangeDb / 20).toDouble());
    }
    final top = raw.fold<double>(0, math.max);
    return [for (final v in raw) top <= 0 ? 0.0 : v / top * .9];
  }();
}

class _WaveCard extends ConsumerWidget {
  const _WaveCard({required this.progress, required this.slow, this.eqOpen = false, this.onEq});
  final ValueNotifier<double> progress;
  final ValueNotifier<GFrame> slow;

  /// Landscape: preset and an EQ button at the end of the status line; the equalizer opens over the spectrum.
  final bool eqOpen;
  final VoidCallback? onEq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = _PalScope.of(context);
    final t = GText.of(context);
    final track = ref.watch(playerProvider.select((p) => p.current));
    final spectrum = track == null ? null : ref.watch(spectrumProvider(track.id)).value;
    final seconds = track?.duration ?? 0;
    final env = spectrum == null ? null : _envelope(spectrum, seconds);
    final ctrl = ref.read(playerProvider.notifier);
    void seek(double x, double width) {
      if (seconds <= 0 || width <= 0) return;
      ctrl.seek(Duration(milliseconds: ((x / width).clamp(0.0, 1.0) * seconds * 1000).round()));
    }

    return _GCard(
      padding: 5,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => seek(d.localPosition.dx, c.maxWidth),
                onHorizontalDragUpdate: (d) => seek(d.localPosition.dx, c.maxWidth),
                child: CustomPaint(
                  painter: WaveformPainter(envelope: env, progress: progress, durationSeconds: seconds, pal: pal),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<GFrame>(
                  valueListenable: slow,
                  builder: (context, f, _) {
                    if (track == null) return Align(alignment: Alignment.centerLeft, child: _txt(t.nothing, 8, G.faint, FontWeight.w500));
                    if (!f.truePeak.isFinite) return Align(alignment: Alignment.centerLeft, child: _txt(t.noWave, 8, G.faint, FontWeight.w500));
                    final ok = f.truePeak <= -1;
                    final col = ok ? G.ok : G.warn;
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: col),
                          ),
                          child: _txt(ok ? t.ok : t.over, 8, col, FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _txt(
                            '${t.peak} ${gFmt(f.maxPeak)} · TP ${gFmt(f.truePeak)} dBTP (${t.soFar})',
                            8, G.dim, FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (onEq != null) ...[
                const SizedBox(width: 6),
                const _PresetMenu(small: true),
                const SizedBox(width: 4),
                _Pill('EQ', icon: Icons.tune, selected: eqOpen, onTap: onEq!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Player bar

class _PlayerBar extends ConsumerWidget {
  const _PlayerBar({required this.position, required this.wide});
  final ValueNotifier<Duration> position;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = _PalScope.of(context);
    final t = GText.of(context);
    final p = ref.watch(playerProvider);
    final ctrl = ref.read(playerProvider.notifier);
    final track = p.current;

    final now = Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: track == null
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(colors: [pal.low, pal.high]),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white70),
                )
              : CoverImage(albumId: track.album.id, size: 120, radius: 7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _txt(track?.title ?? t.nothing, 12, G.text, FontWeight.w700),
              if (track != null) _txt(track.artistCredit, 9, G.dim, FontWeight.w500),
            ],
          ),
        ),
      ],
    );

    final transport = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _GIconButton(Icons.shuffle, size: 22, color: p.shuffle ? pal.accent : G.text.withValues(alpha: .7), selected: p.shuffle,
            onTap: p.inJam ? null : ctrl.toggleShuffle),
        _GIconButton(Icons.skip_previous, size: 26, onTap: ctrl.previous),
        GestureDetector(
          onTap: ctrl.togglePlay,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: wide ? 46 : 54,
            height: wide ? 46 : 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [pal.accent2, pal.accent]),
              boxShadow: [BoxShadow(color: pal.accent.withValues(alpha: .5), blurRadius: 14)],
            ),
            child: Icon(p.playing ? Icons.pause : Icons.play_arrow, color: const Color(0xFF0B0B18), size: wide ? 24 : 28),
          ),
        ),
        _GIconButton(Icons.skip_next, size: 26, onTap: ctrl.next),
        _GIconButton(p.loop == LoopMode.one ? Icons.repeat_one : Icons.repeat, size: 22,
            color: p.loop == LoopMode.off ? G.text.withValues(alpha: .7) : pal.accent, selected: p.loop != LoopMode.off,
            onTap: p.inJam ? null : ctrl.cycleLoop),
      ],
    );

    final seek = ValueListenableBuilder<Duration>(
      valueListenable: position,
      builder: (context, pos, _) {
        final dur = (track?.duration ?? 0) * 1000;
        String fmt(int ms) {
          final s = (ms / 1000).floor();
          return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
        }
        return Row(
          children: [
            SizedBox(width: 36, child: _txt(fmt(pos.inMilliseconds), 9, G.dim, FontWeight.w500)),
            Expanded(
              child: _HSlider(
                value: dur > 0 ? pos.inMilliseconds / dur : 0,
                onChanged: (v) => ctrl.seek(Duration(milliseconds: (v * dur).round())),
              ),
            ),
            SizedBox(width: 40, child: Padding(padding: const EdgeInsets.only(left: 6), child: _txt(fmt(dur.round()), 9, G.dim, FontWeight.w500))),
          ],
        );
      },
    );

    final volume = ValueListenableBuilder<double>(
      valueListenable: ctrl.userVolume,
      builder: (context, v, _) => Row(
        children: [
          _GIconButton(v <= 0.001 ? Icons.volume_off : Icons.volume_up, size: 16, color: G.text.withValues(alpha: .8),
              onTap: () => ctrl.setUserVolume(v > 0 ? 0 : 1)),
          Expanded(child: _HSlider(value: v, onChanged: ctrl.setUserVolume)),
        ],
      ),
    );

    return _GCard(
      padding: wide ? 5 : 8,
      child: wide
          ? Row(
              children: [
                Expanded(flex: 30, child: now),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: transport),
                Expanded(flex: 42, child: seek),
                const SizedBox(width: 6),
                SizedBox(width: 120, child: volume),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [Expanded(child: now), const SizedBox(width: 6), SizedBox(width: 96, child: volume)]),
                const SizedBox(height: 2),
                seek,
                transport,
              ],
            ),
    );
  }
}

class _HSlider extends StatelessWidget {
  const _HSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = _PalScope.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        void set(double x) => onChanged((x / c.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => set(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
          child: SizedBox(
            height: 28,
            width: c.maxWidth,
            child: CustomPaint(painter: _HSliderPainter(value.clamp(0.0, 1.0), pal)),
          ),
        );
      },
    );
  }
}

class _HSliderPainter extends CustomPainter {
  _HSliderPainter(this.value, this.pal);
  final double value;
  final GPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    const h = 4.0;
    final y = size.height / 2 - h / 2;
    canvas.drawRRect(RRect.fromLTRBR(0, y, size.width, y + h, const Radius.circular(h / 2)), Paint()..color = Colors.white.withValues(alpha: .22));
    canvas.drawRRect(
      RRect.fromLTRBR(0, y, size.width * value, y + h, const Radius.circular(h / 2)),
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [pal.low, pal.accent]),
    );
    final c = Offset(size.width * value, size.height / 2);
    canvas.drawCircle(c, 7, Paint()..color = pal.accent.withValues(alpha: .35));
    canvas.drawCircle(c, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_HSliderPainter old) => old.value != value || old.pal != pal;
}

class _PalTween extends Tween<GPalette> {
  _PalTween({super.end});

  @override
  GPalette lerp(double t) => GPalette.lerp(begin ?? end!, end!, t);
}
