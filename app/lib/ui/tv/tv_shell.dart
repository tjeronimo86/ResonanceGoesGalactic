import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audiobooks.dart';
import '../../core/books.dart';
import '../../core/desktop.dart';
import '../../core/podcasts.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../widgets/logo.dart';
import 'tv_focusable.dart';
import 'tv_now_playing.dart';

class TvShell extends ConsumerStatefulWidget {
  const TvShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  ConsumerState<TvShell> createState() => _TvShellState();
}

class _TvShellState extends ConsumerState<TvShell> {
  final _rail = FocusScopeNode(debugLabel: 'TV navigation');
  final _content = FocusScopeNode(debugLabel: 'TV content');
  final _railNodes = <String, FocusNode>{};
  final _bar = FocusNode(debugLabel: 'TV now playing bar');

  void _syncRailNodes(List<(String, IconData, String)> entries) {
    final paths = entries.map((entry) => entry.$1).toSet();
    for (final path in _railNodes.keys.toList()) {
      if (!paths.contains(path)) _railNodes.remove(path)!.dispose();
    }
    for (final path in paths) {
      _railNodes.putIfAbsent(path, () => FocusNode(debugLabel: path == '/' ? 'TV Home' : 'TV $path'));
    }
  }

  void _focusCurrentRailEntry() {
    final path = _railNodes.keys
        .where(
          (path) => path == '/'
              ? widget.location == '/'
              : widget.location == path || widget.location.startsWith('$path/'),
        )
        .fold<String?>('/', (best, path) => path.length > (best?.length ?? 0) ? path : best);
    _railNodes[path ?? '/']?.requestFocus();
  }

