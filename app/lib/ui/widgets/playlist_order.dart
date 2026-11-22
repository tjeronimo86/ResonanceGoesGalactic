import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/library.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../l10n/l10n.dart';
import 'action_sheet.dart';
import 'collection.dart' show kBottomInset;
import 'common.dart';

/// How a playlist can be sorted at once.
enum PlaylistSort { title, artist, album, length, reverse }

/// The entry ids of [entries] in [sort] order.
List<String> sortedEntryIds(List<PlaylistEntry> entries, PlaylistSort sort) {
  int text(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
  final sorted = [...entries];
  switch (sort) {
    case PlaylistSort.title:
      sorted.sort((a, b) => text(a.track.title, b.track.title));
    case PlaylistSort.artist:
      sorted.sort((a, b) {
        final artist = text(a.track.artistCredit, b.track.artistCredit);
        return artist != 0 ? artist : text(a.track.title, b.track.title);
      });
    case PlaylistSort.album:
      sorted.sort((a, b) {
        final album = text(a.track.album.name, b.track.album.name);
        if (album != 0) return album;
        return (
          a.track.discNo ?? 0,
          a.track.trackNo ?? 0,
        ).toString().compareTo((b.track.discNo ?? 0, b.track.trackNo ?? 0).toString());
      });
    case PlaylistSort.length:
      sorted.sort((a, b) => a.track.duration.compareTo(b.track.duration));
    case PlaylistSort.reverse:
      return [for (final e in sorted.reversed) e.entryId];
  }
  return [for (final e in sorted) e.entryId];
}

/// Playlist menu → sort: reorder by hand, sort by a field, or order as a DJ set; each can be undone.
Future<void> showPlaylistSortSheet(BuildContext context, WidgetRef ref, PlaylistDetail detail) {
  final l10n = context.l10n;
  final id = detail.playlist.id;
  final before = [for (final e in detail.entries) e.entryId];

  Future<void> apply(Future<void> Function() change) async {
    final api = ref.read(apiProvider);
    try {
      await change();
      ref.invalidate(playlistDetailProvider(id));
      if (!context.mounted) return;
      showMessage(
        context,
        l10n.playlistSorted,
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () async {
            await api.setPlaylistOrder(id, before);
            ref.invalidate(playlistDetailProvider(id));
          },
        ),
      );
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  SheetAction sort(PlaylistSort by, IconData icon, String label) => SheetAction(
    icon: icon,
    label: label,
    onSelected: () => apply(() => ref.read(apiProvider).setPlaylistOrder(id, sortedEntryIds(detail.entries, by))),
  );

  SheetAction set(String arc, IconData icon, String label) =>
      SheetAction(icon: icon, label: label, onSelected: () => apply(() => ref.read(apiProvider).djSetOrder(id, arc)));

  return showActionSheet(
    context,
    header: ListTile(
      title: Text(l10n.playlistSort, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(l10n.playlistSortHint),
    ),
    actions: [
      SheetAction(
        icon: Icons.drag_handle,
        label: l10n.playlistReorder,
        onSelected: () => context.push('/playlist/$id/order'),
      ),
      set('peak', Icons.show_chart, l10n.playlistSetPeak),
      set('rise', Icons.trending_up, l10n.playlistSetRise),
      set('down', Icons.trending_down, l10n.playlistSetDown),
      set('flow', Icons.waves, l10n.playlistSetFlow),
      sort(PlaylistSort.title, Icons.sort_by_alpha, l10n.playlistSortTitle),
      sort(PlaylistSort.artist, Icons.person, l10n.playlistSortArtist),
      sort(PlaylistSort.album, Icons.album, l10n.playlistSortAlbum),
      sort(PlaylistSort.length, Icons.timer_outlined, l10n.playlistSortLength),
      sort(PlaylistSort.reverse, Icons.swap_vert, l10n.playlistSortReverse),
    ],
  );
}

/// Reordering a playlist by dragging its songs; every drop is saved right away.
class PlaylistOrderPage extends ConsumerStatefulWidget {
  const PlaylistOrderPage({super.key, required this.playlistId});
  final String playlistId;

  @override
  ConsumerState<PlaylistOrderPage> createState() => _PlaylistOrderPageState();
}

class _PlaylistOrderPageState extends ConsumerState<PlaylistOrderPage> {
  List<PlaylistEntry>? _entries;

  Future<void> _move(int from, int to) async {
    final entries = [..._entries!];
    if (to == from) return;
    final moved = entries.removeAt(from);
    entries.insert(to, moved);
    setState(() => _entries = entries);
    final before = to + 1 < entries.length ? entries[to + 1].entryId : null;
    try {
      await ref.read(apiProvider).moveInPlaylist(widget.playlistId, moved.entryId, before);
      ref.invalidate(playlistDetailProvider(widget.playlistId));
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      ref.invalidate(playlistDetailProvider(widget.playlistId));
      setState(() => _entries = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(playlistDetailProvider(widget.playlistId));
    return Scaffold(
      appBar: AppBar(
        title: Text(value.value?.playlist.name ?? context.l10n.playlistReorder),
        actions: [TextButton(onPressed: () => context.pop(), child: Text(context.l10n.commonDone))],
      ),
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(playlistDetailProvider(widget.playlistId)),
        builder: (detail) {
          final entries = _entries ??= [...detail.entries];
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: kBottomInset),
            buildDefaultDragHandles: false,
            itemCount: entries.length,
            onReorderItem: _move,
            itemBuilder: (context, i) {
              final e = entries[i];
              return ListTile(
                key: ValueKey(e.entryId),
                leading: SizedBox(width: 44, child: CoverImage(albumId: e.track.album.id, size: 64)),
                title: Text(e.track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(e.track.artistCredit, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
              );
            },
          );
        },
      ),
    );
  }
}
