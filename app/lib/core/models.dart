import '../l10n/l10n.dart';

// Plain data classes mirroring the server's JSON (see backend/app/schemas.py).

DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);

class NamedRef {
  const NamedRef(this.id, this.name);
  final String id;
  final String name;

  factory NamedRef.fromJson(Map<String, dynamic> j) => NamedRef(j['id'] as String, (j['name'] ?? j['title']) as String);
}

class User {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.accentColor,
    required this.isDisabled,
    required this.createdAt,
    this.lastSeenAt,
    this.hasSubsonicPassword = false,
  });

  final String id;
  final String username;
  final String displayName;
  final String role;
  final String accentColor;
  final bool isDisabled;
  final bool hasSubsonicPassword;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'role': role,
    'accent_color': accentColor,
    'is_disabled': isDisabled,
    'has_subsonic_password': hasSubsonicPassword,
    'created_at': createdAt.toIso8601String(),
    'last_seen_at': lastSeenAt?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'],
    username: j['username'],
    displayName: j['display_name'],
    role: j['role'],
    accentColor: j['accent_color'],
    isDisabled: j['is_disabled'] ?? false,
    hasSubsonicPassword: j['has_subsonic_password'] ?? false,
    createdAt: DateTime.parse(j['created_at']),
    lastSeenAt: _date(j['last_seen_at']),
  );
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistCredit,
    required this.album,
    required this.duration,
    this.trackNo,
    this.discNo,
    this.codec,
    this.bitrate,
    this.replayGainTrack,
    this.replayGainAlbum,
    this.liked = false,
  });

  final String id;
  final String title;
  final NamedRef artist;
  final String artistCredit;
  final NamedRef album;
  final double duration;
  final int? trackNo;
  final int? discNo;
  final String? codec;
  final int? bitrate;
  final double? replayGainTrack;
  final double? replayGainAlbum;
  final bool liked;

  Duration get length => Duration(milliseconds: (duration * 1000).round());

  Track copyWith({bool? liked}) => Track(
    id: id,
    title: title,
    artist: artist,
    artistCredit: artistCredit,
    album: album,
    duration: duration,
    trackNo: trackNo,
    discNo: discNo,
    codec: codec,
    bitrate: bitrate,
    replayGainTrack: replayGainTrack,
    replayGainAlbum: replayGainAlbum,
    liked: liked ?? this.liked,
  );

  factory Track.fromJson(Map<String, dynamic> j) => Track(
    id: j['id'],
    title: j['title'],
    artist: NamedRef.fromJson(j['artist']),
    artistCredit: j['artist_credit'],
    album: NamedRef.fromJson(noteCoverKey(j['album'])),
    duration: (j['duration'] as num).toDouble(),
    trackNo: j['track_no'],
    discNo: j['disc_no'],
    codec: j['codec'],
    bitrate: j['bitrate'],
    replayGainTrack: (j['replaygain_track_gain'] as num?)?.toDouble(),
    replayGainAlbum: (j['replaygain_album_gain'] as num?)?.toDouble(),
    liked: j['liked'] ?? false,
  );
}

class LyricLine {
  const LyricLine({required this.timeMs, required this.text});
  final int? timeMs;
  final String text;

  factory LyricLine.fromJson(Map<String, dynamic> j) => LyricLine(timeMs: j['time_ms'], text: j['text']);

  Map<String, dynamic> toJson() => {'time_ms': timeMs, 'text': text};
}

class Lyrics {
  const Lyrics({required this.synced, required this.instrumental, required this.source, required this.lines});
  final bool synced;
  final bool instrumental;
  final String? source;
  final List<LyricLine> lines;

  factory Lyrics.fromJson(Map<String, dynamic> j) => Lyrics(
    synced: j['synced'],
    instrumental: j['instrumental'],
    source: j['source'],
    lines: [for (final line in j['lines']) LyricLine.fromJson(line)],
  );

  Map<String, dynamic> toJson() => {
    'synced': synced,
    'instrumental': instrumental,
    'source': source,
    'lines': [for (final line in lines) line.toJson()],
  };
}

