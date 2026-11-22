import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/library.dart';
import '../../core/downloads.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../player/player.dart';
import '../../offline/offline_store.dart';
import '../pages/admin/metadata_editor.dart';
import 'common.dart';
import 'credits_sheet.dart';
import 'ringtone_sheet.dart';
import 'action_sheet.dart';

/// One row in a track list. [number] shows a track number instead of the cover, or before it (chart places) when
/// [showCover] stays on.
class TrackRow extends ConsumerStatefulWidget {
  const TrackRow({
    super.key,
    required this.track,
    required this.onPlay,
    this.number,
    this.showCover = true,
    this.showAlbum = true,
    this.smart = false,
    this.queued = false,
    this.onRemove,
    this.extraActions = const [],
    this.addedBy,
    this.mixInfo,
    this.dragHandle,
  });

  final Track track;
  final VoidCallback onPlay;
  final int? number;
  final bool showCover;
  final bool showAlbum;
  final bool smart;

  /// Added to the queue by the user: marked like Spotify does.
  final bool queued;

  /// In the queue: swiping to the left removes the song.
  final VoidCallback? onRemove;
  final List<TrackAction> extraActions;

  /// Collaborative playlists: who added the song, shown after the artist.
  final String? addedBy;

  /// Tempo and key (transition editor), shown before the like button.
  final Widget? mixInfo;

  /// In a reorderable list (the queue): the handle that moves the song, at the end of the row.
  final Widget? dragHandle;

  @override
  ConsumerState<TrackRow> createState() => _TrackRowState();
}

class TrackAction {
  const TrackAction(this.label, this.icon, this.onSelected);
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
}

class _TrackRowState extends ConsumerState<TrackRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.track;
    final downloaded = !kIsWeb && ref.watch(offlineProvider.select((s) => s.isDownloaded(t.id)));
    final offline = !kIsWeb && ref.watch(sessionProvider.select((s) => s.offline));
    final current = ref.watch(playerProvider.select((p) => p.current?.id == t.id));
    final playing = current && ref.watch(playerProvider.select((p) => p.playing));
    final accent = Theme.of(context).colorScheme.primary;
    final wide = isWide(context);
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Palette.textMuted);

    Widget leading;
    if (widget.number != null && !widget.showCover) {
      leading = SizedBox(
        width: 32,
        child: Center(
          child: _hover && wide
              ? const Icon(Icons.play_arrow, size: 20)
              : playing
              ? Icon(Icons.graphic_eq, size: 18, color: accent)
              : Text('${widget.number}', style: muted?.copyWith(color: current ? accent : null)),
        ),
      );
    } else if (widget.number != null) {
      leading = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${widget.number}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: current ? accent : Palette.textMuted, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 44, child: CoverImage(albumId: t.album.id, size: 64)),
        ],
      );
    } else {
      leading = SizedBox(width: 44, child: CoverImage(albumId: t.album.id, size: 64));
    }

    final row = Opacity(
      opacity: offline && !downloaded ? 0.4 : 1,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: widget.onPlay,
          onLongPress: () => showTrackMenu(context, ref, t, widget.extraActions),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _hover ? Colors.white10 : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackTitle(
                        track: t,
                        smart: widget.smart,
                        style: TextStyle(color: current ? accent : Colors.white, fontSize: 15),
                      ),
                      Row(
                        children: [
                          if (widget.queued) ...[
                            Icon(Icons.queue_music, size: 14, color: accent),
                            const SizedBox(width: 4),
                          ],
                          if (downloaded) ...[
                            Icon(Icons.arrow_circle_down, size: 14, color: accent),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              widget.addedBy == null
                                  ? t.artistCredit
                                  : '${t.artistCredit} · ${context.l10n.playlistAddedBy(widget.addedBy!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: muted?.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (wide && widget.showAlbum)
                  Expanded(
                    flex: 3,
                    child: Text(t.album.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
                  ),
                if (widget.mixInfo != null) ...[widget.mixInfo!, const SizedBox(width: 8)],
                if (wide || t.liked)
                  IconButton(
                    tooltip: t.liked ? context.l10n.playerRemoveLiked : context.l10n.playerAddLiked,
                    icon: Icon(t.liked ? Icons.favorite : Icons.favorite_border, size: 18),
                    color: t.liked ? accent : Palette.textMuted,
                    onPressed: () => ref.read(libraryActionsProvider).setLiked(t, !t.liked).catchError((e) {
                      if (context.mounted) showError(context, e);
                    }),
                  ),
                if (wide) SizedBox(width: 48, child: Text(formatDuration(t.length), style: muted)),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  color: Palette.textMuted,
                  onPressed: () => showTrackMenu(context, ref, t, widget.extraActions),
                ),
                ?widget.dragHandle,
              ],
            ),
          ),
        ),
      ),
    );
    if (wide) return row;
    return QueueSwipe(track: t, onRemove: widget.onRemove, child: row);
  }
}