  /// Directions the content cannot move further in leave it: down to the now-playing bar, left to the rail.
  KeyEventResult _leaveContent(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final focus = FocusManager.instance.primaryFocus;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (focus == null || !focus.focusInDirection(TraversalDirection.down)) _bar.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (focus == null || !focus.focusInDirection(TraversalDirection.left)) _focusCurrentRailEntry();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _leaveBar(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final focus = FocusManager.instance.primaryFocus;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _enterContent();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
        (focus == null || !focus.focusInDirection(TraversalDirection.left))) {
      _focusCurrentRailEntry();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _toggleBar() => _bar.hasFocus ? _enterContent() : _bar.requestFocus();

  /// Down past the last rail entry reaches the bar, so it never takes scrolling to the end of a page.
  void _railDown() {
    if (!(FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.down) ?? false)) _bar.requestFocus();
  }

  void _enterContent() {
    FocusNode target = _content;
    while (target is FocusScopeNode && target.focusedChild != null) {
      target = target.focusedChild!;
    }
    if (target is FocusScopeNode) {
      _content.nextFocus();
    } else {
      target.requestFocus();
    }
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else if (widget.location != '/') {
      router.go('/');
    } else if (!_rail.hasFocus) {
      _focusCurrentRailEntry();
    } else if (!isDesktop) {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _rail.dispose();
    _content.dispose();
    for (final node in _railNodes.values) {
      node.dispose();
    }
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ebooks = ref.watch(ebooksVisibleProvider);
    final audiobooks = ref.watch(audiobooksVisibleProvider);
    final podcasts = ref.watch(podcastsVisibleProvider);
    final media = ebooks || audiobooks || podcasts
        ? _tvMediaEntry(l10n, ebooks: ebooks, audiobooks: audiobooks, podcasts: podcasts)
        : null;
    final entries = [
      ('/', Icons.home_outlined, l10n.navHome),
      ('/search', Icons.search, l10n.navSearch),
      ('/library', Icons.library_music_outlined, l10n.navLibrary),
      ('/world-radio', Icons.public, l10n.worldRadioTitle),
      ?media,
      ('/settings', Icons.settings_outlined, l10n.navSettings),
    ];
    _syncRailNodes(entries);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontSizeFactor: 1.35),
        focusColor: Colors.white24,
        listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.all(16), minTileHeight: 80),
      ),
      child: Actions(
        actions: {
          TvBackIntent: CallbackAction<TvBackIntent>(onInvoke: (_) => _back()),
          TvNowPlayingBarIntent: CallbackAction<TvNowPlayingBarIntent>(onInvoke: (_) => _toggleBar()),
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Scaffold(
            backgroundColor: Palette.background,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width < 1100 ? 210 : 280,
                          child: ColoredBox(
                            color: Palette.sidebar,
                            child: FocusScope(
                              node: _rail,
                              child: Actions(
                                actions: {
                                  TvDirectionIntent: CallbackAction<TvDirectionIntent>(
                                    onInvoke: (intent) {
                                      if (intent.direction == TraversalDirection.right) {
                                        _enterContent();
                                      } else if (intent.direction == TraversalDirection.down) {
                                        _railDown();
                                      } else {
                                        FocusManager.instance.primaryFocus?.focusInDirection(intent.direction);
                                      }
                                      return null;
                                    },
                                  ),
                                },
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) {
                                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                      _enterContent();
                                      return KeyEventResult.handled;
                                    }
                                    if (event is! KeyUpEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                      _railDown();
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Center(child: ResonanceLogo(size: 64)),
                                        const SizedBox(height: 32),
                                        for (final (path, icon, label) in entries)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: TvFocusable(
                                              autofocus: path == '/',
                                              focusNode: _railNodes[path],
                                              onActivate: () => context.go(path),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      icon,
                                                      color:
                                                          (path == media?.$1
                                                              ? _isTvMediaLocation(widget.location)
                                                              : widget.location.startsWith(path))
                                                          ? theme.colorScheme.primary
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(child: Text(label, maxLines: 2)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: (_, event) => _leaveContent(event),
                            child: Actions(
                              actions: {
                                TvDirectionIntent: CallbackAction<TvDirectionIntent>(
                                  onInvoke: (intent) {
                                    final focus = FocusManager.instance.primaryFocus;
                                    if (focus?.focusInDirection(intent.direction) ?? false) return null;
                                    if (intent.direction == TraversalDirection.down) {
                                      _bar.requestFocus();
                                    } else if (intent.direction == TraversalDirection.left) {
                                      _focusCurrentRailEntry();
                                    }
                                    return null;
                                  },
                                ),
                              },
                              child: FocusScope(
                                node: _content,
                                child: FocusTraversalGroup(child: widget.child),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onKeyEvent: (_, event) => _leaveBar(event),
                    child: Actions(
                      actions: {
                        TvDirectionIntent: CallbackAction<TvDirectionIntent>(
                          onInvoke: (intent) {
                            final focus = FocusManager.instance.primaryFocus;
                            switch (intent.direction) {
                              case TraversalDirection.up:
                                _enterContent();
                              case TraversalDirection.left:
                                if (!(focus?.focusInDirection(TraversalDirection.left) ?? false)) {
                                  _focusCurrentRailEntry();
                                }
                              case TraversalDirection.right:
                                focus?.focusInDirection(TraversalDirection.right);
                              case TraversalDirection.down:
                                break;
                            }
                            return null;
                          },
                        ),
                      },
                      child: TvNowPlayingBar(focusNode: _bar),
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
}

(String, IconData, String) _tvMediaEntry(
  AppLocalizations l10n, {
  required bool ebooks,
  required bool audiobooks,
  required bool podcasts,
}) {
  final count = [ebooks, audiobooks, podcasts].where((enabled) => enabled).length;
  if (count > 1) return ('/books', Icons.video_library, l10n.navMedia);
  if (ebooks) return ('/books', Icons.menu_book, l10n.navBooks);
  if (audiobooks) return ('/audiobooks', Icons.headphones, l10n.navAudiobooks);
  return ('/podcasts', Icons.podcasts, l10n.navPodcasts);
}

bool _isTvMediaLocation(String location) =>
    location.startsWith('/books') || location.startsWith('/audiobooks') || location.startsWith('/podcasts');