class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.hasCover,
    required this.trackCount,
    this.year,
    this.genre,
  });

  final String id;
  final String title;
  final NamedRef artist;
  final int? year;
  final String? genre;
  final bool hasCover;
  final int trackCount;

  factory Album.fromJson(Map<String, dynamic> j) => Album(
    id: noteCoverKey(j)['id'],
    title: j['title'],
    artist: NamedRef.fromJson(j['artist']),
    year: j['year'],
    genre: j['genre'],
    hasCover: j['has_cover'] ?? false,
    trackCount: j['track_count'] ?? 0,
  );
}

class AlbumDetail {
  const AlbumDetail(this.album, this.tracks, this.duration, this.saved);
  final Album album;
  final List<Track> tracks;
  final double duration;
  final bool saved;

  factory AlbumDetail.fromJson(Map<String, dynamic> j) => AlbumDetail(
    Album.fromJson(j),
    [for (final t in j['tracks']) Track.fromJson(t)],
    (j['duration'] as num).toDouble(),
    j['saved'] ?? false,
  );
}

class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.albumCount,
    this.coverAlbumId,
    this.hasImage = false,
  });
  final String id;
  final String name;
  final int albumCount;
  final String? coverAlbumId;
  final bool hasImage;

  factory Artist.fromJson(Map<String, dynamic> j) => Artist(
    id: j['id'],
    name: j['name'],
    albumCount: j['album_count'] ?? 0,
    coverAlbumId: j['cover_album_id'],
    hasImage: j['has_image'] ?? false,
  );
}

class ArtistDetail {
  const ArtistDetail(this.artist, this.albums, this.topTracks, {this.bio});
  final Artist artist;
  final List<Album> albums;
  final List<Track> topTracks;
  final String? bio;

  factory ArtistDetail.fromJson(Map<String, dynamic> j) => ArtistDetail(
    Artist.fromJson(j),
    [for (final a in j['albums']) Album.fromJson(a)],
    [for (final t in j['top_tracks']) Track.fromJson(t)],
    bio: j['bio'],
  );
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.owner,
    required this.trackCount,
    required this.duration,
    required this.coverAlbumIds,
    this.coverKey,
    this.description,
    this.sharedWith = const [],
    this.kind = 'user',
    this.mixKey,
    this.collaborative = false,
    this.canEdit = false,
  });

  final String id;
  final String name;
  final String? description;
  final bool isPublic;

  /// Users it is shared with may add, move and remove songs.
  final bool collaborative;

  /// This user may add, move and remove songs (owner, or collaborator).
  final bool canEdit;
  final NamedRef owner;
  final int trackCount;
  final double duration;
  final List<String> coverAlbumIds;
  final String? coverKey;
  // Users the playlist is shared with (only filled for the owner).
  final List<NamedRef> sharedWith;
  // "user", "radio" (song/album radio), or "mix" (generated by the server).
  final String kind;
  final String? mixKey;
  bool get isRadio => kind == 'radio';
  // Generated by the server (Daily Mix, Discover Weekly, genre mixes, …).
  bool get isMix => kind == 'mix';

  /// A blend: the user's and another user's shared mix (mix key `blend:<other user>`).
  bool get isBlend => isMix && (mixKey?.startsWith('blend:') ?? false);

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
    id: j['id'],
    name: j['name'],
    description: j['description'],
    isPublic: j['is_public'],
    owner: NamedRef.fromJson(j['owner']),
    trackCount: j['track_count'] ?? 0,
    duration: (j['duration'] as num? ?? 0).toDouble(),
    coverAlbumIds: [for (final id in j['cover_album_ids'] ?? const []) id as String],
    coverKey: j['cover_key'],
    sharedWith: [for (final u in j['shared_with'] ?? const []) NamedRef.fromJson(u)],
    kind: j['kind'] ?? 'user',
    mixKey: j['mix_key'],
    collaborative: j['collaborative'] ?? false,
    canEdit: j['can_edit'] ?? false,
  );
}

class PlaylistEntry {
  const PlaylistEntry(this.entryId, this.track, {this.rank, this.addedBy});
  final String entryId;
  final Track track;

  /// Collaborative playlists: who added the song.
  final NamedRef? addedBy;

  /// Place in the charts (chart playlists only).
  final int? rank;
}

class PlaylistDetail {
  const PlaylistDetail(this.playlist, this.entries, this.editable);
  final Playlist playlist;
  final List<PlaylistEntry> entries;
  final bool editable;

