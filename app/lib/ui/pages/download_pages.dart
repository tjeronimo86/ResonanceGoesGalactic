import '../../l10n/l10n.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/downloads.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../widgets/catalog.dart';
import '../widgets/collection.dart';
import '../widgets/common.dart';
import '../widgets/track_list.dart';

/// Catalog results below the library search results.
class CatalogSearchSection extends ConsumerWidget {
  const CatalogSearchSection({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(catalogSearchProvider(query));
    final heading = Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.catalogDiscoverMore, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(context.l10n.catalogDownloadHint, style: TextStyle(color: Palette.textMuted, fontSize: 13)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        value.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(ApiException.from(e, context.l10n).message, style: const TextStyle(color: Palette.textMuted)),
          ),
          data: (r) => r.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(context.l10n.catalogNoResults, style: TextStyle(color: Palette.textMuted)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    for (final t in r.tracks.take(6))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CatalogTrackRow(track: t),
                      ),
                    Shelf(
                      title: context.l10n.commonAlbums,
                      children: [for (final a in r.albums) CatalogAlbumCard(album: a)],
                    ),
                    Shelf(
                      title: context.l10n.commonArtists,
                      children: [for (final a in r.artists) CatalogArtistCard(artist: a)],
                    ),
                    _PlaylistShelf(query: query),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Deezer, Apple Music and Spotify playlists to import; loads on its own so slow services do not hold up the rest.
class _PlaylistShelf extends ConsumerWidget {
  const _PlaylistShelf({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(catalogPlaylistsProvider(query)).value ?? const <CatalogPlaylist>[];
    return Shelf(
      title: context.l10n.libraryPlaylists,
      children: [
        for (final p in playlists)
          MediaCard(
            image: NetworkCover(url: p.imageUrl, icon: Icons.queue_music),
            title: p.name,
            subtitle: [p.sourceName, ?p.owner].join(' • '),
            onTap: () => context.push(Uri(path: '/catalog/playlist', queryParameters: {'link': p.link}).toString()),
          ),
      ],
    );
  }
}

/// The songs of a Deezer, Apple Music or Spotify playlist; importing it creates a playlist in the library and
/// downloads the songs that are missing.
class CatalogPlaylistPage extends ConsumerStatefulWidget {
  const CatalogPlaylistPage({super.key, required this.link});
  final String link;

  @override
  ConsumerState<CatalogPlaylistPage> createState() => _CatalogPlaylistPageState();
}

class _CatalogPlaylistPageState extends ConsumerState<CatalogPlaylistPage> {
  bool _busy = false;

  Future<void> _import() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiProvider)
          .startSpotifyImport(liked: false, playlistIds: const [], links: [widget.link], downloadMissing: true);
      if (!mounted) return;
      showMessage(
        context,
        l10n.spotifyStarted,
        action: SnackBarAction(label: l10n.catalogPlaylistShowImport, onPressed: () => context.push('/spotify')),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = ref.watch(catalogPlaylistProvider(widget.link));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(catalogPlaylistProvider(widget.link)),
        builder: (d) {
          final p = d.playlist;
          final total = d.tracks.length;
          final have = d.inLibraryCount;
          final duration = d.tracks.fold<double>(0, (s, t) => s + (t.duration ?? 0));
          final accent = Theme.of(context).colorScheme.primary;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CollectionHeader(
                  image: NetworkCover(url: p.imageUrl, icon: Icons.queue_music),
                  kind: l10n.catalogPlaylistKind,
                  title: p.name,
                  meta: Text(
                    [
                      p.sourceName,
                      ?p.owner,
                      songs(l10n, total),
                      if (duration > 0) formatLongDuration(l10n, duration),
                      have == total && total > 0 ? l10n.catalogAllInLibrary : l10n.catalogLibraryCount(have, total),
                    ].join(' • '),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy || total == 0 ? null : _import,
                            icon: const Icon(Icons.download_rounded),
                            label: Text(d.playlistId == null ? l10n.catalogPlaylistImport : l10n.catalogPlaylistUpdate),
                          ),
                          if (d.playlistId != null)
                            OutlinedButton.icon(
                              onPressed: () => context.push('/playlist/${d.playlistId}'),
                              icon: const Icon(Icons.library_music_outlined),
                              label: Text(l10n.catalogOpenInLibrary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.catalogPlaylistImportHint,
                        style: const TextStyle(color: Palette.textMuted, fontSize: 13),
                      ),
                      if (p.source == 'spotify' && total == 100)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.catalogSpotifyPreviewLimit,
                            style: const TextStyle(color: Palette.textMuted, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverList.builder(
                  itemCount: total,
                  itemBuilder: (context, i) {
                    final t = d.tracks[i];
                    return ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 28,
                        child: Center(
                          child: t.libraryId != null
                              ? Icon(Icons.check_circle, size: 18, color: accent)
                              : Text('${i + 1}', style: const TextStyle(color: Palette.textMuted)),
                        ),
                      ),
                      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text([t.artist, ?t.album].join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: t.duration == null
                          ? null
                          : Text(
                              formatDuration(Duration(milliseconds: (t.duration! * 1000).round())),
                              style: const TextStyle(color: Palette.textMuted),
                            ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: kBottomInset)),
            ],
          );
        },
      ),
    );
  }
}

class CatalogAlbumPage extends ConsumerWidget {
  const CatalogAlbumPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(catalogAlbumProvider(id));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(catalogAlbumProvider(id)),
        builder: (d) {
          final a = d.album;
          final total = d.tracks.length;
          final have = d.inLibraryCount;
          final multiDisc = d.tracks.map((t) => t.discNo ?? 1).toSet().length > 1;
          final rows = <Widget>[];
          int? disc;
          for (final t in d.tracks) {
            if (multiDisc && t.discNo != disc) {
              disc = t.discNo;
              rows.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    context.l10n.commonDiscNumber(disc ?? 1),
                    style: const TextStyle(color: Palette.textMuted, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }
            rows.add(CatalogTrackRow(track: t, number: t.trackNo, showCover: false));
          }
          final duration = d.tracks.fold<double>(0, (s, t) => s + (t.duration ?? 0));
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CollectionHeader(
                  image: NetworkCover(url: a.coverBigUrl ?? a.coverUrl),
                  kind: a.typeLabel(context.l10n),
                  title: a.title,
                  meta: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InkWell(
                        onTap: a.artistId == null ? null : () => context.push('/catalog/artist/${a.artistId}'),
                        child: Text(
                          a.artist,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      Text(
                        [
                          if (a.year != null) ' • ${a.year}',
                          ' • ${songs(context.l10n, total)}',
                          if (duration > 0) ', ${formatLongDuration(context.l10n, duration)}',
                          ' • ${have == total ? context.l10n.catalogAllInLibrary : context.l10n.catalogLibraryCount(have, total)}',
                        ].join(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (have < total)
                        RequestButton(
                          kind: 'album',
                          catalogId: a.id,
                          inLibrary: false,
                          label: have == 0
                              ? context.l10n.catalogDownloadAlbum
                              : total - have == 1
                              ? context.l10n.catalogDownloadMissingSong
                              : context.l10n.catalogDownloadMissingSongs(total - have),
                        ),
                      if (a.libraryId != null)
                        OutlinedButton.icon(
                          onPressed: () => context.push('/album/${a.libraryId}'),
                          icon: const Icon(Icons.library_music_outlined),
                          label: Text(context.l10n.catalogOpenInLibrary),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverList.list(children: rows),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: kBottomInset)),
            ],
          );
        },
      ),
    );
  }
}

class CatalogArtistPage extends ConsumerWidget {
  const CatalogArtistPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(catalogArtistProvider(id));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(catalogArtistProvider(id)),
        builder: (d) {
          final groups = [
            (context.l10n.commonAlbums, d.albums.where((a) => a.recordType == 'album').toList()),
            (context.l10n.catalogEps, d.albums.where((a) => a.recordType == 'ep').toList()),
            (context.l10n.catalogSingles, d.albums.where((a) => a.recordType == 'single').toList()),
          ];
          final have = d.albums.where((a) => a.libraryId != null).length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CollectionHeader(
                  circleImage: true,
                  image: NetworkCover(url: d.artist.pictureUrl, radius: 0, icon: Icons.person),
                  kind: context.l10n.commonArtist,
                  title: d.artist.name,
                  meta: Text(context.l10n.catalogArtistReleases(d.albums.length, have)),
                ),
              ),
              if (d.artist.libraryId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/artist/${d.artist.libraryId}'),
                        icon: const Icon(Icons.library_music_outlined),
                        label: Text(context.l10n.catalogOpenInLibrary),
                      ),
                    ),
                  ),
                ),
              if (d.topTracks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(context.l10n.artistPopular, style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverList.list(children: [for (final t in d.topTracks) CatalogTrackRow(track: t)]),
                ),
              ],
              for (final (title, albums) in groups)
                if (albums.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    sliver: SliverGrid.extent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.72,
                      children: [for (final a in albums) CatalogAlbumCard(album: a, showArtist: false)],
                    ),
                  ),
                ],
              const SliverToBoxAdapter(child: SizedBox(height: kBottomInset)),
            ],
          );
        },
      ),
    );
  }
}

