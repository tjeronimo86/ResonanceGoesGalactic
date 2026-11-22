import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audiobooks.dart';
import '../../core/podcasts.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../l10n/locale.dart';
import '../../offline/media_downloads.dart';
import '../../player/player.dart';
import 'catalog.dart';
import 'common.dart';
import 'offline.dart';

/// Saves a podcast episode, audiobook or ebook on the device, or removes it again.
class MediaDownloadButton extends ConsumerStatefulWidget {
  const MediaDownloadButton({super.key, required this.kind, required this.id, required this.onAdd, this.size = 30});
  final String kind;
  final String id;
  final Future<void> Function(MediaDownloadsController controller) onAdd;
  final double size;

  @override
  ConsumerState<MediaDownloadButton> createState() => _MediaDownloadButtonState();
}

class _MediaDownloadButtonState extends ConsumerState<MediaDownloadButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final downloads = ref.watch(mediaDownloadsProvider);
    final phase = downloads.phase(widget.kind, widget.id);
    final key = '${widget.kind}:${widget.id}';
    final size = widget.size;
    return IconButton(
      tooltip: switch (phase) {
        MediaDownloadPhase.none => context.l10n.mediaDownload,
        MediaDownloadPhase.downloading => context.l10n.mediaDownloading,
        MediaDownloadPhase.done => context.l10n.mediaRemove,
        MediaDownloadPhase.failed => context.l10n.mediaFailed,
      },
      color: phase == MediaDownloadPhase.done ? Theme.of(context).colorScheme.primary : Palette.textMuted,
      iconSize: size,
      onPressed: _busy ? null : () => _tap(key, phase),
      icon: switch (phase) {
        MediaDownloadPhase.downloading => SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: downloads.progress[key], strokeWidth: 2),
              Icon(Icons.arrow_downward, size: size * 0.6),
            ],
          ),
        ),
        MediaDownloadPhase.done => const Icon(Icons.download_for_offline),
        MediaDownloadPhase.failed => Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        MediaDownloadPhase.none => const Icon(Icons.download_for_offline_outlined),
      },
    );
  }

  Future<void> _tap(String key, MediaDownloadPhase phase) async {
    final controller = ref.read(mediaDownloadsProvider.notifier);
    if (phase == MediaDownloadPhase.failed) return controller.retry(key);
    setState(() => _busy = true);
    try {
      if (phase == MediaDownloadPhase.none) {
        await widget.onAdd(controller);
      } else if (await confirmOfflineDelete(context, context.l10n.mediaRemoveTitle)) {
        await controller.remove(key);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Plays a downloaded episode or audiobook, or opens a downloaded ebook in a reader app.
Future<void> openMediaDownload(BuildContext context, WidgetRef ref, MediaDownload item) async {
  try {
    switch (item.kind) {
      case 'episode':
        await ref.read(playerProvider.notifier).playEpisode(item.episode);
      case 'audiobook':
        final l10n = lookupAppLocalizations(ref.read(appLocaleProvider));
        await ref.read(playerProvider.notifier).playBook(AbsItem.fromJson(item.data, l10n));
      default:
        await openEbookFile(context, ref.read(mediaDownloadsProvider).filePath(item, 0));
    }
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

Future<void> openEbookFile(BuildContext context, String path) async {
  // Hands the file to a reader app (Android, iOS) or the system's default program (desktop).
  if (!await FileDownloader().openFile(filePath: path) && context.mounted) {
    showInfo(context, context.l10n.mediaOpenFailed);
  }
}

/// The downloaded episodes, audiobooks and ebooks, below the music on the offline page.
class MediaDownloadsSection extends ConsumerWidget {
  const MediaDownloadsSection({super.key, this.kinds});

  /// Only these kinds ('episode', 'audiobook', 'ebook'); all when null.
  final Set<String>? kinds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();
    final downloads = ref.watch(mediaDownloadsProvider);
    final newest = [
      for (final item in downloads.items.values.toList().reversed)
        if (kinds?.contains(item.kind) ?? true) item,
    ];
    // Episodes first and by release, newest on top; audiobooks and ebooks follow, last downloaded first.
    final released = {
      for (final item in newest)
        if (item.kind == 'episode') item.key: item.episode.publishedAt,
    };
    final items = [
      ...newest.where((i) => i.kind == 'episode').toList()
        ..sort((a, b) => (released[b.key] ?? DateTime(0)).compareTo(released[a.key] ?? DateTime(0))),
      ...newest.where((i) => i.kind == 'audiobook'),
      ...newest.where((i) => i.kind == 'ebook'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            kinds?.length == 1 && kinds!.single == 'episode'
                ? context.l10n.mediaSectionEpisodes
                : context.l10n.mediaSection,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final item in items) _MediaTile(item: item, downloads: downloads),
      ],
    );
  }
}

class _MediaTile extends ConsumerWidget {
  const _MediaTile({required this.item, required this.downloads});
  final MediaDownload item;
  final MediaDownloadsState downloads;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = downloads.coverPath(item);
    final icon = switch (item.kind) {
      'episode' => Icons.podcasts,
      'audiobook' => Icons.headphones,
      _ => Icons.menu_book,
    };
    final phase = downloads.phase(item.kind, item.id);
    final progress = downloads.progress[item.key];
    final kind = switch (item.kind) {
      'episode' => context.l10n.mediaKindEpisode,
      'audiobook' => context.l10n.audiobooksBook,
      _ => context.l10n.mediaKindEbook,
    };
    return ListTile(
      leading: SizedBox(
        width: 56,
        child: cover == null
            ? NetworkCover(url: item.coverUrl, icon: icon, radius: 6)
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(aspectRatio: 1, child: Image.file(File(cover), fit: BoxFit.cover)),
              ),
      ),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            [
              kind,
              ?item.subtitle,
              if (phase == MediaDownloadPhase.downloading)
                progress == null
                    ? context.l10n.mediaDownloading
                    : '${context.l10n.mediaDownloading} ${(progress * 100).floor()} %',
              if (phase == MediaDownloadPhase.failed) context.l10n.mediaFailed,
            ].join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (phase == MediaDownloadPhase.downloading)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(value: progress, minHeight: 3, borderRadius: BorderRadius.circular(2)),
            )
          else if (item.kind != 'ebook')
            _Listened(item: item),
        ],
      ),
      trailing: MediaDownloadButton(kind: item.kind, id: item.id, size: 24, onAdd: (_) async {}),
      onTap: phase == MediaDownloadPhase.done ? () => openMediaDownload(context, ref, item) : null,
    );
  }
}