  factory PlaylistDetail.fromJson(Map<String, dynamic> j) => PlaylistDetail(Playlist.fromJson(j), [
    for (final e in j['entries'])
      PlaylistEntry(
        e['entry_id'],
        Track.fromJson(e['track']),
        rank: e['rank'],
        addedBy: e['added_by'] == null ? null : NamedRef.fromJson(e['added_by']),
      ),
  ], j['editable'] ?? false);
}

class Home {
  const Home(this.recentlyPlayed, this.recentlyAdded, this.playlists, this.mostPlayed);
  final List<Album> recentlyPlayed;
  final List<Album> recentlyAdded;
  final List<Playlist> playlists;
  final List<Track> mostPlayed;

  factory Home.fromJson(Map<String, dynamic> j) => Home(
    [for (final a in j['recently_played']) Album.fromJson(a)],
    [for (final a in j['recently_added']) Album.fromJson(a)],
    [for (final p in j['playlists']) Playlist.fromJson(p)],
    [for (final t in j['most_played']) Track.fromJson(t)],
  );
}

/// A song whose lyrics contain the search query, with the line it is in.
class LyricsHit {
  const LyricsHit(this.track, this.line);
  final Track track;
  final String line;

  factory LyricsHit.fromJson(Map<String, dynamic> j) =>
      LyricsHit(Track.fromJson(j['track'] as Map<String, dynamic>), j['line'] as String? ?? '');
}

class SearchResult {
  const SearchResult(this.artists, this.albums, this.tracks, [this.playlists = const [], this.lyrics = const []]);
  final List<Artist> artists;
  final List<Album> albums;
  final List<Track> tracks;
  final List<Playlist> playlists;
  final List<LyricsHit> lyrics;

  bool get isEmpty => artists.isEmpty && albums.isEmpty && tracks.isEmpty && playlists.isEmpty && lyrics.isEmpty;

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
    [for (final a in j['artists']) Artist.fromJson(a)],
    [for (final a in j['albums']) Album.fromJson(a)],
    [for (final t in j['tracks']) Track.fromJson(t)],
    [for (final p in j['playlists'] ?? const []) Playlist.fromJson(p)],
    [for (final l in j['lyrics'] ?? const []) LyricsHit.fromJson(l as Map<String, dynamic>)],
  );
}

class Invite {
  const Invite({
    required this.id,
    required this.role,
    required this.createdAt,
    this.note,
    this.expiresAt,
    this.usedAt,
    this.usedBy,
    this.token,
  });

  final String id;
  final String? note;
  final String role;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final String? usedBy;
  // Only present right after creation.
  final String? token;

  bool get isUsed => usedAt != null;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory Invite.fromJson(Map<String, dynamic> j) => Invite(
    id: j['id'],
    note: j['note'],
    role: j['role'],
    createdAt: DateTime.parse(j['created_at']),
    expiresAt: _date(j['expires_at']),
    usedAt: _date(j['used_at']),
    usedBy: j['used_by_username'],
    token: j['token'],
  );
}

class Job {
  const Job(this.id, this.kind, this.status, this.progress, this.message, this.createdAt);
  final String id;
  final String kind;
  final String status;
  final double progress;
  final String? message;
  final DateTime createdAt;

  bool get isActive => status == 'queued' || status == 'running';

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    j['id'],
    j['kind'],
    j['status'],
    (j['progress'] as num).toDouble(),
    j['message'],
    DateTime.parse(j['created_at']),
  );
}

class DuplicateTrack {
  const DuplicateTrack({
    required this.id,
    required this.title,
    required this.path,
    required this.codec,
    required this.bitrate,
    required this.size,
    required this.duration,
    required this.keep,
    this.album = '',
  });

  final String id;
  final String title;
  final String path;
  final String? codec;
  final int? bitrate;
  final int size;
  final double duration;
  final bool keep;
  final String album;

  factory DuplicateTrack.fromJson(Map<String, dynamic> j) => DuplicateTrack(
    id: j['id'],
    title: j['title'],
    path: j['path'],
    codec: j['codec'],
    bitrate: j['bitrate'],
    size: j['size'],
    duration: (j['duration'] as num).toDouble(),
    keep: j['keep'],
    album: j['album'] ?? '',
  );
}

