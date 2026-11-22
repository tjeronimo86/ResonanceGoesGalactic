import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/downloads.dart';
import '../../core/library.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../l10n/l10n.dart';
import '../widgets/catalog.dart';
import '../widgets/common.dart';
import 'tv_browse_pages.dart';
import 'tv_focusable.dart';
import 'tv_keyboard_search.dart';
import 'tv_shelves.dart';

class TvSearchPage extends StatelessWidget {
  const TvSearchPage({super.key});

  @override
  Widget build(BuildContext context) => TvKeyboardSearch(
    hint: context.l10n.searchHint,
    resultsBuilder: (context, query, firstResult) => _TvSearchResults(query: query, firstResult: firstResult),
  );
}

class _TvSearchResults extends ConsumerWidget {
  const _TvSearchResults({required this.query, required this.firstResult});

  final String query;
  final FocusNode firstResult;

  bool _hasCatalogCards(CatalogSearch? catalog) =>
      (catalog?.albums.any((album) => album.libraryId == null) ?? false) ||
      (catalog?.tracks.any((track) => track.libraryId == null) ?? false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRequestDownloads = ref.watch(sessionProvider).loggedIn;
    final libraryValue = ref.watch(searchProvider(query));
    final catalogValue = canRequestDownloads ? ref.watch(catalogSearchProvider(query)) : null;
    final result = libraryValue.value;
    final catalog = catalogValue?.value;
    final pendingIds = canRequestDownloads ? ref.watch(openRequestIdsProvider) : const <String>{};
    final librarySettled = libraryValue.hasValue || libraryValue.hasError;
    final catalogSettled = catalogValue == null || catalogValue.hasValue || catalogValue.hasError;
    final hasResults = !(result?.isEmpty ?? true) || _hasCatalogCards(catalog);
    final focusNode = librarySettled && catalogSettled && hasResults ? firstResult : null;

    return TvAsync(
      value: libraryValue,
      onRetry: () => ref.invalidate(searchProvider(query)),
      builder: (library) => TvShelves(
        title: library.isEmpty && !_hasCatalogCards(catalog) ? context.l10n.searchNoLibraryResults(query) : '',
        autofocusFirstCard: false,
        firstCardFocusNode: focusNode,
        shelves: [
          TvShelfData(context.l10n.commonArtists, [for (final artist in library.artists) tvArtist(context, artist)]),
          TvShelfData(context.l10n.commonAlbums, [for (final album in library.albums) tvAlbum(context, album)]),
          TvShelfData(context.l10n.commonSongsTitle, [
            for (final (index, track) in library.tracks.indexed)
              TvCardData(
                title: track.title,
                subtitle: track.artistCredit,
                image: CoverImage(albumId: track.album.id),
                onActivate: () => playMusic(context, ref, library.tracks, index: index, contextId: 'search'),
              ),
          ]),
          TvShelfData(context.l10n.libraryPlaylists, [
            for (final playlist in library.playlists) tvPlaylist(context, playlist),
          ]),
          TvShelfData(context.l10n.searchInLyrics, [
            for (final (index, hit) in library.lyrics.indexed)
              TvCardData(
                title: hit.track.title,
                subtitle: context.l10n.searchLyricsLine(hit.line),
                image: CoverImage(albumId: hit.track.album.id),
                onActivate: () => playMusic(
                  context,
                  ref,
                  [for (final h in library.lyrics) h.track],
                  index: index,
                  contextId: 'search',
                ),
              ),
          ]),
          if (canRequestDownloads && catalog != null)
            TvShelfData(context.l10n.tvSearchAvailableAlbums, [
              for (final album in catalog.albums)
                if (album.libraryId == null)
                  TvCardData(
                    title: album.title,
                    subtitle: pendingIds.contains(album.id) ? context.l10n.catalogRequested : album.artist,
                    image: NetworkCover(url: album.coverBigUrl ?? album.coverUrl),
                    onActivate: () => _activateCatalog(
                      context,
                      ref,
                      kind: 'album',
                      catalogId: album.id,
                      title: album.title,
                      artist: album.artist,
                      requested: pendingIds.contains(album.id),
                    ),
                  ),
            ]),
          if (canRequestDownloads && catalog != null)
            TvShelfData(context.l10n.tvSearchAvailableSongs, [
              for (final track in catalog.tracks)
                if (track.libraryId == null)
                  TvCardData(
                    title: track.title,
                    subtitle: pendingIds.contains(track.id) ? context.l10n.catalogRequested : track.artist,
                    image: NetworkCover(url: track.coverUrl, icon: Icons.music_note),
                    onActivate: () => _activateCatalog(
                      context,
                      ref,
                      kind: 'track',
                      catalogId: track.id,
                      title: track.title,
                      artist: track.artist,
                      requested: pendingIds.contains(track.id),
                    ),
                  ),
            ]),
        ],
      ),
    );
  }
}

Future<void> _activateCatalog(
  BuildContext context,
  WidgetRef ref, {
  required String kind,
  required String catalogId,
  required String title,
  required String artist,
  required bool requested,
}) async {
  if (requested) {
    showInfo(context, context.l10n.catalogRequested);
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(context.l10n.tvCatalogRequestBy(artist)),
      actions: [
        TvButton(
          icon: Icons.download,
          label: context.l10n.catalogDownload,
          autofocus: true,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
        TvButton(
          icon: Icons.close,
          label: context.l10n.commonCancel,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final request = await ref.read(downloadActionsProvider).request(kind, catalogId);
    if (!context.mounted) return;
    showInfo(context, switch (request.status) {
      'pending_approval' => context.l10n.catalogAwaitingApproval(request.title),
      'done' => context.l10n.catalogAlreadyInLibrary(request.title),
      _ => context.l10n.catalogDownloadingTitle(request.title),
    });
  } catch (error) {
    if (context.mounted) showError(context, error);
  }
}