/// Swiping a song to the right adds it to the queue (touch layouts); the row springs back. With [onRemove] (the
/// queue itself), swiping to the left takes it out again.
class QueueSwipe extends ConsumerWidget {
  const QueueSwipe({super.key, required this.track, required this.child, this.onRemove});
  final Track track;
  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = ThemeData.estimateBrightnessForColor(accent) == Brightness.dark ? Colors.white : Colors.black;
    return Dismissible(
      key: const ValueKey('queue-swipe'),
      direction: onRemove == null ? DismissDirection.startToEnd : DismissDirection.horizontal,
      dismissThresholds: const {DismissDirection.startToEnd: 0.25, DismissDirection.endToStart: 0.25},
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
        child: Icon(Icons.queue_music, color: onAccent),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.remove_circle_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.endToStart) {
          onRemove?.call();
          return false;
        }
        ref.read(playerProvider.notifier).addToQueue(track).catchError((Object e) {
          if (context.mounted) showError(context, e);
        });
        return false;
      },
      child: child,
    );
  }
}

Future<void> showTrackMenu(BuildContext context, WidgetRef ref, Track t, [List<TrackAction> extra = const []]) {
  final player = ref.read(playerProvider.notifier);
  return showActionSheet(
    context,
    header: ListTile(
      leading: SizedBox(width: 48, child: CoverImage(albumId: t.album.id, size: 64)),
      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(t.artistCredit, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    actions: [
      SheetAction(
        icon: t.liked ? Icons.favorite : Icons.favorite_border,
        label: t.liked ? context.l10n.playerRemoveLiked : context.l10n.playerAddLiked,
        onSelected: () => ref.read(libraryActionsProvider).setLiked(t, !t.liked),
      ),
      SheetAction(
        icon: Icons.playlist_add,
        label: context.l10n.playerAddToPlaylist,
        onSelected: () => showAddToPlaylist(context, ref, [t.id]),
      ),
      SheetAction(
        icon: Icons.queue_play_next,
        label: context.l10n.playerPlayNext,
        onSelected: () => player.playNext(t),
      ),
      SheetAction(
        icon: Icons.queue_music,
        label: context.l10n.playerAddToQueue,
        onSelected: () => player.addToQueue(t),
      ),
      SheetAction(
        icon: Icons.radio,
        label: context.l10n.radioStartSong,
        onSelected: () => startRadio(context, ref, 'track', t.id, seed: t),
      ),
      SheetAction(
        icon: Icons.album,
        label: context.l10n.playerGoToAlbum,
        onSelected: () => context.push('/album/${t.album.id}'),
      ),
      SheetAction(
        icon: Icons.person,
        label: context.l10n.playerGoToArtist,
        onSelected: () => context.push('/artist/${t.artist.id}'),
      ),
      if (!ref.read(sessionProvider).offline)
        SheetAction(
          icon: Icons.people_outline,
          label: context.l10n.creditsShow,
          onSelected: () => showCreditsSheet(context, t),
        ),
      if (ringtonesAvailable(ref))
        SheetAction(
          icon: Icons.ring_volume,
          label: context.l10n.ringtoneMenu,
          onSelected: () => showRingtoneSheet(context, ref, t),
        ),
      if (!ref.read(sessionProvider).offline)
        SheetAction(
          icon: Icons.restart_alt,
          label: context.l10n.redownloadMenu,
          onSelected: () => showRedownloadDialog(context, ref, t),
        ),
      for (final a in extra) SheetAction(icon: a.icon, label: a.label, onSelected: a.onSelected),
      if (ref.read(sessionProvider).user?.isAdmin ?? false) ...[
        SheetAction(
          icon: Icons.edit_note,
          label: context.l10n.editorCorrectMetadata,
          onSelected: () => showTrackEditor(context, ref, t),
        ),
        SheetAction(
          icon: Icons.delete_outline,
          label: context.l10n.adminDeleteSong,
          onSelected: () => deleteTrackAsAdmin(context, ref, t),
        ),
      ],
    ],
  );
}

Future<void> showRedownloadDialog(BuildContext context, WidgetRef ref, Track track) async {
  var youtubeUrl = '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(context.l10n.redownloadTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.redownloadExplanation),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: context.l10n.redownloadYoutubeLabel,
              hintText: context.l10n.redownloadYoutubeHint,
            ),
            onChanged: (value) => youtubeUrl = value,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(context.l10n.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(context.l10n.redownloadTitle)),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    final url = youtubeUrl.trim();
    final request = await ref.read(apiProvider).redownload(track.id, youtubeUrl: url.isEmpty ? null : url);
    ref.invalidate(requestsProvider);
    ref.invalidate(requestDetailProvider);
    ref.invalidate(downloadSummaryProvider);
    if (context.mounted) {
      showInfo(
        context,
        request.status == 'pending_approval' ? context.l10n.redownloadAwaitingApproval : context.l10n.redownloadStarted,
      );
    }
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

Future<void> showAddToPlaylist(BuildContext context, WidgetRef ref, List<String> trackIds) async {
  final playlists = await ref.read(playlistsProvider.future);
  if (!context.mounted) return;
  final actions = ref.read(libraryActionsProvider);
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: const Color(0xFF282828),
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(context.l10n.libraryNewPlaylist),
            onTap: () async {
              Navigator.pop(sheet);
              final p = await createPlaylistInteractive(context, ref);
              if (p == null) return;
              await actions.addToPlaylist(p.id, trackIds);
            },
          ),
          for (final p in playlists.where((p) => p.canEdit && !p.isRadio && !p.isMix))
            ListTile(
              leading: SizedBox(
                width: 40,
                child: PlaylistCover(playlistId: p.id, coverKey: p.coverKey, albumIds: p.coverAlbumIds),
              ),
              title: Text(p.name),
              subtitle: Text(songs(context.l10n, p.trackCount)),
              onTap: () async {
                Navigator.pop(sheet);
                try {
                  await actions.addToPlaylist(p.id, trackIds);
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
        ],
      ),
    ),
  );
}