class DuplicateGroup {
  const DuplicateGroup({
    required this.albumId,
    required this.albumTitle,
    required this.artistName,
    required this.tracks,
    this.kind = 'same_album',
    this.verified = true,
    this.pending = false,
  });

  final String albumId;
  final String albumTitle;
  final String artistName;
  final List<DuplicateTrack> tracks;
  final String kind;
  final bool verified;
  final bool pending;

  factory DuplicateGroup.fromJson(Map<String, dynamic> j) => DuplicateGroup(
    albumId: j['album_id'],
    albumTitle: j['album_title'],
    artistName: j['artist_name'],
    tracks: [for (final track in j['tracks']) DuplicateTrack.fromJson(track)],
    kind: j['kind'] ?? 'same_album',
    verified: j['verified'] ?? (j['kind'] != 'cross_album'),
    pending: j['pending'] ?? false,
  );
}

class DuplicateMergeResult {
  const DuplicateMergeResult({required this.mergedGroups, required this.deletedTracks, required this.freedBytes});

  final int mergedGroups;
  final int deletedTracks;
  final int freedBytes;

  factory DuplicateMergeResult.fromJson(Map<String, dynamic> j) => DuplicateMergeResult(
    mergedGroups: j['merged_groups'],
    deletedTracks: j['deleted_tracks'],
    freedBytes: j['freed_bytes'],
  );
}

class LibraryStats {
  const LibraryStats(this.artists, this.albums, this.tracks, this.totalBytes, this.totalSeconds);
  final int artists;
  final int albums;
  final int tracks;
  final int totalBytes;
  final double totalSeconds;

  factory LibraryStats.fromJson(Map<String, dynamic> j) =>
      LibraryStats(j['artists'], j['albums'], j['tracks'], j['total_bytes'], (j['total_seconds'] as num).toDouble());
}

class AuthStatus {
  const AuthStatus(this.serverName, this.setupRequired, this.registrationMode);
  final String serverName;
  final bool setupRequired;
  final String registrationMode;

  factory AuthStatus.fromJson(Map<String, dynamic> j) =>
      AuthStatus(j['server_name'], j['setup_required'], j['registration_mode']);
}

// --- catalog (MusicBrainz) & download requests -------------------------------

class CatalogArtist {
  const CatalogArtist({required this.id, required this.name, this.pictureUrl, this.libraryId});
  final String id;
  final String name;
  final String? pictureUrl;
  final String? libraryId;

  factory CatalogArtist.fromJson(Map<String, dynamic> j) =>
      CatalogArtist(id: j['id'], name: j['name'], pictureUrl: j['picture_url'], libraryId: j['library_id']);
}

class CatalogAlbum {
  const CatalogAlbum({
    required this.id,
    this.source = 'deezer',
    required this.title,
    required this.artist,
    this.artistId,
    this.recordType,
    this.year,
    this.coverUrl,
    this.coverBigUrl,
    this.libraryId,
  });
  final String id;
  final String source;
  final String title;
  final String artist;
  final String? artistId;
  final String? recordType;
  final int? year;
  final String? coverUrl;
  final String? coverBigUrl;
  final String? libraryId;

  /// German label for Deezer's record type.
  String typeLabel(AppLocalizations l10n) => switch (recordType) {
    'ep' => l10n.catalogEp,
    'single' => l10n.catalogSingle,
    'compile' => l10n.catalogCompilation,
    _ => l10n.commonAlbum,
  };

  factory CatalogAlbum.fromJson(Map<String, dynamic> j) => CatalogAlbum(
    id: j['id'],
    source: j['source'] ?? 'deezer',
    title: j['title'],
    artist: j['artist'],
    artistId: j['artist_id'],
    recordType: j['record_type'],
    year: j['year'],
    coverUrl: j['cover_url'],
    coverBigUrl: j['cover_big_url'],
    libraryId: j['library_id'],
  );
}

class CatalogTrack {
  const CatalogTrack({
    required this.id,
    this.source = 'deezer',
    required this.title,
    required this.artist,
    this.artistId,
    this.album,
    this.albumId,
    this.coverUrl,
    this.duration,
    this.isrc,
    this.previewUrl,
    this.discNo,
    this.trackNo,
    this.libraryId,
  });
  final String id;
  final String source;
  final String title;
  final String artist;
  final String? artistId;
  final String? album;
  final String? albumId;
  final String? coverUrl;
  final double? duration;
  final String? isrc;
  final String? previewUrl;
  final int? discNo;
  final int? trackNo;
  final String? libraryId;

