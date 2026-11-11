import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../l10n/l10n.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/audiobooks.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/library.dart';
import '../../player/player.dart';
import '../../player/spectrum.dart';
import '../../player/visualizer_themes.dart';
import 'audiobook_pages.dart';
import 'podcast_pages.dart';
import '../widgets/catalog.dart';
import '../widgets/credits_sheet.dart';
import '../widgets/collection.dart';
import '../widgets/common.dart';
import '../widgets/player_bar.dart';
import '../widgets/reflection.dart';
import '../widgets/track_list.dart';
import '../widgets/jam_sheet.dart';
import '../widgets/devices_sheet.dart';
import '../../player/jam.dart';

class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((p) => p.current));
    final book = ref.watch(playerProvider.select((p) => p.book));
    final station = ref.watch(playerProvider.select((p) => p.station));
    final stationNow = ref.watch(playerProvider.select((p) => p.stationNow));
    final accent = Theme.of(context).colorScheme.primary;
    // Spoken word always takes the cover's color; music only with the visualizer (whose bars use it too).
    final coverColor = book != null
        ? book.coverUrl.isEmpty
              ? null
              : ref.watch(coverColorProvider(CachedNetworkImageProvider(book.coverUrl))).value
        : track != null && station == null && ref.watch(visualizerEnabledProvider)
        ? ref.watch(coverColorProvider(coverImageProvider(ref, track.album.id, size: 300))).value
        : null;
    final hsl = coverColor == null ? null : HSLColor.fromColor(coverColor);
    final topColor = hsl == null
        ? accent.withValues(alpha: 0.45)
        : hsl
              .withLightness(math.min(hsl.lightness, 0.22))
              .withSaturation(math.min(hsl.saturation, 0.65))
              .withAlpha(1)
              .toColor();
    return Scaffold(
      body: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 600),
        tween: ColorTween(end: topColor),
        builder: (context, color, child) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color!, Palette.background],
              stops: coverColor == null ? null : const [0.0, 0.85],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: station != null
              ? _StationNowPlaying(station: station, now: stationNow)
              : book != null
              ? _BookNowPlaying(book: book)
              : track == null
              ? Center(child: Text(context.l10n.playerNothingPlaying))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Phones in landscape count as wide (about 1000 x 450), so the height decides, not isWide.
                    final landscape = constraints.maxWidth > constraints.maxHeight && constraints.maxHeight < 600;
                    final maxSide = MediaQuery.sizeOf(context).width >= 900 ? 720.0 : 480.0;
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                                      onPressed: () => context.pop(),
                                    ),
                                    Expanded(
                                      child: Text(
                                        track.album.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const DevicesButton(),
                                    const JamButton(),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => showTrackMenu(context, ref, track),
                                    ),
                                  ],
                                ),
                                if (landscape)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                                      child: LayoutBuilder(
                                        builder: (context, available) {
                                          final side = math.min(available.maxHeight, available.maxWidth * 0.45);
                                          return Row(
                                            children: [
                                              SizedBox.square(
                                                dimension: side,
                                                child: TrackCover(track: track, allowReflection: false),
                                              ),
                                              const SizedBox(width: 24),
                                              Expanded(
                                                child: Center(child: _TrackControls(track: track)),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                else ...[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: ref.watch(coverflowProvider)
                                          ? Coverflow(maxSide: maxSide)
                                          : TrackCover(track: track, maxSide: maxSide),
                                    ),
                                  ),
                                  _TrackControls(track: track),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                        ),
                        _LyricsCard(trackId: track.id),
                        if (!ref.watch(sessionProvider.select((s) => s.offline))) CreditsCard(track: track),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _TrackControls extends ConsumerWidget {
  const _TrackControls({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TrackTitle(
                          track: track,
                          smart: ref.watch(playerProvider.select((p) => p.smartIds.contains(track.id))),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const AutomixChip(),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      context.pop();
                      context.push('/artist/${track.artist.id}');
                    },
                    child: Text(
                      track.artistCredit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Palette.textMuted, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            LikeButton(track: track, size: 28),
          ],
        ),
        const SizedBox(height: 12),
        const SeekBar(),
        const SizedBox(height: 8),
        const TransportControls(big: true),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SleepTimerButton(),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
              IconButton(
                tooltip: 'Galactic',
                icon: const Icon(Icons.graphic_eq),
                onPressed: () => context.push('/galactic'),
              ),
            IconButton(
              tooltip: context.l10n.lyricsTitle,
              icon: const Icon(Icons.lyrics_outlined),
              onPressed: () => context.push('/lyrics'),
            ),
            IconButton(
              tooltip: context.l10n.playerQueue,
              icon: const Icon(Icons.queue_music),
              onPressed: () => context.push('/queue'),
            ),
          ],
        ),
      ],
    ),
  );
}