/// Downloads overview: own requests for everyone, all requests + approvals for admins.
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  String _scope = 'mine';

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(sessionProvider.select((s) => s.user?.isAdmin ?? false));
    final scope = isAdmin ? _scope : 'mine';
    return DefaultTabController(
      // The failed tab is for admins, who fix songs with a new link or a retry.
      length: isAdmin ? 3 : 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(context.l10n.navDownloads, style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'mine', label: Text(context.l10n.downloadsMine)),
                    ButtonSegment(value: 'all', label: Text(context.l10n.downloadsAllUsers)),
                  ],
                  selected: {scope},
                  onSelectionChanged: (s) => setState(() => _scope = s.first),
                ),
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: context.l10n.downloadsOpen),
              Tab(text: context.l10n.downloadsCompleted),
              if (isAdmin) Tab(text: context.l10n.downloadsFailed),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestList(scope: scope, state: 'open', empty: context.l10n.downloadsEmptyActive),
            _RequestList(scope: scope, state: 'finished', empty: context.l10n.downloadsEmptyCompleted),
            if (isAdmin) _RequestList(scope: scope, state: 'failed', empty: context.l10n.downloadsEmptyFailed),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends ConsumerStatefulWidget {
  const _RequestList({required this.scope, required this.state, required this.empty});
  final String scope;
  final String state;
  final String empty;

  @override
  ConsumerState<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends ConsumerState<_RequestList> {
  static const _pageSize = 100;
  int _count = _pageSize;

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final key = (scope, widget.state, _count);
    final failedTab = widget.state == 'failed';
    return AsyncBody(
      value: ref.watch(requestsProvider(key)),
      onRetry: () => ref.invalidate(requestsProvider(key)),
      builder: (page) {
        final list = page.items;
        if (list.isEmpty) {
          return Center(
            child: Text(
              widget.empty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.textMuted),
            ),
          );
        }
        final more = list.length < page.total;
        final header = failedTab ? 1 : 0;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, kBottomInset),
          itemCount: header + list.length + (more ? 1 : 0),
          itemBuilder: (context, i) {
            if (i < header) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _retryAll(context, ref),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.downloadsRetryAll),
                    ),
                    const SizedBox(width: 12),
                    Text(context.l10n.downloadsCount(page.total), style: const TextStyle(color: Palette.textMuted)),
                  ],
                ),
              );
            }
            if (i - header < list.length) return _RequestTile(request: list[i - header], showUser: scope == 'all');
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: OutlinedButton(
                  onPressed: () => setState(() => _count += _pageSize),
                  child: Text(context.l10n.downloadsLoadMore(list.length, page.total)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _retryAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(context.l10n.downloadsRetryAll),
        content: Text(context.l10n.downloadsRetryAllConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(context.l10n.downloadsRetryAll)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final result = await ref.read(downloadActionsProvider).retryAllFailed(widget.scope);
      if (context.mounted) showInfo(context, context.l10n.downloadsRetryAllDone(result.songs, result.requests));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.request, required this.showUser});
  final DownloadRequest request;
  final bool showUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final isAdmin = ref.watch(sessionProvider.select((s) => s.user?.isAdmin ?? false));
    const muted = TextStyle(color: Palette.textMuted, fontSize: 13);
    final counts = r.kind == 'album' ? ' • ${r.doneCount}/${songs(context.l10n, r.itemCount)}' : '';
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => context.push('/downloads/${r.id}'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: NetworkCover(
                url: r.coverUrl,
                icon: r.kind == 'upgrade'
                    ? Icons.high_quality
                    : r.kind == 'redownload'
                    ? Icons.restart_alt
                    : r.kind == 'album'
                    ? Icons.album
                    : r.kind == 'search'
                    ? Icons.travel_explore
                    : Icons.music_note,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    [
                      r.kind == 'upgrade'
                          ? context.l10n.downloadsQualityUpgrade
                          : r.kind == 'redownload'
                          ? context.l10n.downloadsRedownload
                          : r.kind == 'album'
                          ? context.l10n.commonAlbum
                          : r.kind == 'search'
                          ? context.l10n.downloadsSearch
                          : context.l10n.commonSong,
                      r.artist,
                      if (showUser) context.l10n.downloadsRequestedBySuffix((r.user.name).toString()),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(requestStatusIcon(r.status), size: 14, color: requestStatusColor(context, r.status)),
                      const SizedBox(width: 4),
                      Text('${requestStatusLabel(context.l10n, r.status)}$counts', style: muted.copyWith(fontSize: 12)),
                    ],
                  ),
                  if (r.status == 'active') ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: r.progress, minHeight: 3, borderRadius: BorderRadius.circular(2)),
                  ],
                ],
              ),
            ),
            _CopyButton(artist: r.artist, title: r.title),
            if (isAdmin && r.status == 'pending_approval') ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: context.l10n.downloadsReject,
                icon: const Icon(Icons.close),
                onPressed: () => _reject(context, ref, r),
              ),
              IconButton.filled(
                tooltip: context.l10n.downloadsApprove,
                icon: const Icon(Icons.check),
                onPressed: () => _run(context, () => ref.read(downloadActionsProvider).action(r.id, 'approve')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Copies "Artist - Title" so a failed download can be looked up in the browser.
Future<void> copySearchText(BuildContext context, String artist, String title) async {
  final text = [artist, title].where((s) => s.trim().isNotEmpty).join(' - ');
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showInfo(context, context.l10n.downloadsCopied(text));
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.artist, required this.title});
  final String artist;
  final String title;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.downloadsCopyTitle,
    icon: const Icon(Icons.content_copy, size: 18),
    visualDensity: VisualDensity.compact,
    color: Palette.textMuted,
    onPressed: () => copySearchText(context, artist, title),
  );
}