  factory CatalogTrack.fromJson(Map<String, dynamic> j) => CatalogTrack(
    id: j['id'],
    source: j['source'] ?? 'deezer',
    title: j['title'],
    artist: j['artist'],
    artistId: j['artist_id'],
    album: j['album'],
    albumId: j['album_id'],
    coverUrl: j['cover_url'],
    duration: (j['duration'] as num?)?.toDouble(),
    isrc: j['isrc'],
    previewUrl: j['preview_url'],
    discNo: j['disc_no'],
    trackNo: j['track_no'],
    libraryId: j['library_id'],
  );
}

class CatalogSearch {
  const CatalogSearch(this.artists, this.albums, this.tracks);
  final List<CatalogArtist> artists;
  final List<CatalogAlbum> albums;
  final List<CatalogTrack> tracks;

  bool get isEmpty => artists.isEmpty && albums.isEmpty && tracks.isEmpty;

  factory CatalogSearch.fromJson(Map<String, dynamic> j) => CatalogSearch(
    [for (final a in j['artists']) CatalogArtist.fromJson(a)],
    [for (final a in j['albums']) CatalogAlbum.fromJson(a)],
    [for (final t in j['tracks']) CatalogTrack.fromJson(t)],
  );
}

/// A public playlist of Deezer, Apple Music or Spotify that can be imported.
class CatalogPlaylist {
  const CatalogPlaylist({
    required this.source,
    required this.link,
    required this.name,
    this.owner,
    this.imageUrl,
    this.trackCount,
  });
  final String source;
  final String link;
  final String name;
  final String? owner;
  final String? imageUrl;
  final int? trackCount;

  String get sourceName => switch (source) {
    'deezer' => 'Deezer',
    'apple' => 'Apple Music',
    _ => 'Spotify',
  };

  factory CatalogPlaylist.fromJson(Map<String, dynamic> j) => CatalogPlaylist(
    source: j['source'] as String,
    link: j['link'] as String,
    name: j['name'] as String,
    owner: j['owner'] as String?,
    imageUrl: j['image_url'] as String?,
    trackCount: j['track_count'] as int?,
  );
}

class CatalogPlaylistTrack {
  const CatalogPlaylistTrack({required this.title, required this.artist, this.album, this.duration, this.libraryId});
  final String title;
  final String artist;
  final String? album;
  final double? duration;
  final String? libraryId;

  factory CatalogPlaylistTrack.fromJson(Map<String, dynamic> j) => CatalogPlaylistTrack(
    title: j['title'] as String,
    artist: j['artist'] as String? ?? '',
    album: j['album'] as String?,
    duration: (j['duration'] as num?)?.toDouble(),
    libraryId: j['library_id'] as String?,
  );
}

/// A playlist's songs before importing it; [playlistId] is the library playlist of an earlier import.
class CatalogPlaylistDetail {
  const CatalogPlaylistDetail({required this.playlist, required this.tracks, this.playlistId});
  final CatalogPlaylist playlist;
  final List<CatalogPlaylistTrack> tracks;
  final String? playlistId;

  int get inLibraryCount => tracks.where((t) => t.libraryId != null).length;

  factory CatalogPlaylistDetail.fromJson(Map<String, dynamic> j) => CatalogPlaylistDetail(
    playlist: CatalogPlaylist.fromJson({...j, 'track_count': (j['tracks'] as List).length}),
    tracks: [for (final t in j['tracks']) CatalogPlaylistTrack.fromJson(Map<String, dynamic>.from(t))],
    playlistId: j['playlist_id'] as String?,
  );
}

class CatalogArtistDetail {
  const CatalogArtistDetail(this.artist, this.topTracks, this.albums);
  final CatalogArtist artist;
  final List<CatalogTrack> topTracks;
  final List<CatalogAlbum> albums;

  factory CatalogArtistDetail.fromJson(Map<String, dynamic> j) => CatalogArtistDetail(
    CatalogArtist.fromJson(j['artist']),
    [for (final t in j['top_tracks']) CatalogTrack.fromJson(t)],
    [for (final a in j['albums']) CatalogAlbum.fromJson(a)],
  );
}

