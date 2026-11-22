import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/library.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../widgets/collection.dart';
import '../widgets/common.dart';

/// A song with a button that adds it to the playlist (a check mark once added).
class AddableTrackRow extends StatelessWidget {
  const AddableTrackRow({super.key, required this.track, required this.added, required this.onAdd, this.onPlay});
  final Track track;
  final bool added;
  final VoidCallback onAdd;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: SizedBox(width: 48, height: 48, child: CoverImage(albumId: track.album.id, size: 96)),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        track.artistCredit,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Palette.textMuted),
      ),
      onTap: onPlay,
      trailing: IconButton(
        tooltip: added ? context.l10n.playlistAdded : context.l10n.playlistAddSong,
        icon: Icon(
          added ? Icons.check_circle : Icons.add_circle_outline,
          color: added ? Theme.of(context).colorScheme.primary : Colors.white70,
        ),
        onPressed: added ? null : onAdd,
      ),
    );
  }
}

/// "Recommended songs" under a playlist: suggestions to add, based on its songs (or the user's likes while it is
/// empty), a button to refresh them and one to search.
class PlaylistSuggestions extends ConsumerStatefulWidget {
  const PlaylistSuggestions({super.key, required this.playlistId, required this.trackIds});
  final String playlistId;
  final List<String> trackIds;

  @override
  ConsumerState<PlaylistSuggestions> createState() => _PlaylistSuggestionsState();
}

class _PlaylistSuggestionsState extends ConsumerState<PlaylistSuggestions> {
  static const _count = 10;
  List<Track>? _tracks;
  final _shown = <String>{};
  final _added = <String>{};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      // The playlist's latest songs say most about where it is going.
      final seeds = widget.trackIds.length > 50
          ? widget.trackIds.sublist(widget.trackIds.length - 50)
          : widget.trackIds;
      final tracks = await ref
          .read(apiProvider)
          .recommendations(
            trackIds: seeds,
            excludeIds: {...widget.trackIds, ..._shown}.take(2000).toList(),
            limit: _count,
          );
      if (!mounted) return;
      _shown.addAll(tracks.map((t) => t.id));
      setState(() => _tracks = tracks);
    } catch (_) {
      if (mounted) setState(() => _tracks ??= const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(Track track) async {
    setState(() => _added.add(track.id));
    try {
      await ref.read(libraryActionsProvider).addToPlaylist(widget.playlistId, [track.id]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _added.remove(track.id));
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracks = _tracks;
    // Added songs leave the list, as they are in the playlist above now.
    final visible = [
      for (final t in tracks ?? const <Track>[])
        if (!_added.contains(t.id)) t,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              context.l10n.playlistRecommended,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
            child: Text(
              widget.trackIds.isEmpty
                  ? context.l10n.playlistRecommendedFromLikes
                  : context.l10n.playlistRecommendedFromPlaylist,
              style: TextStyle(color: Palette.textMuted),
            ),
          ),
          if (tracks == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visible.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(context.l10n.playlistNoRecommendations, style: TextStyle(color: Palette.textMuted)),
            )
          else
            for (final (i, t) in visible.indexed)
              AddableTrackRow(
                key: ValueKey(t.id),
                track: t,
                added: false,
                onAdd: () => _add(t),
                onPlay: () => playMusic(context, ref, visible, index: i),
              ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.playlistRefreshRecommendations),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/playlist/${widget.playlistId}/add'),
                icon: const Icon(Icons.search),
                label: Text(context.l10n.playlistSearchSongs),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Search that adds songs to a playlist straight away.
class PlaylistAddSongsPage extends ConsumerStatefulWidget {
  const PlaylistAddSongsPage({super.key, required this.playlistId});
  final String playlistId;

  @override
  ConsumerState<PlaylistAddSongsPage> createState() => _PlaylistAddSongsPageState();
}

class _PlaylistAddSongsPageState extends ConsumerState<PlaylistAddSongsPage> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<Track>? _results;
  String _searched = '';
  final _added = <String>{};

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(text.trim()));
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() {
        _results = null;
        _searched = '';
      });
      return;
    }
    try {
      final result = await ref.read(apiProvider).search(q);
      // An older search finishing late must not replace a newer one.
      if (!mounted || _query.text.trim() != q) return;
      setState(() {
        _results = result.tracks;
        _searched = q;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _add(Track track) async {
    setState(() => _added.add(track.id));
    try {
      await ref.read(libraryActionsProvider).addToPlaylist(widget.playlistId, [track.id]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _added.remove(track.id));
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _changed,
          onSubmitted: (text) => _search(text.trim()),
          decoration: InputDecoration(
            hintText: context.l10n.playlistSearchHint,
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _query.clear();
                _search('');
              },
            ),
          ),
        ),
      ),
      body: results == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.playlistSearchEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.textMuted),
                ),
              ),
            )
          : results.isEmpty
          ? Center(child: Text(context.l10n.playlistSearchNothing(_searched)))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: kBottomInset),
              itemCount: results.length,
              itemBuilder: (_, i) => AddableTrackRow(
                track: results[i],
                added: _added.contains(results[i].id),
                onAdd: () => _add(results[i]),
                onPlay: () => playMusic(context, ref, results, index: i),
              ),
            ),
    );
  }
}
