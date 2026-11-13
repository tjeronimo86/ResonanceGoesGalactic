// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsPlayback => 'Wiedergabe';

  @override
  String get commonProductName => 'Resonance';

  @override
  String get errorInvalidInput => 'Ungültige Eingabe';

  @override
  String get errorServerUnreachable => 'Server nicht erreichbar';

  @override
  String errorHttpStatus(String statusCode) {
    return 'Fehler $statusCode';
  }

  @override
  String get catalogSingle => 'Single';

  @override
  String get catalogCompilation => 'Compilation';

  @override
  String get commonAlbum => 'Album';

  @override
  String get commonUnknown => 'Unbekannt';

  @override
  String get playerMusicLoadError => 'Die Musik konnte nicht geladen werden. Bitte erneut versuchen.';

  @override
  String get playerAudiobookLoadError => 'Das Hörbuch konnte nicht geladen werden. Bitte erneut versuchen.';

  @override
  String playerBookPart(int part, int total) {
    return 'Teil $part von $total';
  }

  @override
  String get navHome => 'Start';

  @override
  String get navSearch => 'Suche';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navAudiobooks => 'Hörbücher';

  @override
  String get navMedia => 'Mediathek';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get adminDashboard => 'Admin-Dashboard';

  @override
  String get libraryCreatePlaylist => 'Playlist erstellen';

  @override
  String get libraryNewPlaylist => 'Neue Playlist';

  @override
  String get playlistCollaborative => 'Gemeinsame Playlist';

  @override
  String get playlistCollaborativeHint =>
      'Alle, mit denen du sie teilst, können Songs hinzufügen, verschieben und entfernen.';

  @override
  String playlistAddedBy(String name) {
    return 'von $name';
  }

  @override
  String get commonName => 'Name';

  @override
  String get libraryLikedSongs => 'Lieblingssongs';

  @override
  String get commonPlaylist => 'Playlist';

  @override
  String libraryPlaylistBy(String name) {
    return 'Playlist • $name';
  }

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get searchHint => 'Was möchtest du hören?';

  @override
  String searchNoLibraryResults(String query) {
    return 'Keine Treffer für „$query“ in deiner Bibliothek.';
  }

  @override
  String get tvKeyboardSpace => 'Leerzeichen';

  @override
  String get tvKeyboardDelete => 'Löschen';

  @override
  String get tvKeyboardClear => 'Leeren';

  @override
  String get tvKeyboardSearch => 'Suchen';

  @override
  String get tvSearchAvailableAlbums => 'Zum Herunterladen: Alben';

  @override
  String get tvSearchAvailableSongs => 'Zum Herunterladen: Songs';

  @override
  String tvCatalogRequestBy(String artist) {
    return 'Von $artist';
  }

  @override
  String get commonSongsTitle => 'Songs';

  @override
  String get commonArtist => 'Künstler';

  @override
  String get commonAlbums => 'Alben';

  @override
  String get libraryAllArtists => 'Alle Künstler';

  @override
  String get libraryTitle => 'Deine Bibliothek';

  @override
  String get libraryPlaylists => 'Playlists';

  @override
  String get librarySavedAlbums => 'Gespeicherte Alben';

  @override
  String get libraryAllAlbums => 'Alle Alben';

  @override
  String get libraryLoadingSongs => '… Songs';

  @override
  String get libraryNoAlbums => 'Keine Alben';

  @override
  String get librarySaveAlbumsHint => 'Speichere Alben mit ⊕, um sie hier zu sehen.';

  @override
  String commonDiscNumber(int number) {
    return 'CD $number';
  }

  @override
  String get libraryRemoveAlbum => 'Aus Bibliothek entfernen';

  @override
  String get librarySaveAlbum => 'In Bibliothek speichern';

  @override
  String get playerAddToPlaylist => 'Zur Playlist hinzufügen';

  @override
  String get editorCorrectAlbum => 'Album korrigieren';

  @override
  String get editorMatchAlbum => 'Album zuordnen';

  @override
  String get editorChangeCover => 'Cover ändern';

  @override
  String artistLibraryAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Alben in deiner Bibliothek');
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Beliebt';

  @override
  String get artistDiscography => 'Diskografie';

  @override
  String get libraryPublicPlaylist => 'Öffentliche Playlist';

  @override
  String get libraryRenamePlaylist => 'Playlist umbenennen';

  @override
  String get commonRename => 'Umbenennen';

  @override
  String get libraryMakePrivate => 'Privat machen';

  @override
  String get librarySharePlaylist => 'Für alle Nutzer freigeben';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get libraryEmptyPlaylist => 'Noch keine Songs. Füge welche über das ⋯-Menü eines Songs hinzu.';

  @override
  String get libraryRemoveFromPlaylist => 'Aus dieser Playlist entfernen';

  @override
  String get homeGreetingNight => 'Gute Nacht';

  @override
  String get homeGreetingMorning => 'Guten Morgen';

  @override
  String get homeGreetingAfternoon => 'Guten Tag';

  @override
  String get homeGreetingEvening => 'Guten Abend';

  @override
  String get homeRecentlyPlayed => 'Zuletzt gehört';

  @override
  String get homeYourPlaylists => 'Deine Playlists';

  @override
  String get homeRecentlyAdded => 'Neu in der Bibliothek';

  @override
  String get homeEmptyLibrary =>
      'Deine Bibliothek ist noch leer.\nEin Admin kann im Dashboard einen Bibliotheks-Scan starten.';

  @override
  String get settingsAutoplay => 'Autoplay';

  @override
  String get settingsAutoplayHint => 'Wenn die Warteschlange endet, ähnliche Songs weiterspielen';

  @override
  String get playerAutoplaySection => 'Autoplay – ähnliche Songs';

  @override
  String get playerSmartShuffle => 'Smart Shuffle';

  @override
  String get playerShuffleOff => 'Zufallswiedergabe aus';

  @override
  String get playerNothingPlaying => 'Gerade läuft nichts';

  @override
  String get playerQueue => 'Warteschlange';

  @override
  String get audiobooksBook => 'Hörbuch';

  @override
  String get playerGoToAudiobook => 'Zum Hörbuch';

  @override
  String get audiobooksChapters => 'Kapitel';

  @override
  String get playerEmptyQueue => 'Die Warteschlange ist leer';

  @override
  String get playerNowPlaying => 'Läuft gerade';

  @override
  String get playerNextUp => 'Als Nächstes';

  @override
  String get playerRemoveFromQueue => 'Aus Warteschlange entfernen';

  @override
  String get playerNextInQueue => 'Als Nächstes in der Warteschlange';

  @override
  String get playerLater => 'Danach';

  @override
  String playerRemovedTrack(String title) {
    return '„$title“ aus der Warteschlange entfernt';
  }

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsAdministratorSuffix => ' • Administrator';

  @override
  String get settingsDisplayName => 'Anzeigename';

  @override
  String get settingsChangePassword => 'Passwort ändern';

  @override
  String get settingsResetCode => 'Code für neues Passwort';

  @override
  String get settingsResetCodeHint => 'Für ein anderes Gerät, wenn du dein Passwort vergessen hast';

  @override
  String settingsResetCodeBody(int minutes) {
    return 'Gib diesen Code dort bei „Passwort vergessen?“ ein. Er gilt $minutes Minuten und nur, bis das Passwort geändert ist.';
  }

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authResetTitle => 'Neues Passwort setzen';

  @override
  String get authResetHint =>
      'Öffne Resonance auf einem Gerät, auf dem du noch angemeldet bist: Einstellungen → „Code für neues Passwort“. Ohne angemeldetes Gerät kann ein Admin dir ein neues Passwort setzen.';

  @override
  String get authResetCode => 'Code';

  @override
  String get authResetSubmit => 'Passwort setzen';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsMediaTabs => 'Medien-Tabs';

  @override
  String get settingsEbooks => 'E-Books';

  @override
  String get settingsShowInMenu => 'Im Menü anzeigen';

  @override
  String get settingsAccentColor => 'Akzentfarbe';

  @override
  String get settingsCustomColor => 'Eigene Farbe';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonApply => 'Übernehmen';

  @override
  String get settingsNormalizeVolume => 'Lautstärke angleichen';

  @override
  String get settingsNormalizeVolumeHint => 'Nutzt ReplayGain, damit alle Songs ähnlich laut sind';

  @override
  String get settingsSignedInDevices => 'Angemeldete Geräte';

  @override
  String get settingsUnknownDevice => 'Unbekanntes Gerät';

  @override
  String get settingsCurrentDeviceSuffix => ' (dieses Gerät)';

  @override
  String settingsLastActive(String date) {
    return 'Zuletzt aktiv: $date';
  }

  @override
  String get commonSignOut => 'Abmelden';

  @override
  String get settingsCurrentPassword => 'Aktuelles Passwort';

  @override
  String get settingsNewPassword => 'Neues Passwort';

  @override
  String get commonChange => 'Ändern';

  @override
  String get settingsPasswordChanged => 'Passwort geändert';

  @override
  String get catalogDiscoverMore => 'Mehr entdecken';

  @override
  String get catalogDownloadHint => 'Was noch nicht in der Bibliothek ist, kannst du hier herunterladen.';

  @override
  String get catalogNoResults => 'Auch im Katalog nichts gefunden.';

  @override
  String get catalogAllInLibrary => 'Komplett in der Bibliothek';

  @override
  String catalogLibraryCount(int count, int total) {
    return '$count von $total in der Bibliothek';
  }

  @override
  String get catalogDownloadAlbum => 'Album herunterladen';

  @override
  String get catalogDownloadMissingSong => 'Fehlenden Song herunterladen';

  @override
  String catalogDownloadMissingSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Fehlende $count Songs herunterladen');
    return '$_temp0';
  }

  @override
  String get catalogOpenInLibrary => 'In Bibliothek öffnen';

  @override
  String get catalogEps => 'EPs';

  @override
  String get catalogSingles => 'Singles';

  @override
  String catalogArtistReleases(int count, int inLibrary) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Veröffentlichungen • $inLibrary in der Bibliothek',
    );
    return '$_temp0';
  }

  @override
  String get downloadsMine => 'Meine';

  @override
  String get downloadsAllUsers => 'Alle Nutzer';

  @override
  String get downloadsOpen => 'Offen';

  @override
  String get downloadsCompleted => 'Abgeschlossen';

  @override
  String get downloadsEmptyActive => 'Keine laufenden Downloads.\nSuche nach Musik und tippe auf ⤓.';

  @override
  String get downloadsEmptyCompleted => 'Noch nichts heruntergeladen.';

  @override
  String get downloadsFailed => 'Fehlgeschlagen';

  @override
  String get downloadsEmptyFailed => 'Keine fehlgeschlagenen Downloads.';

  @override
  String get downloadsRetryAll => 'Alle erneut versuchen';

  @override
  String get downloadsRetryAllConfirm =>
      'Alle fehlgeschlagenen Songs in dieser Liste werden noch einmal gesucht und heruntergeladen. Bei sehr vielen Songs kann YouTube zwischendurch pausieren.';

  @override
  String downloadsRetryAllDone(int songs, int requests) {
    return '$songs Songs aus $requests Anfragen werden erneut versucht';
  }

  @override
  String downloadsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Anfragen', one: '1 Anfrage');
    return '$_temp0';
  }

  @override
  String downloadsLoadMore(int shown, int total) {
    return 'Mehr laden ($shown von $total)';
  }

  @override
  String get commonSong => 'Song';

  @override
  String downloadsRequestedBySuffix(String name) {
    return 'von $name';
  }

  @override
  String get downloadsReject => 'Ablehnen';

  @override
  String get downloadsApprove => 'Freigeben';

  @override
  String get downloadsRejectRequest => 'Anfrage ablehnen';

  @override
  String get downloadsReasonOptional => 'Begründung (optional)';

  @override
  String get downloadsDownload => 'Download';

  @override
  String downloadsProgress(String status, int done, int total, String failed) {
    return '$status • $done/$total fertig$failed';
  }

  @override
  String downloadsFailedSuffix(int count) {
    return ' • $count fehlgeschlagen';
  }

  @override
  String downloadsRequestedBy(String name) {
    return 'Angefragt von $name';
  }

  @override
  String downloadsReason(String reason) {
    return 'Begründung: $reason';
  }

  @override
  String get downloadsRetryFailed => 'Fehlgeschlagene erneut versuchen';

  @override
  String get downloadsOwnSource => 'Eigenen Link angeben';

  @override
  String get downloadsCopyTitle => 'Titel und Interpret kopieren';

  @override
  String downloadsCopied(String text) {
    return '„$text“ kopiert';
  }

  @override
  String get downloadsOwnSourceLabel => 'YouTube-, SoundCloud- oder Bandcamp-Link';

  @override
  String get downloadsOwnSourceHint => 'Auch normale YouTube-Videos – geladen wird nur die Tonspur.';

  @override
  String get downloadsDeleteEntry => 'Eintrag löschen';

  @override
  String get catalogYouTubeMusic => 'YouTube Music';

  @override
  String get downloadsTorrent => 'Torrent';

  @override
  String get downloadsSearchingTorrent => 'Suche Torrent …';

  @override
  String downloadsTorrentProgress(String name, int progress) {
    return 'Torrent: $name ($progress %)';
  }

  @override
  String get downloadsImportingTorrent => 'Torrent wird importiert …';

  @override
  String downloadsTorrentName(String name) {
    return 'Torrent: $name';
  }

  @override
  String downloadsTorrentFallback(String error) {
    return 'Kein Torrent – lade über YouTube Music$error';
  }

  @override
  String commonDurationHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String commonDurationMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get audiobooksFinished => 'Beendet';

  @override
  String audiobooksTimeRemaining(String duration) {
    return 'Noch $duration';
  }

  @override
  String get statsUnitHours => 'Std.';

  @override
  String get statsUnitMinutes => 'Min.';

  @override
  String get statsTitle => 'Deine Statistik';

  @override
  String get statsTotal => 'Gesamte Hörzeit';

  @override
  String statsDaysOfAudio(String days) {
    return 'Das sind $days Tage Audio';
  }

  @override
  String get statsToday => 'Heute';

  @override
  String get statsThisWeek => 'Diese Woche';

  @override
  String get statsThisMonth => 'Dieser Monat';

  @override
  String get statsActivity => 'Aktivität';

  @override
  String get statsCurrentStreak => 'Aktuelle Serie';

  @override
  String get statsBestStreak => 'Längste Serie';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Tage', one: '1 Tag');
    return '$_temp0';
  }

  @override
  String get statsBooksFinished => 'Bücher gehört';

  @override
  String get statsBooksThisYear => 'Bücher dieses Jahr';

  @override
  String get statsDaysActive => 'Aktive Tage';

  @override
  String get statsDailyAverage => 'Ø pro aktivem Tag';

  @override
  String get statsLast7Days => 'Letzte 7 Tage';

  @override
  String get statsMostListened => 'Am meisten gehört';

  @override
  String statsHoursMinutesShort(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String statsMinutesShort(int minutes) {
    return '$minutes Min.';
  }

  @override
  String statsTeaser(String time, int books) {
    return '$time gehört · $books Bücher fertig';
  }

  @override
  String get mediaContinue => 'Weiterhören';

  @override
  String get mediaLatest => 'Neueste Folgen';

  @override
  String audiobooksChapterOf(int index, int count) {
    return 'Kapitel $index von $count';
  }

  @override
  String get audiobooksPreviousChapter => 'Vorheriges Kapitel';

  @override
  String get audiobooksNextChapter => 'Nächstes Kapitel';

  @override
  String get playerSpeedShort => 'Tempo';

  @override
  String get playerSleepShort => 'Timer';

  @override
  String playerAtSpeed(String speed) {
    return 'bei $speed';
  }

  @override
  String get audiobooksNotConfigured => 'Hörbücher sind auf diesem Server nicht eingerichtet.';

  @override
  String get audiobooksLoginTitle => 'Mit Audiobookshelf verbinden';

  @override
  String audiobooksLoginHint(String address) {
    return 'Melde dich mit deinem Audiobookshelf-Konto an$address. Dein Hörfortschritt bleibt mit allen Audiobookshelf-Apps synchron.';
  }

  @override
  String get authUsername => 'Benutzername';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get audiobooksNoLibrary => 'Keine Hörbuch-Bibliothek gefunden';

  @override
  String audiobooksSignOutUser(String name) {
    return 'Abmelden ($name)';
  }

  @override
  String get audiobooksSearchHint => 'Titel, Autor oder Serie suchen';

  @override
  String get audiobooksContinueListening => 'Weiterhören';

  @override
  String get audiobooksResume => 'Fortsetzen';

  @override
  String get audiobooksAllBooks => 'Alle Hörbücher';

  @override
  String get commonNothingFound => 'Nichts gefunden';

  @override
  String audiobooksNarrator(String name) {
    return 'gelesen von $name';
  }

  @override
  String get audiobooksStartOver => 'Von vorn beginnen';

  @override
  String get audiobooksMarkUnfinished => 'Als nicht beendet markieren';

  @override
  String get audiobooksMarkFinished => 'Als beendet markieren';

  @override
  String authCheckAddress(String error) {
    return '$error\nIst die Adresse richtig?';
  }

  @override
  String get authConnectTitle => 'Mit Server verbinden';

  @override
  String get authServerAddress => 'Server-Adresse';

  @override
  String get authConnect => 'Verbinden';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get authOtherServer => 'Anderer Server';

  @override
  String authSignInTo(String name) {
    return 'Bei $name anmelden';
  }

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String authServer(String address) {
    return 'Server: $address';
  }

  @override
  String get authPasswordsMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get authInvalidInvite => 'Einladung ungültig';

  @override
  String get authInvalidInviteHint =>
      'Dieser Einladungslink wurde bereits benutzt oder ist abgelaufen. Bitte frag einen Admin nach einem neuen Link.';

  @override
  String get authBackToLogin => 'Zur Anmeldung';

  @override
  String get authWelcomeAdmin => 'Willkommen! Admin-Konto anlegen';

  @override
  String get authFirstAccountHint => 'Das erste Konto auf diesem Server wird automatisch Administrator.';

  @override
  String get authPasswordMinimum => 'Passwort (min. 8 Zeichen)';

  @override
  String get authRepeatPassword => 'Passwort wiederholen';

  @override
  String get authRegister => 'Registrieren';

  @override
  String get authAlreadyHaveAccount => 'Ich habe schon ein Konto';

  @override
  String catalogAwaitingApproval(String title) {
    return '„$title“ wartet auf Freigabe durch einen Admin';
  }

  @override
  String catalogAlreadyInLibrary(String title) {
    return '„$title“ ist schon in deiner Bibliothek';
  }

  @override
  String catalogDownloadingTitle(String title) {
    return '„$title“ wird heruntergeladen';
  }

  @override
  String get catalogInYourLibrary => 'In deiner Bibliothek';

  @override
  String get catalogRequested => 'Angefragt';

  @override
  String get catalogDownload => 'Herunterladen';

  @override
  String get catalogInLibrary => 'In Bibliothek';

  @override
  String get catalogPlaylistKind => 'Playlist';

  @override
  String get catalogPlaylistImport => 'Importieren und fehlende Songs laden';

  @override
  String get catalogPlaylistUpdate => 'Erneut importieren';

  @override
  String get catalogPlaylistShowImport => 'Ansehen';

  @override
  String get catalogPlaylistImportHint =>
      'Legt die Playlist in deiner Bibliothek an; fehlende Songs werden heruntergeladen und rücken nach.';

  @override
  String get catalogSpotifyPreviewLimit => 'Spotify gibt bei fremden Playlists nur die ersten 100 Songs heraus.';

  @override
  String get downloadsStatusPendingApproval => 'Wartet auf Freigabe';

  @override
  String get downloadsStatusRunning => 'Läuft';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String get playlistSort => 'Sortieren';

  @override
  String get playlistSortHint => 'Ändert die Reihenfolge der Playlist für alle';

  @override
  String get playlistSorted => 'Playlist neu sortiert';

  @override
  String get playlistReorder => 'Reihenfolge von Hand ändern';

  @override
  String get playlistSetPeak => 'Als DJ-Set: aufwärmen, Höhepunkt, ausklingen';

  @override
  String get playlistSetRise => 'Als DJ-Set: immer energiegeladener';

  @override
  String get playlistSetDown => 'Als DJ-Set: immer ruhiger';

  @override
  String get playlistSetFlow => 'Als DJ-Set: gleichmäßiger Fluss';

  @override
  String get playlistSortTitle => 'Nach Titel';

  @override
  String get playlistSortArtist => 'Nach Künstler';

  @override
  String get playlistSortAlbum => 'Nach Album';

  @override
  String get playlistSortLength => 'Nach Länge';

  @override
  String get playlistSortReverse => 'Umdrehen';

  @override
  String get downloadsStatusPartial => 'Teilweise fertig';

  @override
  String get downloadsStatusFailed => 'Fehlgeschlagen';

  @override
  String get downloadsStatusRejected => 'Abgelehnt';

  @override
  String get downloadsStatusCancelled => 'Abgebrochen';

  @override
  String get downloadsStatusQueued => 'In Warteschlange';

  @override
  String get downloadsStatusSearching => 'Suche Quelle …';

  @override
  String get downloadsStatusDownloading => 'Lädt herunter';

  @override
  String get downloadsStatusProcessing => 'Wird getaggt …';

  @override
  String get downloadsStatusExisting => 'Schon vorhanden';

  @override
  String get playerShuffle => 'Zufallswiedergabe';

  @override
  String get playerRemoveLiked => 'Aus Lieblingssongs entfernen';

  @override
  String get playerAddLiked => 'Zu Lieblingssongs hinzufügen';

  @override
  String get playerPlayNext => 'Als Nächstes spielen';

  @override
  String get playerAddToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String playerQueuedTrack(String title) {
    return '„$title“ in der Warteschlange';
  }

  @override
  String get playerGoToAlbum => 'Zum Album';

  @override
  String get playerGoToArtist => 'Zum Künstler';

  @override
  String get editorCorrectMetadata => 'Metadaten korrigieren';

  @override
  String libraryAddedToPlaylist(String name) {
    return 'Zu „$name“ hinzugefügt';
  }

  @override
  String get commonSave => 'Speichern';

  @override
  String get playerSkipBack => '30 Sekunden zurück';

  @override
  String get playerSkipForward => '30 Sekunden vor';

  @override
  String get playerPrevious => 'Zurück';

  @override
  String get playerNext => 'Weiter';

  @override
  String get playerRepeat => 'Wiederholen';

  @override
  String get playerSpeed => 'Geschwindigkeit';

  @override
  String get playerSleepTimer => 'Sleep-Timer';

  @override
  String playerSleepTimerTime(String time) {
    return 'Sleep-Timer: pausiert um $time';
  }

  @override
  String playerTimerMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes Minuten');
    return '$_temp0';
  }

  @override
  String get playerDisableTimer => 'Timer ausschalten';

  @override
  String get playerFullscreen => 'Vollbild';

  @override
  String commonDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutes Min. $seconds Sek.';
  }

  @override
  String get updateAllowInstall => 'Bitte erlaube Resonance in den Android-Einstellungen, Apps zu installieren.';

  @override
  String updateFailedCode(String code) {
    return 'Update fehlgeschlagen ($code). Bitte erneut versuchen.';
  }

  @override
  String updateFailedMessage(String error) {
    return 'Update fehlgeschlagen: $error';
  }

  @override
  String get updateInProgress => 'App wird aktualisiert';

  @override
  String get updateDownloadStarting => 'Download startet …';

  @override
  String updateDownloadProgress(int percent) {
    return 'Download $percent %';
  }

  @override
  String get commonClose => 'Schließen';

  @override
  String get mixExport => 'Mix als MP3 exportieren';

  @override
  String mixExportRendering(int percent) {
    return 'Der Server mischt die Übergänge … $percent %';
  }

  @override
  String get mixExportBackground => 'Im Hintergrund weiter';

  @override
  String get mixExportFailed => 'Der Mix konnte nicht erstellt werden';

  @override
  String get mixExportSaving => 'Mix wird gespeichert …';

  @override
  String mixExportSaved(String target) {
    return 'Mix gespeichert: $target';
  }

  @override
  String updateAvailableTitle(String version) {
    return 'Neue App-Version $version verfügbar';
  }

  @override
  String get updateInstall => 'Installieren';

  @override
  String updateInstalledVersion(String version) {
    return 'App-Version $version';
  }

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version ist verfügbar';
  }

  @override
  String get updateCurrent => 'Aktuell';

  @override
  String get updateAction => 'Aktualisieren';

  @override
  String get updateCheck => 'Nach Updates suchen';

  @override
  String get updateAlreadyCurrent => 'Die App ist aktuell';

  @override
  String get adminImportCleanupTitle => 'Bibliothek aufräumen?';

  @override
  String get adminImportCleanupHint =>
      'Alle Songs der Bibliothek werden per Audio-Fingerabdruck erkannt, neu getaggt, mit Cover versehen und nach „Künstler/Album (Jahr)/Nr - Titel“ umbenannt. Die Dateien werden dabei direkt verändert.\n\nLikes, Playlists und Verlauf bleiben erhalten. Bei großen Bibliotheken dauert das mehrere Stunden.';

  @override
  String get adminImportCleanupConfirm => 'Aufräumen';

  @override
  String get adminImportFolder => 'Import-Ordner';

  @override
  String adminImportPendingFiles(int count, String mode) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Audiodateien warten • Modus: $mode',
    );
    return '$_temp0';
  }

  @override
  String get adminImportCopyHint => 'Kopieren (Originale bleiben unverändert)';

  @override
  String get adminImportMove => 'Verschieben';

  @override
  String get adminImportAcoustIdHint =>
      'Kein AcoustID-Schlüssel eingetragen – Songs werden nur über ihre vorhandenen Tags erkannt. Einen kostenlosen Schlüssel gibt es auf acoustid.org/new-application; eintragen unter „Server“.';

  @override
  String get adminImportStart => 'Import starten';

  @override
  String get adminImportCleanup => 'Bibliothek aufräumen';

  @override
  String get adminImportHistory => 'Verlauf';

  @override
  String get adminImportEmptyHistory => 'Noch kein Import gelaufen.';

  @override
  String get adminImportWaiting => 'Wartet';

  @override
  String adminImportBatchTitle(String mode) {
    return 'Import ($mode)';
  }

  @override
  String adminImportFileProgress(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(total, locale: localeName, other: '$count von $total Dateien');
    return '$_temp0';
  }

  @override
  String get adminImportIdentified => 'Erkannt';

  @override
  String get adminImportImported => 'Importiert';

  @override
  String get adminImportDuplicates => 'Duplikate';

  @override
  String get adminImportUnidentified => 'Nicht erkannt';

  @override
  String get adminImportErrors => 'Fehler';

  @override
  String get adminImportMethodAlbumFingerprint => 'Erkannt per Fingerabdruck (komplettes Album)';

  @override
  String get adminImportMethodTrackFingerprint => 'Erkannt per Fingerabdruck (einzelner Song)';

  @override
  String get adminImportMethodTags => 'Erkannt über vorhandene Tags (Katalog)';

  @override
  String get adminImportMethodUnidentified => 'Nicht erkannt – vorhandene Tags übernommen';

  @override
  String get adminTabOverview => 'Übersicht';

  @override
  String get adminTabUsers => 'Benutzer';

  @override
  String get adminTabInvites => 'Einladungen';

  @override
  String get adminTabImport => 'Import';

  @override
  String get adminTabReview => 'Zu prüfen';

  @override
  String get adminTabServer => 'Server';

  @override
  String get adminStorage => 'Speicher';

  @override
  String get adminPlaytime => 'Spielzeit';

  @override
  String get adminMixAnalysis => 'AutoMix-Analyse';

  @override
  String get adminVocalAnalysis => 'Gesangserkennung für AutoMix';

  @override
  String get adminVocalAnalysisHint =>
      'Trennt Anfang und Ende jedes Songs in Stimme und Musik (Demucs), damit sich bei Übergängen keine Stimmen überlagern. Beim Einschalten wird einmalig etwa 1 GB heruntergeladen; jeder Song braucht dann rund eine Minute Rechenzeit im Hintergrund, die ganze Bibliothek mehrere Tage. Oft gehörte Songs kommen zuerst dran.';

  @override
  String get adminVocalAnalysisInstalling => 'Gesangserkennung wird eingerichtet (etwa 1 GB) …';

  @override
  String adminVocalAnalysisFailed(String message) {
    return 'Einrichtung der Gesangserkennung fehlgeschlagen, neuer Versuch in einer Stunde: $message';
  }

  @override
  String adminVocalAnalysisProgress(String analyzed, String total) {
    return 'Gesangserkennung: $analyzed von $total Songs';
  }

  @override
  String get adminLyrics => 'Songtexte';

  @override
  String adminLyricsProgress(String synced, String plainOnly, String none, String pending) {
    return '$synced mit synchronisiertem Text, $plainOnly nur Text, $none ohne · $pending noch offen';
  }

  @override
  String get adminLyricsBackgroundFetch => 'Songtexte im Hintergrund laden';

  @override
  String adminMixAnalysisProgress(String analyzed, String total) {
    return '$analyzed von $total Songs analysiert';
  }

  @override
  String adminMixAnalysisDone(String total) {
    return 'Alle $total Songs analysiert';
  }

  @override
  String adminMixAnalysisFailed(String failed) {
    return ', $failed fehlgeschlagen';
  }

  @override
  String commonDurationHours(String hours) {
    return '$hours Std.';
  }

  @override
  String get adminScanHint =>
      'Der schnelle Scan liest nur neue und geänderte Dateien ein. Der vollständige Scan liest alle Tags und Cover neu.';

  @override
  String get adminQuickScan => 'Schneller Scan';

  @override
  String get adminFullScan => 'Vollständiger Scan';

  @override
  String get adminJobs => 'Aufgaben';

  @override
  String get adminNoJobs => 'Noch keine Aufgaben';

  @override
  String get adminLibraryScan => 'Bibliotheks-Scan';

  @override
  String get adminUserYouSuffix => ' (du)';

  @override
  String get adminUserDisabledSuffix => ' • deaktiviert';

  @override
  String adminUserLastSeenSuffix(String date) {
    return ' • zuletzt $date';
  }

  @override
  String adminNewPasswordFor(String name) {
    return 'Neues Passwort für $name';
  }

  @override
  String get adminPasswordSet => 'Passwort gesetzt, alle Geräte abgemeldet';

  @override
  String adminDeleteUserTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get adminDeleteUserHint => 'Playlists und Verlauf werden ebenfalls gelöscht.';

  @override
  String get adminRemoveAdmin => 'Admin-Rechte entziehen';

  @override
  String get adminMakeAdmin => 'Zum Admin machen';

  @override
  String get adminEnableUser => 'Aktivieren';

  @override
  String get adminDisableUser => 'Deaktivieren';

  @override
  String get adminResetPassword => 'Passwort zurücksetzen';

  @override
  String get adminPasswordMinimum => 'Min. 8 Zeichen';

  @override
  String get adminCreateInviteTitle => 'Einladungslink erstellen';

  @override
  String get adminInviteNote => 'Notiz (z. B. für wen)';

  @override
  String get adminInviteValidity => 'Gültig für';

  @override
  String get adminInviteOneDay => '1 Tag';

  @override
  String get adminInviteThreeDays => '3 Tage';

  @override
  String get adminInviteSevenDays => '7 Tage';

  @override
  String get adminInviteThirtyDays => '30 Tage';

  @override
  String get adminInviteUnlimited => 'Unbegrenzt';

  @override
  String get adminInviteAsAdmin => 'Als Admin registrieren';

  @override
  String get commonCreate => 'Erstellen';

  @override
  String get adminInviteLink => 'Einladungslink';

  @override
  String get adminInviteLinkHint => 'Der Link kann genau einmal benutzt werden. Er wird nur jetzt angezeigt.';

  @override
  String get adminLinkCopied => 'Link kopiert';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get adminNewInvite => 'Neuer Link';

  @override
  String get adminNoInvites => 'Noch keine Einladungen.\nErstelle einen Link, um jemanden einzuladen.';

  @override
  String get adminInvitation => 'Einladung';

  @override
  String adminInviteUsed(String name, String date) {
    return 'Benutzt von $name am $date';
  }

  @override
  String get adminInviteExpired => 'Abgelaufen';

  @override
  String adminInviteOpen(String expiry, String role) {
    return 'Offen • $expiry$role';
  }

  @override
  String get adminInviteNoExpiry => 'läuft nicht ab';

  @override
  String adminInviteExpires(String date) {
    return 'gültig bis $date';
  }

  @override
  String get adminInviteAdminSuffix => ' • Admin';

  @override
  String get adminServerName => 'Servername';

  @override
  String get adminRegistration => 'Registrierung';

  @override
  String get adminRegistrationInviteOnly => 'Nur mit Einladungslink';

  @override
  String get adminRegistrationInviteHint => 'Admins erstellen einmalig nutzbare Links (empfohlen)';

  @override
  String get adminRegistrationPublic => 'Öffentliche Registrierung';

  @override
  String get adminRegistrationPublicHint => 'Jeder, der den Server erreicht, kann ein Konto anlegen';

  @override
  String get adminLibraryImport => 'Bibliothek & Import';

  @override
  String get adminAcoustIdKey => 'AcoustID-Schlüssel';

  @override
  String get adminAcoustIdNotSet => 'Nicht gesetzt – kostenlos auf acoustid.org/new-application';

  @override
  String get adminConfigured => 'Gesetzt';

  @override
  String get adminAcoustIdHint => 'Für die Erkennung per Audio-Fingerabdruck';

  @override
  String get adminMoveImportedFiles => 'Importierte Dateien verschieben';

  @override
  String get adminMoveImportedFilesHint => 'Der Import-Ordner wird danach geleert';

  @override
  String get adminCopyImportedFiles => 'Importierte Dateien kopieren';

  @override
  String get adminCopyImportedFilesHint => 'Originale bleiben unverändert im Import-Ordner';

  @override
  String get adminImportUnidentifiedFiles => 'Nicht erkannte Dateien trotzdem importieren';

  @override
  String get adminImportUnidentifiedFilesHint =>
      'Mit ihren vorhandenen Tags; sonst bleiben sie im Import-Ordner liegen';

  @override
  String get adminAutoImport => 'Import-Ordner automatisch importieren';

  @override
  String get adminAutoImportHint => 'Prüft alle 5 Minuten auf neue Dateien (nur im Modus „Verschieben“)';

  @override
  String get adminSongRadio => 'Song-Radio';

  @override
  String get adminRadioAutoDownload => 'Fehlende Songs automatisch herunterladen';

  @override
  String get adminRadioAutoDownloadHint =>
      'Ähnliche Songs, die noch nicht in der Bibliothek sind, landen in der Download-Warteschlange';

  @override
  String get adminRadioTemporary => 'Radio-Downloads sind temporär';

  @override
  String adminRadioTemporaryHint(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Werden nach $days Tagen gelöscht, außer jemand liked sie oder fügt sie einer Playlist hinzu',
    );
    return '$_temp0';
  }

  @override
  String get adminRadioRetention => 'Aufbewahrung temporärer Songs (Tage)';

  @override
  String get adminEnableAudiobookshelf => 'Audiobookshelf einbinden';

  @override
  String get adminEnableAudiobookshelfHint =>
      'Zeigt den Tab „Hörbücher“. Jeder Benutzer meldet sich dort mit seinem eigenen Audiobookshelf-Konto an.';

  @override
  String get adminAudiobookshelfAddress => 'Audiobookshelf-Adresse';

  @override
  String get adminAudiobookshelfAddressHint => 'z. B. https://audio.example.com – auch für externe Apps gedacht';

  @override
  String get adminAlbumTorrents => 'Torrents für Alben';

  @override
  String get adminAlbumTorrentsHint =>
      'Sucht Alben zuerst über Prowlarr (öffentliche Tracker) und lädt sie mit qBittorrent über das VPN. Was dort fehlt, kommt von YouTube Music.';

  @override
  String get adminProwlarrApiKey => 'Prowlarr-API-Schlüssel';

  @override
  String get adminProwlarrApiKeyHint => 'Prowlarr → Settings → General → API Key';

  @override
  String get adminQbittorrentUsername => 'qBittorrent-Benutzer';

  @override
  String get adminQbittorrentPassword => 'qBittorrent-Passwort';

  @override
  String get adminMinimumSeeders => 'Mindestanzahl Seeder';

  @override
  String get adminTorrentTimeout => 'Aufgeben nach … Minuten ohne Fortschritt';

  @override
  String get adminTorrentSeedDays => 'Torrents behalten für … Tage';

  @override
  String get adminTorrentSeedDaysHint =>
      'Danach werden fertige Torrents samt Dateien aus qBittorrent gelöscht (die Songs in der Bibliothek bleiben). Von qBittorrent gestoppte Torrents werden sofort gelöscht. 0 = direkt nach dem Import.';

  @override
  String get adminYouTubeSource => 'YouTube Music als Quelle';

  @override
  String get adminYouTubeSourceHint => 'Lädt Songs über yt-dlp von YouTube Music (Opus, ca. 130–160 kbit/s)';

  @override
  String get adminYouTubeCookies => 'YouTube-Anmeldung';

  @override
  String get adminYouTubeCookiesHint =>
      'Explizite und andere altersbeschränkte Songs brauchen ein angemeldetes YouTube-Konto. Lade die cookies.txt eines Zweitkontos hoch (im privaten Browserfenster mit einer Erweiterung wie „Get cookies.txt LOCALLY“ exportieren, danach das Fenster schließen).';

  @override
  String adminYouTubeCookiesActive(String date) {
    return 'Angemeldet seit $date';
  }

  @override
  String get adminYouTubeCookiesFromEnv => 'Auf dem Server gesetzt (RESONANCE_YTDLP_COOKIES_FILE)';

  @override
  String get adminYouTubeCookiesNone => 'Nicht angemeldet: altersbeschränkte Videos werden übersprungen';

  @override
  String get adminYouTubeCookiesExpired =>
      'Anmeldung abgelaufen: YouTube hat die Cookies erneuert. Exportiere sie neu und lade sie hoch.';

  @override
  String get adminYouTubeCookiesUpload => 'cookies.txt hochladen';

  @override
  String get adminYouTubeCookiesRemove => 'Entfernen';

  @override
  String get adminYouTubeCookiesSaved => 'YouTube-Anmeldung gespeichert';

  @override
  String get adminSoundCloudSource => 'SoundCloud als Quelle';

  @override
  String get adminSoundCloudSourceHint => 'Wird versucht, wenn YouTube nichts findet';

  @override
  String get adminBandcampSource => 'Bandcamp als Quelle';

  @override
  String get adminBandcampSourceHint => 'Freie Streams in 128 kbit/s, wird zuletzt versucht';

  @override
  String get downloadsSearch => 'Suche';

  @override
  String get adminQualityUpgrades => 'Qualitäts-Upgrades';

  @override
  String get downloadsQualityUpgrade => 'Qualitäts-Upgrade';

  @override
  String get adminQualityUpgradeSearchNow => 'Jetzt suchen';

  @override
  String get adminQualityUpgradeStarted => 'Suche gestartet';

  @override
  String get adminQualityUpgradesHint =>
      'Sucht im Hintergrund bessere Versionen (Torrent) für Songs in niedriger Qualität und ersetzt sie. Benötigt aktivierte Torrents.';

  @override
  String get adminAutoApprove => 'Anfragen automatisch genehmigen';

  @override
  String get adminAutoApproveHint => 'Sonst muss ein Admin Anfragen von Benutzern freigeben';

  @override
  String get adminDailyLimit => 'Tageslimit pro Benutzer';

  @override
  String adminDailyLimitHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Max. $count automatische Downloads pro Tag',
    );
    return '$_temp0';
  }

  @override
  String get adminDownloadsPerDay => 'Downloads pro Benutzer und Tag';

  @override
  String get adminNotConfigured => 'Nicht gesetzt';

  @override
  String get adminTestConnection => 'Verbindung testen';

  @override
  String get adminTestKey => 'Schlüssel testen';

  @override
  String get adminProwlarr => 'Prowlarr';

  @override
  String get adminQbittorrent => 'qBittorrent';

  @override
  String editorSavedTrack(String title, String artist, String album) {
    return 'Gespeichert: $title – $artist ($album)';
  }

  @override
  String editorBitrate(int bitrate) {
    return '$bitrate kbit/s';
  }

  @override
  String get editorTabSearch => 'Suchen';

  @override
  String get editorTabFingerprint => 'Fingerabdruck';

  @override
  String get editorTabEdit => 'Bearbeiten';

  @override
  String get editorSearchTrackHint => 'Künstler und Titel';

  @override
  String get editorChooseTrackHint => 'Tippe auf den richtigen Song – Tags, Cover und Dateiname werden übernommen.';

  @override
  String get editorFingerprintSearching => 'Audio-Fingerabdruck wird abgeglichen …';

  @override
  String get editorFingerprintUnknown =>
      'AcoustID kennt diese Aufnahme nicht. Versuche es über „Suchen“ oder „Bearbeiten“.';

  @override
  String get editorUnknownTitle => 'Unbekannter Titel';

  @override
  String editorFingerprintScore(int percent) {
    return '   $percent % Übereinstimmung';
  }

  @override
  String get editorAutoSelectAlbum => 'Originalalbum automatisch wählen';

  @override
  String get editorUnknownAlbum => 'Unbekanntes Album';

  @override
  String editorTrackNumberWithTotal(int number, String total) {
    return 'Nr. $number$total';
  }

  @override
  String editorTrackTotalSuffix(int total) {
    return ' von $total';
  }

  @override
  String get editorNumbersOnly => 'Bitte nur Zahlen bei Jahr, Nr. und CD eingeben';

  @override
  String get editorNoChanges => 'Keine Änderungen';

  @override
  String get editorTitle => 'Titel';

  @override
  String get editorSwapTitleArtist => 'Titel und Künstler tauschen';

  @override
  String get editorAlbumArtist => 'Album-Künstler';

  @override
  String get editorYear => 'Jahr';

  @override
  String get editorTrackNumber => 'Nr.';

  @override
  String get editorGenre => 'Genre';

  @override
  String get editorManualHint =>
      'Leere Felder bleiben unverändert. Die Datei wird danach nach „Album-Künstler/Album (Jahr)/Nr - Titel“ umbenannt.';

  @override
  String editorMatchedSongs(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(total, locale: localeName, other: '$count von $total Songs zugeordnet');
    return '$_temp0';
  }

  @override
  String get editorUnmatchedSongs => 'Nicht zugeordnet (unverändert):';

  @override
  String get editorSearchAlbumHint => 'Künstler und Album oder MusicBrainz-Link';

  @override
  String editorMatchAlbumHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die $count Songs dieses Albums werden per Titel, Position und Länge den Songs der gewählten Veröffentlichung zugeordnet. Was nicht passt, bleibt unverändert.',
    );
    return '$_temp0';
  }

  @override
  String get editorUseMusicBrainzRelease => 'MusicBrainz-Veröffentlichung verwenden';

  @override
  String get editorRetagging => 'Songs werden neu getaggt …';

  @override
  String get editorCoverSaved => 'Cover gespeichert';

  @override
  String get editorCoverSuggestionsHint =>
      'Vorschläge von MusicBrainz und Deezer. Das Cover wird in alle Songs des Albums eingebettet.';

  @override
  String get editorUploadImage => 'Bild hochladen';

  @override
  String get editorNoCoverSuggestions => 'Keine Vorschläge gefunden';

  @override
  String get editorNoCover => 'Ohne Cover';

  @override
  String editorAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Alben');
    return '$_temp0';
  }

  @override
  String get editorLoadMore => 'Mehr laden';

  @override
  String get editorAllDone => 'Alles erledigt 🎉';

  @override
  String get commonOk => 'OK';

  @override
  String get editorDisc => 'CD';

  @override
  String get catalogEp => 'EP';

  @override
  String get adminImportCopyMode => 'kopieren';

  @override
  String get adminImportMoveMode => 'verschieben';

  @override
  String get adminLibrary => 'Bibliothek';

  @override
  String commonSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Songs', one: '1 Song');
    return '$_temp0';
  }

  @override
  String get commonArtists => 'Künstler';

  @override
  String get adminUserRole => 'Benutzer';

  @override
  String get authServerAddressExample => 'musik.example.com';

  @override
  String get spotifyTitle => 'Von Spotify oder Apple Music importieren';

  @override
  String get spotifyLinkHeading => 'Playlist per Link importieren';

  @override
  String get spotifyLinksHint =>
      'Füge Links zu öffentlichen Spotify- oder Apple-Music-Playlists ein, einen pro Zeile. Apple-Music-Playlists werden vollständig übernommen, bei Spotify ohne verbundenes Konto höchstens 100 Songs pro Playlist.';

  @override
  String get spotifyLinkPlaceholder => 'https://open.spotify.com/playlist/… oder https://music.apple.com/…';

  @override
  String get spotifyImport => 'Importieren';

  @override
  String get spotifyNotConfigured =>
      'Spotify ist auf diesem Server noch nicht eingerichtet. Ein Admin kann das im Admin-Dashboard unter „Server“ erledigen.';

  @override
  String get spotifyConnectHint =>
      'Verbinde dein Spotify-Konto, um deine Lieblingssongs und eigenen Playlists in Resonance zu übernehmen.';

  @override
  String get spotifyConnect => 'Mit Spotify verbinden';

  @override
  String get spotifyWaiting => 'Melde dich im geöffneten Fenster bei Spotify an und komm danach hierher zurück.';

  @override
  String spotifyConnectedAs(String name) {
    return 'Verbunden als $name';
  }

  @override
  String get spotifyDisconnect => 'Trennen';

  @override
  String get spotifyLikedSongs => 'Lieblingssongs';

  @override
  String spotifyLikedHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Songs', one: '1 Song');
    return '$_temp0 · werden in Resonance geliked';
  }

  @override
  String get spotifyPlaylistsHeading => 'Deine Playlists';

  @override
  String get spotifyPlaylistsNote =>
      'Spotify gibt nur deine eigenen Playlists und solche frei, an denen du mitarbeitest.';

  @override
  String spotifyPlaylistSubtitle(int count, String owner) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Songs', one: '1 Song');
    return '$_temp0 · $owner';
  }

  @override
  String get spotifyAlreadyImported => 'bereits importiert – wird abgeglichen';

  @override
  String get spotifyDownloadMissing => 'Fehlende Songs herunterladen';

  @override
  String get spotifyDownloadMissingHint =>
      'Songs, die noch nicht in der Bibliothek sind, werden angefragt und nach dem Download automatisch einsortiert.';

  @override
  String get spotifyStart => 'Import starten';

  @override
  String get spotifyNothingSelected => 'Wähle die Lieblingssongs oder mindestens eine Playlist aus.';

  @override
  String get spotifyStarted => 'Import gestartet';

  @override
  String get spotifyHistory => 'Bisherige Importe';

  @override
  String get spotifyStatusQueued => 'Wartet';

  @override
  String get spotifyStatusRunning => 'Läuft';

  @override
  String get spotifyStatusDone => 'Fertig';

  @override
  String get spotifyStatusFailed => 'Fehlgeschlagen';

  @override
  String spotifyImportCounts(int matched, int total, int missing, int requested) {
    return '$matched von $total gefunden · $missing fehlen · $requested angefragt';
  }

  @override
  String get spotifyShowMissing => 'Fehlende anzeigen';

  @override
  String get spotifySyncMenu => 'Mit Spotify abgleichen';

  @override
  String get spotifySyncTitle => 'Mit Spotify abgleichen';

  @override
  String get spotifySyncConnectHint =>
      'Verbinde dein Spotify-Konto, um diese Playlist nach Spotify zu exportieren oder mit einer Spotify-Playlist abzugleichen.';

  @override
  String get spotifySyncReconnectHint =>
      'Für den Export braucht Resonance zusätzlich Schreibrechte bei Spotify. Verbinde Spotify dafür einmal neu.';

  @override
  String get spotifySyncIntro =>
      'Die Songs dieser Playlist werden auf Spotify gesucht und dort in eine Playlist übernommen. Songs, die Spotify nicht hat, werden übersprungen und unten angezeigt.';

  @override
  String get spotifySyncNew => 'Neue Spotify-Playlist anlegen';

  @override
  String get spotifySyncExisting => 'Mit bestehender Spotify-Playlist verknüpfen';

  @override
  String get spotifySyncPick => 'Spotify-Playlist';

  @override
  String get spotifySyncTwoWay => 'In beide Richtungen abgleichen';

  @override
  String get spotifySyncTwoWayHint =>
      'Alle 10 Minuten: Änderungen auf Spotify kommen nach Resonance (fehlende Songs werden heruntergeladen), Änderungen in Resonance nach Spotify.';

  @override
  String get spotifySyncOneWayHint =>
      'Nur Export: Songs aus Resonance werden zu Spotify übertragen, wenn du auf „Jetzt abgleichen“ tippst.';

  @override
  String get spotifySyncExport => 'Nach Spotify exportieren';

  @override
  String get spotifySyncLink => 'Verknüpfen';

  @override
  String get spotifySyncFriendsHint =>
      'Tipp: Lade Freunde in Spotify als Mitarbeitende zu der Playlist ein. Mit dem Abgleich in beide Richtungen landen ihre Songs dann auch hier.';

  @override
  String get spotifySyncLinked => 'Mit Spotify verknüpft';

  @override
  String get spotifySyncRunning => 'Wird abgeglichen …';

  @override
  String spotifySyncFailed(String error) {
    return 'Fehler: $error';
  }

  @override
  String spotifySyncLast(String time) {
    return 'Zuletzt abgeglichen: $time';
  }

  @override
  String get spotifySyncNow => 'Jetzt abgleichen';

  @override
  String get spotifySyncOpen => 'In Spotify öffnen';

  @override
  String get spotifySyncUnlink => 'Verknüpfung lösen';

  @override
  String get spotifySyncUnlinkConfirm =>
      'Die Playlist wird nicht mehr abgeglichen. Die Playlist auf Spotify bleibt bestehen.';

  @override
  String spotifySyncUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs nicht auf Spotify gefunden',
      one: '1 Song nicht auf Spotify gefunden',
    );
    return '$_temp0';
  }

  @override
  String get spotifyMissingTitle => 'Nicht in der Bibliothek';

  @override
  String get adminSpotifyGroup => 'Spotify-Import';

  @override
  String get adminSpotifyClientId => 'Spotify Client ID';

  @override
  String get adminSpotifyClientSecret => 'Spotify Client Secret';

  @override
  String adminSpotifyHint(String uri) {
    return 'developer.spotify.com/dashboard → App anlegen, Redirect URI: $uri';
  }

  @override
  String get audiobooksViewLibrary => 'Bibliothek';

  @override
  String get audiobooksViewSeries => 'Serien';

  @override
  String get audiobooksViewAuthors => 'Autoren';

  @override
  String get audiobooksViewNarrators => 'Sprecher';

  @override
  String audiobooksBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Hörbücher', one: '1 Hörbuch');
    return '$_temp0';
  }

  @override
  String get albumFindMissing => 'Fehlende Songs suchen';

  @override
  String get adminDeleteSong => 'Song löschen';

  @override
  String get adminDeleteAlbum => 'Album löschen';

  @override
  String adminDeleteSongConfirm(String title) {
    return '„$title“ wird endgültig vom Server gelöscht, auch die Datei.';
  }

  @override
  String adminDeleteAlbumConfirm(String title) {
    return 'Das Album „$title“ wird mit allen Songs endgültig vom Server gelöscht, auch die Dateien.';
  }

  @override
  String get adminDeleted => 'Gelöscht';

  @override
  String get libraryShareWithUsers => 'Mit bestimmten Nutzern teilen';

  @override
  String get libraryNoOtherUsers => 'Es gibt noch keine anderen Nutzer.';

  @override
  String librarySharedWith(String names) {
    return 'Geteilt mit $names';
  }

  @override
  String albumMissingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs nicht in deiner Bibliothek',
      one: '1 Song nicht in deiner Bibliothek',
    );
    return '$_temp0';
  }

  @override
  String get radioStartSong => 'Song-Radio starten';

  @override
  String get radioStartAlbum => 'Album-Radio starten';

  @override
  String get radioKind => 'Radio';

  @override
  String get radioKeep => 'Als Playlist behalten';

  @override
  String radioDownloading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlende Songs werden geladen und dann zum Radio hinzugefügt',
      one: '1 fehlender Song wird geladen und dann zum Radio hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get libraryRadios => 'Radios';

  @override
  String get adminRadioMaxDownloads => 'Max. Downloads pro Radio-Start';

  @override
  String get adminRadioPlaylistRetention => 'Radios aufbewahren (Tage seit letzter Nutzung, 0 = immer)';

  @override
  String get offlineBanner => 'Offline – nur Heruntergeladenes';

  @override
  String get offlineEmptyHint =>
      'Lade Alben, Playlists, Podcast-Folgen, Hörbücher und E-Books herunter, um sie offline zu nutzen.';

  @override
  String get offlineDownloaded => 'Heruntergeladen';

  @override
  String get offlineDownload => 'Herunterladen';

  @override
  String offlineNotificationRunning(String numFinished, String numTotal) {
    return 'Resonance: $numFinished von $numTotal Songs geladen';
  }

  @override
  String get offlineNotificationComplete => 'Resonance: Downloads fertig';

  @override
  String get offlineRemoveTitle => 'Download entfernen?';

  @override
  String get storageExport => 'Exportieren';

  @override
  String get storageExportAll => 'Alle exportieren';

  @override
  String get storageExportUnsupported => 'Exportieren braucht Android 10 oder neuer';

  @override
  String storageExportProgress(int done, int total) {
    return '$done von $total Songs';
  }

  @override
  String storageExported(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs nach $folder exportiert',
      one: '1 Song nach $folder exportiert',
      zero: 'Schon alles exportiert',
    );
    return '$_temp0';
  }

  @override
  String get coverCropTitle => 'Ausschnitt wählen';

  @override
  String get coverCropHint => 'Bild verschieben und mit zwei Fingern oder dem Mausrad zoomen';

  @override
  String get storageOpenFolder => 'Ordner öffnen';

  @override
  String get storageCollections => 'Heruntergeladene Sammlungen';

  @override
  String get storageFiles => 'Dateien nach Größe';

  @override
  String get offlineQuality => 'Downloadqualität';

  @override
  String get offlineQualityNormal => 'Normal (Opus 160 kbit/s)';

  @override
  String get offlineQualityHigh => 'Hoch (Opus 256 kbit/s)';

  @override
  String get offlineQualityOriginal => 'Original (verlustfrei, braucht viel Speicher)';

  @override
  String get offlineWifiOnly => 'Nur über WLAN herunterladen';

  @override
  String get offlineStorage => 'Speicherbelegung';

  @override
  String offlineStorageUsed(String size, int count) {
    return '$size • $count Songs';
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
    return '$count Songs werden heruntergeladen';
  }

  @override
  String offlineProgress(int done, int total) {
    return '$done von $total heruntergeladen';
  }

  @override
  String get offlineClearAll => 'Alle Downloads löschen';

  @override
  String get offlineClearConfirm => 'Alle Downloads löschen?';

  @override
  String get mixKind => 'Mix';

  @override
  String get mixSave => 'Als Playlist speichern';

  @override
  String get homeMadeForYou => 'Für dich erstellt';

  @override
  String get homeCharts => 'Charts';

  @override
  String get homeGenreMixes => 'Deine Genres';

  @override
  String get homeDecadeMixes => 'Deine Jahrzehnte';

  @override
  String get lyricsTitle => 'Songtext';

  @override
  String get lyricsExpand => 'Vollbild';

  @override
  String get lyricsUnsynced => 'Diese Songtexte sind nicht synchronisiert.';

  @override
  String get lyricsInstrumental => 'Instrumental';

  @override
  String get lyricsNotFound => 'Für diesen Song gibt es keinen Songtext.';

  @override
  String get lyricsAttribution => 'Songtext von LRCLIB';

  @override
  String get adminLyricsOnline => 'Songtexte online suchen (LRCLIB)';

  @override
  String get adminLyricsOnlineHint =>
      'Für Songs ohne eigene Songtexte werden synchronisierte Texte von lrclib.net geladen.';

  @override
  String get redownloadMenu => 'Falsche Version? Neu herunterladen';

  @override
  String get redownloadTitle => 'Neu herunterladen';

  @override
  String get redownloadExplanation =>
      'Der Song wird erneut gesucht und ersetzt. Die bisher verwendete Quelle wird übersprungen. Likes und Playlists bleiben erhalten.';

  @override
  String get redownloadYoutubeLabel => 'YouTube-, SoundCloud- oder Bandcamp-Link (optional)';

  @override
  String get redownloadYoutubeHint => 'Falls du eine bestimmte Version willst';

  @override
  String get redownloadStarted => 'Neu-Download gestartet';

  @override
  String get redownloadAwaitingApproval => 'Anfrage gesendet – ein Admin muss sie freigeben';

  @override
  String get downloadsRedownload => 'Neu-Download';

  @override
  String get audioBrowseHome => 'Startseite';

  @override
  String get settingsCrossfade => 'Crossfade';

  @override
  String get settingsCrossfadeOff => 'Aus';

  @override
  String settingsCrossfadeSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get settingsVisualizer => 'Visualizer';

  @override
  String get settingsVisualizerHint => 'Zeigt beim Abspielen animierte Frequenzbalken im Player.';

  @override
  String get settingsVisualizerStyle => 'Visualizer-Stil';

  @override
  String get settingsVisualizerReflection => 'Spiegelung';

  @override
  String get settingsVisualizerReflectionHint => 'Cover und Visualizer spiegeln';

  @override
  String get visualizerPeaksOn => 'Punkte an';

  @override
  String get visualizerPeaksOff => 'Punkte aus';

  @override
  String get settingsCoverflow => 'Coverflow';

  @override
  String get settingsCoverflowHint => 'Cover der Warteschlange zum Wischen nebeneinander';

  @override
  String get settingsCoverflowFlip => 'Cover umdrehen';

  @override
  String get settingsCoverflowFlipHint => 'Tippen auf das Cover zeigt die Songs des Albums';

  @override
  String get visualizerThemeAuto => 'Automatisch';

  @override
  String get visualizerThemeRetro => 'Retro-Stereo';

  @override
  String get visualizerThemeSynthwave => 'Synthwave';

  @override
  String get visualizerThemeNeon => 'Neon';

  @override
  String get visualizerThemeOcean => 'Ozean';

  @override
  String get visualizerThemeSunset => 'Sonnenuntergang';

  @override
  String get visualizerThemeFire => 'Feuer';

  @override
  String get visualizerThemeMatrix => 'Matrix';

  @override
  String get visualizerThemeAurora => 'Polarlicht';

  @override
  String get visualizerThemeMono => 'Monochrom';

  @override
  String get visualizerThemeRainbow => 'Regenbogen';

  @override
  String get settingsAutomix => 'Automix';

  @override
  String get settingsAutomixHint =>
      'Übergänge wie bei einem DJ: Der nächste Song setzt im Takt ein und sein Tempo wird kurz angeglichen. Songs ohne Analyse (z. B. offline) werden einfach überblendet. Der Crossfade-Regler legt die Mindestlänge der Übergänge fest.';

  @override
  String get settingsVocalSwap => 'Gesangs-Tausch';

  @override
  String get settingsVocalSwapHint =>
      'Der nächste Song kommt ohne Gesang herein, sein Beat läuft unter dem Gesang des aktuellen Songs (nur PC, braucht die Song-Analyse auf dem Server)';

  @override
  String get settingsKeyShift => 'Tonart angleichen';

  @override
  String get settingsKeyShiftHint =>
      'AutoMix verschiebt den nächsten Song um bis zu zwei Halbtöne, wenn die Tonarten nicht zusammenpassen – der ganze Song klingt dann höher oder tiefer als das Original';

  @override
  String get equalizerTitle => 'Equalizer';

  @override
  String get equalizerOff => 'Aus';

  @override
  String get equalizerPresetFlat => 'Flach';

  @override
  String get equalizerPresetBass => 'Bass-Boost';

  @override
  String get equalizerPresetTreble => 'Höhen';

  @override
  String get equalizerPresetVocal => 'Stimme';

  @override
  String get equalizerPresetRock => 'Rock';

  @override
  String get equalizerPresetPop => 'Pop';

  @override
  String get equalizerPresetHiphop => 'Hip-Hop';

  @override
  String get equalizerPresetElectronic => 'Electronic';

  @override
  String get equalizerPresetAcoustic => 'Akustik';

  @override
  String get equalizerPresetLoudness => 'Loudness';

  @override
  String get equalizerPresetCustom => 'Eigene';

  @override
  String get equalizerPresets => 'Voreinstellungen';

  @override
  String get equalizerReset => 'Zurücksetzen';

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
  String get settingsSubsonicTitle => 'Andere Musik-Apps (Subsonic)';

  @override
  String get settingsSubsonicSubtitle => 'Nutze Resonance in Apps wie Symfonium oder Feishin';

  @override
  String settingsSubsonicConnection(String serverUrl, String username) {
    return 'Server: $serverUrl\nBenutzername: $username';
  }

  @override
  String get settingsSubsonicConfigured => 'Ein App-Passwort ist eingerichtet.';

  @override
  String get settingsSubsonicRegenerate => 'Neues Passwort erzeugen';

  @override
  String get settingsSubsonicRemove => 'Entfernen';

  @override
  String get settingsSubsonicHint =>
      'Erzeuge ein App-Passwort und gib es in der anderen App als Passwort ein. Dein normales Passwort funktioniert dort nicht.';

  @override
  String get settingsSubsonicGenerate => 'Passwort erzeugen';

  @override
  String get settingsSubsonicCopied => 'Kopiert';

  @override
  String get settingsSubsonicShownOnce => 'Wird nur jetzt angezeigt.';

  @override
  String get adminIntegrations => 'Integrationen';

  @override
  String get adminDiscordClientId => 'Discord-Anwendungs-ID';

  @override
  String get adminDiscordClientIdHint =>
      'Für den Discord-Status der Desktop-App. Anwendung unter discord.com/developers anlegen und die Application ID hier eintragen.';

  @override
  String get settingsDiscordPresence => 'Discord-Status anzeigen';

  @override
  String get settingsDiscordPresenceHint => 'Zeigt in Discord an, was du gerade hörst';

  @override
  String get settingsDiscordNotConfigured => 'Vom Admin noch nicht eingerichtet';

  @override
  String discordPresenceArtist(String artist) {
    return 'von $artist';
  }

  @override
  String get playlistRemoveCover => 'Cover entfernen';

  @override
  String get playlistCoverRemoved => 'Cover entfernt';

  @override
  String get editorLooksGood => 'Passt so';

  @override
  String get discoverWeekly => 'Mix der Woche';

  @override
  String get adminMixes => 'Mixes';

  @override
  String get adminDiscoverWeeklyHint => 'Jeden Montag 30 neue Songs pro Nutzer, fehlende werden heruntergeladen';

  @override
  String get adminDiscoverDownloads => 'Downloads pro Woche und Nutzer';

  @override
  String get adminDiscoverSize => 'Songs im Mix der Woche (10–100)';

  @override
  String get adminChartsEnabled => 'Charts-Playlists';

  @override
  String get adminChartsEnabledHint => 'Top 100 Deutschland und Global, täglich aktualisiert';

  @override
  String get adminChartsDownloads => 'Fehlende Chart-Songs pro Tag laden';

  @override
  String get adminEditorialEnabled => 'Redaktionelle Playlists (Apple Music)';

  @override
  String get adminEditorialDownloads => 'Songs pro Playlist nachladen';

  @override
  String get adminEditorialYears => 'Jahres-Hits';

  @override
  String get worldRadioTitle => 'Weltradio';

  @override
  String get worldRadioSearchHint => 'Sender suchen';

  @override
  String get worldRadioSearch => 'Suchen';

  @override
  String worldRadioPopularInCountry(String country) {
    return 'Beliebt in $country';
  }

  @override
  String get worldRadioGenres => 'Genres';

  @override
  String get worldRadioAllGenres => 'Alle Genres';

  @override
  String get worldRadioFavoriteHint => 'Markiere Sender im Player mit dem Stern als Favorit';

  @override
  String get worldRadioFavorites => 'Favoriten';

  @override
  String worldRadioStationCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Sender', one: '1 Sender');
    return '$_temp0';
  }

  @override
  String get worldRadioYourStations => 'Deine Radiosender';

  @override
  String get worldRadioUnavailable => 'Sender nicht erreichbar';

  @override
  String get worldRadioLive => 'LIVE';

  @override
  String get worldRadioCountry => 'Land';

  @override
  String get worldRadioSearchCountry => 'Land suchen';

  @override
  String get jamTitle => 'Jam';

  @override
  String get jamIntro => 'Gemeinsam hören: Freunde treten mit einem Code bei, alle können Songs hinzufügen.';

  @override
  String get jamStart => 'Jam starten';

  @override
  String get jamJoin => 'Jam beitreten';

  @override
  String get jamCodeHint => '6-stelliger Zahlencode';

  @override
  String get jamConnecting => 'Verbinde …';

  @override
  String get jamCopyLink => 'Link kopieren';

  @override
  String get jamLinkCopied => 'Link kopiert';

  @override
  String get jamMembers => 'Teilnehmer';

  @override
  String get jamHost => 'Host';

  @override
  String get jamKick => 'Entfernen';

  @override
  String get jamMembersControl => 'Mitglieder dürfen steuern';

  @override
  String get jamListenHere => 'Auf diesem Gerät mithören';

  @override
  String get jamListenHereHint => 'Aus: nur steuern, die Musik läuft auf einem anderen Gerät';

  @override
  String get jamLeave => 'Jam verlassen';

  @override
  String get jamEnd => 'Jam beenden';

  @override
  String get jamEndConfirm => 'Den Jam für alle beenden?';

  @override
  String get jamEnded => 'Der Jam wurde beendet';

  @override
  String get jamNotConnected => 'Keine Verbindung zum Jam';

  @override
  String get jamQueue => 'Jam-Warteschlange';

  @override
  String jamAddedBy(String name) {
    return 'Hinzugefügt von $name';
  }

  @override
  String jamChip(int count) {
    return 'Jam · $count';
  }

  @override
  String get adminDuplicates => 'Duplikate';

  @override
  String get adminDuplicatesDifferentAlbums => 'Verschiedene Alben · gleiche Aufnahme';

  @override
  String get adminDuplicatesPending => 'Wird noch geprüft';

  @override
  String get adminDuplicatesEmpty => 'Keine Duplikate gefunden';

  @override
  String adminDuplicatesHint(int groups) {
    return '$groups Songs liegen mehrfach vor. Behalten wird jeweils die beste Datei, die anderen werden gelöscht. Likes, Playlists und Verlauf gehen auf die behaltene Datei über. Playlists, Likes und Verlauf zeigen danach auf die behaltene Datei – du musst nichts neu hinzufügen. Bei verschiedenen Alben verschwindet der Song vom anderen Album.';
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
    return '$n Duplikate löschen';
  }

  @override
  String get adminDuplicatesConfirmTitle => 'Duplikate löschen?';

  @override
  String get adminDuplicatesConfirmHint => 'Die schlechteren Dateien werden endgültig gelöscht.';

  @override
  String adminDuplicatesMerged(int deleted, String freed) {
    return '$deleted Dateien gelöscht, $freed frei geworden';
  }

  @override
  String get updateRestarting => 'Wird installiert, Resonance startet gleich neu …';

  @override
  String get shortcutsTitle => 'Tastenkürzel';

  @override
  String get shortcutPlayPause => 'Abspielen / Pause';

  @override
  String get shortcutNextPrevious => 'Nächster / vorheriger Song';

  @override
  String get shortcutSeek => '10 Sekunden vor / zurück';

  @override
  String get shortcutVolume => 'Lauter / leiser';

  @override
  String get shortcutShuffle => 'Zufallswiedergabe';

  @override
  String get shortcutRepeat => 'Wiederholen';

  @override
  String get shortcutSearch => 'Suchen';

  @override
  String get navBooks => 'Bücher';

  @override
  String get booksEbooks => 'Ebooks';

  @override
  String get booksSearchHint => 'Buch, Autor oder Serie suchen';

  @override
  String get booksRecent => 'Neu in der Bibliothek';

  @override
  String get booksAuthors => 'Autoren';

  @override
  String get booksSeries => 'Serien';

  @override
  String get booksRequests => 'Anfragen';

  @override
  String get booksImport => 'Importieren';

  @override
  String get booksAll => 'Alle Bücher';

  @override
  String get booksEmptyLibrary =>
      'Noch keine Bücher. Suche nach einem Buch, um es anzufragen, oder importiere eigene Dateien.';

  @override
  String get booksInLibrary => 'In deiner Bibliothek';

  @override
  String get booksFromCatalog => 'Zum Anfragen';

  @override
  String get booksNoResults => 'Nichts gefunden';

  @override
  String get booksRequestFree => 'Nicht dabei? Selbst anfragen';

  @override
  String get booksRequest => 'Anfragen';

  @override
  String booksRequested(String title) {
    return 'Angefragt: $title';
  }

  @override
  String get booksRequestsDisabled =>
      'Automatische Downloads sind auf diesem Server aus. Du kannst Bücher aber importieren.';

  @override
  String get booksLanguage => 'Sprache';

  @override
  String get booksLanguageDe => 'Deutsch';

  @override
  String get booksLanguageEn => 'Englisch';

  @override
  String get booksLanguageAny => 'Egal';

  @override
  String booksVolume(String number) {
    return 'Band $number';
  }

  @override
  String get booksDownload => 'Herunterladen';

  @override
  String get booksEdit => 'Bearbeiten';

  @override
  String get booksDelete => 'Löschen';

  @override
  String booksDeleteConfirm(String title) {
    return '„$title“ aus der Bibliothek löschen?';
  }

  @override
  String get booksTitle => 'Titel';

  @override
  String get booksAuthorsField => 'Autoren (mit Komma getrennt)';

  @override
  String get booksSeriesField => 'Serie';

  @override
  String get booksSeriesIndex => 'Band';

  @override
  String get booksStatusPending => 'Wartet auf Freigabe';

  @override
  String get booksStatusQueued => 'In der Warteschlange';

  @override
  String get booksStatusSearching => 'Wird gesucht';

  @override
  String get booksStatusDownloading => 'Lädt';

  @override
  String get booksStatusImporting => 'Wird importiert';

  @override
  String get booksStatusDone => 'Fertig';

  @override
  String get booksStatusFailed => 'Fehlgeschlagen';

  @override
  String get booksStatusCancelled => 'Abgebrochen';

  @override
  String get booksStatusRejected => 'Abgelehnt';

  @override
  String get booksCancelRequest => 'Anfrage abbrechen';

  @override
  String get booksRemoveRequest => 'Entfernen';

  @override
  String get booksApprove => 'Freigeben';

  @override
  String get booksReject => 'Ablehnen';

  @override
  String get booksNoRequests => 'Keine Anfragen';

  @override
  String get booksAllUsers => 'Alle Nutzer';

  @override
  String get booksImportFiles => 'Dateien hochladen';

  @override
  String get booksImportFilesHint => 'EPUB, AZW3, MOBI oder PDF';

  @override
  String get booksImportUrl => 'Von Link importieren';

  @override
  String get booksImportUrlLabel => 'Link zur Buchdatei';

  @override
  String get booksImporting => 'Wird importiert …';

  @override
  String booksImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher importiert',
      one: '1 Buch importiert',
    );
    return '$_temp0';
  }

  @override
  String booksImportFailed(String name, String error) {
    return '$name: $error';
  }

  @override
  String get adminBooksEnable => 'Ebooks aktivieren';

  @override
  String get adminBooksEnableHint =>
      'Bücher-Tab, OPDS-Katalog (/opds) und KOReader-Sync (/kosync). Anmeldung dort mit dem App-Passwort.';

  @override
  String get adminBooksLanguage => 'Standardsprache für Anfragen';

  @override
  String get adminBooksGoogleKey => 'Google-Books-API-Schlüssel';

  @override
  String get adminBooksGoogleKeyHint => 'Optional – ohne Schlüssel wird nur Audible durchsucht';

  @override
  String get adminBooksDailyLimit => 'Bücher pro Nutzer und Tag (0 = unbegrenzt)';

  @override
  String get adminBooksTorrentsHint => 'Automatische Downloads nutzen die Torrent-Einstellungen unter Downloads.';

  @override
  String get editorSourceApple => 'Apple Music';

  @override
  String get editorSourceDiscogs => 'Discogs';

  @override
  String get editorSourceDeezer => 'Deezer';

  @override
  String get editorSourceMusicBrainz => 'MusicBrainz';

  @override
  String get adminDiscogsToken => 'Discogs-Token';

  @override
  String get adminDiscogsHint => 'Kostenlos unter discogs.com → Einstellungen → Entwickler';

  @override
  String get adminLastfmKey => 'Last.fm API-Key';

  @override
  String get adminLastfmHint => 'Kostenlos unter last.fm/api';

  @override
  String get adminFanartKey => 'fanart.tv API-Key';

  @override
  String get adminFillGenres => 'Fehlende Genres ergänzen (Last.fm)';

  @override
  String get artistAbout => 'Über';

  @override
  String get artistShowMore => 'Mehr anzeigen';

  @override
  String get artistShowLess => 'Weniger anzeigen';

  @override
  String get adminDuplicatesSelectAll => 'Alle auswählen';

  @override
  String get adminDuplicatesSelectNone => 'Keine auswählen';

  @override
  String adminDuplicatesProgress(int done, int total) {
    return 'Lösche … $done von $total';
  }

  @override
  String get settingsTvMode => 'TV-/Controller-Modus';

  @override
  String get settingsTvModeHint => 'Große Oberfläche für Fernbedienung und Controller';

  @override
  String get tvPlay => 'Abspielen';

  @override
  String get tvPause => 'Pause';

  @override
  String get tvBack => 'Zurück';

  @override
  String get tvPopularStations => 'Beliebte Sender';

  @override
  String get changelogTitle => 'Neuigkeiten';

  @override
  String get changelogInstalled => 'Installiert';

  @override
  String changelogNewVersion(String version) {
    return 'Neu in Version $version';
  }

  @override
  String get changelogAll => 'Alle Neuigkeiten';

  @override
  String get navPodcasts => 'Podcasts';

  @override
  String get podcastsContinue => 'Weiterhören';

  @override
  String get podcastsNewEpisodes => 'Neue Folgen';

  @override
  String get podcastsYourPodcasts => 'Deine Podcasts';

  @override
  String get podcastsCategories => 'Kategorien';

  @override
  String get podcastsSubscriptions => 'Abos';

  @override
  String get podcastsSearch => 'Podcasts suchen';

  @override
  String get podcastsSearchHint => 'Podcasts suchen';

  @override
  String get podcastsAddRss => 'Per RSS-Link hinzufügen';

  @override
  String get podcastsAddFeedByUrl => 'RSS-Feed hinzufügen';

  @override
  String get podcastsNoResults =>
      'Nichts gefunden. Podcasts, die nur bei Spotify erscheinen, haben keinen offenen Feed – kennst du die RSS-Adresse, füge sie oben rechts hinzu.';

  @override
  String get podcastsRssUrl => 'RSS-Link';

  @override
  String get podcastsEmpty => 'Noch keine Abos. Suche nach einem Podcast oder füge einen RSS-Link hinzu.';

  @override
  String get podcastsSubscribe => 'Abonnieren';

  @override
  String get podcastsSubscribed => 'Abonniert';

  @override
  String get podcastsUnsubscribe => 'Abo beenden';

  @override
  String get podcastsDescription => 'Beschreibung';

  @override
  String get podcastsEpisodes => 'Episoden';

  @override
  String get podcastsEpisode => 'Podcast-Episode';

  @override
  String get podcastsCompleted => 'Abgeschlossen';

  @override
  String get podcastsLoadMore => 'Weitere Episoden laden';

  @override
  String get podcastsOpen => 'Podcast öffnen';

  @override
  String get podcastsSkipBack => '15 Sekunden zurück';

  @override
  String get podcastsMarkPlayed => 'Als gehört markieren';

  @override
  String get podcastsMarkUnplayed => 'Als ungehört markieren';

  @override
  String get podcastsMarkAllPlayed => 'Alle als gehört markieren';

  @override
  String get podcastsMarkAllUnplayed => 'Alle als ungehört markieren';

  @override
  String get podcastsSort => 'Reihenfolge';

  @override
  String get podcastsNewestFirst => 'Neueste zuerst';

  @override
  String get podcastsOldestFirst => 'Älteste zuerst';

  @override
  String podcastsEpisodeStats(int count, int played) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Folgen', one: '1 Folge');
    return '$_temp0 · $played gehört';
  }

  @override
  String podcastsTimeLeft(String time) {
    return 'noch $time';
  }

  @override
  String get podcastsPlayed => 'Gehört';

  @override
  String get podcastsShowNotes => 'Shownotes';

  @override
  String get podcastsPlayEpisode => 'Folge abspielen';

  @override
  String get podcastsMore => 'Mehr';

  @override
  String get podcastsLess => 'Weniger';

  @override
  String get podcastsPlayFirstUnplayed => 'Nächste ungehörte Folge abspielen';

  @override
  String get podcastsRemoveAds => 'Eingespielte Werbung entfernen';

  @override
  String get podcastsRemoveAdsHint =>
      'Neue Folgen liegen kurz nach Erscheinen ohne eingespielte Werbespots bereit. Werbung, die die Hosts selbst sprechen, bleibt drin.';

  @override
  String podcastsAdsRemoved(String time) {
    return '$time Werbung entfernt';
  }

  @override
  String get playerPodcastLoadError => 'Die Podcast-Episode konnte nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get connectPlayOn => 'Wiedergabe auf…';

  @override
  String get connectThisDevice => 'Dieses Gerät';

  @override
  String get connectDeviceName => 'Gerätename';

  @override
  String connectPlayingOn(String device) {
    return 'Wiedergabe auf $device';
  }

  @override
  String connectAway(String device) {
    return '$device ist nicht verbunden · Play setzt hier fort';
  }

  @override
  String get connectOffline => 'Nicht verbunden';

  @override
  String get connectJamHint => 'Während eines Jams ist kein Gerätewechsel möglich.';

  @override
  String get connectMusicOnly =>
      'Nur Musik kann übertragen werden. Hörbücher, Podcasts und Radio bleiben auf diesem Gerät.';

  @override
  String get connectUnavailable => 'Gerät nicht verfügbar. Prüfe deine Verbindung.';

  @override
  String get tvFavoriteRemove => 'Aus Favoriten entfernen';

  @override
  String get tvFavoriteAdd => 'Zu Favoriten hinzufügen';

  @override
  String get tvAmbientOn => 'Ruhemodus an';

  @override
  String get tvAmbientOff => 'Ruhemodus aus';

  @override
  String get settingsTvAmbient => 'Ruhemodus';

  @override
  String get settingsTvAmbientHint => 'Bei Inaktivität nur Cover und Titel zeigen';

  @override
  String get ringtoneMenu => 'Als Klingelton verwenden';

  @override
  String get ringtoneLength => 'Länge';

  @override
  String ringtoneSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String ringtoneRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get ringtoneSuggested => 'Vorschlag: die vollste Stelle des Songs, meist der Refrain';

  @override
  String coverflowBackSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Songs', one: '1 Song');
    return '$_temp0';
  }

  @override
  String get ringtoneBackToSuggestion => 'Zurück zum Vorschlag';

  @override
  String get ringtonePreview => 'Probehören';

  @override
  String get ringtoneStopPreview => 'Probe stoppen';

  @override
  String get ringtoneTypeRingtone => 'Klingelton';

  @override
  String get ringtoneTypeNotification => 'Benachrichtigung';

  @override
  String get ringtoneTypeAlarm => 'Wecker';

  @override
  String get ringtoneApply => 'Festlegen';

  @override
  String ringtoneDone(String title, String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'notification': 'Benachrichtigungston',
      'alarm': 'Weckton',
      'other': 'Klingelton',
    });
    return '„$title“ ist jetzt dein $_temp0';
  }

  @override
  String ringtoneSaved(String title) {
    return 'Gespeichert – wähle „$title“ in den Toneinstellungen aus';
  }

  @override
  String get ringtonePermissionTitle => 'Berechtigung nötig';

  @override
  String get ringtonePermissionText =>
      'Damit Resonance den Ton direkt festlegen kann, erlaube „Systemeinstellungen ändern“. Der Song ist schon gespeichert – ohne die Berechtigung wählst du ihn selbst in den Toneinstellungen aus.';

  @override
  String get ringtonePermissionAllow => 'Erlauben';

  @override
  String get ringtonePermissionManual => 'Selbst auswählen';

  @override
  String get ringtoneUnsupported => 'Klingeltöne aus Songs brauchen Android 10 oder neuer';

  @override
  String get mediaDownload => 'Aufs Gerät laden';

  @override
  String get mediaDownloaded => 'Auf dem Gerät';

  @override
  String get mediaDownloading => 'Wird aufs Gerät geladen …';

  @override
  String get mediaRemoveTitle => 'Vom Gerät löschen?';

  @override
  String get mediaRemove => 'Vom Gerät löschen';

  @override
  String get mediaFailed => 'Download fehlgeschlagen – tippen zum Wiederholen';

  @override
  String get mediaSection => 'Podcasts, Hörbücher & E-Books';

  @override
  String get mediaSectionEpisodes => 'Heruntergeladene Folgen';

  @override
  String get mediaOfflineEmpty =>
      'Keine Folgen, Hörbücher oder E-Books auf dem Gerät. Lade sie mit dem Download-Symbol herunter, solange du online bist.';

  @override
  String get mediaOpen => 'Öffnen';

  @override
  String get mediaOpenFailed => 'Keine App zum Öffnen dieser Datei gefunden';

  @override
  String get mediaStorage => 'Podcasts, Hörbücher & E-Books';

  @override
  String mediaStorageUsed(String size, int count) {
    return '$size • $count auf dem Gerät';
  }

  @override
  String get mediaKindEpisode => 'Podcast-Folge';

  @override
  String get mediaKindEbook => 'E-Book';

  @override
  String get settingsTransitionEditor => 'Übergangs-Editor (Beta)';

  @override
  String get settingsTransitionEditorHint =>
      'Playlists bekommen einen Mix-Knopf. Damit siehst du die Übergänge zwischen den Songs mit BPM und Tonart und kannst sie selbst einstellen.';

  @override
  String get transitionAuto => 'Automatisch';

  @override
  String get transitionCrossfade => 'Überblenden';

  @override
  String get transitionFadeIn => 'Einblenden';

  @override
  String get transitionFadeOut => 'Ausblenden';

  @override
  String get transitionFilter => 'Filter';

  @override
  String transitionBars(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Takte', one: '1 Takt');
    return '$_temp0';
  }

  @override
  String get transitionPresets => 'Voreinstellungen';

  @override
  String get transitionVolume => 'Lautstärke';

  @override
  String get transitionEq => 'EQ';

  @override
  String get transitionVolumeAuto => 'Passend zu den Songs';

  @override
  String get transitionVolumeCrossfade => 'Gleichmäßig überblenden';

  @override
  String get transitionVolumeFadeIn => 'Einblenden und hart ausblenden';

  @override
  String get transitionVolumeFadeOut => 'Ausblenden, dann einblenden';

  @override
  String get transitionVolumeFilter => 'Wegfiltern und schnell einblenden';

  @override
  String get transitionEqSwap => 'Basswechsel in Übergangsmitte';

  @override
  String get transitionEqSweep => 'Vom Bass aufwärts wegfiltern';

  @override
  String get transitionReset => 'Auf Automatisch zurücksetzen';

  @override
  String get transitionPreview => 'Probehören';

  @override
  String get transitionStopPreview => 'Probehören beenden';

  @override
  String get transitionNeedsAutomix =>
      'Übergänge und Probehören brauchen AutoMix. Schalte es in den Einstellungen ein.';

  @override
  String get transitionSaved => 'Übergang gespeichert';

  @override
  String get transitionNotAnalyzed => 'Die Songs sind noch nicht analysiert. Versuch es gleich noch einmal.';

  @override
  String get transitionDragHint => 'Ziehe eine Spur, um Start oder Einsatz zu verschieben.';

  @override
  String get transitionViewOnly => 'Nur wer die Playlist bearbeiten darf, kann Übergänge ändern.';

  @override
  String get transitionEdit => 'Übergang bearbeiten';

  @override
  String get transitionMixOn => 'Mixen';

  @override
  String get transitionMixOff => 'Mixen beenden';

  @override
  String get playlistRecommended => 'Empfohlene Songs';

  @override
  String get playlistRecommendedFromPlaylist => 'Basierend auf den Songs in dieser Playlist';

  @override
  String get playlistRecommendedFromLikes => 'Basierend auf deinen Lieblingssongs';

  @override
  String get playlistNoRecommendations => 'Gerade keine Empfehlungen.';

  @override
  String get playlistRefreshRecommendations => 'Neue Vorschläge';

  @override
  String get playlistSearchSongs => 'Nach Songs suchen';

  @override
  String get playlistFindSomething => 'Lass uns etwas für deine Playlist finden';

  @override
  String get playlistSearchHint => 'Songs suchen';

  @override
  String get playlistSearchEmpty => 'Suche nach Songs, um sie direkt zur Playlist hinzuzufügen.';

  @override
  String playlistSearchNothing(Object query) {
    return 'Nichts gefunden für „$query“';
  }

  @override
  String get playlistAddSong => 'Zur Playlist hinzufügen';

  @override
  String get playlistAdded => 'Hinzugefügt';

  @override
  String playlistAddedTo(Object title) {
    return '„$title“ hinzugefügt';
  }

  @override
  String get transitionCustom => 'Benutzerdefiniert';

  @override
  String get transitionNone => 'Keine';

  @override
  String get transitionFilterLane => 'Filter';

  @override
  String get transitionEffects => 'Effekte';

  @override
  String get transitionLooping => 'Looping';

  @override
  String get transitionBeatmatching => 'Beatmatching';

  @override
  String get transitionBeatmatchingHint => 'Gleicht das Tempo der Songs an, damit die Beats übereinander liegen.';

  @override
  String get transitionEchoOut => 'Echo-Ausstieg';

  @override
  String get transitionLoopOut => 'Loop-Ausstieg';

  @override
  String get transitionCut => 'Harter Schnitt';

  @override
  String get volumeSmooth => 'Nahtlos überblenden';

  @override
  String get volumeOverlap => 'Überlappung';

  @override
  String get volumeFadeInOut => 'Einblenden und ausblenden';

  @override
  String get volumeHardInFadeOut => 'Hart einblenden und ausblenden';

  @override
  String get volumeFadeInHardOut => 'Einblenden und hart ausblenden';

  @override
  String get volumeCenterCut => 'Zentraler Schnitt';

  @override
  String get volumeCrossfade => 'Überblenden';

  @override
  String get volumeFadeInQuickOut => 'Einblenden und schnell ausblenden';

  @override
  String get volumeFadeInCutBar => 'Einblenden, hart ausblenden, 1 Takt verbleibend';

  @override
  String get volumeOverlapCutBar => 'Überlappung, hart ausblenden, 1 Takt verbleibend';

  @override
  String get eqSwapMiddle => 'Basswechsel in Übergangsmitte';

  @override
  String get eqSwapEnd => 'Basswechsel am Übergangsende';

  @override
  String get eqSwapStart => 'Basswechsel am Übergangsstart';

  @override
  String get eqThreeBand => '3-Frequenz-Überblendung';

  @override
  String get eqQuickBassCut => 'Schnelle Bassabsenkung';

  @override
  String get eqLongBassCut => 'Lange Bassabsenkung';

  @override
  String get eqBassFadeOut => 'Bass ausblenden';

  @override
  String get filterLowpassOut => 'Tiefpassfilter ausgehend';

  @override
  String get filterLowpassIn => 'Tiefpassfilter eingehend';

  @override
  String get filterLowpassInOut => 'Tiefpassfilter eingehend und ausgehend';

  @override
  String get filterLowpassInHighpassOut => 'Tiefpass eingehend, Hochpass ausgehend';

  @override
  String get filterHighpassOut => 'Hochpassfilter ausgehend';

  @override
  String get filterHighpassIn => 'Hochpassfilter eingehend';

  @override
  String get filterHighpassInOut => 'Hochpassfilter eingehend und ausgehend';

  @override
  String get filterHighpassInLowpassOut => 'Hochpass eingehend, Tiefpass ausgehend';

  @override
  String get filterHighpassHalf => 'Sanfter Hochpassfilter ausgehend';

  @override
  String get filterNoiseEnd => 'Rauschen am Übergangsende';

  @override
  String get effectFlanger => 'Flanger (nur PC)';

  @override
  String get effectPhaser => 'Phaser (nur PC)';

  @override
  String get effectGate => 'Gater auf Achteln (nur PC)';

  @override
  String get effectBeatRoll => 'Beat-Roll: 1 → 1/16 Schlag (nur PC)';

  @override
  String get transitionZoomIn => 'Heranzoomen';

  @override
  String get transitionZoomOut => 'Herauszoomen';

  @override
  String get transitionDraw => 'Kurven zeichnen';

  @override
  String get transitionBass => 'Bass';

  @override
  String get transitionDrawn => 'Von Hand gezeichnet';

  @override
  String get transitionDrawReset => 'Kurve zurücksetzen';

  @override
  String get transitionDrawHint =>
      'Klicken setzt einen Punkt, Ziehen verschiebt ihn, Rechtsklick oder langes Drücken entfernt ihn. Oben der aktuelle Song, unten der nächste.';

  @override
  String get effectBrake => 'Bremse wie am Plattenspieler (nur PC)';

  @override
  String get effectReverbMiddle => 'Hall, Song endet in der Mitte';

  @override
  String get effectReverbCut => 'Hall, Schnitt am Übergangsende';

  @override
  String get effectReverbTail => 'Hall klingt bis zum Übergangsende aus';

  @override
  String effectEchoCut(Object beat) {
    return 'Echo pro $beat Beat, Schnitt am Übergangsende';
  }

  @override
  String effectEchoTail(Object beat) {
    return 'Echo pro $beat Beat klingt bis zum Übergangsende aus';
  }

  @override
  String effectDelayCut(Object beat) {
    return 'Verzögerung pro $beat Beat, Schnitt am Übergangsende';
  }

  @override
  String loopBeats(int count) {
    return '$count-Beat-Loop';
  }

  @override
  String get transitionFxUnavailable =>
      'Effekte, Filter und Loops gehen auf diesem Gerät nicht; du hörst nur die Lautstärke.';

  @override
  String get creditsTitle => 'Mitwirkende';

  @override
  String get creditsShow => 'Mitwirkende anzeigen';

  @override
  String get creditsShowAll => 'Alle anzeigen';

  @override
  String get creditsPerformers => 'Interpretiert von';

  @override
  String get creditsWriters => 'Geschrieben von';

  @override
  String get creditsProducers => 'Produziert von';

  @override
  String get creditsEngineers => 'Technik';

  @override
  String get creditsLabel => 'Label';

  @override
  String creditsSources(Object sources) {
    return 'Quelle: $sources';
  }

  @override
  String get creditsSourceTags => 'Dateiinfos';

  @override
  String get creditRoleArtist => 'Künstler';

  @override
  String get creditRoleFeatured => 'Gastkünstler';

  @override
  String get creditRoleComposer => 'Komposition';

  @override
  String get creditRoleLyricist => 'Text';

  @override
  String get creditRoleWriter => 'Songwriter';

  @override
  String get creditRoleArranger => 'Arrangement';

  @override
  String get creditRoleProducer => 'Produktion';

  @override
  String get creditRoleCoProducer => 'Co-Produktion';

  @override
  String get creditRoleExecutiveProducer => 'Executive Producer';

  @override
  String get creditRoleMix => 'Mixing';

  @override
  String get creditRoleMastering => 'Mastering';

  @override
  String get creditRoleRecording => 'Aufnahme';

  @override
  String get creditRoleEngineer => 'Toningenieur';

  @override
  String get creditRoleProgramming => 'Programmierung';

  @override
  String get creditRoleVocals => 'Gesang';

  @override
  String get creditRoleBackgroundVocals => 'Hintergrundgesang';

  @override
  String get creditRolePerformer => 'Musiker';

  @override
  String get libraryCreate => 'Erstellen';

  @override
  String get blendCreate => 'Blend';

  @override
  String get blendKind => 'Blend';

  @override
  String get blendPickUser => 'Blend mit …';

  @override
  String get blendHint =>
      'Eine gemeinsame Playlist aus eurem Geschmack, jeden Tag neu. Ihr seht sie beide unter „Für dich“.';

  @override
  String get blendNoUsers => 'Auf diesem Server gibt es niemanden, mit dem du einen Blend machen kannst.';

  @override
  String blendWaiting(Object name) {
    return 'Blend mit $name erstellt. Sobald ihr beide etwas gehört oder geliked habt, erscheint er unter „Für dich“.';
  }

  @override
  String get blendLeave => 'Blend verlassen';

  @override
  String blendLeaveConfirm(Object name) {
    return 'Der Blend mit $name wird für euch beide gelöscht.';
  }

  @override
  String get releaseRadar => 'Neuerscheinungen';

  @override
  String get adminReleaseRadarHint =>
      'Jeden Freitag neue Songs der meistgehörten Künstler jedes Nutzers, fehlende werden heruntergeladen';

  @override
  String get adminReleaseRadarSize => 'Songs in den Neuerscheinungen (10–100)';

  @override
  String get wrappedSettingsTitle => 'Jahresrückblick';

  @override
  String get wrappedSettingsHint => 'Deine meistgehörten Songs, Künstler und Genres des Jahres';

  @override
  String wrappedBannerTitle(Object year) {
    return 'Dein $year in Musik';
  }

  @override
  String get wrappedBannerText => 'Dein Jahresrückblick ist da – sieh dir an, was du gehört hast.';

  @override
  String wrappedEmpty(Object year) {
    return 'Für $year gibt es noch keine Wiedergaben.';
  }

  @override
  String wrappedYearButton(Object year) {
    return 'Rückblick $year ansehen';
  }

  @override
  String get wrappedIntroKicker => 'Dein Jahresrückblick';

  @override
  String wrappedIntroTitle(Object year) {
    return 'Dein $year in Musik';
  }

  @override
  String get wrappedIntroHint => 'Tippe rechts für weiter, links für zurück. Halte gedrückt zum Anhalten.';

  @override
  String get wrappedMinutesBefore => 'Dieses Jahr hast du';

  @override
  String get wrappedMinutesAfter => 'Minuten Musik gehört.';

  @override
  String wrappedMinutesDays(Object days) {
    return 'Das sind $days Tage am Stück.';
  }

  @override
  String wrappedTopDay(Object day, Object minutes) {
    return 'Am meisten am $day: $minutes Minuten an einem Tag.';
  }

  @override
  String get wrappedGenresTitle => 'Deine Top-Genres';

  @override
  String get wrappedTopArtistKicker => 'Dein Künstler des Jahres';

  @override
  String wrappedArtistStats(Object minutes, Object plays) {
    return '$plays Wiedergaben · $minutes Minuten';
  }

  @override
  String get wrappedTopArtistsTitle => 'Deine Top-Künstler';

  @override
  String wrappedPlays(Object plays) {
    return '$plays Wiedergaben';
  }

  @override
  String get wrappedTopSongKicker => 'Dein Song des Jahres';

  @override
  String wrappedSongStats(Object plays) {
    return '$plays-mal gehört';
  }

  @override
  String get wrappedPlay => 'Abspielen';

  @override
  String get wrappedTopSongsTitle => 'Deine Top-Songs';

  @override
  String get wrappedClockKicker => 'Du hörst am liebsten';

  @override
  String get wrappedMorning => 'morgens';

  @override
  String get wrappedAfternoon => 'tagsüber';

  @override
  String get wrappedEvening => 'abends';

  @override
  String get wrappedNight => 'nachts';

  @override
  String wrappedPeakHour(Object time) {
    return 'Die meiste Musik lief um $time Uhr.';
  }

  @override
  String wrappedBestMonth(Object month) {
    return 'Dein stärkster Monat: $month';
  }

  @override
  String get wrappedVarietyKicker => 'Du warst neugierig';

  @override
  String get wrappedDifferentSongs => 'verschiedene Songs';

  @override
  String get wrappedDifferentArtists => 'verschiedene Künstler';

  @override
  String wrappedNewArtists(Object count) {
    return '$count davon hast du dieses Jahr zum ersten Mal gehört.';
  }

  @override
  String get wrappedFirstSong => 'Dein erster Song des Jahres';

  @override
  String wrappedSummaryTitle(Object year) {
    return 'Dein $year';
  }

  @override
  String get wrappedMinutesLabel => 'Minuten gehört';

  @override
  String get wrappedTopGenreLabel => 'Top-Genre';

  @override
  String get wrappedSavePlaylist => 'Top-Songs als Playlist';

  @override
  String get wrappedOpenPlaylist => 'Playlist öffnen';

  @override
  String get wrappedUpdatePlaylist => 'Aktualisieren';

  @override
  String get wrappedReplay => 'Nochmal';

  @override
  String wrappedPlaylistName(Object year) {
    return 'Deine Top-Songs $year';
  }

  @override
  String wrappedPlaylistDescription(Object year) {
    return 'Deine 100 meistgehörten Songs $year';
  }
}