class CatalogAlbumDetail {
  const CatalogAlbumDetail(this.album, this.tracks, {this.label, this.genres = const []});
  final CatalogAlbum album;
  final List<CatalogTrack> tracks;
  final String? label;
  final List<String> genres;

  int get inLibraryCount => tracks.where((t) => t.libraryId != null).length;

  factory CatalogAlbumDetail.fromJson(Map<String, dynamic> j) => CatalogAlbumDetail(
    CatalogAlbum.fromJson(j),
    [for (final t in j['tracks']) CatalogTrack.fromJson(t)],
    label: j['label'],
    genres: [for (final g in j['genres'] ?? const []) g as String],
  );
}

/// Item statuses that still need work by the server.
const openItemStatuses = {'waiting', 'queued', 'searching', 'downloading', 'processing'};

class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.position,
    required this.title,
    required this.artist,
    required this.status,
    required this.progress,
    this.duration,
    this.source,
    this.error,
    this.trackId,
  });
  final String id;
  final int position;
  final String title;
  final String artist;
  final double? duration;
  final String status;
  final double progress;
  final String? source;
  final String? error;
  final String? trackId;

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
    id: j['id'],
    position: j['position'],
    title: j['title'],
    artist: j['artist'],
    duration: (j['duration'] as num?)?.toDouble(),
    status: j['status'],
    progress: (j['progress'] as num).toDouble(),
    source: j['source'],
    error: j['error'],
    trackId: j['track_id'],
  );
}

class DownloadRequest {
  const DownloadRequest({
    required this.id,
    required this.kind,
    this.catalogId,
    this.replaceTrackId,
    required this.title,
    required this.artist,
    required this.status,
    required this.isTemporary,
    required this.user,
    required this.progress,
    required this.itemCount,
    required this.doneCount,
    required this.failedCount,
    required this.createdAt,
    this.coverUrl,
    this.note,
    this.torrentStatus,
    this.torrentName,
    this.torrentProgress = 0,
    this.torrentError,
    this.items = const [],
  });
  final String id;
  final String kind;
  final String? catalogId;
  final String? replaceTrackId;
  final String title;
  final String artist;
  final String? coverUrl;
  final String status;
  final bool isTemporary;
  final String? note;
  final NamedRef user;
  final double progress;
  final int itemCount;
  final int doneCount;
  final int failedCount;
  final DateTime createdAt;
  final String? torrentStatus;
  final String? torrentName;
  final double torrentProgress;
  final String? torrentError;
  final List<DownloadItem> items;

  bool get isOpen => status == 'pending_approval' || status == 'active';

  factory DownloadRequest.fromJson(Map<String, dynamic> j) => DownloadRequest(
    id: j['id'],
    kind: j['kind'],
    catalogId: j['catalog_id'],
    replaceTrackId: j['replace_track_id'],
    title: j['title'],
    artist: j['artist'],
    coverUrl: j['cover_url'],
    status: j['status'],
    isTemporary: j['is_temporary'] ?? false,
    note: j['note'],
    user: NamedRef(j['user']['id'], j['user']['username']),
    progress: (j['progress'] as num).toDouble(),
    itemCount: j['item_count'],
    doneCount: j['done_count'],
    failedCount: j['failed_count'],
    createdAt: DateTime.parse(j['created_at']),
    torrentStatus: j['torrent_status'],
    torrentName: j['torrent_name'],
    torrentProgress: (j['torrent_progress'] as num?)?.toDouble() ?? 0,
    torrentError: j['torrent_error'],
    items: [for (final i in j['items'] ?? const []) DownloadItem.fromJson(i)],
  );
}

class DownloadSummary {
  const DownloadSummary({this.active = 0, this.queued = 0, this.failed = 0, this.pendingApproval = 0});
  final int active;
  final int queued;
  final int failed;
  final int pendingApproval;

  /// Songs currently being worked on or waiting for a worker.
  int get running => active + queued;

  factory DownloadSummary.fromJson(Map<String, dynamic> j) => DownloadSummary(
    active: j['active'],
    queued: j['queued'],
    failed: j['failed'],
    pendingApproval: j['pending_approval'],
  );
}

// --- import / library cleanup (admin) -----------------------------------------

