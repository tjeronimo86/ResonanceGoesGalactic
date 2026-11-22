import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/library.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../player/player.dart';
import '../../player/engine.dart' show supportsSmartShuffle;
import '../../offline/offline_store.dart';

/// One look for every search field (filled, rounded like the theme); only hint and trailing action differ.
InputDecoration searchDecoration(String hint, {Widget? suffixIcon}) =>
    InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search), suffixIcon: suffixIcon);

class ShuffleButton extends ConsumerWidget {
  const ShuffleButton({super.key, this.iconSize = 24});
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(playerProvider);
    final allowSmart = supportsSmartShuffle(p.context, isRadio: p.isRadio);
    return IconButton(
      tooltip: !p.shuffle
          ? context.l10n.playerShuffle
          : !p.smartShuffle && allowSmart
          ? context.l10n.playerSmartShuffle
          : context.l10n.playerShuffleOff,
      iconSize: iconSize,
      color: p.shuffle ? Theme.of(context).colorScheme.primary : Palette.textMuted,
      onPressed: p.inJam ? null : ref.read(playerProvider.notifier).toggleShuffle,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shuffle),
          if (p.smartShuffle) const Positioned(top: -3, right: -4, child: Icon(Icons.auto_awesome, size: 10)),
        ],
      ),
    );
  }
}

class TrackTitle extends StatelessWidget {
  const TrackTitle({super.key, required this.track, this.smart = false, this.style});
  final Track track;
  final bool smart;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final title = Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    return smart
        ? Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(child: title),
            ],
          )
        : title;
  }
}

/// A file size as MB or GB in the app's language.
String formatStorage(BuildContext context, int bytes) {
  final gigabytes = bytes >= 1024 * 1024 * 1024;
  final value = NumberFormat(
    '0.0',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(bytes / (gigabytes ? 1024 * 1024 * 1024 : 1024 * 1024));
  return gigabytes ? context.l10n.offlineGigabytes(value) : context.l10n.offlineMegabytes(value);
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

String formatLongDuration(AppLocalizations l10n, double seconds) {
  final d = Duration(seconds: seconds.round());
  if (d.inHours > 0) {
    return l10n.commonDurationHoursMinutes(d.inHours, d.inMinutes.remainder(60));
  }
  return l10n.commonDurationMinutesSeconds(d.inMinutes, d.inSeconds.remainder(60));
}

/// Hours and minutes only ("1 Std. 6 Min.", "4 Min."), rounded up, for how much is left of something long.
String formatRemaining(AppLocalizations l10n, double seconds) {
  final minutes = (seconds / 60).ceil().clamp(1, 1 << 31);
  if (minutes >= 60) {
    return minutes % 60 == 0
        ? l10n.commonDurationHours('${minutes ~/ 60}')
        : l10n.commonDurationHoursMinutes(minutes ~/ 60, minutes % 60);
  }
  return l10n.commonDurationMinutes(minutes);
}

/// "1 Song" / "3 Songs".
String songs(AppLocalizations l10n, int n) => l10n.commonSongs(n);

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

/// Album cover with a neutral placeholder.
/// The image CoverImage shows for an album (downloaded file if current, else the cached network image).
ImageProvider coverImageProvider(WidgetRef ref, String albumId, {int size = 300}) {
  final offline = ref.read(offlineProvider);
  final local = kIsWeb ? null : offline.coverPath(albumId);
  if (local != null && offline.coverCurrent(albumId)) return FileImage(File(local));
  final key = coverKeys[albumId];
  return CachedNetworkImageProvider(
    '${ref.read(apiProvider).coverUrl(albumId, size: size)}${key == null ? '' : '&v=$key'}',
    cacheKey: 'cover:$albumId:$size${key == null ? '' : ':$key'}',
  );
}

class CoverImage extends ConsumerWidget {
  const CoverImage({super.key, this.albumId, this.size = 300, this.radius = 4, this.icon = Icons.music_note});

  final String? albumId;
  final int size;
  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Queue entries a Connect device has not described yet have an empty album id.
    final noAlbum = albumId == null || albumId!.isEmpty;
    final version = noAlbum ? 0 : ref.watch(coverVersionsProvider.select((v) => v[albumId] ?? 0));
    // An album the server lists without a cover only answers 404, unless a cover was set since.
    final missing = noAlbum || (version == 0 && albumsWithoutCover.contains(albumId));
    final localCover = kIsWeb || missing ? null : ref.watch(offlineProvider.select((s) => s.coverPath(albumId!)));
    final key = missing ? null : coverKeys[albumId];
    final current = missing || ref.watch(offlineProvider.select((s) => s.coverCurrent(albumId!)));
    final suffix = '${key == null ? '' : ':$key'}${version > 0 ? ':$version' : ''}';
    final query = '${key == null ? '' : '&v=$key'}${version > 0 ? '&r=$version' : ''}';
    final placeholder = Container(
      color: const Color(0xFF282828),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (_, c) => Icon(icon, color: Palette.textMuted, size: (c.maxWidth * 0.4).clamp(12, 64)),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 1,
        child: missing
            ? placeholder
            : localCover != null && current
            ? Image.file(File(localCover), fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
            : CachedNetworkImage(
                imageUrl: '${ref.watch(apiProvider).coverUrl(albumId!, size: size)}$query',
                // Cache key without the token so a re-login keeps the cache; the cover key changes with the image.
                cacheKey: 'cover:$albumId:$size$suffix',
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => placeholder,
                // An outdated downloaded cover still beats an empty square while offline.
                errorWidget: (_, _, _) => localCover != null
                    ? Image.file(File(localCover), fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
                    : placeholder,
              ),
      ),
    );
  }
}

class ArtistImage extends ConsumerWidget {
  const ArtistImage({super.key, required this.artist, this.size = 300});
  final Artist artist;
  final int size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = CoverImage(albumId: artist.coverAlbumId, size: size, radius: 0, icon: Icons.person);
    if (!artist.hasImage) return fallback;
    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: ref.watch(apiProvider).artistImageUrl(artist.id, size: size),
        cacheKey: 'artist:${artist.id}:$size',
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// 2x2 mosaic for playlists, like Spotify.
class PlaylistCover extends ConsumerWidget {
  const PlaylistCover({
    super.key,
    required this.albumIds,
    this.playlistId,
    this.coverKey,
    this.radius = 4,
    this.icon = Icons.queue_music,
  });

  final List<String> albumIds;
  final String? playlistId;
  final String? coverKey;
  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (playlistId != null && coverKey != null && !ref.watch(sessionProvider.select((s) => s.offline))) {
      final placeholder = Container(
        color: const Color(0xFF282828),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (_, c) => Icon(icon, color: Palette.textMuted, size: (c.maxWidth * 0.4).clamp(12, 64)),
        ),
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 1,
          child: CachedNetworkImage(
            imageUrl: ref.watch(apiProvider).playlistCoverUrl(playlistId!, coverKey!),
            cacheKey: 'playlist-cover:$playlistId:$coverKey:300',
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          ),
        ),
      );
    }
    if (albumIds.length < 4) {
      return CoverImage(albumId: albumIds.firstOrNull, radius: radius, icon: icon);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [for (final id in albumIds.take(4)) CoverImage(albumId: id, size: 150, radius: 0)],
        ),
      ),
    );
  }
}

