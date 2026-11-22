import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../player/jam.dart';
import '../player/connect.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audiobooks.dart';
import '../core/podcasts.dart';
import '../core/books.dart';
import '../core/downloads.dart';
import '../core/library.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../player/player.dart';
import 'widgets/blends.dart';
import 'widgets/common.dart';
import 'widgets/player_bar.dart';
import 'widgets/update.dart';

typedef _MediaEntry = (String, IconData, IconData, String);

_MediaEntry? _mediaEntry(
  BuildContext context, {
  required bool ebooks,
  required bool audiobooks,
  required bool podcasts,
}) {
  final count = [ebooks, audiobooks, podcasts].where((enabled) => enabled).length;
  if (count == 0) return null;
  if (count > 1) {
    return ('/books', Icons.video_library_outlined, Icons.video_library, context.l10n.navMedia);
  }
  if (ebooks) {
    return ('/books', Icons.menu_book_outlined, Icons.menu_book, context.l10n.navBooks);
  }
  if (audiobooks) {
    return ('/audiobooks', Icons.headphones_outlined, Icons.headphones, context.l10n.navAudiobooks);
  }
  return ('/podcasts', Icons.podcasts_outlined, Icons.podcasts, context.l10n.navPodcasts);
}

bool _isMediaLocation(String location) =>
    location.startsWith('/books') || location.startsWith('/audiobooks') || location.startsWith('/podcasts');