class ImportInfo {
  const ImportInfo({
    required this.importDir,
    required this.pendingFiles,
    required this.acoustidConfigured,
    required this.importMode,
  });
  final String importDir;
  final int pendingFiles;
  final bool acoustidConfigured;
  final String importMode;

  factory ImportInfo.fromJson(Map<String, dynamic> j) => ImportInfo(
    importDir: j['import_dir'],
    pendingFiles: j['pending_files'],
    acoustidConfigured: j['acoustid_configured'],
    importMode: j['import_mode'],
  );
}

class ImportBatch {
  const ImportBatch({
    required this.id,
    required this.kind,
    required this.mode,
    required this.status,
    required this.total,
    required this.processed,
    required this.identified,
    required this.imported,
    required this.duplicates,
    required this.unidentified,
    required this.failed,
    required this.progress,
    required this.createdAt,
    this.message,
    this.finishedAt,
  });
  final String id;
  final String kind;
  final String mode;
  final String status;
  final int total;
  final int processed;
  final int identified;
  final int imported;
  final int duplicates;
  final int unidentified;
  final int failed;
  final double progress;
  final String? message;
  final DateTime createdAt;
  final DateTime? finishedAt;

  bool get isRunning => status == 'queued' || status == 'running';

  factory ImportBatch.fromJson(Map<String, dynamic> j) => ImportBatch(
    id: j['id'],
    kind: j['kind'],
    mode: j['mode'],
    status: j['status'],
    total: j['total'],
    processed: j['processed'],
    identified: j['identified'],
    imported: j['imported'],
    duplicates: j['duplicates'],
    unidentified: j['unidentified'],
    failed: j['failed'],
    progress: (j['progress'] as num).toDouble(),
    message: j['message'],
    createdAt: DateTime.parse(j['created_at']),
    finishedAt: _date(j['finished_at']),
  );
}

class ImportFile {
  const ImportFile({
    required this.id,
    required this.path,
    required this.status,
    this.method,
    this.acoustidScore,
    this.target,
    this.error,
    this.title,
    this.artist,
    this.album,
  });
  final String id;
  final String path;
  final String status;
  final String? method;
  final double? acoustidScore;
  final String? target;
  final String? error;
  final String? title;
  final String? artist;
  final String? album;

  factory ImportFile.fromJson(Map<String, dynamic> j) => ImportFile(
    id: j['id'],
    path: j['path'],
    status: j['status'],
    method: j['method'],
    acoustidScore: (j['acoustid_score'] as num?)?.toDouble(),
    target: j['target'],
    error: j['error'],
    title: j['title'],
    artist: j['artist'],
    album: j['album'],
  );
}

// --- metadata editor (admin) -------------------------------------------------

/// Tags as they are currently stored in a library file.
class TrackFile {
  const TrackFile({
    required this.path,
    required this.query,
    required this.duration,
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.year,
    this.trackNo,
    this.discNo,
    this.genre,
    this.codec,
    this.bitrate,
    this.mbRecordingId,
    this.mbReleaseId,
  });
  final String path;
  final String query;
  final double duration;
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? year;
  final int? trackNo;
  final int? discNo;
  final String? genre;
  final String? codec;
  final int? bitrate;
  final String? mbRecordingId;
  final String? mbReleaseId;

  factory TrackFile.fromJson(Map<String, dynamic> j) => TrackFile(
    path: j['path'],
    query: j['query'],
    duration: (j['duration'] as num).toDouble(),
    title: j['title'],
    artist: j['artist'],
    album: j['album'],
    albumArtist: j['album_artist'],
    year: j['year'],
    trackNo: j['track_no'],
    discNo: j['disc_no'],
    genre: j['genre'],
    codec: j['codec'],
    bitrate: j['bitrate'],
    mbRecordingId: j['mb_recording_id'],
    mbReleaseId: j['mb_release_id'],
  );
}

class FingerprintRelease {
  const FingerprintRelease({
    required this.releaseId,
    this.album,
    this.year,
    this.discNo,
    this.trackNo,
    this.releaseTracks,
  });
  final String releaseId;
  final String? album;
  final int? year;
  final int? discNo;
  final int? trackNo;
  final int? releaseTracks;

  factory FingerprintRelease.fromJson(Map<String, dynamic> j) => FingerprintRelease(
    releaseId: j['release_id'],
    album: j['album'],
    year: j['year'],
    discNo: j['disc_no'],
    trackNo: j['track_no'],
    releaseTracks: j['release_tracks'],
  );
}