class LikedCover extends StatelessWidget {
  const LikedCover({super.key, this.radius = 4});
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
          ),
        ),
        child: LayoutBuilder(
          builder: (_, c) => Icon(Icons.favorite, color: Colors.white, size: (c.maxWidth * 0.4).clamp(12, 72)),
        ),
      ),
    ),
  );
}

class DiscoverCover extends StatelessWidget {
  const DiscoverCover({super.key, this.radius = 4});
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
        ),
        child: LayoutBuilder(
          builder: (_, c) => Padding(
            padding: EdgeInsets.all(c.maxWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore, color: Colors.white, size: (c.maxWidth * 0.4).clamp(12, 72)),
                SizedBox(height: c.maxWidth * 0.06),
                Text(
                  context.l10n.discoverWeekly,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: (c.maxWidth * 0.1).clamp(8, 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Card used in horizontal shelves and grids (album / artist / playlist).
class MediaCard extends StatefulWidget {
  const MediaCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.circle = false,
    this.onPlay,
  });

  final Widget image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final bool circle;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hover ? Palette.cardHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: widget.circle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  widget.circle ? ClipOval(child: widget.image) : widget.image,
                  if (widget.onPlay != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: AnimatedOpacity(
                        opacity: _hover ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: PlayButton(onPressed: widget.onPlay!, size: 44),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: widget.circle ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.bodySmall?.copyWith(color: Palette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.onPressed, this.size = 56, this.playing = false});
  final VoidCallback onPressed;
  final double size;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(playing ? Icons.pause : Icons.play_arrow, color: scheme.onPrimary, size: size * 0.55),
        ),
      ),
    );
  }
}

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, this.onPlay});
  final Album album;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) => MediaCard(
    image: CoverImage(albumId: album.hasCover ? album.id : null, icon: Icons.album),
    title: album.title,
    subtitle: [if (album.year != null) '${album.year}', album.artist.name].join(' • '),
    onTap: () => context.push('/album/${album.id}'),
    onPlay: onPlay,
  );
}

class ArtistCard extends StatelessWidget {
  const ArtistCard({super.key, required this.artist});
  final Artist artist;

  @override
  Widget build(BuildContext context) => MediaCard(
    circle: true,
    image: ArtistImage(artist: artist),
    title: artist.name,
    subtitle: context.l10n.commonArtist,
    onTap: () => context.push('/artist/${artist.id}'),
  );
}

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({super.key, required this.playlist});
  final Playlist playlist;

  @override
  Widget build(BuildContext context) => MediaCard(
    image: playlist.mixKey == 'discover-weekly' && playlist.coverKey == null
        ? const DiscoverCover()
        : PlaylistCover(playlistId: playlist.id, coverKey: playlist.coverKey, albumIds: playlist.coverAlbumIds),
    title: playlist.name,
    subtitle: playlist.isMix && playlist.description != null
        ? playlist.description!
        : context.l10n.libraryPlaylistBy((playlist.owner.name).toString()),
    onTap: () => context.push('/playlist/${playlist.id}'),
  );
}