/// App frame: Spotify-style sidebar + player bar on desktop, bottom nav + mini player on mobile.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(playerErrorsProvider, (_, next) {
      final error = next.asData?.value;
      if (error != null) showError(context, error);
    });
    // Keeps the Jam connection alive app-wide and shows its messages.
    ref.watch(jamProvider.select((v) => v?.state.code));
    ref.listen(jamMessagesProvider, (_, next) {
      final message = next.asData?.value;
      if (message != null && message.isNotEmpty) showInfo(context, message);
    });
    ref.watch(connectProvider.select((v) => v.connected));
    ref.listen(connectMessagesProvider, (_, next) {
      final message = next.asData?.value;
      if (message != null && message.isNotEmpty) showInfo(context, message);
    });
    final offline = !kIsWeb && ref.watch(sessionProvider.select((s) => s.offline));
    final isAdmin = ref.watch(sessionProvider.select((s) => s.user?.isAdmin ?? false));
    final audiobooks = ref.watch(audiobooksVisibleProvider);
    final ebooks = ref.watch(ebooksVisibleProvider);
    final podcasts = ref.watch(podcastsVisibleProvider);
    final media = _mediaEntry(context, ebooks: ebooks, audiobooks: audiobooks, podcasts: podcasts);
    final pendingApproval = isAdmin ? ref.watch(downloadSummaryProvider).value?.pendingApproval ?? 0 : 0;
    // Refresh library views whenever downloads finish.
    ref.listen(downloadSummaryProvider, (prev, next) {
      final before = prev?.value?.running ?? 0;
      final now = next.value?.running;
      if (now != null && now < before) ref.read(downloadActionsProvider).libraryChanged();
    });

    if (isWide(context)) {
      return Scaffold(
        backgroundColor: Palette.sidebar,
        // Tablets: Android's taskbar and status bar sit on top of the app; keep the sidebar and player clear of them.
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: _Sidebar(location: location, isAdmin: isAdmin, media: media),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ColoredBox(
                            color: Palette.background,
                            child: PlayerArea(child: UpdateNotifier(child: child)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              MeasureHeight(
                height: playerAreaHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [if (offline) const _OfflineBanner(), const DesktopPlayerBar()],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tabs = [
      ('/', Icons.home_outlined, Icons.home, context.l10n.navHome),
      ('/search', Icons.search, Icons.search, context.l10n.navSearch),
      ('/library', Icons.library_music_outlined, Icons.library_music, context.l10n.navLibrary),
      ?media,
      if (isAdmin) ('/admin', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, context.l10n.navAdmin),
    ];
    var selected = tabs.lastIndexWhere(
      (t) => t.$1 != '/' && (t.$1 == media?.$1 ? _isMediaLocation(location) : location.startsWith(t.$1)),
    );
    if (selected < 0) selected = 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PlayerArea(child: UpdateNotifier(child: child)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: MeasureHeight(
              height: playerAreaHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [if (offline) const _OfflineBanner(), const MiniPlayer()],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(tabs[i].$1),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: t.$1 == '/admin' && pendingApproval > 0,
                label: Text('$pendingApproval'),
                child: Icon(t.$2),
              ),
              selectedIcon: Icon(t.$3),
              label: t.$4,
            ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.location, required this.isAdmin, required this.media});
  final String location;
  final bool isAdmin;
  final _MediaEntry? media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final userId = ref.watch(currentUserIdProvider);
    final summary = ref.watch(downloadSummaryProvider).value ?? const DownloadSummary();

    Widget nav(String path, IconData icon, IconData activeIcon, String label, {int badge = 0}) {
      final active = path == '/'
          ? location == '/'
          : path == media?.$1
          ? _isMediaLocation(location)
          : location.startsWith(path);
      return ListTile(
        leading: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(active ? activeIcon : icon, color: active ? Colors.white : Palette.textMuted),
        ),
        title: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, color: active ? Colors.white : Palette.textMuted),
        ),
        onTap: () => context.go(path),
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              nav('/', Icons.home_outlined, Icons.home, context.l10n.navHome),
              nav('/search', Icons.search, Icons.search, context.l10n.navSearch),
              nav(
                '/downloads',
                Icons.download_outlined,
                Icons.download,
                context.l10n.navDownloads,
                badge: summary.running,
              ),
              if (media != null) nav(media!.$1, media!.$2, media!.$3, media!.$4),
              if (isAdmin)
                nav(
                  '/admin',
                  Icons.admin_panel_settings_outlined,
                  Icons.admin_panel_settings,
                  context.l10n.adminDashboard,
                  badge: summary.pendingApproval,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.library_music, color: Palette.textMuted),
                  title: Text(
                    context.l10n.navLibrary,
                    style: TextStyle(fontWeight: FontWeight.w700, color: Palette.textMuted),
                  ),
                  onTap: () => context.go('/library'),
                  trailing: IconButton(
                    tooltip: context.l10n.libraryCreate,
                    icon: const Icon(Icons.add, color: Palette.textMuted),
                    onPressed: () => showCreateSheet(context, ref),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _SidebarItem(
                        image: const LikedCover(),
                        title: context.l10n.libraryLikedSongs,
                        subtitle: context.l10n.commonPlaylist,
                        active: location == '/liked',
                        onTap: () => context.go('/liked'),
                      ),
                      // Only the user's own and shared playlists; mixes and radios live on the home page.
                      ...?playlists.value
                          ?.where((p) => !p.isMix && !p.isRadio)
                          .map(
                            (p) => _SidebarItem(
                              image: PlaylistCover(playlistId: p.id, coverKey: p.coverKey, albumIds: p.coverAlbumIds),
                              title: p.name,
                              subtitle: p.owner.id == userId
                                  ? context.l10n.commonPlaylist
                                  : context.l10n.libraryPlaylistBy((p.owner.name).toString()),
                              active: location == '/playlist/${p.id}',
                              onTap: () => context.go('/playlist/${p.id}'),
                            ),
                          ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: Palette.textMuted),
                  title: Text(context.l10n.navSettings, style: TextStyle(color: Palette.textMuted)),
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final Widget image;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: active ? Colors.white12 : Colors.transparent,
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(width: 48, child: image),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: const TextStyle(color: Palette.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => Material(
    color: Palette.surface,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 16, color: Palette.textMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(context.l10n.offlineBanner, style: const TextStyle(fontSize: 12, color: Palette.textMuted)),
          ),
        ],
      ),
    ),
  );
}
