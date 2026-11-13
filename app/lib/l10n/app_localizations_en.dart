// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsPlayback => 'Playback';

  @override
  String get commonProductName => 'Resonance';

  @override
  String get errorInvalidInput => 'Invalid input';

  @override
  String get errorServerUnreachable => 'Server unreachable';

  @override
  String errorHttpStatus(String statusCode) {
    return 'Error $statusCode';
  }

  @override
  String get catalogSingle => 'Single';

  @override
  String get catalogCompilation => 'Compilation';

  @override
  String get commonAlbum => 'Album';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get playerMusicLoadError => 'The music couldn\'t be loaded. Please try again.';

  @override
  String get playerAudiobookLoadError => 'The audiobook couldn\'t be loaded. Please try again.';

  @override
  String playerBookPart(int part, int total) {
    return 'Part $part of $total';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Your Library';

  @override
  String get navAudiobooks => 'Audiobooks';

  @override
  String get navMedia => 'Media';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get libraryCreatePlaylist => 'Create playlist';

  @override
  String get libraryNewPlaylist => 'New playlist';

  @override
  String get playlistCollaborative => 'Collaborative playlist';

  @override
  String get playlistCollaborativeHint => 'Everyone you share it with can add, move and remove songs.';

  @override
  String playlistAddedBy(String name) {
    return 'by $name';
  }

  @override
  String get commonName => 'Name';

  @override
  String get libraryLikedSongs => 'Liked Songs';

  @override
  String get commonPlaylist => 'Playlist';

  @override
  String libraryPlaylistBy(String name) {
    return 'Playlist • $name';
  }

  @override
  String get navSettings => 'Settings';

  @override
  String get searchHint => 'What do you want to listen to?';

  @override
  String searchNoLibraryResults(String query) {
    return 'No results for “$query” in your library.';
  }

  @override
  String get tvKeyboardSpace => 'Space';

  @override
  String get tvKeyboardDelete => 'Delete';

  @override
  String get tvKeyboardClear => 'Clear';

  @override
  String get tvKeyboardSearch => 'Search';

  @override
  String get tvSearchAvailableAlbums => 'Available to download: albums';

  @override
  String get tvSearchAvailableSongs => 'Available to download: songs';

  @override
  String tvCatalogRequestBy(String artist) {
    return 'By $artist';
  }

  @override
  String get commonSongsTitle => 'Songs';

  @override
  String get commonArtist => 'Artist';

  @override
  String get commonAlbums => 'Albums';

  @override
  String get libraryAllArtists => 'All artists';

  @override
  String get libraryTitle => 'Your Library';

  @override
  String get libraryPlaylists => 'Playlists';

  @override
  String get librarySavedAlbums => 'Saved albums';

  @override
  String get libraryAllAlbums => 'All albums';

  @override
  String get libraryLoadingSongs => '… songs';

  @override
  String get libraryNoAlbums => 'No albums';

  @override
  String get librarySaveAlbumsHint => 'Save albums with ⊕ to see them here.';

  @override
  String commonDiscNumber(int number) {
    return 'CD $number';
  }

  @override
  String get libraryRemoveAlbum => 'Remove from library';

  @override
  String get librarySaveAlbum => 'Save to library';

  @override
  String get playerAddToPlaylist => 'Add to playlist';

  @override
  String get editorCorrectAlbum => 'Edit album metadata';

  @override
  String get editorMatchAlbum => 'Match album';

  @override
  String get editorChangeCover => 'Change cover';

  @override
  String artistLibraryAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums in your library',
      one: '$count album in your library',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Popular';

  @override
  String get artistDiscography => 'Discography';

  @override
  String get libraryPublicPlaylist => 'Public playlist';

  @override
  String get libraryRenamePlaylist => 'Rename playlist';

  @override
  String get commonRename => 'Rename';

  @override
  String get libraryMakePrivate => 'Make private';

  @override
  String get librarySharePlaylist => 'Share with all users';

  @override
  String get commonDelete => 'Delete';

  @override
  String get libraryEmptyPlaylist => 'No songs yet. Add some using a song\'s ⋯ menu.';

  @override
  String get libraryRemoveFromPlaylist => 'Remove from this playlist';

  @override
  String get homeGreetingNight => 'Good night';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeRecentlyPlayed => 'Recently played';

  @override
  String get homeYourPlaylists => 'Your playlists';

  @override
  String get homeRecentlyAdded => 'New in your library';

  @override
  String get homeEmptyLibrary => 'Your library is still empty.\nAn admin can start a library scan in the dashboard.';

  @override
  String get settingsAutoplay => 'Autoplay';

  @override
  String get settingsAutoplayHint => 'Keep playing similar songs when the queue ends';

  @override
  String get playerAutoplaySection => 'Autoplay – similar songs';

  @override
  String get playerSmartShuffle => 'Smart Shuffle';

  @override
  String get playerShuffleOff => 'Shuffle off';

  @override
  String get playerNothingPlaying => 'Nothing playing right now';

  @override
  String get playerQueue => 'Queue';

  @override
  String get audiobooksBook => 'Audiobook';

  @override
  String get playerGoToAudiobook => 'Go to audiobook';

  @override
  String get audiobooksChapters => 'Chapters';

  @override
  String get playerEmptyQueue => 'The queue is empty';

  @override
  String get playerNowPlaying => 'Now playing';

  @override
  String get playerNextUp => 'Next up';

  @override
  String get playerRemoveFromQueue => 'Remove from queue';

  @override
  String get playerNextInQueue => 'Next in queue';

  @override
  String get playerLater => 'Later';

  @override
  String playerRemovedTrack(String title) {
    return 'Removed “$title” from queue';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAdministratorSuffix => ' • Administrator';

  @override
  String get settingsDisplayName => 'Display name';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsResetCode => 'Code for a new password';

  @override
  String get settingsResetCodeHint => 'For another device, if you forgot your password';

  @override
  String settingsResetCodeBody(int minutes) {
    return 'Enter this code there under “Forgot password?”. It works for $minutes minutes and only until the password is changed.';
  }

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authResetTitle => 'Set a new password';

  @override
  String get authResetHint =>
      'Open Resonance on a device where you are still signed in: Settings → “Code for a new password”. Without a signed-in device, an admin can set a new password for you.';

  @override
  String get authResetCode => 'Code';

  @override
  String get authResetSubmit => 'Set password';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsMediaTabs => 'Media tabs';

  @override
  String get settingsEbooks => 'Ebooks';

  @override
  String get settingsShowInMenu => 'Show in the menu';

  @override
  String get settingsAccentColor => 'Accent color';

  @override
  String get settingsCustomColor => 'Custom color';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonApply => 'Apply';

  @override
  String get settingsNormalizeVolume => 'Normalize volume';

  @override
  String get settingsNormalizeVolumeHint => 'Uses ReplayGain to keep songs at a similar volume';

  @override
  String get settingsSignedInDevices => 'Signed-in devices';

  @override
  String get settingsUnknownDevice => 'Unknown device';

  @override
  String get settingsCurrentDeviceSuffix => ' (this device)';

  @override
  String settingsLastActive(String date) {
    return 'Last active: $date';
  }

  @override
  String get commonSignOut => 'Log out';

  @override
  String get settingsCurrentPassword => 'Current password';

  @override
  String get settingsNewPassword => 'New password';

  @override
  String get commonChange => 'Change';

  @override
  String get settingsPasswordChanged => 'Password changed';

  @override
  String get catalogDiscoverMore => 'Discover more';

  @override
  String get catalogDownloadHint => 'Download music here that isn\'t in your library yet.';

  @override
  String get catalogNoResults => 'Nothing found in the catalog either.';

  @override
  String get catalogAllInLibrary => 'All in your library';

  @override
  String catalogLibraryCount(int count, int total) {
    return '$count of $total in your library';
  }

  @override
  String get catalogDownloadAlbum => 'Download album';

  @override
  String get catalogDownloadMissingSong => 'Download missing song';

  @override
  String catalogDownloadMissingSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Download $count missing songs',
      one: 'Download $count missing song',
    );
    return '$_temp0';
  }

  @override
  String get catalogOpenInLibrary => 'Open in library';

  @override
  String get catalogEps => 'EPs';

  @override
  String get catalogSingles => 'Singles';

  @override
  String catalogArtistReleases(int count, int inLibrary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count releases • $inLibrary in your library',
      one: '$count release • $inLibrary in your library',
    );
    return '$_temp0';
  }

  @override
  String get downloadsMine => 'Mine';

  @override
  String get downloadsAllUsers => 'All users';

  @override
  String get downloadsOpen => 'Open';

  @override
  String get downloadsCompleted => 'Completed';

  @override
  String get downloadsEmptyActive => 'No active downloads.\nSearch for music and tap ⤓.';

  @override
  String get downloadsEmptyCompleted => 'Nothing downloaded yet.';

  @override
  String get downloadsFailed => 'Failed';

  @override
  String get downloadsEmptyFailed => 'No failed downloads.';

  @override
  String get downloadsRetryAll => 'Retry all';

  @override
  String get downloadsRetryAllConfirm =>
      'All failed songs in this list are searched and downloaded again. With a lot of songs YouTube may pause in between.';

  @override
  String downloadsRetryAllDone(int songs, int requests) {
    return 'Retrying $songs songs from $requests requests';
  }

  @override
  String downloadsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count requests', one: '1 request');
    return '$_temp0';
  }

  @override
  String downloadsLoadMore(int shown, int total) {
    return 'Load more ($shown of $total)';
  }

  @override
  String get commonSong => 'Song';

  @override
  String downloadsRequestedBySuffix(String name) {
    return 'by $name';
  }

  @override
  String get downloadsReject => 'Reject';

  @override
  String get downloadsApprove => 'Approve';

  @override
  String get downloadsRejectRequest => 'Reject request';

  @override
  String get downloadsReasonOptional => 'Reason (optional)';

  @override
  String get downloadsDownload => 'Download';

  @override
  String downloadsProgress(String status, int done, int total, String failed) {
    return '$status • $done/$total done$failed';
  }

  @override
  String downloadsFailedSuffix(int count) {
    return ' • $count failed';
  }

  @override
  String downloadsRequestedBy(String name) {
    return 'Requested by $name';
  }

  @override
  String downloadsReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get downloadsRetryFailed => 'Retry failed downloads';

  @override
  String get downloadsOwnSource => 'Use your own link';

  @override
  String get downloadsCopyTitle => 'Copy title and artist';

  @override
  String downloadsCopied(String text) {
    return 'Copied “$text”';
  }

  @override
  String get downloadsOwnSourceLabel => 'YouTube, SoundCloud or Bandcamp link';

  @override
  String get downloadsOwnSourceHint => 'Regular YouTube videos work too – only the audio is downloaded.';

  @override
  String get downloadsDeleteEntry => 'Delete entry';

  @override
  String get catalogYouTubeMusic => 'YouTube Music';

  @override
  String get downloadsTorrent => 'Torrent';

  @override
  String get downloadsSearchingTorrent => 'Searching for a torrent …';

  @override
  String downloadsTorrentProgress(String name, int progress) {
    return 'Torrent: $name ($progress %)';
  }

  @override
  String get downloadsImportingTorrent => 'Importing torrent …';

  @override
  String downloadsTorrentName(String name) {
    return 'Torrent: $name';
  }

  @override
  String downloadsTorrentFallback(String error) {
    return 'No torrent – downloading from YouTube Music$error';
  }

  @override
  String commonDurationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String commonDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get audiobooksFinished => 'Finished';

  @override
  String audiobooksTimeRemaining(String duration) {
    return '$duration left';
  }

  @override
  String get statsUnitHours => 'h';

  @override
  String get statsUnitMinutes => 'm';

  @override
  String get statsTitle => 'Your stats';

  @override
  String get statsTotal => 'Total listening time';

  @override
  String statsDaysOfAudio(String days) {
    return 'That\'s $days days of audio';
  }

  @override
  String get statsToday => 'Today';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsActivity => 'Activity';

  @override
  String get statsCurrentStreak => 'Current streak';

  @override
  String get statsBestStreak => 'Best streak';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get statsBooksFinished => 'Books finished';

  @override
  String get statsBooksThisYear => 'Books this year';

  @override
  String get statsDaysActive => 'Days active';

  @override
  String get statsDailyAverage => 'Daily average';

  @override
  String get statsLast7Days => 'Last 7 days';

  @override
  String get statsMostListened => 'Most listened';

  @override
  String statsHoursMinutesShort(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String statsMinutesShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String statsTeaser(String time, int books) {
    return '$time listened · $books books finished';
  }

  @override
  String get mediaContinue => 'Continue';

  @override
  String get mediaLatest => 'Latest episodes';

  @override
  String audiobooksChapterOf(int index, int count) {
    return 'Chapter $index of $count';
  }

  @override
  String get audiobooksPreviousChapter => 'Previous chapter';

  @override
  String get audiobooksNextChapter => 'Next chapter';

  @override
  String get playerSpeedShort => 'Speed';

  @override
  String get playerSleepShort => 'Timer';

  @override
  String playerAtSpeed(String speed) {
    return 'at $speed';
  }

  @override
  String get audiobooksNotConfigured => 'Audiobooks aren\'t set up on this server.';

  @override
  String get audiobooksLoginTitle => 'Connect to Audiobookshelf';

  @override
  String audiobooksLoginHint(String address) {
    return 'Log in with your Audiobookshelf account$address. Your listening progress stays in sync across all Audiobookshelf apps.';
  }

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Log in';

  @override
  String get audiobooksNoLibrary => 'No audiobook library found';

  @override
  String audiobooksSignOutUser(String name) {
    return 'Log out ($name)';
  }

  @override
  String get audiobooksSearchHint => 'Search by title, author, or series';

  @override
  String get audiobooksContinueListening => 'Continue listening';

  @override
  String get audiobooksResume => 'Resume';

  @override
  String get audiobooksAllBooks => 'All audiobooks';

  @override
  String get commonNothingFound => 'Nothing found';

  @override
  String audiobooksNarrator(String name) {
    return 'narrated by $name';
  }

  @override
  String get audiobooksStartOver => 'Start from the beginning';

  @override
  String get audiobooksMarkUnfinished => 'Mark as unfinished';

  @override
  String get audiobooksMarkFinished => 'Mark as finished';

  @override
  String authCheckAddress(String error) {
    return '$error\nIs the address correct?';
  }

  @override
  String get authConnectTitle => 'Connect to server';

  @override
  String get authServerAddress => 'Server address';

  @override
  String get authConnect => 'Connect';

  @override
  String get commonRetry => 'Try again';

  @override
  String get authOtherServer => 'Other server';

  @override
  String authSignInTo(String name) {
    return 'Log in to $name';
  }

  @override
  String get authCreateAccount => 'Create account';

  @override
  String authServer(String address) {
    return 'Server: $address';
  }

  @override
  String get authPasswordsMismatch => 'Passwords don\'t match';

  @override
  String get authInvalidInvite => 'Invalid invitation';

  @override
  String get authInvalidInviteHint =>
      'This invite link has already been used or has expired. Please ask an admin for a new link.';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get authWelcomeAdmin => 'Welcome! Create an admin account';

  @override
  String get authFirstAccountHint => 'The first account on this server automatically becomes an administrator.';

  @override
  String get authPasswordMinimum => 'Password (min. 8 characters)';

  @override
  String get authRepeatPassword => 'Repeat password';

  @override
  String get authRegister => 'Sign up';

  @override
  String get authAlreadyHaveAccount => 'I already have an account';

  @override
  String catalogAwaitingApproval(String title) {
    return '“$title” is waiting for admin approval';
  }

  @override
  String catalogAlreadyInLibrary(String title) {
    return '“$title” is already in your library';
  }

  @override
  String catalogDownloadingTitle(String title) {
    return '“$title” is being downloaded';
  }

  @override
  String get catalogInYourLibrary => 'In your library';

  @override
  String get catalogRequested => 'Requested';

  @override
  String get catalogDownload => 'Download';

  @override
  String get catalogInLibrary => 'In library';

  @override
  String get catalogPlaylistKind => 'Playlist';

  @override
  String get catalogPlaylistImport => 'Import and download missing songs';

  @override
  String get catalogPlaylistUpdate => 'Import again';

  @override
  String get catalogPlaylistShowImport => 'View';

  @override
  String get catalogPlaylistImportHint =>
      'Creates the playlist in your library; missing songs are downloaded and added once they arrive.';

  @override
  String get catalogSpotifyPreviewLimit => 'Spotify only hands out the first 100 songs of other people\'s playlists.';

  @override
  String get downloadsStatusPendingApproval => 'Waiting for approval';

  @override
  String get downloadsStatusRunning => 'Running';

  @override
  String get commonDone => 'Done';

  @override
  String get commonUndo => 'Undo';

  @override
  String get playlistSort => 'Sort';

  @override
  String get playlistSortHint => 'Changes the playlist\'s order for everyone';

  @override
  String get playlistSorted => 'Playlist sorted';

  @override
  String get playlistReorder => 'Reorder by hand';

  @override
  String get playlistSetPeak => 'As a DJ set: warm up, peak, cool down';

  @override
  String get playlistSetRise => 'As a DJ set: building up';

  @override
  String get playlistSetDown => 'As a DJ set: winding down';

  @override
  String get playlistSetFlow => 'As a DJ set: steady flow';

  @override
  String get playlistSortTitle => 'By title';

  @override
  String get playlistSortArtist => 'By artist';

  @override
  String get playlistSortAlbum => 'By album';

  @override
  String get playlistSortLength => 'By length';

  @override
  String get playlistSortReverse => 'Reverse';

  @override
  String get downloadsStatusPartial => 'Partially complete';

  @override
  String get downloadsStatusFailed => 'Failed';

  @override
  String get downloadsStatusRejected => 'Rejected';

  @override
  String get downloadsStatusCancelled => 'Cancelled';

  @override
  String get downloadsStatusQueued => 'Queued';

  @override
  String get downloadsStatusSearching => 'Finding a source …';

  @override
  String get downloadsStatusDownloading => 'Downloading';

  @override
  String get downloadsStatusProcessing => 'Tagging …';

  @override
  String get downloadsStatusExisting => 'Already exists';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get playerRemoveLiked => 'Remove from Liked Songs';

  @override
  String get playerAddLiked => 'Add to Liked Songs';

  @override
  String get playerPlayNext => 'Play next';

  @override
  String get playerAddToQueue => 'Add to queue';

  @override
  String playerQueuedTrack(String title) {
    return '“$title” added to queue';
  }

  @override
  String get playerGoToAlbum => 'Go to album';

  @override
  String get playerGoToArtist => 'Go to artist';

  @override
  String get editorCorrectMetadata => 'Edit metadata';

  @override
  String libraryAddedToPlaylist(String name) {
    return 'Added to “$name”';
  }

  @override
  String get commonSave => 'Save';

  @override
  String get playerSkipBack => 'Back 30 seconds';

  @override
  String get playerSkipForward => 'Forward 30 seconds';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get playerRepeat => 'Repeat';

  @override
  String get playerSpeed => 'Speed';

  @override
  String get playerSleepTimer => 'Sleep timer';

  @override
  String playerSleepTimerTime(String time) {
    return 'Sleep timer: pauses at $time';
  }

  @override
  String playerTimerMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return '$_temp0';
  }

  @override
  String get playerDisableTimer => 'Turn off timer';

  @override
  String get playerFullscreen => 'Fullscreen';

  @override
  String commonDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String get updateAllowInstall => 'Please allow Resonance to install apps in Android settings.';

  @override
  String updateFailedCode(String code) {
    return 'Update failed ($code). Please try again.';
  }

  @override
  String updateFailedMessage(String error) {
    return 'Update failed: $error';
  }

  @override
  String get updateInProgress => 'Updating app';

  @override
  String get updateDownloadStarting => 'Starting download …';

  @override
  String updateDownloadProgress(int percent) {
    return 'Download $percent %';
  }

  @override
  String get commonClose => 'Close';

  @override
  String get mixExport => 'Export the mix as MP3';

  @override
  String mixExportRendering(int percent) {
    return 'The server is mixing the transitions … $percent %';
  }

  @override
  String get mixExportBackground => 'Continue in background';

  @override
  String get mixExportFailed => 'The mix could not be made';

  @override
  String get mixExportSaving => 'Saving the mix …';

  @override
  String mixExportSaved(String target) {
    return 'Mix saved: $target';
  }

  @override
  String updateAvailableTitle(String version) {
    return 'New app version $version available';
  }

  @override
  String get updateInstall => 'Install';

  @override
  String updateInstalledVersion(String version) {
    return 'App version $version';
  }

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateCurrent => 'Up to date';

  @override
  String get updateAction => 'Update';

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateAlreadyCurrent => 'The app is up to date';

  @override
  String get adminImportCleanupTitle => 'Clean up library?';

  @override
  String get adminImportCleanupHint =>
      'All songs in the library will be identified by audio fingerprint, retagged, given cover art, and renamed to “Artist/Album (Year)/No - Title”. The files will be modified directly.\n\nLikes, playlists, and history will be preserved. This takes several hours for large libraries.';

  @override
  String get adminImportCleanupConfirm => 'Clean up';

  @override
  String get adminImportFolder => 'Import folder';

  @override
  String adminImportPendingFiles(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audio files waiting • Mode: $mode',
      one: '$count audio file waiting • Mode: $mode',
    );
    return '$_temp0';
  }

  @override
  String get adminImportCopyHint => 'Copy (originals stay unchanged)';

  @override
  String get adminImportMove => 'Move';

  @override
  String get adminImportAcoustIdHint =>
      'No AcoustID key configured – songs will only be identified using their existing tags. Get a free key at acoustid.org/new-application and enter it under “Server”.';

  @override
  String get adminImportStart => 'Start import';

  @override
  String get adminImportCleanup => 'Clean up library';

  @override
  String get adminImportHistory => 'History';

  @override
  String get adminImportEmptyHistory => 'No imports yet.';

  @override
  String get adminImportWaiting => 'Waiting';

  @override
  String adminImportBatchTitle(String mode) {
    return 'Import ($mode)';
  }

  @override
  String adminImportFileProgress(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$count of $total files',
      one: '$count of $total file',
    );
    return '$_temp0';
  }

  @override
  String get adminImportIdentified => 'Identified';

  @override
  String get adminImportImported => 'Imported';

  @override
  String get adminImportDuplicates => 'Duplicates';

  @override
  String get adminImportUnidentified => 'Unidentified';

  @override
  String get adminImportErrors => 'Errors';

  @override
  String get adminImportMethodAlbumFingerprint => 'Identified by fingerprint (whole album)';

  @override
  String get adminImportMethodTrackFingerprint => 'Identified by fingerprint (single song)';

  @override
  String get adminImportMethodTags => 'Identified using existing tags (catalog)';

  @override
  String get adminImportMethodUnidentified => 'Unidentified – existing tags kept';

  @override
  String get adminTabOverview => 'Overview';

  @override
  String get adminTabUsers => 'Users';

  @override
  String get adminTabInvites => 'Invitations';

  @override
  String get adminTabImport => 'Import';

  @override
  String get adminTabReview => 'Review';

  @override
  String get adminTabServer => 'Server';

  @override
  String get adminStorage => 'Storage';

  @override
  String get adminPlaytime => 'Playtime';

  @override
  String get adminMixAnalysis => 'AutoMix analysis';

  @override
  String get adminVocalAnalysis => 'Vocal detection for AutoMix';

  @override
  String get adminVocalAnalysisHint =>
      'Splits the start and end of every song into voice and music (Demucs) so voices do not overlap in transitions. Switching it on downloads about 1 GB once; each song then takes about a minute of CPU time in the background, the whole library several days. Often played songs go first.';

  @override
  String get adminVocalAnalysisInstalling => 'Setting up vocal detection (about 1 GB) …';

  @override
  String adminVocalAnalysisFailed(String message) {
    return 'Setting up vocal detection failed, next attempt in an hour: $message';
  }

  @override
  String adminVocalAnalysisProgress(String analyzed, String total) {
    return 'Vocal detection: $analyzed of $total songs';
  }

  @override
  String get adminLyrics => 'Lyrics';

  @override
  String adminLyricsProgress(String synced, String plainOnly, String none, String pending) {
    return '$synced synced, $plainOnly plain only, $none none · $pending pending';
  }

  @override
  String get adminLyricsBackgroundFetch => 'Fetch lyrics in the background';

  @override
  String adminMixAnalysisProgress(String analyzed, String total) {
    return '$analyzed of $total songs analyzed';
  }

  @override
  String adminMixAnalysisDone(String total) {
    return 'All $total songs analyzed';
  }

  @override
  String adminMixAnalysisFailed(String failed) {
    return ', $failed failed';
  }

  @override
  String commonDurationHours(String hours) {
    return '$hours hr';
  }

  @override
  String get adminScanHint =>
      'A quick scan reads only new and changed files. A full scan rereads all tags and cover art.';

  @override
  String get adminQuickScan => 'Quick scan';

  @override
  String get adminFullScan => 'Full scan';

  @override
  String get adminJobs => 'Jobs';

  @override
  String get adminNoJobs => 'No jobs yet';

  @override
  String get adminLibraryScan => 'Library scan';

  @override
  String get adminUserYouSuffix => ' (you)';

  @override
  String get adminUserDisabledSuffix => ' • disabled';

  @override
  String adminUserLastSeenSuffix(String date) {
    return ' • last seen $date';
  }

  @override
  String adminNewPasswordFor(String name) {
    return 'New password for $name';
  }

  @override
  String get adminPasswordSet => 'Password set, all devices logged out';

  @override
  String adminDeleteUserTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get adminDeleteUserHint => 'Playlists and history will also be deleted.';

  @override
  String get adminRemoveAdmin => 'Remove admin rights';

  @override
  String get adminMakeAdmin => 'Make admin';

  @override
  String get adminEnableUser => 'Enable';

  @override
  String get adminDisableUser => 'Disable';

  @override
  String get adminResetPassword => 'Reset password';

  @override
  String get adminPasswordMinimum => 'Min. 8 characters';

  @override
  String get adminCreateInviteTitle => 'Create invite link';

  @override
  String get adminInviteNote => 'Note (e.g. who it\'s for)';

  @override
  String get adminInviteValidity => 'Valid for';

  @override
  String get adminInviteOneDay => '1 day';

  @override
  String get adminInviteThreeDays => '3 days';

  @override
  String get adminInviteSevenDays => '7 days';

  @override
  String get adminInviteThirtyDays => '30 days';

  @override
  String get adminInviteUnlimited => 'Unlimited';

  @override
  String get adminInviteAsAdmin => 'Register as admin';

  @override
  String get commonCreate => 'Create';

  @override
  String get adminInviteLink => 'Invite link';

  @override
  String get adminInviteLinkHint => 'This link can be used exactly once. It is only shown now.';

  @override
  String get adminLinkCopied => 'Link copied';

  @override
  String get commonCopy => 'Copy';

  @override
  String get adminNewInvite => 'New link';

  @override
  String get adminNoInvites => 'No invitations yet.\nCreate a link to invite someone.';

  @override
  String get adminInvitation => 'Invitation';

  @override
  String adminInviteUsed(String name, String date) {
    return 'Used by $name on $date';
  }

  @override
  String get adminInviteExpired => 'Expired';

  @override
  String adminInviteOpen(String expiry, String role) {
    return 'Open • $expiry$role';
  }

  @override
  String get adminInviteNoExpiry => 'never expires';

  @override
  String adminInviteExpires(String date) {
    return 'valid until $date';
  }

  @override
  String get adminInviteAdminSuffix => ' • Admin';

  @override
  String get adminServerName => 'Server name';

  @override
  String get adminRegistration => 'Registration';

  @override
  String get adminRegistrationInviteOnly => 'Invite link only';

  @override
  String get adminRegistrationInviteHint => 'Admins create single-use links (recommended)';

  @override
  String get adminRegistrationPublic => 'Public registration';

  @override
  String get adminRegistrationPublicHint => 'Anyone who can reach the server can create an account';

  @override
  String get adminLibraryImport => 'Library & Import';

  @override
  String get adminAcoustIdKey => 'AcoustID key';

  @override
  String get adminAcoustIdNotSet => 'Not set – get a free key at acoustid.org/new-application';

  @override
  String get adminConfigured => 'Set';

  @override
  String get adminAcoustIdHint => 'For identification using audio fingerprints';

  @override
  String get adminMoveImportedFiles => 'Move imported files';

  @override
  String get adminMoveImportedFilesHint => 'The import folder is emptied afterwards';

  @override
  String get adminCopyImportedFiles => 'Copy imported files';

  @override
  String get adminCopyImportedFilesHint => 'Originals stay unchanged in the import folder';

  @override
  String get adminImportUnidentifiedFiles => 'Import unidentified files anyway';

  @override
  String get adminImportUnidentifiedFilesHint => 'Using their existing tags; otherwise they stay in the import folder';

  @override
  String get adminAutoImport => 'Automatically import the import folder';

  @override
  String get adminAutoImportHint => 'Checks for new files every 5 minutes (only in “Move” mode)';

  @override
  String get adminSongRadio => 'Song radio';

  @override
  String get adminRadioAutoDownload => 'Automatically download missing songs';

  @override
  String get adminRadioAutoDownloadHint =>
      'Similar songs that aren\'t in the library yet are added to the download queue';

  @override
  String get adminRadioTemporary => 'Radio downloads are temporary';

  @override
  String adminRadioTemporaryHint(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Deleted after $days days unless someone likes them or adds them to a playlist',
      one: 'Deleted after $days day unless someone likes them or adds them to a playlist',
    );
    return '$_temp0';
  }

  @override
  String get adminRadioRetention => 'Temporary song retention (days)';

  @override
  String get adminEnableAudiobookshelf => 'Connect Audiobookshelf';

  @override
  String get adminEnableAudiobookshelfHint =>
      'Shows the “Audiobooks” tab. Each user logs in with their own Audiobookshelf account.';

  @override
  String get adminAudiobookshelfAddress => 'Audiobookshelf address';

  @override
  String get adminAudiobookshelfAddressHint => 'e.g. https://audio.example.com – also used by external apps';

  @override
  String get adminAlbumTorrents => 'Torrents for albums';

  @override
  String get adminAlbumTorrentsHint =>
      'Searches for albums through Prowlarr (public trackers) first and downloads them with qBittorrent over the VPN. Anything missing comes from YouTube Music.';

  @override
  String get adminProwlarrApiKey => 'Prowlarr API key';

  @override
  String get adminProwlarrApiKeyHint => 'Prowlarr → Settings → General → API Key';

  @override
  String get adminQbittorrentUsername => 'qBittorrent username';

  @override
  String get adminQbittorrentPassword => 'qBittorrent password';

  @override
  String get adminMinimumSeeders => 'Minimum seeders';

  @override
  String get adminTorrentTimeout => 'Give up after … minutes without progress';

  @override
  String get adminTorrentSeedDays => 'Keep torrents for … days';

  @override
  String get adminTorrentSeedDaysHint =>
      'Afterwards finished torrents and their files are deleted from qBittorrent (the songs in the library stay). Torrents stopped by qBittorrent are deleted right away. 0 = right after the import.';

  @override
  String get adminYouTubeSource => 'YouTube Music as a source';

  @override
  String get adminYouTubeSourceHint => 'Downloads songs from YouTube Music via yt-dlp (Opus, approx. 130–160 kbit/s)';

  @override
  String get adminYouTubeCookies => 'YouTube sign-in';

  @override
  String get adminYouTubeCookiesHint =>
      'Explicit and other age-restricted songs need a signed-in YouTube account. Upload a cookies.txt of a spare account (export it in a private browser window with an extension like \"Get cookies.txt LOCALLY\", then close the window).';

  @override
  String adminYouTubeCookiesActive(String date) {
    return 'Signed in since $date';
  }

  @override
  String get adminYouTubeCookiesFromEnv => 'Set on the server (RESONANCE_YTDLP_COOKIES_FILE)';

  @override
  String get adminYouTubeCookiesNone => 'Not signed in: age-restricted videos are skipped';

  @override
  String get adminYouTubeCookiesExpired =>
      'Sign-in expired: YouTube rotated the cookies. Export them again and upload them.';

  @override
  String get adminYouTubeCookiesUpload => 'Upload cookies.txt';

  @override
  String get adminYouTubeCookiesRemove => 'Remove';

  @override
  String get adminYouTubeCookiesSaved => 'YouTube sign-in saved';

  @override
  String get adminSoundCloudSource => 'SoundCloud as a source';

  @override
  String get adminSoundCloudSourceHint => 'Tried when YouTube finds nothing';

  @override
  String get adminBandcampSource => 'Bandcamp as a source';

  @override
  String get adminBandcampSourceHint => 'Free 128 kbit/s streams, tried last';

  @override
  String get downloadsSearch => 'Search';

  @override
  String get adminQualityUpgrades => 'Quality upgrades';

  @override
  String get downloadsQualityUpgrade => 'Quality upgrade';

  @override
  String get adminQualityUpgradeSearchNow => 'Search now';

  @override
  String get adminQualityUpgradeStarted => 'Search started';

  @override
  String get adminQualityUpgradesHint =>
      'Looks for better versions (torrent) of low-quality songs in the background and replaces them. Requires torrents to be enabled.';

  @override
  String get adminAutoApprove => 'Automatically approve requests';

  @override
  String get adminAutoApproveHint => 'Otherwise an admin must approve users\' requests';

  @override
  String get adminDailyLimit => 'Daily limit per user';

  @override
  String adminDailyLimitHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Max. $count automatic downloads per day',
      one: 'Max. $count automatic download per day',
    );
    return '$_temp0';
  }

  @override
  String get adminDownloadsPerDay => 'Downloads per user per day';

  @override
  String get adminNotConfigured => 'Not set';

  @override
  String get adminTestConnection => 'Test connection';

  @override
  String get adminTestKey => 'Test key';

  @override
  String get adminProwlarr => 'Prowlarr';

  @override
  String get adminQbittorrent => 'qBittorrent';

  @override
  String editorSavedTrack(String title, String artist, String album) {
    return 'Saved: $title – $artist ($album)';
  }

  @override
  String editorBitrate(int bitrate) {
    return '$bitrate kbit/s';
  }

  @override
  String get editorTabSearch => 'Search';

  @override
  String get editorTabFingerprint => 'Fingerprint';

  @override
  String get editorTabEdit => 'Edit';

  @override
  String get editorSearchTrackHint => 'Artist and title';

  @override
  String get editorChooseTrackHint => 'Tap the correct song to apply its tags, cover art, and filename.';

  @override
  String get editorFingerprintSearching => 'Matching audio fingerprint …';

  @override
  String get editorFingerprintUnknown => 'AcoustID doesn\'t recognize this recording. Try “Search” or “Edit”.';

  @override
  String get editorUnknownTitle => 'Unknown title';

  @override
  String editorFingerprintScore(int percent) {
    return '   $percent % match';
  }

  @override
  String get editorAutoSelectAlbum => 'Choose original album automatically';

  @override
  String get editorUnknownAlbum => 'Unknown album';

  @override
  String editorTrackNumberWithTotal(int number, String total) {
    return 'No. $number$total';
  }

  @override
  String editorTrackTotalSuffix(int total) {
    return ' of $total';
  }

  @override
  String get editorNumbersOnly => 'Please enter numbers only for year, track number, and CD';

  @override
  String get editorNoChanges => 'No changes';

  @override
  String get editorTitle => 'Title';

  @override
  String get editorSwapTitleArtist => 'Swap title and artist';

  @override
  String get editorAlbumArtist => 'Album artist';

  @override
  String get editorYear => 'Year';

  @override
  String get editorTrackNumber => 'No.';

  @override
  String get editorGenre => 'Genre';

  @override
  String get editorManualHint =>
      'Empty fields stay unchanged. The file is then renamed to “Album Artist/Album (Year)/No - Title”.';

  @override
  String editorMatchedSongs(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$count of $total songs matched',
      one: '$count of $total song matched',
    );
    return '$_temp0';
  }

  @override
  String get editorUnmatchedSongs => 'Unmatched (unchanged):';

  @override
  String get editorSearchAlbumHint => 'Artist and album or MusicBrainz link';

  @override
  String editorMatchAlbumHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The $count songs on this album are matched to the chosen release by title, position, and duration. Songs that don\'t match stay unchanged.',
      one:
          'The $count song on this album is matched to the chosen release by title, position, and duration. Songs that don\'t match stay unchanged.',
    );
    return '$_temp0';
  }

  @override
  String get editorUseMusicBrainzRelease => 'Use MusicBrainz release';

  @override
  String get editorRetagging => 'Retagging songs …';

  @override
  String get editorCoverSaved => 'Cover saved';

  @override
  String get editorCoverSuggestionsHint =>
      'Suggestions from MusicBrainz and Deezer. The cover is embedded in all songs on the album.';

  @override
  String get editorUploadImage => 'Upload image';

  @override
  String get editorNoCoverSuggestions => 'No suggestions found';

  @override
  String get editorNoCover => 'No cover';

  @override
  String editorAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count albums', one: '$count album');
    return '$_temp0';
  }

  @override
  String get editorLoadMore => 'Load more';

  @override
  String get editorAllDone => 'All done 🎉';

  @override
  String get commonOk => 'OK';

  @override
  String get editorDisc => 'CD';

  @override
  String get catalogEp => 'EP';

  @override
  String get adminImportCopyMode => 'copy';

  @override
  String get adminImportMoveMode => 'move';

  @override
  String get adminLibrary => 'Library';

  @override
  String commonSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count songs', one: '1 song');
    return '$_temp0';
  }

  @override
  String get commonArtists => 'Artists';

  @override
  String get adminUserRole => 'User';

  @override
  String get authServerAddressExample => 'music.example.com';

  @override
  String get spotifyTitle => 'Import from Spotify or Apple Music';

  @override
  String get spotifyLinkHeading => 'Import a playlist by link';

  @override
  String get spotifyLinksHint =>
      'Paste links to public Spotify or Apple Music playlists, one per line. Apple Music playlists are imported in full; Spotify without a connected account imports at most 100 songs per playlist.';

  @override
  String get spotifyLinkPlaceholder => 'https://open.spotify.com/playlist/… or https://music.apple.com/…';

  @override
  String get spotifyImport => 'Import';

  @override
  String get spotifyNotConfigured =>
      'Spotify isn\'t set up on this server yet. An admin can do that in the Admin Dashboard under “Server”.';

  @override
  String get spotifyConnectHint =>
      'Connect your Spotify account to bring your Liked Songs and your own playlists into Resonance.';

  @override
  String get spotifyConnect => 'Connect Spotify';

  @override
  String get spotifyWaiting => 'Log in to Spotify in the window that opened, then come back here.';

  @override
  String spotifyConnectedAs(String name) {
    return 'Connected as $name';
  }

  @override
  String get spotifyDisconnect => 'Disconnect';

  @override
  String get spotifyLikedSongs => 'Liked Songs';

  @override
  String spotifyLikedHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count songs', one: '1 song');
    return '$_temp0 · will be liked in Resonance';
  }

  @override
  String get spotifyPlaylistsHeading => 'Your playlists';

  @override
  String get spotifyPlaylistsNote => 'Spotify only shares playlists you own or collaborate on.';

  @override
  String spotifyPlaylistSubtitle(int count, String owner) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count songs', one: '1 song');
    return '$_temp0 · $owner';
  }

  @override
  String get spotifyAlreadyImported => 'already imported – will be synced';

  @override
  String get spotifyDownloadMissing => 'Download missing songs';

  @override
  String get spotifyDownloadMissingHint =>
      'Songs that aren\'t in the library yet are requested and added automatically once downloaded.';

  @override
  String get spotifyStart => 'Start import';

  @override
  String get spotifyNothingSelected => 'Select Liked Songs or at least one playlist.';

  @override
  String get spotifyStarted => 'Import started';

  @override
  String get spotifyHistory => 'Previous imports';

  @override
  String get spotifyStatusQueued => 'Queued';

  @override
  String get spotifyStatusRunning => 'Running';

  @override
  String get spotifyStatusDone => 'Done';

  @override
  String get spotifyStatusFailed => 'Failed';

  @override
  String spotifyImportCounts(int matched, int total, int missing, int requested) {
    return '$matched of $total found · $missing missing · $requested requested';
  }

  @override
  String get spotifyShowMissing => 'Show missing';

  @override
  String get spotifySyncMenu => 'Sync with Spotify';

  @override
  String get spotifySyncTitle => 'Sync with Spotify';

  @override
  String get spotifySyncConnectHint =>
      'Connect your Spotify account to export this playlist to Spotify or keep it in sync with a Spotify playlist.';

  @override
  String get spotifySyncReconnectHint =>
      'To export, Resonance also needs permission to change your Spotify playlists. Connect Spotify once more for that.';

  @override
  String get spotifySyncIntro =>
      'The songs of this playlist are looked up on Spotify and added to a playlist there. Songs Spotify doesn\'t have are skipped and listed below.';

  @override
  String get spotifySyncNew => 'Create a new Spotify playlist';

  @override
  String get spotifySyncExisting => 'Link an existing Spotify playlist';

  @override
  String get spotifySyncPick => 'Spotify playlist';

  @override
  String get spotifySyncTwoWay => 'Sync both ways';

  @override
  String get spotifySyncTwoWayHint =>
      'Every 10 minutes: changes on Spotify come to Resonance (missing songs get downloaded), changes in Resonance go to Spotify.';

  @override
  String get spotifySyncOneWayHint =>
      'Export only: songs from Resonance are sent to Spotify when you tap \"Sync now\".';

  @override
  String get spotifySyncExport => 'Export to Spotify';

  @override
  String get spotifySyncLink => 'Link';

  @override
  String get spotifySyncFriendsHint =>
      'Tip: invite friends to the playlist as collaborators in Spotify. With two-way sync their songs show up here too.';

  @override
  String get spotifySyncLinked => 'Linked with Spotify';

  @override
  String get spotifySyncRunning => 'Syncing …';

  @override
  String spotifySyncFailed(String error) {
    return 'Error: $error';
  }

  @override
  String spotifySyncLast(String time) {
    return 'Last synced: $time';
  }

  @override
  String get spotifySyncNow => 'Sync now';

  @override
  String get spotifySyncOpen => 'Open in Spotify';

  @override
  String get spotifySyncUnlink => 'Unlink';

  @override
  String get spotifySyncUnlinkConfirm => 'The playlist will no longer be synced. The playlist on Spotify stays.';

  @override
  String spotifySyncUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs not found on Spotify',
      one: '1 song not found on Spotify',
    );
    return '$_temp0';
  }

  @override
  String get spotifyMissingTitle => 'Not in the library';

  @override
  String get adminSpotifyGroup => 'Spotify import';

  @override
  String get adminSpotifyClientId => 'Spotify Client ID';

  @override
  String get adminSpotifyClientSecret => 'Spotify Client Secret';

  @override
  String adminSpotifyHint(String uri) {
    return 'developer.spotify.com/dashboard → create an app, Redirect URI: $uri';
  }

  @override
  String get audiobooksViewLibrary => 'Library';

  @override
  String get audiobooksViewSeries => 'Series';

  @override
  String get audiobooksViewAuthors => 'Authors';

  @override
  String get audiobooksViewNarrators => 'Narrators';

  @override
  String audiobooksBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count audiobooks', one: '1 audiobook');
    return '$_temp0';
  }

  @override
  String get albumFindMissing => 'Find missing songs';

  @override
  String get adminDeleteSong => 'Delete song';

  @override
  String get adminDeleteAlbum => 'Delete album';

  @override
  String adminDeleteSongConfirm(String title) {
    return '\"$title\" will be permanently deleted from the server, including the file.';
  }

  @override
  String adminDeleteAlbumConfirm(String title) {
    return 'The album \"$title\" and all its songs will be permanently deleted from the server, including the files.';
  }

  @override
  String get adminDeleted => 'Deleted';

  @override
  String get libraryShareWithUsers => 'Share with specific users';

  @override
  String get libraryNoOtherUsers => 'There are no other users yet.';

  @override
  String librarySharedWith(String names) {
    return 'Shared with $names';
  }

  @override
  String albumMissingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs not in your library',
      one: '1 song not in your library',
    );
    return '$_temp0';
  }

  @override
  String get radioStartSong => 'Go to song radio';

  @override
  String get radioStartAlbum => 'Go to album radio';

  @override
  String get radioKind => 'Radio';

  @override
  String get radioKeep => 'Keep as playlist';

  @override
  String radioDownloading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missing songs are being downloaded and will then be added to the radio',
      one: '1 missing song is being downloaded and will then be added to the radio',
    );
    return '$_temp0';
  }

  @override
  String get libraryRadios => 'Radios';

  @override
  String get adminRadioMaxDownloads => 'Max. downloads per radio start';

  @override
  String get adminRadioPlaylistRetention => 'Keep radios (days since last use, 0 = forever)';

  @override
  String get offlineBanner => 'Offline – downloads only';

  @override
  String get offlineEmptyHint =>
      'Download albums, playlists, podcast episodes, audiobooks and ebooks to use them offline.';

  @override
  String get offlineDownloaded => 'Downloaded';

  @override
  String get offlineDownload => 'Download';

  @override
  String offlineNotificationRunning(String numFinished, String numTotal) {
    return 'Resonance: $numFinished of $numTotal songs downloaded';
  }

  @override
  String get offlineNotificationComplete => 'Resonance: Downloads complete';

  @override
  String get offlineRemoveTitle => 'Remove download?';

  @override
  String get storageExport => 'Export';

  @override
  String get storageExportAll => 'Export all';

  @override
  String get storageExportUnsupported => 'Exporting needs Android 10 or newer';

  @override
  String storageExportProgress(int done, int total) {
    return '$done of $total songs';
  }

  @override
  String storageExported(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count songs to $folder',
      one: 'Exported 1 song to $folder',
      zero: 'Everything was already exported',
    );
    return '$_temp0';
  }

  @override
  String get coverCropTitle => 'Choose the crop';

  @override
  String get coverCropHint => 'Drag the image and zoom with two fingers or the mouse wheel';

  @override
  String get storageOpenFolder => 'Open folder';

  @override
  String get storageCollections => 'Downloaded collections';

  @override
  String get storageFiles => 'Files by size';

  @override
  String get offlineQuality => 'Download quality';

  @override
  String get offlineQualityNormal => 'Normal (Opus 160 kbit/s)';

  @override
  String get offlineQualityHigh => 'High (Opus 256 kbit/s)';

  @override
  String get offlineQualityOriginal => 'Original (lossless, uses a lot of storage)';

  @override
  String get offlineWifiOnly => 'Download over Wi-Fi only';

  @override
  String get offlineStorage => 'Storage used';

  @override
  String offlineStorageUsed(String size, int count) {
    return '$size • $count songs';
  }

  @override
  String offlineMegabytes(String value) {
    return '$value MB';
  }

  @override
  String offlineGigabytes(String value) {
    return '$value GB';
  }

  @override
  String offlineDownloading(int count) {
    return '$count songs downloading';
  }

  @override
  String offlineProgress(int done, int total) {
    return '$done of $total downloaded';
  }

  @override
  String get offlineClearAll => 'Delete all downloads';

  @override
  String get offlineClearConfirm => 'Delete all downloads?';

  @override
  String get mixKind => 'Mix';

  @override
  String get mixSave => 'Save as playlist';

  @override
  String get homeMadeForYou => 'Made for you';

  @override
  String get homeCharts => 'Charts';

  @override
  String get homeGenreMixes => 'Your genres';

  @override
  String get homeDecadeMixes => 'Your decades';

  @override
  String get lyricsTitle => 'Lyrics';

  @override
  String get lyricsExpand => 'Expand';

  @override
  String get lyricsUnsynced => 'These lyrics aren\'t synced.';

  @override
  String get lyricsInstrumental => 'Instrumental';

  @override
  String get lyricsNotFound => 'No lyrics available for this song.';

  @override
  String get lyricsAttribution => 'Lyrics from LRCLIB';

  @override
  String get adminLyricsOnline => 'Look up lyrics online (LRCLIB)';

  @override
  String get adminLyricsOnlineHint => 'Songs without their own lyrics get synced lyrics from lrclib.net.';

  @override
  String get redownloadMenu => 'Wrong version? Download again';

  @override
  String get redownloadTitle => 'Download again';

  @override
  String get redownloadExplanation =>
      'The song is searched again and replaced. The source used before is skipped. Likes and playlists are kept.';

  @override
  String get redownloadYoutubeLabel => 'YouTube, SoundCloud or Bandcamp link (optional)';

  @override
  String get redownloadYoutubeHint => 'If you want a specific version';

  @override
  String get redownloadStarted => 'Re-download started';

  @override
  String get redownloadAwaitingApproval => 'Request sent – an admin has to approve it';

  @override
  String get downloadsRedownload => 'Re-download';

  @override
  String get audioBrowseHome => 'Home';

  @override
  String get settingsCrossfade => 'Crossfade';

  @override
  String get settingsCrossfadeOff => 'Off';

  @override
  String settingsCrossfadeSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get settingsVisualizer => 'Visualizer';

  @override
  String get settingsVisualizerHint => 'Shows animated frequency bars in the player while music plays.';

  @override
  String get settingsVisualizerStyle => 'Visualizer style';

  @override
  String get settingsVisualizerReflection => 'Reflection';

  @override
  String get settingsVisualizerReflectionHint => 'Mirror the cover and visualizer';

  @override
  String get visualizerPeaksOn => 'Peak dots on';

  @override
  String get visualizerPeaksOff => 'Peak dots off';

  @override
  String get settingsCoverflow => 'Coverflow';

  @override
  String get settingsCoverflowHint => 'Swipe through the queue\'s covers side by side';

  @override
  String get settingsCoverflowFlip => 'Flip covers';

  @override
  String get settingsCoverflowFlipHint => 'Tap the cover to see the album\'s songs';

  @override
  String get visualizerThemeAuto => 'Automatic';

  @override
  String get visualizerThemeRetro => 'Retro hi-fi';

  @override
  String get visualizerThemeSynthwave => 'Synthwave';

  @override
  String get visualizerThemeNeon => 'Neon';

  @override
  String get visualizerThemeOcean => 'Ocean';

  @override
  String get visualizerThemeSunset => 'Sunset';

  @override
  String get visualizerThemeFire => 'Fire';

  @override
  String get visualizerThemeMatrix => 'Matrix';

  @override
  String get visualizerThemeAurora => 'Aurora';

  @override
  String get visualizerThemeMono => 'Monochrome';

  @override
  String get visualizerThemeRainbow => 'Rainbow';

  @override
  String get settingsAutomix => 'AutoMix';

  @override
  String get settingsAutomixHint =>
      'DJ-style transitions: the next song comes in on the beat with its tempo briefly matched. Songs without an analysis (e.g. offline) simply crossfade. The crossfade slider sets the minimum length of the transitions.';

  @override
  String get settingsVocalSwap => 'Vocal swap';

  @override
  String get settingsVocalSwapHint =>
      'The next song comes in without its vocals, its beat running under the current song\'s singing (PC only, needs the server\'s song analysis)';

  @override
  String get settingsKeyShift => 'Match keys';

  @override
  String get settingsKeyShiftHint => 'AutoMix shifts the next song by up to two semitones when the keys clash – the whole song then sounds higher or lower than the original';

  @override
  String get equalizerTitle => 'Equalizer';

  @override
  String get equalizerOff => 'Off';

  @override
  String get equalizerPresetFlat => 'Flat';

  @override
  String get equalizerPresetBass => 'Bass boost';

  @override
  String get equalizerPresetTreble => 'Treble';

  @override
  String get equalizerPresetVocal => 'Vocal';

  @override
  String get equalizerPresetRock => 'Rock';

  @override
  String get equalizerPresetPop => 'Pop';

  @override
  String get equalizerPresetHiphop => 'Hip-Hop';

  @override
  String get equalizerPresetElectronic => 'Electronic';

  @override
  String get equalizerPresetAcoustic => 'Acoustic';

  @override
  String get equalizerPresetLoudness => 'Loudness';

  @override
  String get equalizerPresetCustom => 'Custom';

  @override
  String get equalizerPresets => 'Presets';

  @override
  String get equalizerReset => 'Reset';

  @override
  String equalizerDecibels(String value) {
    return '$value dB';
  }

  @override
  String equalizerBandLabel(int frequency) {
    return '$frequency Hz';
  }

  @override
  String equalizerFrequencyK(int frequency) {
    return '${frequency}k';
  }

  @override
  String get settingsSubsonicTitle => 'Other music apps (Subsonic)';

  @override
  String get settingsSubsonicSubtitle => 'Use Resonance in apps like Symfonium or Feishin';

  @override
  String settingsSubsonicConnection(String serverUrl, String username) {
    return 'Server: $serverUrl\nUsername: $username';
  }

  @override
  String get settingsSubsonicConfigured => 'An app password is set up.';

  @override
  String get settingsSubsonicRegenerate => 'Generate new password';

  @override
  String get settingsSubsonicRemove => 'Remove';

  @override
  String get settingsSubsonicHint =>
      'Generate an app password and enter it as the password in the other app. Your normal password does not work there.';

  @override
  String get settingsSubsonicGenerate => 'Generate password';

  @override
  String get settingsSubsonicCopied => 'Copied';

  @override
  String get settingsSubsonicShownOnce => 'Shown only now.';

  @override
  String get adminIntegrations => 'Integrations';

  @override
  String get adminDiscordClientId => 'Discord application ID';

  @override
  String get adminDiscordClientIdHint =>
      'For the desktop app\'s Discord status. Create an application at discord.com/developers and enter its application ID here.';

  @override
  String get settingsDiscordPresence => 'Show Discord status';

  @override
  String get settingsDiscordPresenceHint => 'Shows what you\'re listening to on Discord';

  @override
  String get settingsDiscordNotConfigured => 'Not set up by the admin yet';

  @override
  String discordPresenceArtist(String artist) {
    return 'by $artist';
  }

  @override
  String get playlistRemoveCover => 'Remove cover';

  @override
  String get playlistCoverRemoved => 'Cover removed';

  @override
  String get editorLooksGood => 'Looks good';

  @override
  String get discoverWeekly => 'Discover Weekly';

  @override
  String get adminMixes => 'Mixes';

  @override
  String get adminDiscoverWeeklyHint => '30 new songs per user every Monday, missing ones are downloaded';

  @override
  String get adminDiscoverDownloads => 'Downloads per week and user';

  @override
  String get adminDiscoverSize => 'Songs in Discover Weekly (10–100)';

  @override
  String get adminChartsEnabled => 'Chart playlists';

  @override
  String get adminChartsEnabledHint => 'Top 100 Germany and Global, updated daily';

  @override
  String get adminChartsDownloads => 'Missing chart songs downloaded per day';

  @override
  String get adminEditorialEnabled => 'Editorial playlists (Apple Music)';

  @override
  String get adminEditorialDownloads => 'Songs downloaded per playlist';

  @override
  String get adminEditorialYears => 'Yearly hits';

  @override
  String get worldRadioTitle => 'World radio';

  @override
  String get worldRadioSearchHint => 'Search stations';

  @override
  String get worldRadioSearch => 'Search';

  @override
  String worldRadioPopularInCountry(String country) {
    return 'Popular in $country';
  }

  @override
  String get worldRadioGenres => 'Genres';

  @override
  String get worldRadioAllGenres => 'All genres';

  @override
  String get worldRadioFavoriteHint => 'Star stations in the player to add favourites';

  @override
  String get worldRadioFavorites => 'Favourites';

  @override
  String worldRadioStationCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count stations', one: '1 station');
    return '$_temp0';
  }

  @override
  String get worldRadioYourStations => 'Your radio stations';

  @override
  String get worldRadioUnavailable => 'Station unavailable';

  @override
  String get worldRadioLive => 'LIVE';

  @override
  String get worldRadioCountry => 'Country';

  @override
  String get worldRadioSearchCountry => 'Search countries';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamIntro => 'Listen together: friends join with a code and everyone can add songs.';

  @override
  String get jamStart => 'Start a Jam';

  @override
  String get jamJoin => 'Join a Jam';

  @override
  String get jamCodeHint => '6-digit code';

  @override
  String get jamConnecting => 'Connecting …';

  @override
  String get jamCopyLink => 'Copy link';

  @override
  String get jamLinkCopied => 'Link copied';

  @override
  String get jamMembers => 'Participants';

  @override
  String get jamHost => 'Host';

  @override
  String get jamKick => 'Remove';

  @override
  String get jamMembersControl => 'Members can control playback';

  @override
  String get jamListenHere => 'Listen on this device';

  @override
  String get jamListenHereHint => 'Off: control only, the music plays on another device';

  @override
  String get jamLeave => 'Leave Jam';

  @override
  String get jamEnd => 'End Jam';

  @override
  String get jamEndConfirm => 'End the Jam for everyone?';

  @override
  String get jamEnded => 'The Jam has ended';

  @override
  String get jamNotConnected => 'Not connected to the Jam';

  @override
  String get jamQueue => 'Jam queue';

  @override
  String jamAddedBy(String name) {
    return 'Added by $name';
  }

  @override
  String jamChip(int count) {
    return 'Jam · $count';
  }

  @override
  String get adminDuplicates => 'Duplicates';

  @override
  String get adminDuplicatesDifferentAlbums => 'Different albums · same recording';

  @override
  String get adminDuplicatesPending => 'Still being checked';

  @override
  String get adminDuplicatesEmpty => 'No duplicates found';

  @override
  String adminDuplicatesHint(int groups) {
    return '$groups songs have multiple files. The best file for each song will be kept and the others deleted. Likes, playlists and listening history will be transferred to the kept file. Playlists, likes and history then point to the kept file – nothing needs to be re-added. For different albums the song disappears from the other album.';
  }

  @override
  String adminDuplicatesGroupTitle(String artist, String album, String title) {
    return '$artist – $album: $title';
  }

  @override
  String adminDuplicatesFile(String marker, String codec, int bitrate, String size) {
    return '$marker $codec · $bitrate kbps · $size';
  }

  @override
  String adminDuplicatesDelete(int n) {
    return 'Delete $n duplicates';
  }

  @override
  String get adminDuplicatesConfirmTitle => 'Delete duplicates?';

  @override
  String get adminDuplicatesConfirmHint => 'The lower-quality files will be permanently deleted.';

  @override
  String adminDuplicatesMerged(int deleted, String freed) {
    return '$deleted files deleted, $freed freed';
  }

  @override
  String get updateRestarting => 'Installing, Resonance restarts in a moment …';

  @override
  String get shortcutsTitle => 'Keyboard shortcuts';

  @override
  String get shortcutPlayPause => 'Play / pause';

  @override
  String get shortcutNextPrevious => 'Next / previous song';

  @override
  String get shortcutSeek => 'Forward / back 10 seconds';

  @override
  String get shortcutVolume => 'Volume up / down';

  @override
  String get shortcutShuffle => 'Shuffle';

  @override
  String get shortcutRepeat => 'Repeat';

  @override
  String get shortcutSearch => 'Search';

  @override
  String get navBooks => 'Books';

  @override
  String get booksEbooks => 'Ebooks';

  @override
  String get booksSearchHint => 'Search books, authors or series';

  @override
  String get booksRecent => 'Recently added';

  @override
  String get booksAuthors => 'Authors';

  @override
  String get booksSeries => 'Series';

  @override
  String get booksRequests => 'Requests';

  @override
  String get booksImport => 'Import';

  @override
  String get booksAll => 'All books';

  @override
  String get booksEmptyLibrary => 'No books yet. Search for a book to request it, or import your own files.';

  @override
  String get booksInLibrary => 'In your library';

  @override
  String get booksFromCatalog => 'Available to request';

  @override
  String get booksNoResults => 'Nothing found';

  @override
  String get booksRequestFree => 'Not listed? Request it yourself';

  @override
  String get booksRequest => 'Request';

  @override
  String booksRequested(String title) {
    return 'Requested: $title';
  }

  @override
  String get booksRequestsDisabled => 'Automatic downloads are turned off on this server. You can still import books.';

  @override
  String get booksLanguage => 'Language';

  @override
  String get booksLanguageDe => 'German';

  @override
  String get booksLanguageEn => 'English';

  @override
  String get booksLanguageAny => 'Any';

  @override
  String booksVolume(String number) {
    return 'Book $number';
  }

  @override
  String get booksDownload => 'Download';

  @override
  String get booksEdit => 'Edit';

  @override
  String get booksDelete => 'Delete';

  @override
  String booksDeleteConfirm(String title) {
    return 'Delete “$title” from the library?';
  }

  @override
  String get booksTitle => 'Title';

  @override
  String get booksAuthorsField => 'Authors (comma separated)';

  @override
  String get booksSeriesField => 'Series';

  @override
  String get booksSeriesIndex => 'Volume';

  @override
  String get booksStatusPending => 'Waiting for approval';

  @override
  String get booksStatusQueued => 'Queued';

  @override
  String get booksStatusSearching => 'Searching';

  @override
  String get booksStatusDownloading => 'Downloading';

  @override
  String get booksStatusImporting => 'Importing';

  @override
  String get booksStatusDone => 'Done';

  @override
  String get booksStatusFailed => 'Failed';

  @override
  String get booksStatusCancelled => 'Cancelled';

  @override
  String get booksStatusRejected => 'Rejected';

  @override
  String get booksCancelRequest => 'Cancel request';

  @override
  String get booksRemoveRequest => 'Remove';

  @override
  String get booksApprove => 'Approve';

  @override
  String get booksReject => 'Reject';

  @override
  String get booksNoRequests => 'No requests';

  @override
  String get booksAllUsers => 'All users';

  @override
  String get booksImportFiles => 'Upload files';

  @override
  String get booksImportFilesHint => 'EPUB, AZW3, MOBI or PDF';

  @override
  String get booksImportUrl => 'Import from link';

  @override
  String get booksImportUrlLabel => 'Link to the book file';

  @override
  String get booksImporting => 'Importing …';

  @override
  String booksImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books imported',
      one: '1 book imported',
    );
    return '$_temp0';
  }

  @override
  String booksImportFailed(String name, String error) {
    return '$name: $error';
  }

  @override
  String get adminBooksEnable => 'Enable ebooks';

  @override
  String get adminBooksEnableHint =>
      'Books tab, OPDS catalog (/opds) and KOReader sync (/kosync). Sign in there with the app password.';

  @override
  String get adminBooksLanguage => 'Default request language';

  @override
  String get adminBooksGoogleKey => 'Google Books API key';

  @override
  String get adminBooksGoogleKeyHint => 'Optional – without a key only Audible is searched';

  @override
  String get adminBooksDailyLimit => 'Books per user and day (0 = unlimited)';

  @override
  String get adminBooksTorrentsHint => 'Automatic downloads use the torrent settings under Downloads.';

  @override
  String get editorSourceApple => 'Apple Music';

  @override
  String get editorSourceDiscogs => 'Discogs';

  @override
  String get editorSourceDeezer => 'Deezer';

  @override
  String get editorSourceMusicBrainz => 'MusicBrainz';

  @override
  String get adminDiscogsToken => 'Discogs token';

  @override
  String get adminDiscogsHint => 'Free at discogs.com → Settings → Developers';

  @override
  String get adminLastfmKey => 'Last.fm API key';

  @override
  String get adminLastfmHint => 'Free at last.fm/api';

  @override
  String get adminFanartKey => 'fanart.tv API key';

  @override
  String get adminFillGenres => 'Fill missing genres (Last.fm)';

  @override
  String get artistAbout => 'About';

  @override
  String get artistShowMore => 'Show more';

  @override
  String get artistShowLess => 'Show less';

  @override
  String get adminDuplicatesSelectAll => 'Select all';

  @override
  String get adminDuplicatesSelectNone => 'Select none';

  @override
  String adminDuplicatesProgress(int done, int total) {
    return 'Deleting … $done of $total';
  }

  @override
  String get settingsTvMode => 'TV/controller mode';

  @override
  String get settingsTvModeHint => 'Large interface for remote controls and game controllers';

  @override
  String get tvPlay => 'Play';

  @override
  String get tvPause => 'Pause';

  @override
  String get tvBack => 'Back';

  @override
  String get tvPopularStations => 'Popular stations';

  @override
  String get changelogTitle => 'What\'s new';

  @override
  String get changelogInstalled => 'Installed';

  @override
  String changelogNewVersion(String version) {
    return 'New in version $version';
  }

  @override
  String get changelogAll => 'All updates';

  @override
  String get navPodcasts => 'Podcasts';

  @override
  String get podcastsContinue => 'Continue listening';

  @override
  String get podcastsNewEpisodes => 'New episodes';

  @override
  String get podcastsYourPodcasts => 'Your podcasts';

  @override
  String get podcastsCategories => 'Categories';

  @override
  String get podcastsSubscriptions => 'Subscriptions';

  @override
  String get podcastsSearch => 'Search podcasts';

  @override
  String get podcastsSearchHint => 'Search podcasts';

  @override
  String get podcastsAddRss => 'Add by RSS link';

  @override
  String get podcastsAddFeedByUrl => 'Add RSS feed';

  @override
  String get podcastsNoResults =>
      'Nothing found. Spotify-exclusive podcasts have no public feed – if you know the RSS address, add it at the top right.';

  @override
  String get podcastsRssUrl => 'RSS URL';

  @override
  String get podcastsEmpty => 'No subscriptions yet. Search for a podcast or add an RSS link.';

  @override
  String get podcastsSubscribe => 'Subscribe';

  @override
  String get podcastsSubscribed => 'Subscribed';

  @override
  String get podcastsUnsubscribe => 'Unsubscribe';

  @override
  String get podcastsDescription => 'Description';

  @override
  String get podcastsEpisodes => 'Episodes';

  @override
  String get podcastsEpisode => 'Podcast episode';

  @override
  String get podcastsCompleted => 'Completed';

  @override
  String get podcastsLoadMore => 'Load more episodes';

  @override
  String get podcastsOpen => 'Open podcast';

  @override
  String get podcastsSkipBack => 'Back 15 seconds';

  @override
  String get podcastsMarkPlayed => 'Mark as played';

  @override
  String get podcastsMarkUnplayed => 'Mark as unplayed';

  @override
  String get podcastsMarkAllPlayed => 'Mark all as played';

  @override
  String get podcastsMarkAllUnplayed => 'Mark all as unplayed';

  @override
  String get podcastsSort => 'Order';

  @override
  String get podcastsNewestFirst => 'Newest first';

  @override
  String get podcastsOldestFirst => 'Oldest first';

  @override
  String podcastsEpisodeStats(int count, int played) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count episodes', one: '1 episode');
    return '$_temp0 · $played played';
  }

  @override
  String podcastsTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get podcastsPlayed => 'Played';

  @override
  String get podcastsShowNotes => 'Show notes';

  @override
  String get podcastsPlayEpisode => 'Play episode';

  @override
  String get podcastsMore => 'More';

  @override
  String get podcastsLess => 'Less';

  @override
  String get podcastsPlayFirstUnplayed => 'Play the next unplayed episode';

  @override
  String get podcastsRemoveAds => 'Remove inserted ads';

  @override
  String get podcastsRemoveAdsHint =>
      'New episodes are ready without spliced-in ad spots shortly after release. Ads read by the hosts stay in.';

  @override
  String podcastsAdsRemoved(String time) {
    return '$time of ads removed';
  }

  @override
  String get playerPodcastLoadError => 'The podcast episode couldn\'t be loaded. Please try again.';

  @override
  String get connectPlayOn => 'Play on…';

  @override
  String get connectThisDevice => 'This device';

  @override
  String get connectDeviceName => 'Device name';

  @override
  String connectPlayingOn(String device) {
    return 'Playing on $device';
  }

  @override
  String connectAway(String device) {
    return '$device is not connected · Play continues here';
  }

  @override
  String get connectOffline => 'Not connected';

  @override
  String get connectJamHint => 'Device transfer is unavailable during a Jam.';

  @override
  String get connectMusicOnly => 'Only music tracks can be transferred. Books, podcasts and radio stay on this device.';

  @override
  String get connectUnavailable => 'Device unavailable. Check your connection.';

  @override
  String get tvFavoriteRemove => 'Remove from favourites';

  @override
  String get tvFavoriteAdd => 'Add to favourites';

  @override
  String get tvAmbientOn => 'Ambient mode on';

  @override
  String get tvAmbientOff => 'Ambient mode off';

  @override
  String get settingsTvAmbient => 'Ambient mode';

  @override
  String get settingsTvAmbientHint => 'Show only the cover and title when idle';

  @override
  String get ringtoneMenu => 'Use as ringtone';

  @override
  String get ringtoneLength => 'Length';

  @override
  String ringtoneSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String ringtoneRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get ringtoneSuggested => 'Suggested: the song\'s fullest part, usually the chorus';

  @override
  String coverflowBackSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count songs', one: '1 song');
    return '$_temp0';
  }

  @override
  String get ringtoneBackToSuggestion => 'Back to the suggestion';

  @override
  String get ringtonePreview => 'Preview';

  @override
  String get ringtoneStopPreview => 'Stop preview';

  @override
  String get ringtoneTypeRingtone => 'Ringtone';

  @override
  String get ringtoneTypeNotification => 'Notification';

  @override
  String get ringtoneTypeAlarm => 'Alarm';

  @override
  String get ringtoneApply => 'Set';

  @override
  String ringtoneDone(String title, String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'notification': 'notification sound',
      'alarm': 'alarm sound',
      'other': 'ringtone',
    });
    return '“$title” is now your $_temp0';
  }

  @override
  String ringtoneSaved(String title) {
    return 'Saved – pick “$title” in the sound settings';
  }

  @override
  String get ringtonePermissionTitle => 'Permission needed';

  @override
  String get ringtonePermissionText =>
      'To set the sound directly, allow Resonance to “modify system settings”. The song is already saved – without the permission you pick it yourself in the sound settings.';

  @override
  String get ringtonePermissionAllow => 'Allow';

  @override
  String get ringtonePermissionManual => 'Pick it myself';

  @override
  String get ringtoneUnsupported => 'Ringtones from songs need Android 10 or newer';

  @override
  String get mediaDownload => 'Download to device';

  @override
  String get mediaDownloaded => 'On this device';

  @override
  String get mediaDownloading => 'Downloading to device …';

  @override
  String get mediaRemoveTitle => 'Remove from device?';

  @override
  String get mediaRemove => 'Remove from device';

  @override
  String get mediaFailed => 'Download failed – tap to retry';

  @override
  String get mediaSection => 'Podcasts, audiobooks & ebooks';

  @override
  String get mediaSectionEpisodes => 'Downloaded episodes';

  @override
  String get mediaOfflineEmpty =>
      'No episodes, audiobooks or ebooks on this device. Download them with the download icon while you are online.';

  @override
  String get mediaOpen => 'Open';

  @override
  String get mediaOpenFailed => 'No app found to open this file';

  @override
  String get mediaStorage => 'Podcasts, audiobooks & ebooks';

  @override
  String mediaStorageUsed(String size, int count) {
    return '$size • $count on this device';
  }

  @override
  String get mediaKindEpisode => 'Podcast episode';

  @override
  String get mediaKindEbook => 'Ebook';

  @override
  String get settingsTransitionEditor => 'Transition editor (beta)';

  @override
  String get settingsTransitionEditorHint =>
      'Playlists get a mix button that shows the transitions between their songs, with BPM and key, and lets you shape them yourself.';

  @override
  String get transitionAuto => 'Automatic';

  @override
  String get transitionCrossfade => 'Crossfade';

  @override
  String get transitionFadeIn => 'Fade in';

  @override
  String get transitionFadeOut => 'Fade out';

  @override
  String get transitionFilter => 'Filter';

  @override
  String transitionBars(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count bars', one: '1 bar');
    return '$_temp0';
  }

  @override
  String get transitionPresets => 'Presets';

  @override
  String get transitionVolume => 'Volume';

  @override
  String get transitionEq => 'EQ';

  @override
  String get transitionVolumeAuto => 'Suited to the songs';

  @override
  String get transitionVolumeCrossfade => 'Even crossfade';

  @override
  String get transitionVolumeFadeIn => 'Fade in, then cut out';

  @override
  String get transitionVolumeFadeOut => 'Fade out, then fade in';

  @override
  String get transitionVolumeFilter => 'Filter out, quick fade in';

  @override
  String get transitionEqSwap => 'Bass swap halfway';

  @override
  String get transitionEqSweep => 'Filter away from the bass up';

  @override
  String get transitionReset => 'Reset to automatic';

  @override
  String get transitionPreview => 'Preview';

  @override
  String get transitionStopPreview => 'Stop preview';

  @override
  String get transitionNeedsAutomix => 'Transitions and previews need AutoMix. Turn it on in the settings.';

  @override
  String get transitionSaved => 'Transition saved';

  @override
  String get transitionNotAnalyzed => 'These songs are not analyzed yet. Try again in a moment.';

  @override
  String get transitionDragHint => 'Drag a lane to move the start or the entry point.';

  @override
  String get transitionViewOnly => 'Only people who can edit the playlist can change transitions.';

  @override
  String get transitionEdit => 'Edit transition';

  @override
  String get transitionMixOn => 'Mix';

  @override
  String get transitionMixOff => 'Stop mixing';

  @override
  String get playlistRecommended => 'Recommended songs';

  @override
  String get playlistRecommendedFromPlaylist => 'Based on the songs in this playlist';

  @override
  String get playlistRecommendedFromLikes => 'Based on your liked songs';

  @override
  String get playlistNoRecommendations => 'No recommendations right now.';

  @override
  String get playlistRefreshRecommendations => 'New suggestions';

  @override
  String get playlistSearchSongs => 'Search for songs';

  @override
  String get playlistFindSomething => 'Let\'s find something for your playlist';

  @override
  String get playlistSearchHint => 'Search songs';

  @override
  String get playlistSearchEmpty => 'Search for songs to add them to the playlist straight away.';

  @override
  String playlistSearchNothing(Object query) {
    return 'Nothing found for “$query”';
  }

  @override
  String get playlistAddSong => 'Add to playlist';

  @override
  String get playlistAdded => 'Added';

  @override
  String playlistAddedTo(Object title) {
    return 'Added “$title”';
  }

  @override
  String get transitionCustom => 'Custom';

  @override
  String get transitionNone => 'None';

  @override
  String get transitionFilterLane => 'Filter';

  @override
  String get transitionEffects => 'Effects';

  @override
  String get transitionLooping => 'Looping';

  @override
  String get transitionBeatmatching => 'Beatmatching';

  @override
  String get transitionBeatmatchingHint => 'Matches the songs\' tempos so their beats line up.';

  @override
  String get transitionEchoOut => 'Echo out';

  @override
  String get transitionLoopOut => 'Loop out';

  @override
  String get transitionCut => 'Hard cut';

  @override
  String get volumeSmooth => 'Seamless crossfade';

  @override
  String get volumeOverlap => 'Overlap';

  @override
  String get volumeFadeInOut => 'Fade in and out';

  @override
  String get volumeHardInFadeOut => 'Cut in, fade out';

  @override
  String get volumeFadeInHardOut => 'Fade in, cut out';

  @override
  String get volumeCenterCut => 'Center cut';

  @override
  String get volumeCrossfade => 'Crossfade';

  @override
  String get volumeFadeInQuickOut => 'Fade in, quick fade out';

  @override
  String get volumeFadeInCutBar => 'Fade in, cut out with 1 bar left';

  @override
  String get volumeOverlapCutBar => 'Overlap, cut out with 1 bar left';

  @override
  String get eqSwapMiddle => 'Bass swap in the middle';

  @override
  String get eqSwapEnd => 'Bass swap at the end';

  @override
  String get eqSwapStart => 'Bass swap at the start';

  @override
  String get eqThreeBand => 'Three-band crossfade';

  @override
  String get eqQuickBassCut => 'Quick bass cut';

  @override
  String get eqLongBassCut => 'Long bass cut';

  @override
  String get eqBassFadeOut => 'Bass fade-out';

  @override
  String get filterLowpassOut => 'Low-pass on the outgoing song';

  @override
  String get filterLowpassIn => 'Low-pass on the incoming song';

  @override
  String get filterLowpassInOut => 'Low-pass in and out';

  @override
  String get filterLowpassInHighpassOut => 'Low-pass in, high-pass out';

  @override
  String get filterHighpassOut => 'High-pass on the outgoing song';

  @override
  String get filterHighpassIn => 'High-pass on the incoming song';

  @override
  String get filterHighpassInOut => 'High-pass in and out';

  @override
  String get filterHighpassInLowpassOut => 'High-pass in, low-pass out';

  @override
  String get filterHighpassHalf => 'Gentle high-pass on the outgoing song';

  @override
  String get filterNoiseEnd => 'Noise riser at the end';

  @override
  String get effectFlanger => 'Flanger (PC only)';

  @override
  String get effectPhaser => 'Phaser (PC only)';

  @override
  String get effectGate => 'Gate on eighth notes (PC only)';

  @override
  String get effectBeatRoll => 'Beat roll: 1 → 1/16 beat (PC only)';

  @override
  String get transitionZoomIn => 'Zoom in';

  @override
  String get transitionZoomOut => 'Zoom out';

  @override
  String get transitionDraw => 'Draw curves';

  @override
  String get transitionBass => 'Bass';

  @override
  String get transitionDrawn => 'Drawn by hand';

  @override
  String get transitionDrawReset => 'Reset curve';

  @override
  String get transitionDrawHint =>
      'Click to add a point, drag to move it, right-click or long-press to remove it. The current song on top, the next one below.';

  @override
  String get effectBrake => 'Turntable brake (PC only)';

  @override
  String get effectReverbMiddle => 'Reverb, song ends in the middle';

  @override
  String get effectReverbCut => 'Reverb, cut at the end';

  @override
  String get effectReverbTail => 'Reverb rings out until the end';

  @override
  String effectEchoCut(Object beat) {
    return 'Echo every $beat beat, cut at the end';
  }

  @override
  String effectEchoTail(Object beat) {
    return 'Echo every $beat beat rings out until the end';
  }

  @override
  String effectDelayCut(Object beat) {
    return 'Delay of $beat beat, cut at the end';
  }

  @override
  String loopBeats(int count) {
    return '$count-beat loop';
  }

  @override
  String get transitionFxUnavailable =>
      'Effects, filters and loops don\'t work on this device; you only hear the volumes.';

  @override
  String get creditsTitle => 'Credits';

  @override
  String get creditsShow => 'Show credits';

  @override
  String get creditsShowAll => 'Show all';

  @override
  String get creditsPerformers => 'Performed by';

  @override
  String get creditsWriters => 'Written by';

  @override
  String get creditsProducers => 'Produced by';

  @override
  String get creditsEngineers => 'Engineering';

  @override
  String get creditsLabel => 'Label';

  @override
  String creditsSources(Object sources) {
    return 'Source: $sources';
  }

  @override
  String get creditsSourceTags => 'File tags';

  @override
  String get creditRoleArtist => 'Artist';

  @override
  String get creditRoleFeatured => 'Featured artist';

  @override
  String get creditRoleComposer => 'Composer';

  @override
  String get creditRoleLyricist => 'Lyricist';

  @override
  String get creditRoleWriter => 'Songwriter';

  @override
  String get creditRoleArranger => 'Arranger';

  @override
  String get creditRoleProducer => 'Producer';

  @override
  String get creditRoleCoProducer => 'Co-producer';

  @override
  String get creditRoleExecutiveProducer => 'Executive producer';

  @override
  String get creditRoleMix => 'Mixing';

  @override
  String get creditRoleMastering => 'Mastering';

  @override
  String get creditRoleRecording => 'Recording';

  @override
  String get creditRoleEngineer => 'Engineer';

  @override
  String get creditRoleProgramming => 'Programming';

  @override
  String get creditRoleVocals => 'Vocals';

  @override
  String get creditRoleBackgroundVocals => 'Background vocals';

  @override
  String get creditRolePerformer => 'Musician';

  @override
  String get libraryCreate => 'Create';

  @override
  String get blendCreate => 'Blend';

  @override
  String get blendKind => 'Blend';

  @override
  String get blendPickUser => 'Blend with …';

  @override
  String get blendHint =>
      'A shared playlist from both your tastes, fresh every day. You both find it under “Made for you”.';

  @override
  String get blendNoUsers => 'There is nobody on this server to blend with.';

  @override
  String blendWaiting(Object name) {
    return 'Blend with $name created. Once you have both played or liked something, it shows up under “Made for you”.';
  }

  @override
  String get blendLeave => 'Leave blend';

  @override
  String blendLeaveConfirm(Object name) {
    return 'The blend with $name is deleted for both of you.';
  }

  @override
  String get releaseRadar => 'Release Radar';

  @override
  String get adminReleaseRadarHint =>
      'Every Friday new songs of each user\'s most played artists, missing ones are downloaded';

  @override
  String get adminReleaseRadarSize => 'Songs in Release Radar (10–100)';

  @override
  String get wrappedSettingsTitle => 'Year in review';

  @override
  String get wrappedSettingsHint => 'Your most played songs, artists and genres of the year';

  @override
  String wrappedBannerTitle(Object year) {
    return 'Your $year in music';
  }

  @override
  String get wrappedBannerText => 'Your year in review is here – see what you listened to.';

  @override
  String wrappedEmpty(Object year) {
    return 'There are no plays for $year yet.';
  }

  @override
  String wrappedYearButton(Object year) {
    return 'See $year';
  }

  @override
  String get wrappedIntroKicker => 'Your year in review';

  @override
  String wrappedIntroTitle(Object year) {
    return 'Your $year in music';
  }

  @override
  String get wrappedIntroHint => 'Tap right for next, left for back. Hold to pause.';

  @override
  String get wrappedMinutesBefore => 'This year you listened to';

  @override
  String get wrappedMinutesAfter => 'minutes of music.';

  @override
  String wrappedMinutesDays(Object days) {
    return 'That\'s $days days in a row.';
  }

  @override
  String wrappedTopDay(Object day, Object minutes) {
    return 'Most on $day: $minutes minutes in one day.';
  }

  @override
  String get wrappedGenresTitle => 'Your top genres';

  @override
  String get wrappedTopArtistKicker => 'Your artist of the year';

  @override
  String wrappedArtistStats(Object minutes, Object plays) {
    return '$plays plays · $minutes minutes';
  }

  @override
  String get wrappedTopArtistsTitle => 'Your top artists';

  @override
  String wrappedPlays(Object plays) {
    return '$plays plays';
  }

  @override
  String get wrappedTopSongKicker => 'Your song of the year';

  @override
  String wrappedSongStats(Object plays) {
    return 'Played $plays times';
  }

  @override
  String get wrappedPlay => 'Play';

  @override
  String get wrappedTopSongsTitle => 'Your top songs';

  @override
  String get wrappedClockKicker => 'You like listening most';

  @override
  String get wrappedMorning => 'in the morning';

  @override
  String get wrappedAfternoon => 'during the day';

  @override
  String get wrappedEvening => 'in the evening';

  @override
  String get wrappedNight => 'at night';

  @override
  String wrappedPeakHour(Object time) {
    return 'Most music played at $time.';
  }

  @override
  String wrappedBestMonth(Object month) {
    return 'Your biggest month: $month';
  }

  @override
  String get wrappedVarietyKicker => 'You were curious';

  @override
  String get wrappedDifferentSongs => 'different songs';

  @override
  String get wrappedDifferentArtists => 'different artists';

  @override
  String wrappedNewArtists(Object count) {
    return 'You heard $count of them for the first time this year.';
  }

  @override
  String get wrappedFirstSong => 'Your first song of the year';

  @override
  String wrappedSummaryTitle(Object year) {
    return 'Your $year';
  }

  @override
  String get wrappedMinutesLabel => 'Minutes listened';

  @override
  String get wrappedTopGenreLabel => 'Top genre';

  @override
  String get wrappedSavePlaylist => 'Top songs as a playlist';

  @override
  String get wrappedOpenPlaylist => 'Open playlist';

  @override
  String get wrappedUpdatePlaylist => 'Update';

  @override
  String get wrappedReplay => 'Replay';

  @override
  String wrappedPlaylistName(Object year) {
    return 'Your Top Songs $year';
  }

  @override
  String wrappedPlaylistDescription(Object year) {
    return 'Your 100 most played songs of $year';
  }
}