Future<void> _run(BuildContext context, Future<void> Function() fn) async {
  try {
    await fn();
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

Future<void> _reject(BuildContext context, WidgetRef ref, DownloadRequest r) async {
  final note = await promptText(context, context.l10n.downloadsRejectRequest, context.l10n.downloadsReasonOptional);
  if (note == null || !context.mounted) return;
  await _run(context, () => ref.read(downloadActionsProvider).reject(r.id, note: note.isEmpty ? null : note));
}

class RequestDetailPage extends ConsumerWidget {
  const RequestDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(requestDetailProvider(id));
    final user = ref.watch(sessionProvider.select((s) => s.user));
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(context.l10n.downloadsDownload)),
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(requestDetailProvider(id)),
        builder: (r) {
          final isAdmin = user?.isAdmin ?? false;
          final actions = ref.read(downloadActionsProvider);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, kBottomInset),
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: NetworkCover(
                      url: r.coverUrl,
                      icon: r.kind == 'upgrade'
                          ? Icons.high_quality
                          : r.kind == 'redownload'
                          ? Icons.restart_alt
                          : r.kind == 'search'
                          ? Icons.travel_explore
                          : Icons.album,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Tooltip(
                                message: context.l10n.downloadsCopyTitle,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => copySearchText(context, r.artist, r.title),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.title,
                                        style: Theme.of(context).textTheme.headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      Text(r.artist, style: const TextStyle(color: Palette.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _CopyButton(artist: r.artist, title: r.title),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.downloadsProgress(
                            (requestStatusLabel(context.l10n, r.status)).toString(),
                            r.doneCount,
                            r.itemCount,
                            (r.failedCount > 0 ? context.l10n.downloadsFailedSuffix(r.failedCount) : '').toString(),
                          ),
                        ),
                        if (isAdmin)
                          Text(
                            context.l10n.downloadsRequestedBy((r.user.name).toString()),
                            style: const TextStyle(color: Palette.textMuted),
                          ),
                        if (r.note != null)
                          Text(
                            context.l10n.downloadsReason((r.note).toString()),
                            style: const TextStyle(color: Palette.textMuted),
                          ),
                        if (r.torrentStatus != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _torrentLabel(context.l10n, r),
                            style: const TextStyle(color: Palette.textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (r.torrentStatus == 'downloading') ...[
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: r.torrentProgress,
                              minHeight: 3,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isAdmin && r.status == 'pending_approval') ...[
                    FilledButton.icon(
                      onPressed: () => _run(context, () => actions.action(r.id, 'approve')),
                      icon: const Icon(Icons.check),
                      label: Text(context.l10n.downloadsApprove),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _reject(context, ref, r),
                      icon: const Icon(Icons.close),
                      label: Text(context.l10n.downloadsReject),
                    ),
                  ],
                  if (r.failedCount > 0 && r.status != 'rejected')
                    FilledButton.tonalIcon(
                      onPressed: () => _run(context, () => actions.action(r.id, 'retry')),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.downloadsRetryFailed),
                    ),
                  if (r.isOpen)
                    OutlinedButton.icon(
                      onPressed: () => _run(context, () => actions.action(r.id, 'cancel')),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(context.l10n.commonCancel),
                    ),
                  if (isAdmin && !r.isOpen)
                    TextButton.icon(
                      onPressed: () => _run(context, () async {
                        await actions.delete(r.id);
                        if (context.mounted) context.pop();
                      }),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(context.l10n.downloadsDeleteEntry),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final item in r.items) _ItemRow(request: r, item: item),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _ownSource(BuildContext context, WidgetRef ref, DownloadRequest r, DownloadItem item) async {
  final controller = TextEditingController();
  final url = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(context.l10n.downloadsOwnSource),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: context.l10n.downloadsOwnSourceLabel,
          helperText: context.l10n.downloadsOwnSourceHint,
          helperMaxLines: 2,
        ),
        onSubmitted: (v) => Navigator.pop(dialog, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: Text(context.l10n.commonCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, controller.text.trim()),
          child: Text(context.l10n.downloadsDownload),
        ),
      ],
    ),
  );
  controller.dispose();
  if (url == null || url.isEmpty || !context.mounted) return;
  await _run(context, () => ref.read(downloadActionsProvider).setItemSource(r.id, item.id, url));
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.request, required this.item});
  final DownloadRequest request;
  final DownloadItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const muted = TextStyle(color: Palette.textMuted, fontSize: 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Icon(requestStatusIcon(item.status), size: 20, color: requestStatusColor(context, item.status)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => copySearchText(context, item.artist, item.title),
                  child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  [
                    item.artist,
                    requestStatusLabel(context.l10n, item.status),
                    if (item.source == 'youtube') context.l10n.catalogYouTubeMusic,
                    if (item.source == 'torrent') context.l10n.downloadsTorrent,
                    if (item.source == 'soundcloud') 'SoundCloud',
                    if (item.source == 'bandcamp') 'Bandcamp',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
                if (item.error != null)
                  Text(item.error!, style: muted.copyWith(color: Theme.of(context).colorScheme.error)),
                if (item.status == 'downloading') ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: item.progress, minHeight: 3, borderRadius: BorderRadius.circular(2)),
                ],
              ],
            ),
          ),
          if (item.duration != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(formatDuration(Duration(seconds: item.duration!.round())), style: muted),
            ),
          _CopyButton(artist: item.artist, title: item.title),
          if (item.status == 'failed' && request.status != 'rejected')
            IconButton(
              tooltip: context.l10n.downloadsOwnSource,
              icon: const Icon(Icons.add_link),
              visualDensity: VisualDensity.compact,
              onPressed: () => _ownSource(context, ref, request, item),
            ),
        ],
      ),
    );
  }
}

String _torrentLabel(AppLocalizations l10n, DownloadRequest r) => switch (r.torrentStatus) {
  'searching' => l10n.downloadsSearchingTorrent,
  'downloading' => l10n.downloadsTorrentProgress((r.torrentName ?? '').toString(), (r.torrentProgress * 100).round()),
  'importing' => l10n.downloadsImportingTorrent,
  'done' => l10n.downloadsTorrentName((r.torrentName ?? '').toString()),
  'failed' => l10n.downloadsTorrentFallback((r.torrentError == null ? '' : ' (${r.torrentError})').toString()),
  _ => '',
};
