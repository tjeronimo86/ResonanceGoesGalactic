import 'package:flutter/foundation.dart';
import 'galactic/galactic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/widgets/jam_sheet.dart';
import 'ui/widgets/changelog.dart';

import 'core/session.dart';
import 'core/tv_mode.dart';
import 'l10n/l10n.dart';
import 'ui/tv/tv_shell.dart';
import 'ui/tv/tv_page.dart';
import 'ui/tv/tv_browse_pages.dart';
import 'ui/tv/tv_detail_page.dart';
import 'ui/tv/tv_ambient.dart';
import 'ui/tv/tv_now_playing.dart';
import 'ui/tv/tv_form_navigation.dart';
import 'ui/tv/tv_media_pages.dart';
import 'ui/tv/tv_radio_page.dart';
import 'ui/tv/tv_search_page.dart';
import 'ui/pages/admin/admin_page.dart';
import 'ui/pages/playlist_add_page.dart';
import 'ui/pages/admin/duplicates_page.dart';
import 'ui/pages/audiobook_pages.dart';
import 'ui/pages/audiobook_stats_page.dart';
import 'ui/pages/podcast_pages.dart';
import 'ui/pages/auth_pages.dart';
import 'ui/pages/book_pages.dart';
import 'ui/pages/browse_pages.dart';
import 'ui/pages/changelog_page.dart';
import 'ui/pages/collection_pages.dart';
import 'ui/pages/download_pages.dart';
import 'ui/pages/equalizer_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/world_radio_page.dart';
import 'ui/pages/now_playing_page.dart';
import 'ui/pages/lyrics_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/storage_page.dart';
import 'ui/widgets/playlist_order.dart';
import 'ui/pages/spotify_page.dart';
import 'ui/pages/wrapped_page.dart';
import 'ui/pages/spotify_sync_page.dart';
import 'ui/shell.dart';