/// Lets a horizontal list scroll by dragging with the mouse too; Flutter only drags with touch and trackpads by
/// default, so a mouse without a horizontal wheel could not reach the end of a row.
class MouseDragScroll extends StatelessWidget {
  const MouseDragScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
    child: child,
  );
}

/// Horizontal shelf with a heading, like Spotify's home rows. Wide layouts get page-back/forward arrows next to the
/// heading, the way Spotify's desktop app scrolls its rows.
class Shelf extends StatefulWidget {
  const Shelf({super.key, required this.title, required this.children, this.itemWidth = 180});
  final String title;
  final List<Widget> children;
  final double itemWidth;

  @override
  State<Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<Shelf> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _page(int direction) {
    final position = _controller.position;
    final step = (position.viewportDimension - widget.itemWidth).clamp(widget.itemWidth, double.infinity);
    _controller.animateTo(
      (position.pixels + direction * step).clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    final strings = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Without a title (a row continuing the section above) only the arrows remain.
          padding: widget.title.isEmpty
              ? const EdgeInsets.fromLTRB(16, 12, 8, 0)
              : const EdgeInsets.fromLTRB(16, 24, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: widget.title.isEmpty
                    ? const SizedBox()
                    : Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (isWide(context))
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final position = _controller.hasClients && _controller.position.hasContentDimensions
                        ? _controller.position
                        : null;
                    // Rows that fit on screen need no arrows.
                    if (position == null || position.maxScrollExtent <= position.minScrollExtent) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      children: [
                        IconButton(
                          tooltip: strings.previousPageTooltip,
                          icon: const Icon(Icons.chevron_left),
                          onPressed: position.pixels > position.minScrollExtent ? () => _page(-1) : null,
                        ),
                        IconButton(
                          tooltip: strings.nextPageTooltip,
                          icon: const Icon(Icons.chevron_right),
                          onPressed: position.pixels < position.maxScrollExtent ? () => _page(1) : null,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
        SizedBox(
          height: widget.itemWidth + 72,
          // The arrows only know whether the row overflows once it has been laid out (and again after resizes).
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              setState(() {});
              return false;
            },
            child: MouseDragScroll(
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: widget.children.length,
                itemBuilder: (_, i) => SizedBox(width: widget.itemWidth, child: widget.children[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders an AsyncValue with consistent loading / error states.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.builder, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    data: builder,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Palette.textMuted),
            const SizedBox(height: 12),
            Text(ApiException.from(e, context.l10n).message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
            ],
          ],
        ),
      ),
    ),
  );
}

void showError(BuildContext context, Object e) => showMessage(context, ApiException.from(e, context.l10n).message);

void showInfo(BuildContext context, String msg) => showMessage(context, msg);

/// Shows [msg] as a snackbar. Shown from the shell's pages it floats above the player at the bottom (mini player,
/// desktop player bar) instead of covering it.
void showMessage(BuildContext context, String msg, {SnackBarAction? action, Duration? duration}) {
  final player = context.getInheritedWidgetOfExactType<PlayerArea>() == null ? 0.0 : playerAreaHeight.value;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      action: action,
      duration: duration ?? const Duration(milliseconds: 4000),
      behavior: SnackBarBehavior.floating,
      margin: player > 0 ? EdgeInsets.fromLTRB(15, 5, 15, 14 + player) : null,
    ),
  );
}

/// Height of what sits at the bottom of the shell over its pages (player, offline banner), kept by [MeasureHeight].
final playerAreaHeight = ValueNotifier<double>(0);

/// Marks the shell's pages, whose snackbars appear in the shell's Scaffold above the player. Routes pushed over the
/// shell (now playing, dialogs) are outside it and keep the default position.
class PlayerArea extends InheritedWidget {
  const PlayerArea({super.key, required super.child});

  @override
  bool updateShouldNotify(PlayerArea oldWidget) => false;
}

/// Writes the laid-out height of [child] to [height] (0 when the child is gone).
class MeasureHeight extends SingleChildRenderObjectWidget {
  const MeasureHeight({super.key, required this.height, super.child});

  final ValueNotifier<double> height;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderMeasureHeight(height);

  @override
  void updateRenderObject(BuildContext context, RenderMeasureHeight renderObject) => renderObject.height = height;

  @override
  void didUnmountRenderObject(RenderMeasureHeight renderObject) => renderObject.height.value = 0;
}

class RenderMeasureHeight extends RenderProxyBox {
  RenderMeasureHeight(this.height);

  ValueNotifier<double> height;

  @override
  void performLayout() {
    super.performLayout();
    height.value = size.height;
  }
}

/// Music entry points share the same error presentation as audiobook playback.
Future<void> playMusic(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks, {
  int? index,
  String? contextId,
  bool isRadio = false,
}) async {
  try {
    await ref.read(playerProvider.notifier).playTracks(tracks, index: index, context: contextId, isRadio: isRadio);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}