/// Asks for the name (and whether others may edit it), creates the playlist and, for a collaborative one, lets the
/// owner pick who it is shared with right away.
Future<Playlist?> createPlaylistInteractive(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  var collaborative = false;
  final name = await showDialog<String>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.libraryNewPlaylist),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: context.l10n.commonName),
              onSubmitted: (v) => Navigator.pop(dialog, v.trim()),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.playlistCollaborative),
              subtitle: Text(context.l10n.playlistCollaborativeHint),
              value: collaborative,
              onChanged: (v) => setState(() => collaborative = v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: Text(context.l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text.trim()),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    ),
  );
  if (name == null || name.isEmpty || !context.mounted) return null;
  final Playlist playlist;
  try {
    playlist = await ref.read(libraryActionsProvider).createPlaylist(name, collaborative: collaborative);
  } catch (e) {
    if (context.mounted) showError(context, e);
    return null;
  }
  if (collaborative && context.mounted) await showShareWithUsers(context, ref, playlist);
  return playlist;
}

Future<String?> promptText(BuildContext context, String title, String label, {String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(dialog, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: Text(context.l10n.commonCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, controller.text.trim()),
          child: Text(context.l10n.commonSave),
        ),
      ],
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, String title, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(context.l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    ) ??
    false;

/// Admin only: deletes the song (database row and file) from the server.
Future<void> deleteTrackAsAdmin(BuildContext context, WidgetRef ref, Track t) async {
  if (!await confirmDelete(context, context.l10n.adminDeleteSong, context.l10n.adminDeleteSongConfirm(t.title))) {
    return;
  }
  try {
    await ref.read(apiProvider).deleteLibraryTrack(t.id);
  } catch (e) {
    if (context.mounted) showError(context, e);
    return;
  }
  invalidateLibrary(ref);
  ref.invalidate(albumProvider(t.album.id));
  if (context.mounted) showInfo(context, context.l10n.adminDeleted);
}

/// Refresh the library lists after songs or albums were deleted.
void invalidateLibrary(WidgetRef ref) {
  ref.invalidate(homeProvider);
  ref.invalidate(likedTracksProvider);
  ref.invalidate(playlistsProvider);
  ref.invalidate(savedAlbumsProvider);
  ref.invalidate(allAlbumsProvider);
  ref.invalidate(allArtistsProvider);
  ref.invalidate(playlistDetailProvider);
  ref.invalidate(artistProvider);
}

/// Owner only: pick the users a playlist is shared with.
Future<void> showShareWithUsers(BuildContext context, WidgetRef ref, Playlist playlist) async {
  final api = ref.read(apiProvider);
  final List<NamedRef> users;
  try {
    users = await api.otherUsers();
  } catch (e) {
    if (context.mounted) showError(context, e);
    return;
  }
  if (!context.mounted) return;
  final selected = {for (final u in playlist.sharedWith) u.id};
  var collaborative = playlist.collaborative;
  final result = await showDialog<Set<String>>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.libraryShareWithUsers),
        contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        content: SizedBox(
          width: 400,
          child: users.isEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: Text(context.l10n.libraryNoOtherUsers))
              : ListView(
                  shrinkWrap: true,
                  children: [
                    SwitchListTile(
                      title: Text(context.l10n.playlistCollaborative),
                      subtitle: Text(context.l10n.playlistCollaborativeHint),
                      value: collaborative,
                      onChanged: (v) => setState(() => collaborative = v),
                    ),
                    const Divider(),
                    for (final u in users)
                      CheckboxListTile(
                        title: Text(u.name),
                        value: selected.contains(u.id),
                        onChanged: (v) => setState(() => v! ? selected.add(u.id) : selected.remove(u.id)),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: Text(context.l10n.commonCancel)),
          FilledButton(
            onPressed: users.isEmpty ? null : () => Navigator.pop(dialog, selected),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    ),
  );
  if (result == null) return;
  try {
    await api.setPlaylistShares(playlist.id, result.toList());
    if (collaborative != playlist.collaborative) {
      await api.updatePlaylist(playlist.id, {'collaborative': collaborative});
    }
  } catch (e) {
    if (context.mounted) showError(context, e);
    return;
  }
  ref.invalidate(playlistDetailProvider(playlist.id));
  ref.invalidate(playlistsProvider);
}

/// Starts a song/album radio: builds it on the server, plays it and opens it.
Future<void> startRadio(BuildContext context, WidgetRef ref, String seedType, String id, {Track? seed}) async {
  final api = ref.read(apiProvider);
  final player = ref.read(playerProvider.notifier);
  final l10n = context.l10n;
  try {
    final instant = seedType == 'track' && seed != null;
    if (instant) await player.playTracks([seed], context: 'radio:pending');
    final (playlist, requested) = await api.startRadio(seedType, id);
    ref.invalidate(playlistsProvider);
    final detail = await api.playlist(playlist.id);
    if (!context.mounted) return;
    final tracks = [for (final e in detail.entries) e.track];
    if (instant) {
      final playing = ref.read(playerProvider);
      if (playing.context == 'radio:pending' && playing.current?.id == seed.id) {
        await player.replaceUpcoming(tracks, context: 'playlist:${playlist.id}', isRadio: true);
      }
    } else {
      await playMusic(context, ref, tracks, contextId: 'playlist:${playlist.id}', isRadio: true);
    }
    if (!context.mounted) return;
    context.push('/playlist/${playlist.id}');
    if (requested > 0) showInfo(context, l10n.radioDownloading(requested));
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}