class TrackCover extends ConsumerWidget {
  const TrackCover({
    super.key,
    required this.track,
    this.centered = true,
    this.allowReflection = true,
    this.dim = 0,
    this.interactive = true,
    this.maxSide = 480,
    this.flip = 0,
    this.back,
    this.onTap,
  });
  final Track track;
  final bool centered;
  final bool allowReflection;
  final double dim;
  final bool interactive;
  final double maxSide;

  /// How far the cover has turned over, 0 (front) to 1 (showing [back]).
  final double flip;
  final Widget? back;

  /// Replaces the tap that toggles the visualizer's peaks; the peaks then move to a long press.
  final VoidCallback? onTap;

  static double sideFor(BoxConstraints constraints, bool reflect, {double maxSide = 480}) {
    final height = reflect ? (constraints.maxHeight - 3) / 1.22 : constraints.maxHeight;
    return math.max(0.0, math.min(math.min(constraints.maxWidth, maxSide), height));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(visualizerThemeProvider);
    final enabled = ref.watch(visualizerEnabledProvider) && centered && flip == 0;
    final showsBack = back != null && flip > 0.5;
    final VoidCallback? togglePeaks = theme.peaks
        ? () {
            final peaks = !ref.read(visualizerPeaksProvider);
            ref.read(visualizerPeaksProvider.notifier).set(peaks);
            showInfo(context, peaks ? context.l10n.visualizerPeaksOn : context.l10n.visualizerPeaksOff);
          }
        : null;
    final reflect = ref.watch(visualizerReflectionProvider) && allowReflection;
    Widget artwork() => Stack(
      fit: StackFit.expand,
      children: [
        CoverImage(albumId: track.album.id, size: 600, radius: 8),
        if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = sideFor(constraints, reflect, maxSide: maxSide);
        final reflection = reflect ? size * 0.22 : 0.0;
        return Center(
          child: SizedBox(
            width: size,
            height: size + (reflect ? 3 + reflection : 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (reflect)
                  Positioned(
                    top: size + 3,
                    left: 0,
                    right: 0,
                    child: CoverReflection(
                      child: _turned(showsBack ? const ColoredBox(color: Palette.card) : artwork()),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size,
                  child: GestureDetector(
                    onTap: interactive && centered ? onTap ?? togglePeaks : null,
                    onLongPress: interactive && centered && onTap != null ? togglePeaks : null,
                    child: showsBack
                        ? _turned(
                            Material(
                              elevation: 16,
                              color: Palette.background,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: back,
                            ),
                          )
                        : _turned(
                            Stack(
                              fit: StackFit.expand,
                              clipBehavior: Clip.none,
                              children: [
                                Material(
                                  elevation: 16,
                                  borderRadius: BorderRadius.circular(8),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      artwork(),
                                      if (enabled)
                                        Positioned(
                                          top: size * 0.6,
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: const DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Color(0x00000000), Color(0x8C000000)],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (enabled)
                                  Positioned(
                                    top: size * 0.6 + 24,
                                    height: math.max(0.0, size * 0.4 - 24),
                                    left: 12,
                                    right: 12,
                                    child: _CoverVisualizer(track: track, reflection: reflection),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Turns [child] about its vertical axis; past halfway the back side turns the rest of the way in, unmirrored.
  /// Halfway it also sinks back a little, as if lifted off and turned in the hand.
  Widget _turned(Widget child) {
    if (flip == 0) return child;
    final depth = 1 - 0.1 * math.sin(math.pi * flip);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(math.pi * (flip > 0.5 ? flip - 1 : flip))
        ..scaleByDouble(depth, depth, depth, 1),
      child: child,
    );
  }
}

class Coverflow extends ConsumerStatefulWidget {
  const Coverflow({super.key, this.interactive = true, this.maxSide = 480});
  final bool interactive;
  final double maxSide;

  @override
  ConsumerState<Coverflow> createState() => _CoverflowState();
}

class _CoverflowState extends ConsumerState<Coverflow> with TickerProviderStateMixin {
  late final AnimationController _position;
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  List<String> _queue = const [];
  int? _index;
  int _generation = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this, value: (ref.read(playerProvider).index ?? 0).toDouble());
  }

  Future<void> _snapTo(int index, {bool select = false}) async {
    final generation = ++_generation;
    try {
      await _position
          .animateTo(index.toDouble(), duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic)
          .orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || generation != _generation || !select) return;
    final player = ref.read(playerProvider);
    if (index != player.index && index >= 0 && index < player.queue.length) {
      ref.read(playerProvider.notifier).jumpTo(index);
    }
  }

  void _release(double velocity) {
    final last = ref.read(playerProvider).queue.length - 1;
    if (last < 0) return;
    var target = _position.value.round();
    if (velocity.abs() > 600) {
      target = velocity < 0 ? (_position.value + 1).floor() : (_position.value - 1).ceil();
    }
    _snapTo(target.clamp(0, last), select: true);
  }

  void _toggleFlip() => _flip.isForwardOrCompleted ? _flip.reverse() : _flip.forward();

  /// Plays a song from the album on the cover's back: inside the album's own queue it only jumps there.
  void _playFromAlbum(AlbumDetail album, int index) {
    final player = ref.read(playerProvider);
    final contextId = 'album:${album.album.id}';
    final queued = player.context == contextId
        ? player.queue.indexWhere((track) => track.id == album.tracks[index].id)
        : -1;
    if (queued >= 0) {
      ref.read(playerProvider.notifier).jumpTo(queued);
    } else {
      playMusic(context, ref, album.tracks, index: index, contextId: contextId);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider.select((p) => (queue: p.queue, index: p.index)));
    final reflect = ref.watch(visualizerReflectionProvider);
    final index = player.index;
    final validIndex = index != null && index >= 0 && index < player.queue.length;
    final queueChanged =
        _queue.length != player.queue.length || (validIndex && _queue[index] != player.queue[index].id);
    if (validIndex && (queueChanged || index != _index)) {
      // Another song turns the cover face up again.
      if (_index != null) _flip.value = 0;
      if (queueChanged) {
        _generation++;
        _position.value = index.toDouble();
      } else {
        _snapTo(index);
      }
    }
    _queue = [for (final track in player.queue) track.id];
    _index = index;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The centered cover is a bit smaller than without coverflow so the tilted neighbors fit beside it; they
        // reach out to the screen edges, past the page padding.
        final large = widget.maxSide > 480;
        final side = TrackCover.sideFor(constraints, reflect, maxSide: widget.maxSide) * (large ? 0.85 : 0.78);
        final height = side + (reflect ? 3 + side * 0.22 : 0);
        // Neighbors spread beside the cover, but never past the screen edge.
        final spread = math.max(
          0.0,
          math.min(side * (large ? 0.35 : 0.25), MediaQuery.sizeOf(context).width / 2 - 4 - side / 2),
        );
        final flow = GestureDetector(
          key: const ValueKey('coverflow'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: widget.interactive
              ? (_) {
                  _dragging = true;
                  _generation++;
                  _position.stop();
                  _flip.reverse();
                }
              : null,
          onHorizontalDragUpdate: widget.interactive
              ? (details) {
                  if (side <= 0 || player.queue.isEmpty) return;
                  _position.value = (_position.value - details.delta.dx / (0.42 * side)).clamp(
                    0.0,
                    player.queue.length - 1.0,
                  );
                }
              : null,
          onHorizontalDragEnd: widget.interactive
              ? (details) {
                  _dragging = false;
                  _release(details.velocity.pixelsPerSecond.dx);
                }
              : null,
          // Taps lose the arena to the cover and the songs on its back and cancel here too; only a started drag
          // snaps, or it would jump back to the song a tap just picked.
          onHorizontalDragCancel: widget.interactive
              ? () {
                  if (!_dragging) return;
                  _dragging = false;
                  _release(0);
                }
              : null,
          child: AnimatedBuilder(
            animation: _position,
            builder: (context, child) {
              final position = _position.value;
              final centered = position.round();
              final first = math.max(0, (position - 2).ceil());
              final last = math.min(player.queue.length - 1, (position + 2).floor());
              final visible = [for (var i = first; i <= last; i++) i]
                ..sort((a, b) {
                  final distance = (b - position).abs().compareTo((a - position).abs());
                  if (distance != 0 || a == b) return distance;
                  if (a == centered) return 1;
                  if (b == centered) return -1;
                  return a.compareTo(b);
                });
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final i in visible)
                    Positioned(
                      key: ValueKey('coverflow-cover-$i'),
                      left: (constraints.maxWidth - side) / 2,
                      top: (constraints.maxHeight - height) / 2,
                      width: side,
                      height: height,
                      child: _transformedCover(
                        player.queue[i],
                        i - position,
                        i == centered,
                        side,
                        height,
                        spread,
                        widget.maxSide,
                      ),
                    ),
                ],
              );
            },
          ),
        );
        return widget.interactive ? flow : IgnorePointer(child: flow);
      },
    );
  }

  Widget _transformedCover(
    Track track,
    double delta,
    bool centered,
    double side,
    double height,
    double spread,
    double maxSide,
  ) {
    final distance = delta.abs();
    final flips = centered && widget.interactive && ref.watch(coverflowFlipProvider);
    Widget cover(double flip) => TrackCover(
      track: track,
      centered: centered,
      dim: 0.35 * math.min(distance, 1.0),
      maxSide: maxSide,
      interactive: widget.interactive,
      flip: flip,
      back: flips ? _AlbumBack(track: track, onClose: _toggleFlip, onPlay: _playFromAlbum) : null,
      onTap: flips ? _toggleFlip : null,
    );
    final tilt = delta.clamp(-1.0, 1.0);
    // Neighbors shrink to 60 % so their near edge, which the tilt brings towards the viewer, stays below the
    // centered cover's height.
    final scale = 1 - 0.40 * math.min(distance, 1.0);
    final x = distance < 1 ? delta * spread : delta.sign * (spread + 0.2 * side * (distance - 1));
    return Transform.translate(
      offset: Offset(x, 0),
      child: Transform(
        // Move the pivot continuously from the center to the neighbor's outer edge.
        alignment: Alignment(tilt, height > 0 ? -(height - side) / height : 0),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(-tilt * 1.05)
          ..scaleByDouble(scale, scale, scale, 1),
        child: IgnorePointer(
          ignoring: !centered,
          child: flips
              ? AnimatedBuilder(
                  animation: _flip,
                  builder: (context, _) => cover(Curves.easeInOutCubic.transform(_flip.value)),
                )
              : cover(0),
        ),
      ),
    );
  }
}

class _StationNowPlaying extends StatelessWidget {
  const _StationNowPlaying({required this.station, this.now});
  final Station station;
  final StationNowPlaying? now;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 32), onPressed: () => context.pop()),
            Expanded(child: Text(context.l10n.worldRadioTitle, textAlign: TextAlign.center)),
            const SizedBox(width: 48),
          ],
        ),
        const Spacer(),
        if (now?.coverUrl != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: NetworkCover(url: station.favicon, radius: 4, icon: Icons.radio),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Flexible(
          flex: 5,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 480),
            child: NetworkCover(url: now?.coverUrl ?? station.favicon, radius: 8, icon: Icons.radio),
          ),
        ),
        const Spacer(),
        Text(
          now?.title ?? station.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (now?.title != null) ...[
          if (now!.artistYear.isNotEmpty) Text(now!.artistYear, style: const TextStyle(color: Palette.textMuted)),
          Text(station.name, style: const TextStyle(color: Palette.textMuted, fontSize: 12)),
        ] else
          Text(
            '${context.l10n.worldRadioTitle} · ${station.country}',
            style: const TextStyle(color: Palette.textMuted),
          ),
        const SizedBox(height: 16),
        const LiveBadge(),
        const SizedBox(height: 16),
        const TransportControls(big: true),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class _LyricsCard extends ConsumerWidget {
  const _LyricsCard({required this.trackId});
  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(lyricsProvider(trackId));
    final lyrics = value.isLoading || value.hasError ? null : value.value;
    if (lyrics == null || lyrics.lines.isEmpty) return const SizedBox.shrink();
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final current = lyrics.synced ? lyrics.lines.lastIndexWhere((line) => line.timeMs! <= position.inMilliseconds) : -1;
    final start = current < 0 ? 0 : current;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Material(
        color: Color.alphaBlend(Colors.black.withValues(alpha: 0.55), accent),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/lyrics'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.lyricsTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/lyrics'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      icon: const Icon(Icons.open_in_full, size: 16),
                      label: Text(context.l10n.lyricsExpand),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = start; i < lyrics.lines.length && i < start + 8; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      lyrics.lines[i].text.isEmpty ? '♪' : lyrics.lines[i].text,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: !lyrics.synced || i == current ? Colors.white : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookNowPlaying extends ConsumerWidget {
  const _BookNowPlaying({required this.book});
  final BookPlayback book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final position = ref.watch(bookPositionProvider);
    final speed = ref.watch(playerProvider.select((p) => p.speed));
    final ctrl = ref.read(playerProvider.notifier);
    final chapter = book.chapterAt(position);
    final chapterIndex = chapter == null ? -1 : book.chapters.indexOf(chapter);
    final episode = book.episode;
    final remaining = math.max(0.0, book.duration - position);
    final speedText = '${NumberFormat(speed == speed.roundToDouble() ? '0' : '0.0#', l10n.localeName).format(speed)}×';
    void previousChapter() {
      if (chapter == null) return;
      // Like a CD player: back to this chapter's start, or to the previous one when just started.
      final target = position - chapter.start > 3 || chapterIndex == 0
          ? chapter.start
          : book.chapters[chapterIndex - 1].start;
      ctrl.seekBook(target);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phones in landscape: cover on the left, controls on the right, like the music player.
        final landscape = constraints.maxWidth > constraints.maxHeight && constraints.maxHeight < 600;
        final short = landscape || constraints.maxHeight < 700;
        final cover = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 440),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 18))],
              ),
              child: NetworkCover(
                url: book.coverUrl.isEmpty ? null : book.coverUrl,
                radius: 14,
                icon: episode != null ? Icons.podcasts : Icons.headphones,
              ),
            ),
          ),
        );
        final controls = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (book.author != null && episode == null)
                Text(
                  book.author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Palette.textMuted, fontSize: 16),
                ),
              if (chapter != null) ...[
                SizedBox(height: short ? 10 : 16),
                _ChapterCard(book: book, chapter: chapter, index: chapterIndex, position: position, speed: speed),
              ],
              SizedBox(height: short ? 6 : 12),
              const SeekBar(),
              Center(
                child: Text(
                  [
                    l10n.audiobooksTimeRemaining(formatRemaining(l10n, remaining / speed)),
                    if (speed != 1) l10n.playerAtSpeed(speedText),
                  ].join(' '),
                  style: const TextStyle(color: Palette.textMuted, fontSize: 12.5),
                ),
              ),
              SizedBox(height: short ? 4 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (book.chapters.isNotEmpty)
                    IconButton(
                      tooltip: l10n.audiobooksPreviousChapter,
                      iconSize: 30,
                      onPressed: chapter == null ? null : previousChapter,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                  IconButton(
                    tooltip: episode != null ? l10n.podcastsSkipBack : l10n.playerSkipBack,
                    iconSize: 36,
                    icon: episode != null
                        ? const _SkipIcon(seconds: 15, forward: false)
                        : const _SkipIcon(seconds: 30, forward: false),
                    onPressed: () => ctrl.skipBook(episode != null ? -15 : -30),
                  ),
                  const TransportControls(big: true, playPauseOnly: true),
                  IconButton(
                    tooltip: l10n.playerSkipForward,
                    iconSize: 36,
                    icon: const _SkipIcon(seconds: 30, forward: true),
                    onPressed: () => ctrl.skipBook(30),
                  ),
                  if (book.chapters.isNotEmpty)
                    IconButton(
                      tooltip: l10n.audiobooksNextChapter,
                      iconSize: 30,
                      onPressed: chapterIndex < 0 || chapterIndex >= book.chapters.length - 1
                          ? null
                          : () => ctrl.seekBook(book.chapters[chapterIndex + 1].start),
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                ],
              ),
              SizedBox(height: short ? 8 : 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SpeedButton(labeled: true),
                  const SleepTimerButton(labeled: true),
                  if (book.chapters.isNotEmpty)
                    _PlayerAction(
                      icon: Icons.format_list_numbered_rounded,
                      label: l10n.audiobooksChapters,
                      onTap: () => showChapterSheet(context, ref, book),
                    ),
                  if (episode != null)
                    _PlayerAction(
                      icon: Icons.notes_rounded,
                      label: l10n.podcastsShowNotes,
                      onTap: () => showEpisodeSheet(context, ref, episode),
                    ),
                ],
              ),
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 32), onPressed: () => context.pop()),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          (episode != null ? l10n.navPodcasts : l10n.navAudiobooks).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.4,
                            color: Palette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          episode?.podcastTitle ?? book.author ?? book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: episode != null ? l10n.podcastsOpen : l10n.playerGoToAudiobook,
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      context.pop();
                      context.push(
                        episode != null ? '/podcasts/${episode.podcastId}' : '/audiobooks/item/${book.itemId}',
                      );
                    },
                  ),
                ],
              ),
              if (landscape)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: LayoutBuilder(
                      builder: (context, available) {
                        final side = math.min(available.maxHeight, available.maxWidth * 0.45);
                        return Row(
                          children: [
                            SizedBox.square(dimension: side, child: cover),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Center(child: SingleChildScrollView(child: controls)),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                )
              else ...[
                const Spacer(),
                Flexible(flex: 12, child: cover),
                const Spacer(),
                controls,
                SizedBox(height: short ? 8 : 20),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The current chapter: its number, title, how far into it and how long it still runs.
class _ChapterCard extends ConsumerWidget {
  const _ChapterCard({
    required this.book,
    required this.chapter,
    required this.index,
    required this.position,
    required this.speed,
  });
  final BookPlayback book;
  final AbsChapter chapter;
  final int index;
  final double position;
  final double speed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final length = math.max(1.0, chapter.end - chapter.start);
    final into = (position - chapter.start).clamp(0.0, length);
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showChapterSheet(context, ref, book),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.audiobooksChapterOf(index + 1, book.chapters.length).toUpperCase(),
                    style: TextStyle(fontSize: 11, letterSpacing: 1, color: accent, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    context.l10n.audiobooksTimeRemaining(formatRemaining(context.l10n, (length - into) / speed)),
                    style: const TextStyle(fontSize: 12, color: Palette.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: into / length,
                  minHeight: 3,
                  color: accent,
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round arrow with the seconds it skips inside.
class _SkipIcon extends StatelessWidget {
  const _SkipIcon({required this.seconds, required this.forward});
  final int seconds;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final size = IconTheme.of(context).size ?? 24;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.flip(
          flipX: forward,
          child: Icon(Icons.replay_rounded, size: size),
        ),
        Padding(
          padding: EdgeInsets.only(top: size * 0.1),
          child: Text(
            '$seconds',
            style: TextStyle(fontSize: size * 0.27, fontWeight: FontWeight.w800, color: IconTheme.of(context).color),
          ),
        ),
      ],
    );
  }
}

/// An icon with a small label under it, for the spoken-word player's bottom row.
class _PlayerAction extends StatelessWidget {
  const _PlayerAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PlayerActionLabel(
    onTap: onTap,
    top: Icon(icon, size: 22, color: Colors.white),
    label: label,
  );
}

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(playerProvider);
    final ctrl = ref.read(playerProvider.notifier);
    final upcoming = p.index == null ? <int>[] : [for (var i = p.index! + 1; i < p.queue.length; i++) i];
    final jam = ref.watch(jamProvider);
    String? addedBy(int i) {
      final queue = jam?.state.queue;
      return queue != null && i < queue.length ? context.l10n.jamAddedBy(queue[i].addedByName) : null;
    }

    bool canRemove(int i) {
      final queue = jam?.state.queue;
      if (jam == null) return true;
      return jam.isHost || (queue != null && i < queue.length && queue[i].addedById == jam.myId);
    }

    // Like Spotify: the user's queue first, then the rest of the context, then autoplay.
    String section(int i) => jam == null && p.isQueued(i)
        ? context.l10n.playerNextInQueue
        : p.autoplayIds.contains(p.queue[i].id)
        ? context.l10n.playerAutoplaySection
        : jam == null && p.queuedCount > 0
        ? context.l10n.playerLater
        : context.l10n.playerNextUp;

    return Scaffold(
      appBar: AppBar(title: Text(jam == null ? context.l10n.playerQueue : context.l10n.jamQueue)),
      body: p.current == null
          ? Center(
              child: Text(context.l10n.playerEmptyQueue, style: TextStyle(color: Palette.textMuted)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, kBottomInset),
              children: [
                _QueueHeading(context.l10n.playerNowPlaying),
                TrackRow(track: p.current!, onPlay: ctrl.togglePlay, smart: p.smartIds.contains(p.current!.id)),
                if (addedBy(p.index!) case final label?) _AddedBy(label),
                for (final i in upcoming) ...[
                  if (i == upcoming.first || section(i) != section(i - 1)) _QueueHeading(section(i)),
                  TrackRow(
                    key: ValueKey('q$i-${p.queue[i].id}'),
                    track: p.queue[i],
                    smart: p.smartIds.contains(p.queue[i].id),
                    queued: jam == null && p.isQueued(i),
                    onPlay: () => ctrl.jumpTo(i),
                    onRemove: canRemove(i) ? () => ctrl.removeAt(i) : null,
                    extraActions: [
                      if (canRemove(i))
                        TrackAction(
                          context.l10n.playerRemoveFromQueue,
                          Icons.remove_circle_outline,
                          () => ctrl.removeAt(i),
                        ),
                    ],
                  ),
                  if (addedBy(i) case final label?) _AddedBy(label),
                ],
              ],
            ),
    );
  }
}

class _AddedBy extends StatelessWidget {
  const _AddedBy(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
    child: Text(text, style: const TextStyle(color: Palette.textMuted, fontSize: 12)),
  );
}

class _QueueHeading extends StatelessWidget {
  const _QueueHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// The spectrum and its reflection, painted outside the cover's clipped Material.
class _CoverVisualizer extends ConsumerWidget {
  const _CoverVisualizer({required this.track, required this.reflection});
  final Track track;
  final double reflection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(coverColorProvider(coverImageProvider(ref, track.album.id, size: 300))).value;
    final theme = ref.watch(visualizerThemeProvider);
    return IgnorePointer(
      child: SpectrumVisualizer(
        trackId: track.id,
        color: (color ?? Colors.white).withValues(alpha: 0.85),
        theme: theme.id == 'auto' ? null : theme,
        mirrored: true,
        gap: 0.35,
        minHeight: 0.015,
        reflection: reflection,
      ),
    );
  }
}

/// The back of a turned-over coverflow cover: the album's songs over its blurred, darkened cover, the playing one
/// highlighted.
class _AlbumBack extends ConsumerWidget {
  const _AlbumBack({required this.track, required this.onClose, required this.onPlay});
  final Track track;
  final VoidCallback onClose;
  final void Function(AlbumDetail album, int index) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final tint = ref.watch(coverColorProvider(coverImageProvider(ref, track.album.id, size: 300))).value ?? accent;
    final current = ref.watch(playerProvider.select((p) => p.current?.id));
    final album = ref.watch(albumProvider(track.album.id));
    final info = album.value?.album;
    final muted = theme.textTheme.bodySmall?.copyWith(color: Colors.white70);
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.clamp),
          child: CoverImage(albumId: track.album.id, size: 300, radius: 0),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(tint.withValues(alpha: 0.18), const Color(0xB3000000)),
                const Color(0xD9000000),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: const ValueKey('coverflow-back-header'),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: CoverImage(albumId: track.album.id, size: 150, radius: 6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info?.title ?? track.album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            [
                              info?.artist.name ?? track.artist.name,
                              if (info?.year != null) '${info!.year}',
                              if (album.value != null) context.l10n.coverflowBackSongs(album.value!.tracks.length),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.flip_to_front_rounded, size: 20, color: Colors.white54),
                  ],
                ),
              ),
            ),
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 14), color: Colors.white12),
            Expanded(
              child: album.when(
                loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: tint)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(ApiException.from(e, context.l10n).message, textAlign: TextAlign.center),
                  ),
                ),
                // The list fades out at its edges instead of being cut off.
                data: (detail) => ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                    stops: [0, 0.04, 0.92, 1],
                  ).createShader(rect),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
                    itemCount: detail.tracks.length,
                    itemBuilder: (context, i) {
                      final song = detail.tracks[i];
                      final playing = song.id == current;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Material(
                          color: playing ? tint.withValues(alpha: 0.16) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey('coverflow-back-track-$i'),
                            onTap: () => onPlay(detail, i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 26,
                                    child: playing
                                        ? Icon(Icons.graphic_eq_rounded, size: 18, color: tint)
                                        : Text(
                                            '${song.trackNo ?? i + 1}',
                                            style: muted?.copyWith(
                                              color: Colors.white54,
                                              fontFeatures: const [ui.FontFeature.tabularFigures()],
                                            ),
                                          ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: playing ? tint : Colors.white,
                                        fontWeight: playing ? FontWeight.w600 : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatDuration(Duration(milliseconds: (song.duration * 1000).round())),
                                    style: muted?.copyWith(
                                      color: Colors.white54,
                                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