class FingerprintMatch {
  const FingerprintMatch({
    required this.recordingId,
    required this.score,
    required this.releases,
    this.title,
    this.artist,
  });
  final String recordingId;
  final String? title;
  final String? artist;
  final double score;
  final List<FingerprintRelease> releases;

  factory FingerprintMatch.fromJson(Map<String, dynamic> j) => FingerprintMatch(
    recordingId: j['recording_id'],
    title: j['title'],
    artist: j['artist'],
    score: (j['score'] as num).toDouble(),
    releases: [for (final r in j['releases']) FingerprintRelease.fromJson(r)],
  );
}

class CoverOption {
  const CoverOption({required this.url, required this.source, required this.label});
  final String url;
  final String source;
  final String label;

  factory CoverOption.fromJson(Map<String, dynamic> j) =>
      CoverOption(url: j['url'], source: j['source'], label: j['label']);
}

class AlbumMatchResult {
  const AlbumMatchResult({required this.matched, required this.unmatched, this.album});
  final Album? album;
  final int matched;
  final List<Track> unmatched;

  factory AlbumMatchResult.fromJson(Map<String, dynamic> j) => AlbumMatchResult(
    album: j['album'] == null ? null : Album.fromJson(j['album']),
    matched: j['matched'],
    unmatched: [for (final t in j['unmatched']) Track.fromJson(t)],
  );
}

class ReviewTrack {
  const ReviewTrack({required this.track, required this.path});
  final Track track;
  final String path;

  factory ReviewTrack.fromJson(Map<String, dynamic> j) => ReviewTrack(track: Track.fromJson(j), path: j['path']);
}

class StationNowPlaying {
  const StationNowPlaying({required this.raw, this.artist, this.title, this.album, this.year, this.coverUrl});

  final String raw;
  final String? artist;
  final String? title;
  final String? album;
  final int? year;
  final String? coverUrl;

  factory StationNowPlaying.fromJson(Map<String, dynamic> json) => StationNowPlaying(
    raw: json['raw'],
    artist: json['artist'],
    title: json['title'],
    album: json['album'],
    year: (json['year'] as num?)?.toInt(),
    coverUrl: json['cover_url'],
  );

  String get artistYear => [if (artist?.isNotEmpty ?? false) artist!, if (year != null) '$year'].join(' · ');

  String subtitle(String stationName) => [if (artistYear.isNotEmpty) artistYear, stationName].join(' · ');

  @override
  bool operator ==(Object other) =>
      other is StationNowPlaying &&
      raw == other.raw &&
      artist == other.artist &&
      title == other.title &&
      album == other.album &&
      year == other.year &&
      coverUrl == other.coverUrl;

  @override
  int get hashCode => Object.hash(raw, artist, title, album, year, coverUrl);
}

class Station {
  const Station({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.tags,
    required this.codec,
    this.favicon,
    this.bitrate,
    this.homepage,
  });

  final String id;
  final String name;
  final String country;
  final String countryCode;
  final List<String> tags;
  final String? favicon;
  final String codec;
  final int? bitrate;
  final String? homepage;

  factory Station.fromJson(Map<String, dynamic> json) => Station(
    id: json['id'],
    name: json['name'],
    country: json['country'],
    countryCode: json['country_code'],
    tags: List<String>.from(json['tags']),
    favicon: json['favicon'],
    codec: json['codec'],
    bitrate: (json['bitrate'] as num?)?.toInt(),
    homepage: json['homepage'],
  );
}

/// The server's cover version per album id (changes when a cover is replaced), collected while parsing tracks and
/// albums so cover images and downloaded covers can tell when they are out of date.
final coverKeys = <String, String>{};

/// Albums the server reported without a cover (`cover_key: null`): their cover URL only answers 404.
final albumsWithoutCover = <String>{};

Map<String, dynamic> noteCoverKey(Map<String, dynamic> album) {
  final key = album['cover_key'];
  final id = album['id'] as String;
  if (key is String) {
    coverKeys[id] = key;
    albumsWithoutCover.remove(id);
  } else if (album.containsKey('cover_key')) {
    albumsWithoutCover.add(id);
  }
  return album;
}