const _publicRoutes = {'/login', '/register', '/server'};

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod session changes into go_router's refresh mechanism.
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final s = ref.read(sessionProvider);
      final loc = state.matchedLocation;
      // Remember where the user wanted to go (deep link / page reload) across splash and login.
      final from = loc == '/splash' || _publicRoutes.contains(loc)
          ? state.uri.queryParameters['from']
          : state.uri.toString();
      String withFrom(String path) => from == null || from == '/' ? path : '$path?from=${Uri.encodeComponent(from)}';

      if (s.loading) return loc == '/splash' ? null : withFrom('/splash');
      if (s.serverUrl == null && !kIsWeb) return loc == '/server' ? null : '/server';
      if (!s.loggedIn) {
        return _publicRoutes.contains(loc) ? null : withFrom('/login');
      }
      if (_publicRoutes.contains(loc) || loc == '/splash') return from ?? '/';
      if (loc.startsWith('/admin') && !(s.user?.isAdmin ?? false)) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/server', builder: (_, _) => const ServerPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterPage(invite: state.uri.queryParameters['invite']),
      ),
      GoRoute(
        path: '/now-playing',
        pageBuilder: (_, _) => CustomTransitionPage(
          child: Consumer(
            builder: (_, ref, _) =>
                ref.watch(tvModeProvider) ? const TvAmbientZone(child: TvNowPlayingPage()) : const NowPlayingPage(),
          ),
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
            child: child,
          ),
        ),
      ),
      // Outside the shell so it opens above the now-playing page and the mini player.
      GoRoute(path: '/queue', builder: (_, _) => const QueuePage()),
      GoRoute(path: '/lyrics', builder: (_, _) => const LyricsPage()),
      GoRoute(path: '/galactic', builder: (_, _) => const GalacticPage()),
      GoRoute(path: '/changelog', builder: (_, _) => const ChangelogPage()),
      GoRoute(
        path: '/wrapped',
        builder: (_, state) => WrappedPage(year: int.tryParse(state.uri.queryParameters['year'] ?? '')),
      ),
      ShellRoute(
        builder: (context, state, child) => WhatsNewNotifier(
          child: Consumer(
            builder: (_, ref, _) => ref.watch(tvModeProvider)
                ? TvShell(location: state.matchedLocation, child: child)
                : AppShell(location: state.matchedLocation, child: child),
          ),
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: TvPage(tvChild: TvHomePage(), child: HomePage()),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: TvPage(tvChild: TvSearchPage(), child: SearchPage()),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: TvPage(tvChild: TvLibraryPage(), child: LibraryPage()),
            ),
          ),
          GoRoute(
            path: '/world-radio',
            builder: (_, _) => const TvPage(tvChild: TvWorldRadioPage(), child: WorldRadioPage()),
          ),
          GoRoute(
            path: '/world-radio/search',
            builder: (_, _) => const TvPage(tvChild: TvRadioSearchPage(), child: WorldRadioPage()),
          ),
          GoRoute(
            path: '/jam/:code',
            builder: (_, state) => JoinJamPage(code: state.pathParameters['code']!),
          ),
          GoRoute(
            path: '/liked',
            builder: (_, _) => const TvPage(
              tvChild: TvDetailPage(kind: 'liked', id: ''),
              child: LikedPage(),
            ),
          ),
          GoRoute(
            path: '/album/:id',
            builder: (_, s) => TvPage(
              tvChild: TvDetailPage(kind: 'album', id: s.pathParameters['id']!),
              child: AlbumPage(id: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/artist/:id',
            builder: (_, s) => TvPage(
              tvChild: TvDetailPage(kind: 'artist', id: s.pathParameters['id']!),
              child: ArtistPage(id: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/playlist/:id',
            builder: (_, s) => TvPage(
              tvChild: TvDetailPage(kind: 'playlist', id: s.pathParameters['id']!),
              child: PlaylistPage(id: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/playlist/:id/order',
            builder: (_, s) => PlaylistOrderPage(playlistId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/playlist/:id/add',
            builder: (_, s) => PlaylistAddSongsPage(playlistId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/playlist/:id/spotify',
            builder: (_, s) => SpotifySyncPage(playlistId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/catalog/album/:id',
            builder: (_, s) => CatalogAlbumPage(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/catalog/playlist',
            builder: (_, s) => CatalogPlaylistPage(link: s.uri.queryParameters['link'] ?? ''),
          ),
          GoRoute(
            path: '/catalog/artist/:id',
            builder: (_, s) => CatalogArtistPage(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/downloads',
            pageBuilder: (_, _) => const NoTransitionPage(child: DownloadsPage()),
          ),
          GoRoute(
            path: '/downloads/:id',
            builder: (_, s) => RequestDetailPage(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/podcasts',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: TvPage(
                tvChild: TvMediaPage(section: TvMediaSection.podcasts),
                child: PodcastsPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/podcasts/search',
            builder: (_, _) => const TvPage(tvChild: TvPodcastSearchPage(), child: PodcastSearchPage()),
          ),
          GoRoute(
            path: '/podcasts/genre/:id',
            builder: (context, s) => PodcastGenrePage(
              id: int.parse(s.pathParameters['id']!),
              name: s.extra as String? ?? context.l10n.podcastsCategories,
            ),
          ),
          GoRoute(
            path: '/podcasts/:id',
            builder: (_, s) => TvPage(
              tvChild: TvPodcastPage(id: s.pathParameters['id']!),
              child: PodcastPage(id: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/audiobooks',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: TvPage(
                tvChild: TvMediaPage(section: TvMediaSection.audiobooks),
                child: AudiobooksPage(),
              ),
            ),
          ),
          GoRoute(path: '/audiobooks/stats', builder: (_, _) => const AudiobookStatsPage()),
          GoRoute(
            path: '/audiobooks/item/:id',
            builder: (_, s) => TvPage(
              tvChild: TvAudiobookPage(id: s.pathParameters['id']!),
              child: AudiobookPage(id: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/books',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: TvPage(tvChild: TvMediaPage(), child: BooksHubPage()),
            ),
          ),
          GoRoute(
            path: '/books/search',
            builder: (_, s) => BookSearchPage(query: s.uri.queryParameters['q'] ?? ''),
          ),
          GoRoute(
            path: '/books/item/:id',
            builder: (_, s) => TvPage(
              tvChild: TvFormNavigation(child: BookPage(id: s.pathParameters['id']!)),
              child: BookPage(id: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/books/list',
            builder: (_, s) =>
                BookListPage(author: s.uri.queryParameters['author'], series: s.uri.queryParameters['series']),
          ),
          GoRoute(path: '/books/authors', builder: (_, _) => const BookGroupsPage(series: false)),
          GoRoute(path: '/books/series', builder: (_, _) => const BookGroupsPage(series: true)),
          GoRoute(path: '/books/requests', builder: (_, _) => const BookRequestsPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(path: '/settings/equalizer', builder: (_, _) => const EqualizerPage()),
          GoRoute(path: '/settings/storage', builder: (_, _) => const StoragePage()),
          GoRoute(path: '/spotify', builder: (_, _) => const SpotifyImportPage()),
          GoRoute(
            path: '/admin',
            pageBuilder: (_, _) => const NoTransitionPage(child: AdminPage()),
          ),
          GoRoute(path: '/admin/duplicates', builder: (_, _) => const DuplicatesPage()),
        ],
      ),
    ],
  );
});