/// The release date of an episode and how far it has been listened to.
class _Listened extends StatelessWidget {
  const _Listened({required this.item});
  final MediaDownload item;

  @override
  Widget build(BuildContext context) {
    final episode = item.kind == 'episode' ? item.episode : null;
    final date = episode?.publishedAt;
    // What this device heard last, else what the server knew at download time.
    final server = episode == null ? AbsItem.fromJson(item.data, context.l10n).progress : null;
    final position = item.position ?? episode?.positionSeconds ?? server?.currentTime ?? 0;
    final completed = item.position == null ? episode?.completed ?? server?.isFinished ?? false : item.completed;
    final duration = item.duration;
    final started = !completed && position > 0 && duration > 0;
    if (date == null && !started && !completed) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.primary;
    const style = TextStyle(color: Palette.textMuted, fontSize: 12.5);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (date != null)
            Flexible(
              child: Text(
                formatEpisodeDate(date.toLocal(), Localizations.localeOf(context).toString()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          if (started) ...[
            if (date != null) const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (position / duration).clamp(0, 1),
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.podcastsTimeLeft(formatRemaining(context.l10n, duration - position)),
              style: style.copyWith(color: accent, fontWeight: FontWeight.w600),
            ),
          ],
          if (completed) ...[
            if (date != null) const SizedBox(width: 8),
            Icon(Icons.check_circle, size: 14, color: accent),
            const SizedBox(width: 4),
            Text(
              context.l10n.podcastsPlayed,
              style: style.copyWith(color: accent, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
