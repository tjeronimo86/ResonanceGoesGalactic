import re
import uuid
from datetime import date, datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models import Role

HEX_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}$")


class ORM(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class NowPlayingOut(ORM):
    raw: str
    artist: str | None
    title: str | None
    album: str | None
    year: int | None
    cover_url: str | None


# --- auth / users -----------------------------------------------------------


class UserOut(ORM):
    id: uuid.UUID
    username: str
    display_name: str
    role: Role
    accent_color: str
    is_disabled: bool
    has_subsonic_password: bool
    created_at: datetime
    last_seen_at: datetime | None


class AuthStatus(BaseModel):
    server_name: str
    setup_required: bool
    registration_mode: str


class RegisterIn(BaseModel):
    username: str = Field(min_length=2, max_length=64, pattern=r"^[A-Za-z0-9_.-]+$")
    password: str = Field(min_length=8, max_length=256)
    display_name: str | None = Field(None, max_length=128)
    invite: str | None = None
    device_name: str | None = Field(None, max_length=128)


class LoginIn(BaseModel):
    username: str
    password: str
    device_name: str | None = Field(None, max_length=128)


class PasswordResetIn(BaseModel):
    username: str = Field(max_length=64)
    code: str = Field(max_length=32)
    new_password: str = Field(min_length=8, max_length=256)
    device_name: str | None = Field(None, max_length=128)


class ResetCodeOut(BaseModel):
    code: str
    expires_in: int


class TokenOut(BaseModel):
    token: str
    user: UserOut


class ProfilePatch(BaseModel):
    display_name: str | None = Field(None, min_length=1, max_length=128)
    accent_color: str | None = None
    current_password: str | None = None
    new_password: str | None = Field(None, min_length=8, max_length=256)

    @field_validator("accent_color")
    @classmethod
    def _hex(cls, v: str | None) -> str | None:
        if v is not None and not HEX_COLOR.match(v):
            raise ValueError("accent_color must look like #RRGGBB")
        return v.upper() if v else v


class SessionOut(ORM):
    id: uuid.UUID
    device_name: str | None
    created_at: datetime
    last_used_at: datetime
    current: bool = False


# --- admin ------------------------------------------------------------------


class InviteIn(BaseModel):
    note: str | None = Field(None, max_length=256)
    role: Role = Role.user
    # None = never expires
    expires_in_hours: int | None = Field(72, ge=1, le=24 * 365)


class InviteOut(ORM):
    id: uuid.UUID
    note: str | None
    role: Role
    created_at: datetime
    expires_at: datetime | None
    used_at: datetime | None
    used_by_username: str | None = None


class InviteCreated(InviteOut):
    token: str


class UserAdminPatch(BaseModel):
    role: Role | None = None
    is_disabled: bool | None = None
    new_password: str | None = Field(None, min_length=8, max_length=256)


class JobOut(ORM):
    id: uuid.UUID
    kind: str
    status: str
    progress: float
    message: str | None
    created_at: datetime
    finished_at: datetime | None


class DuplicateTrackOut(ORM):
    id: uuid.UUID
    title: str
    album: str
    path: str
    codec: str | None
    bitrate: int | None
    size: int
    duration: float
    keep: bool


class DuplicateGroupOut(BaseModel):
    kind: Literal["same_album", "cross_album"] = "same_album"
    verified: bool = True
    pending: bool = False
    album_id: uuid.UUID
    album_title: str
    artist_name: str
    tracks: list[DuplicateTrackOut]


class DuplicateMergeIn(BaseModel):
    keep_ids: list[uuid.UUID] = Field(max_length=5000)
    kind: Literal["same_album", "cross_album"] | None = None


# --- library ----------------------------------------------------------------


class ArtistRef(ORM):
    id: uuid.UUID
    name: str


class AlbumRef(ORM):
    id: uuid.UUID
    title: str
    # Changes with the cover image, so clients can refresh cached covers.
    cover_key: str | None = None


class LyricLine(BaseModel):
    time_ms: int | None
    text: str


class LyricsOut(BaseModel):
    synced: bool
    instrumental: bool
    source: str | None
    lines: list[LyricLine]


class RecommendationsIn(BaseModel):
    # Empty: suggestions for a new playlist, based on the user's latest likes.
    track_ids: list[uuid.UUID] = Field(default_factory=list, max_length=500)
    limit: int = Field(20, ge=1, le=100)
    exclude_ids: list[uuid.UUID] = Field(default_factory=list, max_length=2000)


class TrackOut(ORM):
    id: uuid.UUID
    title: str
    artist: ArtistRef
    artist_credit: str
    album: AlbumRef
    track_no: int | None
    disc_no: int | None
    duration: float
    codec: str | None
    bitrate: int | None
    replaygain_track_gain: float | None
    replaygain_album_gain: float | None
    liked: bool = False


class AlbumOut(ORM):
    id: uuid.UUID
    title: str
    artist: ArtistRef
    year: int | None
    genre: str | None
    has_cover: bool = False
    cover_key: str | None = None
    track_count: int = 0


class AlbumDetail(AlbumOut):
    duration: float = 0
    saved: bool = False
    tracks: list[TrackOut] = []


class ArtistOut(ORM):
    id: uuid.UUID
    name: str
    album_count: int = 0
    cover_album_id: uuid.UUID | None = None
    has_image: bool = False
    bio: str | None = None


class ArtistDetail(ArtistOut):
    albums: list[AlbumOut] = []
    top_tracks: list[TrackOut] = []


class LyricsHit(BaseModel):
    track: TrackOut
    # The line of the lyrics the query was found in.
    line: str


class SearchResult(BaseModel):
    artists: list[ArtistOut]
    albums: list[AlbumOut]
    tracks: list[TrackOut]
    playlists: list["PlaylistOut"] = []
    lyrics: list[LyricsHit] = []


class Page[T](BaseModel):
    items: list[T]
    total: int
    offset: int
    limit: int


# --- playlists --------------------------------------------------------------


class PlaylistIn(BaseModel):
    name: str = Field(min_length=1, max_length=256)
    description: str | None = Field(None, max_length=4000)
    is_public: bool = False
    collaborative: bool = False


class PlaylistPatch(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=256)
    description: str | None = Field(None, max_length=4000)
    is_public: bool | None = None
    collaborative: bool | None = None


class PlaylistSharesIn(BaseModel):
    user_ids: list[uuid.UUID] = Field(max_length=100)


class PlaylistOut(ORM):
    id: uuid.UUID
    name: str
    description: str | None
    is_public: bool
    kind: str = "user"
    mix_key: str | None = None
    owner: ArtistRef  # {id, name} of the owning user
    shared_with: list[ArtistRef] = []
    collaborative: bool = False
    # The viewer may add, move and remove songs (owner, or a user it is shared with when collaborative).
    can_edit: bool = False
    track_count: int = 0
    duration: float = 0
    # Up to 4 album ids for a mosaic cover.
    cover_album_ids: list[uuid.UUID] = []
    cover_key: str | None = None
    updated_at: datetime


class RadioIn(BaseModel):
    seed_type: Literal["track", "album"]
    id: uuid.UUID


class RadioOut(BaseModel):
    playlist: PlaylistOut
    requested: int


class MixesOut(BaseModel):
    made_for_you: list[PlaylistOut]
    genres: list[PlaylistOut]
    discover: PlaylistOut | None
    decades: list[PlaylistOut] = []  # Editorial decades, personal decades/eras, editorial eras.
    charts: list[PlaylistOut] = []  # Top 100 charts, Deutschrap 100, then year charts.


class WrappedTrack(BaseModel):
    track: TrackOut
    plays: int
    minutes: int


class WrappedArtist(BaseModel):
    id: uuid.UUID
    name: str
    plays: int
    minutes: int
    songs: int
    has_image: bool = False
    # The album of the artist's most played song, the picture without an artist image.
    cover_album_id: uuid.UUID | None = None


class WrappedGenre(BaseModel):
    name: str
    # Its part of the year's listening time (0..1); a song in two genres counts for both.
    share: float


class WrappedOut(BaseModel):
    """The yearly review; empty numbers when nothing was played that year."""

    year: int
    # Years with plays, oldest first.
    years: list[int] = []
    minutes: int = 0
    plays: int = 0
    songs: int = 0
    artists: int = 0
    new_artists: int = 0
    top_tracks: list[WrappedTrack] = []
    top_artists: list[WrappedArtist] = []
    top_genres: list[WrappedGenre] = []
    # Minutes per month (12) and per hour of the day (24).
    months: list[int] = []
    hours: list[int] = []
    top_day: date | None = None
    top_day_minutes: int = 0
    first_track: TrackOut | None = None
    # The year's top songs playlist, once made.
    playlist_id: uuid.UUID | None = None


class WrappedPlaylistIn(BaseModel):
    name: str = Field(min_length=1, max_length=256)
    description: str | None = Field(None, max_length=1000)


class BlendIn(BaseModel):
    user_id: uuid.UUID


class BlendOut(BaseModel):
    id: uuid.UUID
    partner: ArtistRef
    # This user's playlist of the blend (None until it could be made: both need some plays or likes).
    playlist_id: uuid.UUID | None
    # How alike both tastes are (0..1).
    match: float


class CreditOut(BaseModel):
    name: str
    # E.g. "artist", "featured", "composer", "lyricist", "producer", "mix", "mastering"; instruments by name.
    roles: list[str]


class CreditsOut(BaseModel):
    performers: list[CreditOut] = []
    writers: list[CreditOut] = []
    producers: list[CreditOut] = []
    engineers: list[CreditOut] = []
    label: str | None = None
    copyright: str | None = None
    # Where they come from: "tags" and/or "musicbrainz".
    sources: list[str] = []


class PlaylistEntryOut(BaseModel):
    entry_id: uuid.UUID
    added_at: datetime
    # Collaborative playlists: who added the song.
    added_by: ArtistRef | None = None
    track: TrackOut
    # Chart playlists: the song's place in the charts (songs still downloading leave gaps).
    rank: int | None = None


class PlaylistDetail(PlaylistOut):
    entries: list[PlaylistEntryOut] = []
    editable: bool = False


CurveName = Literal["volume_out", "volume_in", "bass_out", "bass_in", "filter_out", "filter_in"]
CurvePoint = tuple[Annotated[float, Field(ge=0, le=1)], Annotated[float, Field(ge=-1, le=1)]]


class TransitionLanes(BaseModel):
    """The transition editor's lanes; the app knows what each one sounds like."""

    volume: Literal[
        "smooth", "overlap", "fade_in_out", "hard_in_fade_out", "fade_in_hard_out", "center_cut", "crossfade",
        "fade_in_quick_out", "fade_in_cut_bar", "overlap_cut_bar",
    ] = "smooth"
    eq: Literal[
        "swap_middle", "swap_end", "swap_start", "three_band", "quick_bass_cut", "long_bass_cut", "bass_fade_out", "none"
    ] = "swap_middle"
    filter: Literal[
        "none", "lowpass_out", "lowpass_in", "lowpass_in_out", "lowpass_in_highpass_out", "highpass_out", "highpass_in",
        "highpass_in_out", "highpass_in_lowpass_out", "highpass_half", "noise_end",
    ] = "none"
    effect: Literal[
        "none", "reverb_middle", "reverb_cut", "reverb_tail", "echo_half_cut", "echo_half_tail", "echo_3q_cut",
        "echo_3q_tail", "echo_beat_cut", "echo_beat_tail", "delay_half_cut", "delay_3q_cut", "flanger", "phaser", "gate",
        "beat_roll", "brake",
    ] = "none"
    loop: Literal[0, 1, 2, 4, 8, 16] = 0
    beatmatch: bool = True
    # Curves drawn by hand: points (place in the transition 0–1, value) replacing a lane for one song.
    curves: dict[CurveName, Annotated[list[CurvePoint], Field(min_length=2, max_length=64)]] | None = None


class TransitionIn(BaseModel):
    from_track_id: uuid.UUID
    to_track_id: uuid.UUID
    # What older apps play; newer ones use the lanes.
    style: Literal["crossfade", "fade_in", "fade_out", "filter"]
    bars: Literal[1, 2, 4, 8, 16]
    start: float = Field(ge=0, le=36000)
    incoming_start: float = Field(ge=0, le=36000)
    lanes: TransitionLanes | None = None


class TransitionOut(TransitionIn):
    updated_at: datetime


class AddTracksIn(BaseModel):
    track_ids: list[uuid.UUID] = Field(min_length=1, max_length=1000)
    # Insert before this entry; append when omitted.
    before_entry_id: uuid.UUID | None = None


class MoveEntryIn(BaseModel):
    entry_id: uuid.UUID
    before_entry_id: uuid.UUID | None = None


class OrderIn(BaseModel):
    """Every entry of the playlist, in the new order."""

    entry_ids: list[uuid.UUID] = Field(max_length=20000)


class SetOrderIn(BaseModel):
    arc: Literal["peak", "rise", "down", "flow"] = "peak"


class PlayEventIn(BaseModel):
    track_id: uuid.UUID
    seconds_played: float = Field(ge=0)
    context: str | None = Field(None, max_length=128)


class PlaybackStateIn(BaseModel):
    """The queue (track ids, current index and position) or the spoken-word item that was playing."""

    kind: Literal["tracks", "episode", "audiobook"]
    track_ids: list[uuid.UUID] = Field(default_factory=list, max_length=1000)
    index: int = Field(0, ge=0)
    position: float = Field(0, ge=0)
    context: str | None = Field(None, max_length=128)
    is_radio: bool = False
    # Episode or Audiobookshelf item id.
    item_id: str | None = Field(None, max_length=128)


class PlaybackStateOut(PlaybackStateIn):
    # The queue's songs that still exist, in order; index points into this list.
    tracks: list[TrackOut] = Field(default_factory=list)
    updated_at: datetime


class HomeOut(BaseModel):
    recently_played: list[AlbumOut]
    recently_added: list[AlbumOut]
    playlists: list[PlaylistOut]
    most_played: list[TrackOut]


# --- catalog / downloads ----------------------------------------------------


class CatalogArtist(BaseModel):
    id: str
    name: str
    picture_url: str | None
    library_id: uuid.UUID | None = None


class CatalogAlbum(BaseModel):
    id: str
    source: Literal["deezer", "apple", "discogs"] = "deezer"
    title: str
    artist: str
    artist_id: str | None
    record_type: str | None
    year: int | None
    cover_url: str | None
    cover_big_url: str | None
    library_id: uuid.UUID | None = None


class CatalogTrack(BaseModel):
    id: str
    source: Literal["deezer", "apple"] = "deezer"
    title: str
    artist: str
    artist_id: str | None
    album: str | None
    album_id: str | None
    cover_url: str | None
    duration: float | None
    isrc: str | None = None
    preview_url: str | None
    disc_no: int | None = None
    track_no: int | None = None
    library_id: uuid.UUID | None = None


class MissingTracksOut(BaseModel):
    catalog_id: str
    tracks: list[CatalogTrack]


class CatalogArtistDetail(BaseModel):
    artist: CatalogArtist
    top_tracks: list[CatalogTrack]
    albums: list[CatalogAlbum]


class CatalogAlbumDetail(CatalogAlbum):
    label: str | None
    genres: list[str]
    tracks: list[CatalogTrack]


class CatalogSearchOut(BaseModel):
    artists: list[CatalogArtist]
    albums: list[CatalogAlbum]
    tracks: list[CatalogTrack]


class UserRef(ORM):
    id: uuid.UUID
    username: str


class DownloadItemOut(ORM):
    id: uuid.UUID
    position: int
    title: str
    artist: str
    duration: float | None
    status: str
    progress: float
    source: str | None
    error: str | None
    track_id: uuid.UUID | None


class DownloadRequestOut(ORM):
    id: uuid.UUID
    kind: str
    mb_id: str | None
    catalog_id: str | None
    replace_track_id: uuid.UUID | None
    title: str
    artist: str
    cover_url: str | None
    status: str
    is_temporary: bool
    note: str | None
    torrent_status: str | None
    torrent_name: str | None
    torrent_progress: float
    torrent_error: str | None
    created_at: datetime
    updated_at: datetime
    user: UserRef
    progress: float
    item_count: int
    done_count: int
    failed_count: int


class DownloadRequestDetail(DownloadRequestOut):
    items: list[DownloadItemOut]


class RequestIn(BaseModel):
    kind: Literal["track", "album"]
    id: str = Field(min_length=1, max_length=20, pattern=r"^[0-9]+$")
    temporary: bool = False


class RedownloadIn(BaseModel):
    youtube_url: str | None = Field(None, max_length=500)


class RejectIn(BaseModel):
    note: str | None = Field(None, max_length=500)


class SourceIn(BaseModel):
    url: str = Field(max_length=500)


class DownloadSummary(BaseModel):
    active: int
    queued: int
    failed: int
    pending_approval: int


# --- imports ---------------------------------------------------------------


class ImportBatchIn(BaseModel):
    kind: Literal["import", "cleanup"]


class ImportBatchOut(ORM):
    id: uuid.UUID
    kind: str
    mode: str
    status: str
    total: int
    processed: int
    identified: int
    imported: int
    duplicates: int
    unidentified: int
    failed: int
    message: str | None
    created_at: datetime
    finished_at: datetime | None
    progress: float = 0


class ImportFileOut(ORM):
    id: uuid.UUID
    path: str
    status: str
    method: str | None
    acoustid_score: float | None
    target: str | None
    error: str | None
    title: str | None = None
    artist: str | None = None
    album: str | None = None


# --- metadata editor --------------------------------------------------------


class ManualMetaIn(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=512)
    artist: str | None = Field(None, min_length=1, max_length=512)
    album: str | None = Field(None, min_length=1, max_length=512)
    album_artist: str | None = Field(None, min_length=1, max_length=512)
    year: int | None = Field(None, ge=1000, le=2100)
    track_no: int | None = Field(None, ge=1, le=999)
    disc_no: int | None = Field(None, ge=1, le=99)
    genre: str | None = Field(None, max_length=256)


class TrackFileOut(BaseModel):
    path: str
    title: str | None
    artist: str | None
    album: str | None
    album_artist: str | None
    year: int | None
    track_no: int | None
    disc_no: int | None
    genre: str | None
    duration: float
    codec: str | None
    bitrate: int | None
    mb_recording_id: str | None
    mb_release_id: str | None
    query: str


class FingerprintReleaseOut(BaseModel):
    release_id: str
    album: str | None
    year: int | None
    disc_no: int | None
    track_no: int | None
    release_tracks: int | None


class FingerprintMatchOut(BaseModel):
    recording_id: str
    title: str | None
    artist: str | None
    score: float
    releases: list[FingerprintReleaseOut]


class TrackMatchIn(BaseModel):
    source: Literal["deezer", "musicbrainz", "manual", "apple"]
    deezer_id: str | None = None
    apple_id: str | None = None
    recording_id: str | None = None
    release_id: str | None = None
    meta: ManualMetaIn | None = None


class AlbumMatchIn(BaseModel):
    source: Literal["deezer", "musicbrainz", "apple", "discogs"]
    id: str = Field(min_length=1)


class AlbumMatchOut(BaseModel):
    album: AlbumOut | None
    matched: int
    unmatched: list[TrackOut]


class CoverOptionOut(BaseModel):
    url: str
    source: Literal["musicbrainz", "deezer", "apple", "discogs"]
    label: str


class ReviewTrackOut(TrackOut):
    path: str
