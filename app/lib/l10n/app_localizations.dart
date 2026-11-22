import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en')];

  /// No description provided for @settingsPlayback.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe'**
  String get settingsPlayback;

  /// No description provided for @commonProductName.
  ///
  /// In de, this message translates to:
  /// **'Resonance'**
  String get commonProductName;

  /// No description provided for @errorInvalidInput.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Eingabe'**
  String get errorInvalidInput;

  /// No description provided for @errorServerUnreachable.
  ///
  /// In de, this message translates to:
  /// **'Server nicht erreichbar'**
  String get errorServerUnreachable;

  /// No description provided for @errorHttpStatus.
  ///
  /// In de, this message translates to:
  /// **'Fehler {statusCode}'**
  String errorHttpStatus(String statusCode);

  /// No description provided for @catalogSingle.
  ///
  /// In de, this message translates to:
  /// **'Single'**
  String get catalogSingle;

  /// No description provided for @catalogCompilation.
  ///
  /// In de, this message translates to:
  /// **'Compilation'**
  String get catalogCompilation;

  /// No description provided for @commonAlbum.
  ///
  /// In de, this message translates to:
  /// **'Album'**
  String get commonAlbum;

  /// No description provided for @commonUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get commonUnknown;

  /// No description provided for @playerMusicLoadError.
  ///
  /// In de, this message translates to:
  /// **'Die Musik konnte nicht geladen werden. Bitte erneut versuchen.'**
  String get playerMusicLoadError;

  /// No description provided for @playerAudiobookLoadError.
  ///
  /// In de, this message translates to:
  /// **'Das Hörbuch konnte nicht geladen werden. Bitte erneut versuchen.'**
  String get playerAudiobookLoadError;

  /// No description provided for @playerBookPart.
  ///
  /// In de, this message translates to:
  /// **'Teil {part} von {total}'**
  String playerBookPart(int part, int total);

  /// No description provided for @navHome.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In de, this message translates to:
  /// **'Suche'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek'**
  String get navLibrary;

  /// No description provided for @navAudiobooks.
  ///
  /// In de, this message translates to:
  /// **'Hörbücher'**
  String get navAudiobooks;

  /// No description provided for @navMedia.
  ///
  /// In de, this message translates to:
  /// **'Mediathek'**
  String get navMedia;

  /// No description provided for @navAdmin.
  ///
  /// In de, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navDownloads.
  ///
  /// In de, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @adminDashboard.
  ///
  /// In de, this message translates to:
  /// **'Admin-Dashboard'**
  String get adminDashboard;

  /// No description provided for @libraryCreatePlaylist.
  ///
  /// In de, this message translates to:
  /// **'Playlist erstellen'**
  String get libraryCreatePlaylist;

  /// No description provided for @libraryNewPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Neue Playlist'**
  String get libraryNewPlaylist;

  /// No description provided for @playlistCollaborative.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Playlist'**
  String get playlistCollaborative;

  /// No description provided for @playlistCollaborativeHint.
  ///
  /// In de, this message translates to:
  /// **'Alle, mit denen du sie teilst, können Songs hinzufügen, verschieben und entfernen.'**
  String get playlistCollaborativeHint;

  /// No description provided for @playlistAddedBy.
  ///
  /// In de, this message translates to:
  /// **'von {name}'**
  String playlistAddedBy(String name);

  /// No description provided for @commonName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @libraryLikedSongs.
  ///
  /// In de, this message translates to:
  /// **'Lieblingssongs'**
  String get libraryLikedSongs;

  /// No description provided for @commonPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Playlist'**
  String get commonPlaylist;

  /// No description provided for @libraryPlaylistBy.
  ///
  /// In de, this message translates to:
  /// **'Playlist • {name}'**
  String libraryPlaylistBy(String name);

  /// No description provided for @navSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// No description provided for @searchHint.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du hören?'**
  String get searchHint;

  /// No description provided for @searchNoLibraryResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer für „{query}“ in deiner Bibliothek.'**
  String searchNoLibraryResults(String query);

  /// No description provided for @searchInLyrics.
  ///
  /// In de, this message translates to:
  /// **'In Songtexten'**
  String get searchInLyrics;

  /// No description provided for @searchLyricsLine.
  ///
  /// In de, this message translates to:
  /// **'„{line}“'**
  String searchLyricsLine(String line);

  /// No description provided for @tvKeyboardSpace.
  ///
  /// In de, this message translates to:
  /// **'Leerzeichen'**
  String get tvKeyboardSpace;

  /// No description provided for @tvKeyboardDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get tvKeyboardDelete;

  /// No description provided for @tvKeyboardClear.
  ///
  /// In de, this message translates to:
  /// **'Leeren'**
  String get tvKeyboardClear;

  /// No description provided for @tvKeyboardSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get tvKeyboardSearch;

  /// No description provided for @tvSearchAvailableAlbums.
  ///
  /// In de, this message translates to:
  /// **'Zum Herunterladen: Alben'**
  String get tvSearchAvailableAlbums;

  /// No description provided for @tvSearchAvailableSongs.
  ///
  /// In de, this message translates to:
  /// **'Zum Herunterladen: Songs'**
  String get tvSearchAvailableSongs;

  /// No description provided for @tvCatalogRequestBy.
  ///
  /// In de, this message translates to:
  /// **'Von {artist}'**
  String tvCatalogRequestBy(String artist);

  /// No description provided for @commonSongsTitle.
  ///
  /// In de, this message translates to:
  /// **'Songs'**
  String get commonSongsTitle;

  /// No description provided for @commonArtist.
  ///
  /// In de, this message translates to:
  /// **'Künstler'**
  String get commonArtist;

  /// No description provided for @commonAlbums.
  ///
  /// In de, this message translates to:
  /// **'Alben'**
  String get commonAlbums;

  /// No description provided for @libraryAllArtists.
  ///
  /// In de, this message translates to:
  /// **'Alle Künstler'**
  String get libraryAllArtists;

  /// No description provided for @libraryTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Bibliothek'**
  String get libraryTitle;

  /// No description provided for @libraryPlaylists.
  ///
  /// In de, this message translates to:
  /// **'Playlists'**
  String get libraryPlaylists;

  /// No description provided for @librarySavedAlbums.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Alben'**
  String get librarySavedAlbums;

  /// No description provided for @libraryAllAlbums.
  ///
  /// In de, this message translates to:
  /// **'Alle Alben'**
  String get libraryAllAlbums;

  /// No description provided for @libraryLoadingSongs.
  ///
  /// In de, this message translates to:
  /// **'… Songs'**
  String get libraryLoadingSongs;

  /// No description provided for @libraryNoAlbums.
  ///
  /// In de, this message translates to:
  /// **'Keine Alben'**
  String get libraryNoAlbums;

  /// No description provided for @librarySaveAlbumsHint.
  ///
  /// In de, this message translates to:
  /// **'Speichere Alben mit ⊕, um sie hier zu sehen.'**
  String get librarySaveAlbumsHint;

  /// No description provided for @commonDiscNumber.
  ///
  /// In de, this message translates to:
  /// **'CD {number}'**
  String commonDiscNumber(int number);

  /// No description provided for @libraryRemoveAlbum.
  ///
  /// In de, this message translates to:
  /// **'Aus Bibliothek entfernen'**
  String get libraryRemoveAlbum;

  /// No description provided for @librarySaveAlbum.
  ///
  /// In de, this message translates to:
  /// **'In Bibliothek speichern'**
  String get librarySaveAlbum;

  /// No description provided for @playerAddToPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Zur Playlist hinzufügen'**
  String get playerAddToPlaylist;

  /// No description provided for @editorCorrectAlbum.
  ///
  /// In de, this message translates to:
  /// **'Album korrigieren'**
  String get editorCorrectAlbum;

  /// No description provided for @editorMatchAlbum.
  ///
  /// In de, this message translates to:
  /// **'Album zuordnen'**
  String get editorMatchAlbum;

  /// No description provided for @editorChangeCover.
  ///
  /// In de, this message translates to:
  /// **'Cover ändern'**
  String get editorChangeCover;

  /// No description provided for @artistLibraryAlbums.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, other{{count} Alben in deiner Bibliothek}}'**
  String artistLibraryAlbums(int count);

  /// No description provided for @artistPopular.
  ///
  /// In de, this message translates to:
  /// **'Beliebt'**
  String get artistPopular;

  /// No description provided for @artistDiscography.
  ///
  /// In de, this message translates to:
  /// **'Diskografie'**
  String get artistDiscography;

  /// No description provided for @libraryPublicPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Öffentliche Playlist'**
  String get libraryPublicPlaylist;

  /// No description provided for @libraryRenamePlaylist.
  ///
  /// In de, this message translates to:
  /// **'Playlist umbenennen'**
  String get libraryRenamePlaylist;

  /// No description provided for @commonRename.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get commonRename;

  /// No description provided for @libraryMakePrivate.
  ///
  /// In de, this message translates to:
  /// **'Privat machen'**
  String get libraryMakePrivate;

  /// No description provided for @librarySharePlaylist.
  ///
  /// In de, this message translates to:
  /// **'Für alle Nutzer freigeben'**
  String get librarySharePlaylist;

  /// No description provided for @commonDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// No description provided for @libraryEmptyPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Songs. Füge welche über das ⋯-Menü eines Songs hinzu.'**
  String get libraryEmptyPlaylist;

  /// No description provided for @libraryRemoveFromPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Aus dieser Playlist entfernen'**
  String get libraryRemoveFromPlaylist;

  /// No description provided for @homeGreetingNight.
  ///
  /// In de, this message translates to:
  /// **'Gute Nacht'**
  String get homeGreetingNight;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In de, this message translates to:
  /// **'Guten Tag'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend'**
  String get homeGreetingEvening;

  /// No description provided for @homeRecentlyPlayed.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gehört'**
  String get homeRecentlyPlayed;

  /// No description provided for @homeYourPlaylists.
  ///
  /// In de, this message translates to:
  /// **'Deine Playlists'**
  String get homeYourPlaylists;

  /// No description provided for @homeRecentlyAdded.
  ///
  /// In de, this message translates to:
  /// **'Neu in der Bibliothek'**
  String get homeRecentlyAdded;

  /// No description provided for @homeEmptyLibrary.
  ///
  /// In de, this message translates to:
  /// **'Deine Bibliothek ist noch leer.\nEin Admin kann im Dashboard einen Bibliotheks-Scan starten.'**
  String get homeEmptyLibrary;

  /// No description provided for @settingsAutoplay.
  ///
  /// In de, this message translates to:
  /// **'Autoplay'**
  String get settingsAutoplay;

  /// No description provided for @settingsAutoplayHint.
  ///
  /// In de, this message translates to:
  /// **'Wenn die Warteschlange endet, ähnliche Songs weiterspielen'**
  String get settingsAutoplayHint;

  /// No description provided for @playerAutoplaySection.
  ///
  /// In de, this message translates to:
  /// **'Autoplay – ähnliche Songs'**
  String get playerAutoplaySection;

  /// No description provided for @playerSmartShuffle.
  ///
  /// In de, this message translates to:
  /// **'Smart Shuffle'**
  String get playerSmartShuffle;

  /// No description provided for @playerShuffleOff.
  ///
  /// In de, this message translates to:
  /// **'Zufallswiedergabe aus'**
  String get playerShuffleOff;

  /// No description provided for @playerNothingPlaying.
  ///
  /// In de, this message translates to:
  /// **'Gerade läuft nichts'**
  String get playerNothingPlaying;

  /// No description provided for @playerQueue.
  ///
  /// In de, this message translates to:
  /// **'Warteschlange'**
  String get playerQueue;

  /// No description provided for @audiobooksBook.
  ///
  /// In de, this message translates to:
  /// **'Hörbuch'**
  String get audiobooksBook;

  /// No description provided for @playerGoToAudiobook.
  ///
  /// In de, this message translates to:
  /// **'Zum Hörbuch'**
  String get playerGoToAudiobook;

  /// No description provided for @audiobooksChapters.
  ///
  /// In de, this message translates to:
  /// **'Kapitel'**
  String get audiobooksChapters;

  /// No description provided for @playerEmptyQueue.
  ///
  /// In de, this message translates to:
  /// **'Die Warteschlange ist leer'**
  String get playerEmptyQueue;

  /// No description provided for @playerNowPlaying.
  ///
  /// In de, this message translates to:
  /// **'Läuft gerade'**
  String get playerNowPlaying;

  /// No description provided for @playerNextUp.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes'**
  String get playerNextUp;

  /// No description provided for @playerRemoveFromQueue.
  ///
  /// In de, this message translates to:
  /// **'Aus Warteschlange entfernen'**
  String get playerRemoveFromQueue;

  /// No description provided for @playerMoveInQueue.
  ///
  /// In de, this message translates to:
  /// **'Verschieben'**
  String get playerMoveInQueue;

  /// No description provided for @playerNextInQueue.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes in der Warteschlange'**
  String get playerNextInQueue;

  /// No description provided for @playerLater.
  ///
  /// In de, this message translates to:
  /// **'Danach'**
  String get playerLater;

  /// No description provided for @settingsAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get settingsAccount;

  /// No description provided for @settingsAdministratorSuffix.
  ///
  /// In de, this message translates to:
  /// **' • Administrator'**
  String get settingsAdministratorSuffix;

  /// No description provided for @settingsDisplayName.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename'**
  String get settingsDisplayName;

  /// No description provided for @settingsChangePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort ändern'**
  String get settingsChangePassword;

  /// No description provided for @settingsResetCode.
  ///
  /// In de, this message translates to:
  /// **'Code für neues Passwort'**
  String get settingsResetCode;

  /// No description provided for @settingsResetCodeHint.
  ///
  /// In de, this message translates to:
  /// **'Für ein anderes Gerät, wenn du dein Passwort vergessen hast'**
  String get settingsResetCodeHint;

  /// No description provided for @settingsResetCodeBody.
  ///
  /// In de, this message translates to:
  /// **'Gib diesen Code dort bei „Passwort vergessen?“ ein. Er gilt {minutes} Minuten und nur, bis das Passwort geändert ist.'**
  String settingsResetCodeBody(int minutes);

  /// No description provided for @authForgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get authForgotPassword;

  /// No description provided for @authResetTitle.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort setzen'**
  String get authResetTitle;

  /// No description provided for @authResetHint.
  ///
  /// In de, this message translates to:
  /// **'Öffne Resonance auf einem Gerät, auf dem du noch angemeldet bist: Einstellungen → „Code für neues Passwort“. Ohne angemeldetes Gerät kann ein Admin dir ein neues Passwort setzen.'**
  String get authResetHint;

  /// No description provided for @authResetCode.
  ///
  /// In de, this message translates to:
  /// **'Code'**
  String get authResetCode;

  /// No description provided for @authResetSubmit.
  ///
  /// In de, this message translates to:
  /// **'Passwort setzen'**
  String get authResetSubmit;

  /// No description provided for @settingsAppearance.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get settingsAppearance;

  /// No description provided for @settingsMediaTabs.
  ///
  /// In de, this message translates to:
  /// **'Medien-Tabs'**
  String get settingsMediaTabs;

  /// No description provided for @settingsEbooks.
  ///
  /// In de, this message translates to:
  /// **'E-Books'**
  String get settingsEbooks;

  /// No description provided for @settingsShowInMenu.
  ///
  /// In de, this message translates to:
  /// **'Im Menü anzeigen'**
  String get settingsShowInMenu;

  /// No description provided for @settingsAccentColor.
  ///
  /// In de, this message translates to:
  /// **'Akzentfarbe'**
  String get settingsAccentColor;

  /// No description provided for @settingsCustomColor.
  ///
  /// In de, this message translates to:
  /// **'Eigene Farbe'**
  String get settingsCustomColor;

  /// No description provided for @commonCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonApply.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get commonApply;

  /// No description provided for @settingsNormalizeVolume.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke angleichen'**
  String get settingsNormalizeVolume;

  /// No description provided for @settingsNormalizeVolumeHint.
  ///
  /// In de, this message translates to:
  /// **'Nutzt ReplayGain, damit alle Songs ähnlich laut sind'**
  String get settingsNormalizeVolumeHint;

  /// No description provided for @settingsSignedInDevices.
  ///
  /// In de, this message translates to:
  /// **'Angemeldete Geräte'**
  String get settingsSignedInDevices;

  /// No description provided for @settingsUnknownDevice.
  ///
  /// In de, this message translates to:
  /// **'Unbekanntes Gerät'**
  String get settingsUnknownDevice;

  /// No description provided for @settingsCurrentDeviceSuffix.
  ///
  /// In de, this message translates to:
  /// **' (dieses Gerät)'**
  String get settingsCurrentDeviceSuffix;

  /// No description provided for @settingsLastActive.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt aktiv: {date}'**
  String settingsLastActive(String date);

  /// No description provided for @commonSignOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get commonSignOut;

  /// No description provided for @settingsCurrentPassword.
  ///
  /// In de, this message translates to:
  /// **'Aktuelles Passwort'**
  String get settingsCurrentPassword;

  /// No description provided for @settingsNewPassword.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort'**
  String get settingsNewPassword;

  /// No description provided for @commonChange.
  ///
  /// In de, this message translates to:
  /// **'Ändern'**
  String get commonChange;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In de, this message translates to:
  /// **'Passwort geändert'**
  String get settingsPasswordChanged;

  /// No description provided for @catalogDiscoverMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr entdecken'**
  String get catalogDiscoverMore;

  /// No description provided for @catalogDownloadHint.
  ///
  /// In de, this message translates to:
  /// **'Was noch nicht in der Bibliothek ist, kannst du hier herunterladen.'**
  String get catalogDownloadHint;

  /// No description provided for @catalogNoResults.
  ///
  /// In de, this message translates to:
  /// **'Auch im Katalog nichts gefunden.'**
  String get catalogNoResults;

  /// No description provided for @catalogAllInLibrary.
  ///
  /// In de, this message translates to:
  /// **'Komplett in der Bibliothek'**
  String get catalogAllInLibrary;

  /// No description provided for @catalogLibraryCount.
  ///
  /// In de, this message translates to:
  /// **'{count} von {total} in der Bibliothek'**
  String catalogLibraryCount(int count, int total);

  /// No description provided for @catalogDownloadAlbum.
  ///
  /// In de, this message translates to:
  /// **'Album herunterladen'**
  String get catalogDownloadAlbum;

  /// No description provided for @catalogDownloadMissingSong.
  ///
  /// In de, this message translates to:
  /// **'Fehlenden Song herunterladen'**
  String get catalogDownloadMissingSong;

  /// No description provided for @catalogDownloadMissingSongs.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, other{Fehlende {count} Songs herunterladen}}'**
  String catalogDownloadMissingSongs(int count);

  /// No description provided for @catalogOpenInLibrary.
  ///
  /// In de, this message translates to:
  /// **'In Bibliothek öffnen'**
  String get catalogOpenInLibrary;

  /// No description provided for @catalogEps.
  ///
  /// In de, this message translates to:
  /// **'EPs'**
  String get catalogEps;

  /// No description provided for @catalogSingles.
  ///
  /// In de, this message translates to:
  /// **'Singles'**
  String get catalogSingles;

  /// No description provided for @catalogArtistReleases.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, other{{count} Veröffentlichungen • {inLibrary} in der Bibliothek}}'**
  String catalogArtistReleases(int count, int inLibrary);

  /// No description provided for @downloadsMine.
  ///
  /// In de, this message translates to:
  /// **'Meine'**
  String get downloadsMine;

  /// No description provided for @downloadsAllUsers.
  ///
  /// In de, this message translates to:
  /// **'Alle Nutzer'**
  String get downloadsAllUsers;

  /// No description provided for @downloadsOpen.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get downloadsOpen;

  /// No description provided for @downloadsCompleted.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get downloadsCompleted;

  /// No description provided for @downloadsEmptyActive.
  ///
  /// In de, this message translates to:
  /// **'Keine laufenden Downloads.\nSuche nach Musik und tippe auf ⤓.'**
  String get downloadsEmptyActive;

  /// No description provided for @downloadsEmptyCompleted.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts heruntergeladen.'**
  String get downloadsEmptyCompleted;

  /// No description provided for @downloadsFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagen'**
  String get downloadsFailed;

  /// No description provided for @downloadsEmptyFailed.
  ///
  /// In de, this message translates to:
  /// **'Keine fehlgeschlagenen Downloads.'**
  String get downloadsEmptyFailed;

  /// No description provided for @downloadsRetryAll.
  ///
  /// In de, this message translates to:
  /// **'Alle erneut versuchen'**
  String get downloadsRetryAll;

  /// No description provided for @downloadsRetryAllConfirm.
  ///
  /// In de, this message translates to:
  /// **'Alle fehlgeschlagenen Songs in dieser Liste werden noch einmal gesucht und heruntergeladen. Bei sehr vielen Songs kann YouTube zwischendurch pausieren.'**
  String get downloadsRetryAllConfirm;

  /// No description provided for @downloadsRetryAllDone.
  ///
  /// In de, this message translates to:
  /// **'{songs} Songs aus {requests} Anfragen werden erneut versucht'**
  String downloadsRetryAllDone(int songs, int requests);

  /// No description provided for @downloadsCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Anfrage} other{{count} Anfragen}}'**
  String downloadsCount(int count);

  /// No description provided for @downloadsLoadMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr laden ({shown} von {total})'**
  String downloadsLoadMore(int shown, int total);

  /// No description provided for @commonSong.
  ///
  /// In de, this message translates to:
  /// **'Song'**
  String get commonSong;

  /// No description provided for @downloadsRequestedBySuffix.
  ///
  /// In de, this message translates to:
  /// **'von {name}'**
  String downloadsRequestedBySuffix(String name);

  /// No description provided for @downloadsReject.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get downloadsReject;

  /// No description provided for @downloadsApprove.
  ///
  /// In de, this message translates to:
  /// **'Freigeben'**
  String get downloadsApprove;

  /// No description provided for @downloadsRejectRequest.
  ///
  /// In de, this message translates to:
  /// **'Anfrage ablehnen'**
  String get downloadsRejectRequest;

  /// No description provided for @downloadsReasonOptional.
  ///
  /// In de, this message translates to:
  /// **'Begründung (optional)'**
  String get downloadsReasonOptional;

  /// No description provided for @downloadsDownload.
  ///
  /// In de, this message translates to:
  /// **'Download'**
  String get downloadsDownload;

  /// No description provided for @downloadsProgress.
  ///
  /// In de, this message translates to:
  /// **'{status} • {done}/{total} fertig{failed}'**
  String downloadsProgress(String status, int done, int total, String failed);

  /// No description provided for @downloadsFailedSuffix.
  ///
  /// In de, this message translates to:
  /// **' • {count} fehlgeschlagen'**
  String downloadsFailedSuffix(int count);

  /// No description provided for @downloadsRequestedBy.
  ///
  /// In de, this message translates to:
  /// **'Angefragt von {name}'**
  String downloadsRequestedBy(String name);

  /// No description provided for @downloadsReason.
  ///
  /// In de, this message translates to:
  /// **'Begründung: {reason}'**
  String downloadsReason(String reason);

  /// No description provided for @downloadsRetryFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagene erneut versuchen'**
  String get downloadsRetryFailed;

  /// No description provided for @downloadsOwnSource.
  ///
  /// In de, this message translates to:
  /// **'Eigenen Link angeben'**
  String get downloadsOwnSource;

  /// No description provided for @downloadsCopyTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel und Interpret kopieren'**
  String get downloadsCopyTitle;

  /// No description provided for @downloadsCopied.
  ///
  /// In de, this message translates to:
  /// **'„{text}“ kopiert'**
  String downloadsCopied(String text);

  /// No description provided for @downloadsOwnSourceLabel.
  ///
  /// In de, this message translates to:
  /// **'YouTube-, SoundCloud- oder Bandcamp-Link'**
  String get downloadsOwnSourceLabel;

  /// No description provided for @downloadsOwnSourceHint.
  ///
  /// In de, this message translates to:
  /// **'Auch normale YouTube-Videos – geladen wird nur die Tonspur.'**
  String get downloadsOwnSourceHint;

  /// No description provided for @downloadsDeleteEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen'**
  String get downloadsDeleteEntry;

  /// No description provided for @catalogYouTubeMusic.
  ///
  /// In de, this message translates to:
  /// **'YouTube Music'**
  String get catalogYouTubeMusic;

  /// No description provided for @downloadsTorrent.
  ///
  /// In de, this message translates to:
  /// **'Torrent'**
  String get downloadsTorrent;

  /// No description provided for @downloadsSearchingTorrent.
  ///
  /// In de, this message translates to:
  /// **'Suche Torrent …'**
  String get downloadsSearchingTorrent;

  /// No description provided for @downloadsTorrentProgress.
  ///
  /// In de, this message translates to:
  /// **'Torrent: {name} ({progress} %)'**
  String downloadsTorrentProgress(String name, int progress);

  /// No description provided for @downloadsImportingTorrent.
  ///
  /// In de, this message translates to:
  /// **'Torrent wird importiert …'**
  String get downloadsImportingTorrent;

  /// No description provided for @downloadsTorrentName.
  ///
  /// In de, this message translates to:
  /// **'Torrent: {name}'**
  String downloadsTorrentName(String name);

  /// No description provided for @downloadsTorrentFallback.
  ///
  /// In de, this message translates to:
  /// **'Kein Torrent – lade über YouTube Music{error}'**
  String downloadsTorrentFallback(String error);

  /// No description provided for @commonDurationHoursMinutes.
  ///
  /// In de, this message translates to:
  /// **'{hours} Std. {minutes} Min.'**
  String commonDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @commonDurationMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min.'**
  String commonDurationMinutes(int minutes);

  /// No description provided for @audiobooksFinished.
  ///
  /// In de, this message translates to:
  /// **'Beendet'**
  String get audiobooksFinished;

  /// No description provided for @audiobooksTimeRemaining.
  ///
  /// In de, this message translates to:
  /// **'Noch {duration}'**
  String audiobooksTimeRemaining(String duration);

  /// No description provided for @statsUnitHours.
  ///
  /// In de, this message translates to:
  /// **'Std.'**
  String get statsUnitHours;

  /// No description provided for @statsUnitMinutes.
  ///
  /// In de, this message translates to:
  /// **'Min.'**
  String get statsUnitMinutes;

  /// No description provided for @statsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Statistik'**
  String get statsTitle;

  /// No description provided for @statsTotal.
  ///
  /// In de, this message translates to:
  /// **'Gesamte Hörzeit'**
  String get statsTotal;

  /// No description provided for @statsDaysOfAudio.
  ///
  /// In de, this message translates to:
  /// **'Das sind {days} Tage Audio'**
  String statsDaysOfAudio(String days);

  /// No description provided for @statsToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get statsToday;

  /// No description provided for @statsThisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In de, this message translates to:
  /// **'Dieser Monat'**
  String get statsThisMonth;

  /// No description provided for @statsActivity.
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get statsActivity;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Serie'**
  String get statsCurrentStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In de, this message translates to:
  /// **'Längste Serie'**
  String get statsBestStreak;

  /// No description provided for @statsDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String statsDays(int count);

  /// No description provided for @statsBooksFinished.
  ///
  /// In de, this message translates to:
  /// **'Bücher gehört'**
  String get statsBooksFinished;

  /// No description provided for @statsBooksThisYear.
  ///
  /// In de, this message translates to:
  /// **'Bücher dieses Jahr'**
  String get statsBooksThisYear;

  /// No description provided for @statsDaysActive.
  ///
  /// In de, this message translates to:
  /// **'Aktive Tage'**
  String get statsDaysActive;

  /// No description provided for @statsDailyAverage.
  ///
  /// In de, this message translates to:
  /// **'Ø pro aktivem Tag'**
  String get statsDailyAverage;

  /// No description provided for @statsLast7Days.
  ///
  /// In de, this message translates to:
  /// **'Letzte 7 Tage'**
  String get statsLast7Days;

  /// No description provided for @statsMostListened.
  ///
  /// In de, this message translates to:
  /// **'Am meisten gehört'**
  String get statsMostListened;

  /// No description provided for @statsHoursMinutesShort.
  ///
  /// In de, this message translates to:
  /// **'{hours} Std. {minutes} Min.'**
  String statsHoursMinutesShort(int hours, int minutes);

  /// No description provided for @statsMinutesShort.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min.'**
  String statsMinutesShort(int minutes);

  /// No description provided for @statsTeaser.
  ///
  /// In de, this message translates to:
  /// **'{time} gehört · {books} Bücher fertig'**
  String statsTeaser(String time, int books);

  /// No description provided for @mediaContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiterhören'**
  String get mediaContinue;

  /// No description provided for @mediaLatest.
  ///
  /// In de, this message translates to:
  /// **'Neueste Folgen'**
  String get mediaLatest;

  /// No description provided for @audiobooksChapterOf.
  ///
  /// In de, this message translates to:
  /// **'Kapitel {index} von {count}'**
  String audiobooksChapterOf(int index, int count);

  /// No description provided for @audiobooksPreviousChapter.
  ///
  /// In de, this message translates to:
  /// **'Vorheriges Kapitel'**
  String get audiobooksPreviousChapter;

  /// No description provided for @audiobooksNextChapter.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Kapitel'**
  String get audiobooksNextChapter;

  /// No description provided for @playerSpeedShort.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get playerSpeedShort;

  /// No description provided for @playerSleepShort.
  ///
  /// In de, this message translates to:
  /// **'Timer'**
  String get playerSleepShort;

  /// No description provided for @playerAtSpeed.
  ///
  /// In de, this message translates to:
  /// **'bei {speed}'**
  String playerAtSpeed(String speed);

  /// No description provided for @audiobooksNotConfigured.
  ///
  /// In de, this message translates to:
  /// **'Hörbücher sind auf diesem Server nicht eingerichtet.'**
  String get audiobooksNotConfigured;

  /// No description provided for @audiobooksLoginTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit Audiobookshelf verbinden'**
  String get audiobooksLoginTitle;

  /// No description provided for @audiobooksLoginHint.
  ///
  /// In de, this message translates to:
  /// **'Melde dich mit deinem Audiobookshelf-Konto an{address}. Dein Hörfortschritt bleibt mit allen Audiobookshelf-Apps synchron.'**
  String audiobooksLoginHint(String address);

  /// No description provided for @authUsername.
  ///
  /// In de, this message translates to:
  /// **'Benutzername'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get authSignIn;

  /// No description provided for @audiobooksNoLibrary.
  ///
  /// In de, this message translates to:
  /// **'Keine Hörbuch-Bibliothek gefunden'**
  String get audiobooksNoLibrary;

  /// No description provided for @audiobooksSignOutUser.
  ///
  /// In de, this message translates to:
  /// **'Abmelden ({name})'**
  String audiobooksSignOutUser(String name);

  /// No description provided for @audiobooksSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Titel, Autor oder Serie suchen'**
  String get audiobooksSearchHint;

  /// No description provided for @audiobooksContinueListening.
  ///
  /// In de, this message translates to:
  /// **'Weiterhören'**
  String get audiobooksContinueListening;

  /// No description provided for @audiobooksResume.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get audiobooksResume;

  /// No description provided for @audiobooksAllBooks.
  ///
  /// In de, this message translates to:
  /// **'Alle Hörbücher'**
  String get audiobooksAllBooks;

  /// No description provided for @commonNothingFound.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get commonNothingFound;

  /// No description provided for @audiobooksNarrator.
  ///
  /// In de, this message translates to:
  /// **'gelesen von {name}'**
  String audiobooksNarrator(String name);

  /// No description provided for @audiobooksStartOver.
  ///
  /// In de, this message translates to:
  /// **'Von vorn beginnen'**
  String get audiobooksStartOver;

  /// No description provided for @audiobooksMarkUnfinished.
  ///
  /// In de, this message translates to:
  /// **'Als nicht beendet markieren'**
  String get audiobooksMarkUnfinished;

  /// No description provided for @audiobooksMarkFinished.
  ///
  /// In de, this message translates to:
  /// **'Als beendet markieren'**
  String get audiobooksMarkFinished;

  /// No description provided for @authCheckAddress.
  ///
  /// In de, this message translates to:
  /// **'{error}\nIst die Adresse richtig?'**
  String authCheckAddress(String error);

  /// No description provided for @authConnectTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit Server verbinden'**
  String get authConnectTitle;

  /// No description provided for @authServerAddress.
  ///
  /// In de, this message translates to:
  /// **'Server-Adresse'**
  String get authServerAddress;

  /// No description provided for @authConnect.
  ///
  /// In de, this message translates to:
  /// **'Verbinden'**
  String get authConnect;

  /// No description provided for @commonRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get commonRetry;

  /// No description provided for @authOtherServer.
  ///
  /// In de, this message translates to:
  /// **'Anderer Server'**
  String get authOtherServer;

  /// No description provided for @authSignInTo.
  ///
  /// In de, this message translates to:
  /// **'Bei {name} anmelden'**
  String authSignInTo(String name);

  /// No description provided for @authCreateAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get authCreateAccount;

  /// No description provided for @authServer.
  ///
  /// In de, this message translates to:
  /// **'Server: {address}'**
  String authServer(String address);

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In de, this message translates to:
  /// **'Passwörter stimmen nicht überein'**
  String get authPasswordsMismatch;

  /// No description provided for @authInvalidInvite.
  ///
  /// In de, this message translates to:
  /// **'Einladung ungültig'**
  String get authInvalidInvite;

  /// No description provided for @authInvalidInviteHint.
  ///
  /// In de, this message translates to:
  /// **'Dieser Einladungslink wurde bereits benutzt oder ist abgelaufen. Bitte frag einen Admin nach einem neuen Link.'**
  String get authInvalidInviteHint;

  /// No description provided for @authBackToLogin.
  ///
  /// In de, this message translates to:
  /// **'Zur Anmeldung'**
  String get authBackToLogin;

  /// No description provided for @authWelcomeAdmin.
  ///
  /// In de, this message translates to:
  /// **'Willkommen! Admin-Konto anlegen'**
  String get authWelcomeAdmin;

  /// No description provided for @authFirstAccountHint.
  ///
  /// In de, this message translates to:
  /// **'Das erste Konto auf diesem Server wird automatisch Administrator.'**
  String get authFirstAccountHint;

  /// No description provided for @authPasswordMinimum.
  ///
  /// In de, this message translates to:
  /// **'Passwort (min. 8 Zeichen)'**
  String get authPasswordMinimum;

  /// No description provided for @authRepeatPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort wiederholen'**
  String get authRepeatPassword;

  /// No description provided for @authRegister.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get authRegister;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In de, this message translates to:
  /// **'Ich habe schon ein Konto'**
  String get authAlreadyHaveAccount;

  /// No description provided for @catalogAwaitingApproval.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ wartet auf Freigabe durch einen Admin'**
  String catalogAwaitingApproval(String title);

  /// No description provided for @catalogAlreadyInLibrary.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ ist schon in deiner Bibliothek'**
  String catalogAlreadyInLibrary(String title);

  /// No description provided for @catalogDownloadingTitle.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ wird heruntergeladen'**
  String catalogDownloadingTitle(String title);

  /// No description provided for @catalogInYourLibrary.
  ///
  /// In de, this message translates to:
  /// **'In deiner Bibliothek'**
  String get catalogInYourLibrary;

  /// No description provided for @catalogRequested.
  ///
  /// In de, this message translates to:
  /// **'Angefragt'**
  String get catalogRequested;

  /// No description provided for @catalogDownload.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen'**
  String get catalogDownload;

  /// No description provided for @catalogInLibrary.
  ///
  /// In de, this message translates to:
  /// **'In Bibliothek'**
  String get catalogInLibrary;

  /// No description provided for @catalogPlaylistKind.
  ///
  /// In de, this message translates to:
  /// **'Playlist'**
  String get catalogPlaylistKind;

  /// No description provided for @catalogPlaylistImport.
  ///
  /// In de, this message translates to:
  /// **'Importieren und fehlende Songs laden'**
  String get catalogPlaylistImport;

  /// No description provided for @catalogPlaylistUpdate.
  ///
  /// In de, this message translates to:
  /// **'Erneut importieren'**
  String get catalogPlaylistUpdate;

  /// No description provided for @catalogPlaylistShowImport.
  ///
  /// In de, this message translates to:
  /// **'Ansehen'**
  String get catalogPlaylistShowImport;

  /// No description provided for @catalogPlaylistImportHint.
  ///
  /// In de, this message translates to:
  /// **'Legt die Playlist in deiner Bibliothek an; fehlende Songs werden heruntergeladen und rücken nach.'**
  String get catalogPlaylistImportHint;

  /// No description provided for @catalogSpotifyPreviewLimit.
  ///
  /// In de, this message translates to:
  /// **'Spotify gibt bei fremden Playlists nur die ersten 100 Songs heraus.'**
  String get catalogSpotifyPreviewLimit;

  /// No description provided for @downloadsStatusPendingApproval.
  ///
  /// In de, this message translates to:
  /// **'Wartet auf Freigabe'**
  String get downloadsStatusPendingApproval;

  /// No description provided for @downloadsStatusRunning.
  ///
  /// In de, this message translates to:
  /// **'Läuft'**
  String get downloadsStatusRunning;

  /// No description provided for @commonDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get commonDone;

  /// No description provided for @commonUndo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get commonUndo;

  /// No description provided for @playlistSort.
  ///
  /// In de, this message translates to:
  /// **'Sortieren'**
  String get playlistSort;

  /// No description provided for @playlistSortHint.
  ///
  /// In de, this message translates to:
  /// **'Ändert die Reihenfolge der Playlist für alle'**
  String get playlistSortHint;

  /// No description provided for @playlistSorted.
  ///
  /// In de, this message translates to:
  /// **'Playlist neu sortiert'**
  String get playlistSorted;

  /// No description provided for @playlistReorder.
  ///
  /// In de, this message translates to:
  /// **'Reihenfolge von Hand ändern'**
  String get playlistReorder;

  /// No description provided for @playlistSetPeak.
  ///
  /// In de, this message translates to:
  /// **'Als DJ-Set: aufwärmen, Höhepunkt, ausklingen'**
  String get playlistSetPeak;

  /// No description provided for @playlistSetRise.
  ///
  /// In de, this message translates to:
  /// **'Als DJ-Set: immer energiegeladener'**
  String get playlistSetRise;

  /// No description provided for @playlistSetDown.
  ///
  /// In de, this message translates to:
  /// **'Als DJ-Set: immer ruhiger'**
  String get playlistSetDown;

  /// No description provided for @playlistSetFlow.
  ///
  /// In de, this message translates to:
  /// **'Als DJ-Set: gleichmäßiger Fluss'**
  String get playlistSetFlow;

  /// No description provided for @playlistSortTitle.
  ///
  /// In de, this message translates to:
  /// **'Nach Titel'**
  String get playlistSortTitle;

  /// No description provided for @playlistSortArtist.
  ///
  /// In de, this message translates to:
  /// **'Nach Künstler'**
  String get playlistSortArtist;

  /// No description provided for @playlistSortAlbum.
  ///
  /// In de, this message translates to:
  /// **'Nach Album'**
  String get playlistSortAlbum;

  /// No description provided for @playlistSortLength.
  ///
  /// In de, this message translates to:
  /// **'Nach Länge'**
  String get playlistSortLength;

  /// No description provided for @playlistSortReverse.
  ///
  /// In de, this message translates to:
  /// **'Umdrehen'**
  String get playlistSortReverse;

  /// No description provided for @downloadsStatusPartial.
  ///
  /// In de, this message translates to:
  /// **'Teilweise fertig'**
  String get downloadsStatusPartial;

  /// No description provided for @downloadsStatusFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagen'**
  String get downloadsStatusFailed;

  /// No description provided for @downloadsStatusRejected.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get downloadsStatusRejected;

  /// No description provided for @downloadsStatusCancelled.
  ///
  /// In de, this message translates to:
  /// **'Abgebrochen'**
  String get downloadsStatusCancelled;

  /// No description provided for @downloadsStatusQueued.
  ///
  /// In de, this message translates to:
  /// **'In Warteschlange'**
  String get downloadsStatusQueued;

  /// No description provided for @downloadsStatusSearching.
  ///
  /// In de, this message translates to:
  /// **'Suche Quelle …'**
  String get downloadsStatusSearching;

  /// No description provided for @downloadsStatusDownloading.
  ///
  /// In de, this message translates to:
  /// **'Lädt herunter'**
  String get downloadsStatusDownloading;

  /// No description provided for @downloadsStatusProcessing.
  ///
  /// In de, this message translates to:
  /// **'Wird getaggt …'**
  String get downloadsStatusProcessing;

  /// No description provided for @downloadsStatusExisting.
  ///
  /// In de, this message translates to:
  /// **'Schon vorhanden'**
  String get downloadsStatusExisting;

  /// No description provided for @playerShuffle.
  ///
  /// In de, this message translates to:
  /// **'Zufallswiedergabe'**
  String get playerShuffle;

  /// No description provided for @playerRemoveLiked.
  ///
  /// In de, this message translates to:
  /// **'Aus Lieblingssongs entfernen'**
  String get playerRemoveLiked;

  /// No description provided for @playerAddLiked.
  ///
  /// In de, this message translates to:
  /// **'Zu Lieblingssongs hinzufügen'**
  String get playerAddLiked;

  /// No description provided for @playerPlayNext.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes spielen'**
  String get playerPlayNext;

  /// No description provided for @playerAddToQueue.
  ///
  /// In de, this message translates to:
  /// **'Zur Warteschlange hinzufügen'**
  String get playerAddToQueue;

  /// No description provided for @playerGoToAlbum.
  ///
  /// In de, this message translates to:
  /// **'Zum Album'**
  String get playerGoToAlbum;

  /// No description provided for @playerGoToArtist.
  ///
  /// In de, this message translates to:
  /// **'Zum Künstler'**
  String get playerGoToArtist;

  /// No description provided for @editorCorrectMetadata.
  ///
  /// In de, this message translates to:
  /// **'Metadaten korrigieren'**
  String get editorCorrectMetadata;

  /// No description provided for @commonSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// No description provided for @playerSkipBack.
  ///
  /// In de, this message translates to:
  /// **'30 Sekunden zurück'**
  String get playerSkipBack;

  /// No description provided for @playerSkipForward.
  ///
  /// In de, this message translates to:
  /// **'30 Sekunden vor'**
  String get playerSkipForward;

  /// No description provided for @playerPrevious.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get playerPrevious;

  /// No description provided for @playerNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get playerNext;

  /// No description provided for @playerRepeat.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen'**
  String get playerRepeat;

  /// No description provided for @playerSpeed.
  ///
  /// In de, this message translates to:
  /// **'Geschwindigkeit'**
  String get playerSpeed;

  /// No description provided for @playerSleepTimer.
  ///
  /// In de, this message translates to:
  /// **'Sleep-Timer'**
  String get playerSleepTimer;

  /// No description provided for @playerSleepTimerTime.
  ///
  /// In de, this message translates to:
  /// **'Sleep-Timer: pausiert um {time}'**
  String playerSleepTimerTime(String time);

  /// No description provided for @playerTimerMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes, plural, other{{minutes} Minuten}}'**
  String playerTimerMinutes(int minutes);

  /// No description provided for @playerDisableTimer.
  ///
  /// In de, this message translates to:
  /// **'Timer ausschalten'**
  String get playerDisableTimer;

  /// No description provided for @playerFullscreen.
  ///
  /// In de, this message translates to:
  /// **'Vollbild'**
  String get playerFullscreen;

  /// No description provided for @commonDurationMinutesSeconds.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min. {seconds} Sek.'**
  String commonDurationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @updateAllowInstall.
  ///
  /// In de, this message translates to:
  /// **'Bitte erlaube Resonance in den Android-Einstellungen, Apps zu installieren.'**
  String get updateAllowInstall;

  /// No description provided for @updateFailedCode.
  ///
  /// In de, this message translates to:
  /// **'Update fehlgeschlagen ({code}). Bitte erneut versuchen.'**
  String updateFailedCode(String code);

  /// No description provided for @updateFailedMessage.
  ///
  /// In de, this message translates to:
  /// **'Update fehlgeschlagen: {error}'**
  String updateFailedMessage(String error);

  /// No description provided for @updateInProgress.
  ///
  /// In de, this message translates to:
  /// **'App wird aktualisiert'**
  String get updateInProgress;

  /// No description provided for @updateDownloadStarting.
  ///
  /// In de, this message translates to:
  /// **'Download startet …'**
  String get updateDownloadStarting;

  /// No description provided for @updateDownloadProgress.
  ///
  /// In de, this message translates to:
  /// **'Download {percent} %'**
  String updateDownloadProgress(int percent);

  /// No description provided for @commonClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get commonClose;

  /// No description provided for @mixExport.
  ///
  /// In de, this message translates to:
  /// **'Mix als MP3 exportieren'**
  String get mixExport;

  /// No description provided for @mixExportRendering.
  ///
  /// In de, this message translates to:
  /// **'Der Server mischt die Übergänge … {percent} %'**
  String mixExportRendering(int percent);

  /// No description provided for @mixExportBackground.
  ///
  /// In de, this message translates to:
  /// **'Im Hintergrund weiter'**
  String get mixExportBackground;

  /// No description provided for @mixExportFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Mix konnte nicht erstellt werden'**
  String get mixExportFailed;

  /// No description provided for @mixExportSaving.
  ///
  /// In de, this message translates to:
  /// **'Mix wird gespeichert …'**
  String get mixExportSaving;

  /// No description provided for @mixExportSaved.
  ///
  /// In de, this message translates to:
  /// **'Mix gespeichert: {target}'**
  String mixExportSaved(String target);

  /// No description provided for @updateAvailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Neue App-Version {version} verfügbar'**
  String updateAvailableTitle(String version);

  /// No description provided for @updateInstall.
  ///
  /// In de, this message translates to:
  /// **'Installieren'**
  String get updateInstall;

  /// No description provided for @updateInstalledVersion.
  ///
  /// In de, this message translates to:
  /// **'App-Version {version}'**
  String updateInstalledVersion(String version);

  /// No description provided for @updateAvailableVersion.
  ///
  /// In de, this message translates to:
  /// **'Version {version} ist verfügbar'**
  String updateAvailableVersion(String version);

  /// No description provided for @updateCurrent.
  ///
  /// In de, this message translates to:
  /// **'Aktuell'**
  String get updateCurrent;

  /// No description provided for @updateAction.
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get updateAction;

  /// No description provided for @updateCheck.
  ///
  /// In de, this message translates to:
  /// **'Nach Updates suchen'**
  String get updateCheck;

  /// No description provided for @updateAlreadyCurrent.
  ///
  /// In de, this message translates to:
  /// **'Die App ist aktuell'**
  String get updateAlreadyCurrent;

  /// No description provided for @adminImportCleanupTitle.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek aufräumen?'**
  String get adminImportCleanupTitle;

  /// No description provided for @adminImportCleanupHint.
  ///
  /// In de, this message translates to:
  /// **'Alle Songs der Bibliothek werden per Audio-Fingerabdruck erkannt, neu getaggt, mit Cover versehen und nach „Künstler/Album (Jahr)/Nr - Titel“ umbenannt. Die Dateien werden dabei direkt verändert.\n\nLikes, Playlists und Verlauf bleiben erhalten. Bei großen Bibliotheken dauert das mehrere Stunden.'**
  String get adminImportCleanupHint;

  /// No description provided for @adminImportCleanupConfirm.
  ///
  /// In de, this message translates to:
  /// **'Aufräumen'**
  String get adminImportCleanupConfirm;

  /// No description provided for @adminImportFolder.
  ///
  /// In de, this message translates to:
  /// **'Import-Ordner'**
  String get adminImportFolder;

  /// No description provided for @adminImportPendingFiles.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, other{{count} Audiodateien warten • Modus: {mode}}}'**
  String adminImportPendingFiles(int count, String mode);

  /// No description provided for @adminImportCopyHint.
  ///
  /// In de, this message translates to:
  /// **'Kopieren (Originale bleiben unverändert)'**
  String get adminImportCopyHint;

  /// No description provided for @adminImportMove.
  ///
  /// In de, this message translates to:
  /// **'Verschieben'**
  String get adminImportMove;

  /// No description provided for @adminImportAcoustIdHint.
  ///
  /// In de, this message translates to:
  /// **'Kein AcoustID-Schlüssel eingetragen – Songs werden nur über ihre vorhandenen Tags erkannt. Einen kostenlosen Schlüssel gibt es auf acoustid.org/new-application; eintragen unter „Server“.'**
  String get adminImportAcoustIdHint;

  /// No description provided for @adminImportStart.
  ///
  /// In de, this message translates to:
  /// **'Import starten'**
  String get adminImportStart;

  /// No description provided for @adminImportCleanup.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek aufräumen'**
  String get adminImportCleanup;

  /// No description provided for @adminImportHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get adminImportHistory;

  /// No description provided for @adminImportEmptyHistory.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Import gelaufen.'**
  String get adminImportEmptyHistory;

  /// No description provided for @adminImportWaiting.
  ///
  /// In de, this message translates to:
  /// **'Wartet'**
  String get adminImportWaiting;

  /// No description provided for @adminImportBatchTitle.
  ///
  /// In de, this message translates to:
  /// **'Import ({mode})'**
  String adminImportBatchTitle(String mode);

  /// No description provided for @adminImportFileProgress.
  ///
  /// In de, this message translates to:
  /// **'{total, plural, other{{count} von {total} Dateien}}'**
  String adminImportFileProgress(int count, int total);

  /// No description provided for @adminImportIdentified.
  ///
  /// In de, this message translates to:
  /// **'Erkannt'**
  String get adminImportIdentified;

  /// No description provided for @adminImportImported.
  ///
  /// In de, this message translates to:
  /// **'Importiert'**
  String get adminImportImported;

  /// No description provided for @adminImportDuplicates.
  ///
  /// In de, this message translates to:
  /// **'Duplikate'**
  String get adminImportDuplicates;

  /// No description provided for @adminImportUnidentified.
  ///
  /// In de, this message translates to:
  /// **'Nicht erkannt'**
  String get adminImportUnidentified;

  /// No description provided for @adminImportErrors.
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get adminImportErrors;

  /// No description provided for @adminImportMethodAlbumFingerprint.
  ///
  /// In de, this message translates to:
  /// **'Erkannt per Fingerabdruck (komplettes Album)'**
  String get adminImportMethodAlbumFingerprint;

  /// No description provided for @adminImportMethodTrackFingerprint.
  ///
  /// In de, this message translates to:
  /// **'Erkannt per Fingerabdruck (einzelner Song)'**
  String get adminImportMethodTrackFingerprint;

  /// No description provided for @adminImportMethodTags.
  ///
  /// In de, this message translates to:
  /// **'Erkannt über vorhandene Tags (Katalog)'**
  String get adminImportMethodTags;

  /// No description provided for @adminImportMethodUnidentified.
  ///
  /// In de, this message translates to:
  /// **'Nicht erkannt – vorhandene Tags übernommen'**
  String get adminImportMethodUnidentified;

  /// No description provided for @adminTabOverview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get adminTabOverview;

  /// No description provided for @adminTabUsers.
  ///
  /// In de, this message translates to:
  /// **'Benutzer'**
  String get adminTabUsers;

  /// No description provided for @adminTabInvites.
  ///
  /// In de, this message translates to:
  /// **'Einladungen'**
  String get adminTabInvites;

  /// No description provided for @adminTabImport.
  ///
  /// In de, this message translates to:
  /// **'Import'**
  String get adminTabImport;

  /// No description provided for @adminTabReview.
  ///
  /// In de, this message translates to:
  /// **'Zu prüfen'**
  String get adminTabReview;

  /// No description provided for @adminTabServer.
  ///
  /// In de, this message translates to:
  /// **'Server'**
  String get adminTabServer;

  /// No description provided for @adminStorage.
  ///
  /// In de, this message translates to:
  /// **'Speicher'**
  String get adminStorage;

  /// No description provided for @adminPlaytime.
  ///
  /// In de, this message translates to:
  /// **'Spielzeit'**
  String get adminPlaytime;

  /// No description provided for @adminMixAnalysis.
  ///
  /// In de, this message translates to:
  /// **'AutoMix-Analyse'**
  String get adminMixAnalysis;

  /// No description provided for @adminVocalAnalysis.
  ///
  /// In de, this message translates to:
  /// **'Gesangserkennung für AutoMix'**
  String get adminVocalAnalysis;

  /// No description provided for @adminVocalAnalysisHint.
  ///
  /// In de, this message translates to:
  /// **'Trennt Anfang und Ende jedes Songs in Stimme und Musik (Demucs), damit sich bei Übergängen keine Stimmen überlagern. Beim Einschalten wird einmalig etwa 1 GB heruntergeladen; jeder Song braucht dann rund eine Minute Rechenzeit im Hintergrund, die ganze Bibliothek mehrere Tage. Oft gehörte Songs kommen zuerst dran.'**
  String get adminVocalAnalysisHint;

  /// No description provided for @adminVocalAnalysisInstalling.
  ///
  /// In de, this message translates to:
  /// **'Gesangserkennung wird eingerichtet (etwa 1 GB) …'**
  String get adminVocalAnalysisInstalling;

  /// No description provided for @adminVocalAnalysisFailed.
  ///
  /// In de, this message translates to:
  /// **'Einrichtung der Gesangserkennung fehlgeschlagen, neuer Versuch in einer Stunde: {message}'**
  String adminVocalAnalysisFailed(String message);

  /// No description provided for @adminVocalAnalysisProgress.
  ///
  /// In de, this message translates to:
  /// **'Gesangserkennung: {analyzed} von {total} Songs'**
  String adminVocalAnalysisProgress(String analyzed, String total);

  /// No description provided for @adminLyrics.
  ///
  /// In de, this message translates to:
  /// **'Songtexte'**
  String get adminLyrics;

  /// No description provided for @adminLyricsProgress.
  ///
  /// In de, this message translates to:
  /// **'{synced} mit synchronisiertem Text, {plainOnly} nur Text, {none} ohne · {pending} noch offen'**
  String adminLyricsProgress(String synced, String plainOnly, String none, String pending);

  /// No description provided for @adminLyricsBackgroundFetch.
  ///
  /// In de, this message translates to:
  /// **'Songtexte im Hintergrund laden'**
  String get adminLyricsBackgroundFetch;

  /// No description provided for @adminMixAnalysisProgress.
  ///
  /// In de, this message translates to:
  /// **'{analyzed} von {total} Songs analysiert'**
  String adminMixAnalysisProgress(String analyzed, String total);

  /// No description provided for @adminMixAnalysisDone.
  ///
  /// In de, this message translates to:
  /// **'Alle {total} Songs analysiert'**
  String adminMixAnalysisDone(String total);

  /// No description provided for @adminMixAnalysisFailed.
  ///
  /// In de, this message translates to:
  /// **', {failed} fehlgeschlagen'**
  String adminMixAnalysisFailed(String failed);

  /// No description provided for @commonDurationHours.
  ///
  /// In de, this message translates to:
  /// **'{hours} Std.'**
  String commonDurationHours(String hours);

  /// No description provided for @adminScanHint.
  ///
  /// In de, this message translates to:
  /// **'Der schnelle Scan liest nur neue und geänderte Dateien ein. Der vollständige Scan liest alle Tags und Cover neu.'**
  String get adminScanHint;

  /// No description provided for @adminQuickScan.
  ///
  /// In de, this message translates to:
  /// **'Schneller Scan'**
  String get adminQuickScan;

  /// No description provided for @adminFullScan.
  ///
  /// In de, this message translates to:
  /// **'Vollständiger Scan'**
  String get adminFullScan;

  /// No description provided for @adminJobs.
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get adminJobs;

  /// No description provided for @adminNoJobs.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Aufgaben'**
  String get adminNoJobs;

  /// No description provided for @adminLibraryScan.
  ///
  /// In de, this message translates to:
  /// **'Bibliotheks-Scan'**
  String get adminLibraryScan;

  /// No description provided for @adminUserYouSuffix.
  ///
  /// In de, this message translates to:
  /// **' (du)'**
  String get adminUserYouSuffix;

  /// No description provided for @adminUserDisabledSuffix.
  ///
  /// In de, this message translates to:
  /// **' • deaktiviert'**
  String get adminUserDisabledSuffix;

  /// No description provided for @adminUserLastSeenSuffix.
  ///
  /// In de, this message translates to:
  /// **' • zuletzt {date}'**
  String adminUserLastSeenSuffix(String date);

  /// No description provided for @adminNewPasswordFor.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort für {name}'**
  String adminNewPasswordFor(String name);

  /// No description provided for @adminPasswordSet.
  ///
  /// In de, this message translates to:
  /// **'Passwort gesetzt, alle Geräte abgemeldet'**
  String get adminPasswordSet;

  /// No description provided for @adminDeleteUserTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} löschen?'**
  String adminDeleteUserTitle(String name);

  /// No description provided for @adminDeleteUserHint.
  ///
  /// In de, this message translates to:
  /// **'Playlists und Verlauf werden ebenfalls gelöscht.'**
  String get adminDeleteUserHint;

  /// No description provided for @adminRemoveAdmin.
  ///
  /// In de, this message translates to:
  /// **'Admin-Rechte entziehen'**
  String get adminRemoveAdmin;

  /// No description provided for @adminMakeAdmin.
  ///
  /// In de, this message translates to:
  /// **'Zum Admin machen'**
  String get adminMakeAdmin;

  /// No description provided for @adminEnableUser.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren'**
  String get adminEnableUser;

  /// No description provided for @adminDisableUser.
  ///
  /// In de, this message translates to:
  /// **'Deaktivieren'**
  String get adminDisableUser;

  /// No description provided for @adminResetPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort zurücksetzen'**
  String get adminResetPassword;

  /// No description provided for @adminPasswordMinimum.
  ///
  /// In de, this message translates to:
  /// **'Min. 8 Zeichen'**
  String get adminPasswordMinimum;

  /// No description provided for @adminCreateInviteTitle.
  ///
  /// In de, this message translates to:
  /// **'Einladungslink erstellen'**
  String get adminCreateInviteTitle;

  /// No description provided for @adminInviteNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz (z. B. für wen)'**
  String get adminInviteNote;

  /// No description provided for @adminInviteValidity.
  ///
  /// In de, this message translates to:
  /// **'Gültig für'**
  String get adminInviteValidity;

  /// No description provided for @adminInviteOneDay.
  ///
  /// In de, this message translates to:
  /// **'1 Tag'**
  String get adminInviteOneDay;

  /// No description provided for @adminInviteThreeDays.
  ///
  /// In de, this message translates to:
  /// **'3 Tage'**
  String get adminInviteThreeDays;

  /// No description provided for @adminInviteSevenDays.
  ///
  /// In de, this message translates to:
  /// **'7 Tage'**
  String get adminInviteSevenDays;

  /// No description provided for @adminInviteThirtyDays.
  ///
  /// In de, this message translates to:
  /// **'30 Tage'**
  String get adminInviteThirtyDays;

  /// No description provided for @adminInviteUnlimited.
  ///
  /// In de, this message translates to:
  /// **'Unbegrenzt'**
  String get adminInviteUnlimited;

  /// No description provided for @adminInviteAsAdmin.
  ///
  /// In de, this message translates to:
  /// **'Als Admin registrieren'**
  String get adminInviteAsAdmin;

  /// No description provided for @commonCreate.
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get commonCreate;

  /// No description provided for @adminInviteLink.
  ///
  /// In de, this message translates to:
  /// **'Einladungslink'**
  String get adminInviteLink;

  /// No description provided for @adminInviteLinkHint.
  ///
  /// In de, this message translates to:
  /// **'Der Link kann genau einmal benutzt werden. Er wird nur jetzt angezeigt.'**
  String get adminInviteLinkHint;

  /// No description provided for @adminLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert'**
  String get adminLinkCopied;

  /// No description provided for @commonCopy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get commonCopy;

  /// No description provided for @adminNewInvite.
  ///
  /// In de, this message translates to:
  /// **'Neuer Link'**
  String get adminNewInvite;

  /// No description provided for @adminNoInvites.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einladungen.\nErstelle einen Link, um jemanden einzuladen.'**
  String get adminNoInvites;

  /// No description provided for @adminInvitation.
  ///
  /// In de, this message translates to:
  /// **'Einladung'**
  String get adminInvitation;

  /// No description provided for @adminInviteUsed.
  ///
  /// In de, this message translates to:
  /// **'Benutzt von {name} am {date}'**
  String adminInviteUsed(String name, String date);

  /// No description provided for @adminInviteExpired.
  ///
  /// In de, this message translates to:
  /// **'Abgelaufen'**
  String get adminInviteExpired;

  /// No description provided for @adminInviteOpen.
  ///
  /// In de, this message translates to:
  /// **'Offen • {expiry}{role}'**
  String adminInviteOpen(String expiry, String role);

  /// No description provided for @adminInviteNoExpiry.
  ///
  /// In de, this message translates to:
  /// **'läuft nicht ab'**
  String get adminInviteNoExpiry;

  /// No description provided for @adminInviteExpires.
  ///
  /// In de, this message translates to:
  /// **'gültig bis {date}'**
  String adminInviteExpires(String date);

  /// No description provided for @adminInviteAdminSuffix.
  ///
  /// In de, this message translates to:
  /// **' • Admin'**
  String get adminInviteAdminSuffix;

  /// No description provided for @adminServerName.
  ///
  /// In de, this message translates to:
  /// **'Servername'**
  String get adminServerName;

  /// No description provided for @adminRegistration.
  ///
  /// In de, this message translates to:
  /// **'Registrierung'**
  String get adminRegistration;

  /// No description provided for @adminRegistrationInviteOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur mit Einladungslink'**
  String get adminRegistrationInviteOnly;

  /// No description provided for @adminRegistrationInviteHint.
  ///
  /// In de, this message translates to:
  /// **'Admins erstellen einmalig nutzbare Links (empfohlen)'**
  String get adminRegistrationInviteHint;

  /// No description provided for @adminRegistrationPublic.
  ///
  /// In de, this message translates to:
  /// **'Öffentliche Registrierung'**
  String get adminRegistrationPublic;

  /// No description provided for @adminRegistrationPublicHint.
  ///
  /// In de, this message translates to:
  /// **'Jeder, der den Server erreicht, kann ein Konto anlegen'**
  String get adminRegistrationPublicHint;

  /// No description provided for @adminLibraryImport.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek & Import'**
  String get adminLibraryImport;

  /// No description provided for @adminAcoustIdKey.
  ///
  /// In de, this message translates to:
  /// **'AcoustID-Schlüssel'**
  String get adminAcoustIdKey;

  /// No description provided for @adminAcoustIdNotSet.
  ///
  /// In de, this message translates to:
  /// **'Nicht gesetzt – kostenlos auf acoustid.org/new-application'**
  String get adminAcoustIdNotSet;

  /// No description provided for @adminConfigured.
  ///
  /// In de, this message translates to:
  /// **'Gesetzt'**
  String get adminConfigured;

  /// No description provided for @adminAcoustIdHint.
  ///
  /// In de, this message translates to:
  /// **'Für die Erkennung per Audio-Fingerabdruck'**
  String get adminAcoustIdHint;

  /// No description provided for @adminMoveImportedFiles.
  ///
  /// In de, this message translates to:
  /// **'Importierte Dateien verschieben'**
  String get adminMoveImportedFiles;

  /// No description provided for @adminMoveImportedFilesHint.
  ///
  /// In de, this message translates to:
  /// **'Der Import-Ordner wird danach geleert'**
  String get adminMoveImportedFilesHint;

  /// No description provided for @adminCopyImportedFiles.
  ///
  /// In de, this message translates to:
  /// **'Importierte Dateien kopieren'**
  String get adminCopyImportedFiles;

  /// No description provided for @adminCopyImportedFilesHint.
  ///
  /// In de, this message translates to:
  /// **'Originale bleiben unverändert im Import-Ordner'**
  String get adminCopyImportedFilesHint;

  /// No description provided for @adminImportUnidentifiedFiles.
  ///
  /// In de, this message translates to:
  /// **'Nicht erkannte Dateien trotzdem importieren'**
  String get adminImportUnidentifiedFiles;

  /// No description provided for @adminImportUnidentifiedFilesHint.
  ///
  /// In de, this message translates to:
  /// **'Mit ihren vorhandenen Tags; sonst bleiben sie im Import-Ordner liegen'**
  String get adminImportUnidentifiedFilesHint;

  /// No description provided for @adminAutoImport.
  ///
  /// In de, this message translates to:
  /// **'Import-Ordner automatisch importieren'**
  String get adminAutoImport;

  /// No description provided for @adminAutoImportHint.
  ///
  /// In de, this message translates to:
  /// **'Prüft alle 5 Minuten auf neue Dateien (nur im Modus „Verschieben“)'**
  String get adminAutoImportHint;

  /// No description provided for @adminSongRadio.
  ///
  /// In de, this message translates to:
  /// **'Song-Radio'**
  String get adminSongRadio;

  /// No description provided for @adminRadioAutoDownload.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Songs automatisch herunterladen'**
  String get adminRadioAutoDownload;

  /// No description provided for @adminRadioAutoDownloadHint.
  ///
  /// In de, this message translates to:
  /// **'Ähnliche Songs, die noch nicht in der Bibliothek sind, landen in der Download-Warteschlange'**
  String get adminRadioAutoDownloadHint;

  /// No description provided for @adminRadioTemporary.
  ///
  /// In de, this message translates to:
  /// **'Radio-Downloads sind temporär'**
  String get adminRadioTemporary;

  /// No description provided for @adminRadioTemporaryHint.
  ///
  /// In de, this message translates to:
  /// **'{days, plural, other{Werden nach {days} Tagen gelöscht, außer jemand liked sie oder fügt sie einer Playlist hinzu}}'**
  String adminRadioTemporaryHint(int days);

  /// No description provided for @adminRadioRetention.
  ///
  /// In de, this message translates to:
  /// **'Aufbewahrung temporärer Songs (Tage)'**
  String get adminRadioRetention;

  /// No description provided for @adminEnableAudiobookshelf.
  ///
  /// In de, this message translates to:
  /// **'Audiobookshelf einbinden'**
  String get adminEnableAudiobookshelf;

  /// No description provided for @adminEnableAudiobookshelfHint.
  ///
  /// In de, this message translates to:
  /// **'Zeigt den Tab „Hörbücher“. Jeder Benutzer meldet sich dort mit seinem eigenen Audiobookshelf-Konto an.'**
  String get adminEnableAudiobookshelfHint;

  /// No description provided for @adminAudiobookshelfAddress.
  ///
  /// In de, this message translates to:
  /// **'Audiobookshelf-Adresse'**
  String get adminAudiobookshelfAddress;

  /// No description provided for @adminAudiobookshelfAddressHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. https://audio.example.com – auch für externe Apps gedacht'**
  String get adminAudiobookshelfAddressHint;

  /// No description provided for @adminAlbumTorrents.
  ///
  /// In de, this message translates to:
  /// **'Torrents für Alben'**
  String get adminAlbumTorrents;

  /// No description provided for @adminAlbumTorrentsHint.
  ///
  /// In de, this message translates to:
  /// **'Sucht Alben zuerst über Prowlarr (öffentliche Tracker) und lädt sie mit qBittorrent über das VPN. Was dort fehlt, kommt von YouTube Music.'**
  String get adminAlbumTorrentsHint;

  /// No description provided for @adminProwlarrApiKey.
  ///
  /// In de, this message translates to:
  /// **'Prowlarr-API-Schlüssel'**
  String get adminProwlarrApiKey;

  /// No description provided for @adminProwlarrApiKeyHint.
  ///
  /// In de, this message translates to:
  /// **'Prowlarr → Settings → General → API Key'**
  String get adminProwlarrApiKeyHint;

  /// No description provided for @adminQbittorrentUsername.
  ///
  /// In de, this message translates to:
  /// **'qBittorrent-Benutzer'**
  String get adminQbittorrentUsername;

  /// No description provided for @adminQbittorrentPassword.
  ///
  /// In de, this message translates to:
  /// **'qBittorrent-Passwort'**
  String get adminQbittorrentPassword;

  /// No description provided for @adminMinimumSeeders.
  ///
  /// In de, this message translates to:
  /// **'Mindestanzahl Seeder'**
  String get adminMinimumSeeders;

  /// No description provided for @adminTorrentTimeout.
  ///
  /// In de, this message translates to:
  /// **'Aufgeben nach … Minuten ohne Fortschritt'**
  String get adminTorrentTimeout;

  /// No description provided for @adminTorrentSeedDays.
  ///
  /// In de, this message translates to:
  /// **'Torrents behalten für … Tage'**
  String get adminTorrentSeedDays;

  /// No description provided for @adminTorrentSeedDaysHint.
  ///
  /// In de, this message translates to:
  /// **'Danach werden fertige Torrents samt Dateien aus qBittorrent gelöscht (die Songs in der Bibliothek bleiben). Von qBittorrent gestoppte Torrents werden sofort gelöscht. 0 = direkt nach dem Import.'**
  String get adminTorrentSeedDaysHint;

  /// No description provided for @adminYouTubeSource.
  ///
  /// In de, this message translates to:
  /// **'YouTube Music als Quelle'**
  String get adminYouTubeSource;

  /// No description provided for @adminYouTubeSourceHint.
  ///
  /// In de, this message translates to:
  /// **'Lädt Songs über yt-dlp von YouTube Music (Opus, ca. 130–160 kbit/s)'**
  String get adminYouTubeSourceHint;

  /// No description provided for @adminYouTubeCookies.
  ///
  /// In de, this message translates to:
  /// **'YouTube-Anmeldung'**
  String get adminYouTubeCookies;

  /// No description provided for @adminYouTubeCookiesHint.
  ///
  /// In de, this message translates to:
  /// **'Explizite und andere altersbeschränkte Songs brauchen ein angemeldetes YouTube-Konto. Lade die cookies.txt eines Zweitkontos hoch (im privaten Browserfenster mit einer Erweiterung wie „Get cookies.txt LOCALLY“ exportieren, danach das Fenster schließen).'**
  String get adminYouTubeCookiesHint;

  /// No description provided for @adminYouTubeCookiesActive.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet seit {date}'**
  String adminYouTubeCookiesActive(String date);

  /// No description provided for @adminYouTubeCookiesFromEnv.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Server gesetzt (RESONANCE_YTDLP_COOKIES_FILE)'**
  String get adminYouTubeCookiesFromEnv;

  /// No description provided for @adminYouTubeCookiesNone.
  ///
  /// In de, this message translates to:
  /// **'Nicht angemeldet: altersbeschränkte Videos werden übersprungen'**
  String get adminYouTubeCookiesNone;

  /// No description provided for @adminYouTubeCookiesExpired.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung abgelaufen: YouTube hat die Cookies erneuert. Exportiere sie neu und lade sie hoch.'**
  String get adminYouTubeCookiesExpired;

  /// No description provided for @adminYouTubeCookiesUpload.
  ///
  /// In de, this message translates to:
  /// **'cookies.txt hochladen'**
  String get adminYouTubeCookiesUpload;

  /// No description provided for @adminYouTubeCookiesRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get adminYouTubeCookiesRemove;

  /// No description provided for @adminYouTubeCookiesSaved.
  ///
  /// In de, this message translates to:
  /// **'YouTube-Anmeldung gespeichert'**
  String get adminYouTubeCookiesSaved;

  /// No description provided for @adminSoundCloudSource.
  ///
  /// In de, this message translates to:
  /// **'SoundCloud als Quelle'**
  String get adminSoundCloudSource;

  /// No description provided for @adminSoundCloudSourceHint.
  ///
  /// In de, this message translates to:
  /// **'Wird versucht, wenn YouTube nichts findet'**
  String get adminSoundCloudSourceHint;

  /// No description provided for @adminBandcampSource.
  ///
  /// In de, this message translates to:
  /// **'Bandcamp als Quelle'**
  String get adminBandcampSource;

  /// No description provided for @adminBandcampSourceHint.
  ///
  /// In de, this message translates to:
  /// **'Freie Streams in 128 kbit/s, wird zuletzt versucht'**
  String get adminBandcampSourceHint;

  /// No description provided for @downloadsSearch.
  ///
  /// In de, this message translates to:
  /// **'Suche'**
  String get downloadsSearch;

  /// No description provided for @adminQualityUpgrades.
  ///
  /// In de, this message translates to:
  /// **'Qualitäts-Upgrades'**
  String get adminQualityUpgrades;

  /// No description provided for @downloadsQualityUpgrade.
  ///
  /// In de, this message translates to:
  /// **'Qualitäts-Upgrade'**
  String get downloadsQualityUpgrade;

  /// No description provided for @adminQualityUpgradeSearchNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt suchen'**
  String get adminQualityUpgradeSearchNow;

  /// No description provided for @adminQualityUpgradeStarted.
  ///
  /// In de, this message translates to:
  /// **'Suche gestartet'**
  String get adminQualityUpgradeStarted;

  /// No description provided for @adminQualityUpgradesHint.
  ///
  /// In de, this message translates to:
  /// **'Sucht im Hintergrund bessere Versionen (Torrent) für Songs in niedriger Qualität und ersetzt sie. Benötigt aktivierte Torrents.'**
  String get adminQualityUpgradesHint;

  /// No description provided for @adminAutoApprove.
  ///
  /// In de, this message translates to:
  /// **'Anfragen automatisch genehmigen'**
  String get adminAutoApprove;

  /// No description provided for @adminAutoApproveHint.
  ///
  /// In de, this message translates to:
  /// **'Sonst muss ein Admin Anfragen von Benutzern freigeben'**
  String get adminAutoApproveHint;

  /// No description provided for @adminDailyLimit.
  ///
  /// In de, this message translates to:
  /// **'Tageslimit pro Benutzer'**
  String get adminDailyLimit;

  /// No description provided for @adminDailyLimitHint.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, other{Max. {count} automatische Downloads pro Tag}}'**
  String adminDailyLimitHint(int count);

  /// No description provided for @adminDownloadsPerDay.
  ///
  /// In de, this message translates to:
  /// **'Downloads pro Benutzer und Tag'**
  String get adminDownloadsPerDay;

  /// No description provided for @adminNotConfigured.
  ///
  /// In de, this message translates to:
  /// **'Nicht gesetzt'**
  String get adminNotConfigured;

  /// No description provided for @adminTestConnection.
  ///
  /// In de, this message translates to:
  /// **'Verbindung testen'**
  String get adminTestConnection;

  /// No description provided for @adminTestKey.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel testen'**
  String get adminTestKey;

  /// No description provided for @adminProwlarr.
  ///
  /// In de, this message translates to:
  /// **'Prowlarr'**
  String get adminProwlarr;

  /// No description provided for @adminQbittorrent.
  ///
  /// In de, this message translates to:
  /// **'qBittorrent'**
  String get adminQbittorrent;

  /// No description provided for @editorSavedTrack.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert: {title} – {artist} ({album})'**
  String editorSavedTrack(String title, String artist, String album);

  /// No description provided for @editorBitrate.
  ///
  /// In de, this message translates to:
  /// **'{bitrate} kbit/s'**
  String editorBitrate(int bitrate);

  /// No description provided for @editorTabSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get editorTabSearch;

  /// No description provided for @editorTabFingerprint.
  ///
  /// In de, this message translates to:
  /// **'Fingerabdruck'**
  String get editorTabFingerprint;

  /// No description provided for @editorTabEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get editorTabEdit;

  /// No description provided for @editorSearchTrackHint.
  ///
  /// In de, this message translates to:
  /// **'Künstler und Titel'**
  String get editorSearchTrackHint;

  /// No description provided for @editorChooseTrackHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf den richtigen Song – Tags, Cover und Dateiname werden übernommen.'**
  String get editorChooseTrackHint;

  /// No description provided for @editorFingerprintSearching.
  ///
  /// In de, this message translates to:
  /// **'Audio-Fingerabdruck wird abgeglichen …'**
  String get editorFingerprintSearching;

  /// No description provided for @editorFingerprintUnknown.
  ///
  /// In de, this message translates to:
  /// **'AcoustID kennt diese Aufnahme nicht. Versuche es über „Suchen“ oder „Bearbeiten“.'**
  String get editorFingerprintUnknown;

  /// No description provided for @editorUnknownTitle.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Titel'**
  String get editorUnknownTitle;

  /// No description provided for @editorFingerprintScore.
  ///
  /// In de, this message translates to:
  /// **'   {percent} % Übereinstimmung'**
  String editorFingerprintScore(int percent);

  /// No description provided for @editorAutoSelectAlbum.
  ///
  /// In de, this message translates to:
  /// **'Originalalbum automatisch wählen'**
  String get editorAutoSelectAlbum;

  /// No description provided for @editorUnknownAlbum.
  ///
  /// In de, this message translates to:
  /// **'Unbekanntes Album'**
  String get editorUnknownAlbum;

  /// No description provided for @editorTrackNumberWithTotal.
  ///
  /// In de, this message translates to:
  /// **'Nr. {number}{total}'**
  String editorTrackNumberWithTotal(int number, String total);

  /// No description provided for @editorTrackTotalSuffix.
  ///
  /// In de, this message translates to:
  /// **' von {total}'**
  String editorTrackTotalSuffix(int total);

  /// No description provided for @editorNumbersOnly.
  ///
  /// In de, this message translates to:
  /// **'Bitte nur Zahlen bei Jahr, Nr. und CD eingeben'**
  String get editorNumbersOnly;

  /// No description provided for @editorNoChanges.
  ///
  /// In de, this message translates to:
  /// **'Keine Änderungen'**
  String get editorNoChanges;

  /// No description provided for @editorTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get editorTitle;

  /// No description provided for @editorSwapTitleArtist.
  ///
  /// In de, this message translates to:
  /// **'Titel und Künstler tauschen'**
  String get editorSwapTitleArtist;

  /// No description provided for @editorAlbumArtist.
  ///
  /// In de, this message translates to:
  /// **'Album-Künstler'**
  String get editorAlbumArtist;

  /// No description provided for @editorYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get editorYear;

  /// No description provided for @editorTrackNumber.
  ///
  /// In de, this message translates to:
  /// **'Nr.'**
  String get editorTrackNumber;

  /// No description provided for @editorGenre.
  ///
  /// In de, this message translates to:
  /// **'Genre'**
  String get editorGenre;

  /// No description provided for @editorManualHint.
  ///
  /// In de, this message translates to:
  /// **'Leere Felder bleiben unverändert. Die Datei wird danach nach „Album-Künstler/Album (Jahr)/Nr - Titel“ umbenannt.'**
  String get editorManualHint;

  /// No description provided for @editorMatchedSongs.
  ///
  /// In de, this message translates to:
  /// **'{total, plural, other{{count} von {total} Songs zugeordnet}}'**
  String editorMatchedSongs(int count, int total);

  /// No description provided for @editorUnmatchedSongs.
  ///
  /// In de, this message translates to:
  /// **'Nicht zugeordnet (unverändert):'**
  String get editorUnmatchedSongs;

  /// No description provided for @editorSearchAlbumHint.
  ///
  /// In de, this message translates to:
  /// **'Künstler und Album oder MusicBrainz-Link'**
  String get editorSearchAlbumHint;

  /// No description provided for @editorMatchAlbumHint.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, other{Die {count} Songs dieses Albums werden per Titel, Position und Länge den Songs der gewählten Veröffentlichung zugeordnet. Was nicht passt, bleibt unverändert.}}'**
  String editorMatchAlbumHint(int count);

  /// No description provided for @editorUseMusicBrainzRelease.
  ///
  /// In de, this message translates to:
  /// **'MusicBrainz-Veröffentlichung verwenden'**
  String get editorUseMusicBrainzRelease;

  /// No description provided for @editorRetagging.
  ///
  /// In de, this message translates to:
  /// **'Songs werden neu getaggt …'**
  String get editorRetagging;

  /// No description provided for @editorCoverSaved.
  ///
  /// In de, this message translates to:
  /// **'Cover gespeichert'**
  String get editorCoverSaved;

  /// No description provided for @editorCoverSuggestionsHint.
  ///
  /// In de, this message translates to:
  /// **'Vorschläge von MusicBrainz und Deezer. Das Cover wird in alle Songs des Albums eingebettet.'**
  String get editorCoverSuggestionsHint;

  /// No description provided for @editorUploadImage.
  ///
  /// In de, this message translates to:
  /// **'Bild hochladen'**
  String get editorUploadImage;

  /// No description provided for @editorNoCoverSuggestions.
  ///
  /// In de, this message translates to:
  /// **'Keine Vorschläge gefunden'**
  String get editorNoCoverSuggestions;

  /// No description provided for @editorNoCover.
  ///
  /// In de, this message translates to:
  /// **'Ohne Cover'**
  String get editorNoCover;

  /// No description provided for @editorAlbumCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, other{{count} Alben}}'**
  String editorAlbumCount(int count);

  /// No description provided for @editorLoadMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr laden'**
  String get editorLoadMore;

  /// No description provided for @editorAllDone.
  ///
  /// In de, this message translates to:
  /// **'Alles erledigt 🎉'**
  String get editorAllDone;

  /// No description provided for @commonOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @editorDisc.
  ///
  /// In de, this message translates to:
  /// **'CD'**
  String get editorDisc;

  /// No description provided for @catalogEp.
  ///
  /// In de, this message translates to:
  /// **'EP'**
  String get catalogEp;

  /// No description provided for @adminImportCopyMode.
  ///
  /// In de, this message translates to:
  /// **'kopieren'**
  String get adminImportCopyMode;

  /// No description provided for @adminImportMoveMode.
  ///
  /// In de, this message translates to:
  /// **'verschieben'**
  String get adminImportMoveMode;

  /// No description provided for @adminLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek'**
  String get adminLibrary;

  /// No description provided for @commonSongs.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Song} other{{count} Songs}}'**
  String commonSongs(int count);

  /// No description provided for @commonArtists.
  ///
  /// In de, this message translates to:
  /// **'Künstler'**
  String get commonArtists;

  /// No description provided for @adminUserRole.
  ///
  /// In de, this message translates to:
  /// **'Benutzer'**
  String get adminUserRole;

  /// No description provided for @authServerAddressExample.
  ///
  /// In de, this message translates to:
  /// **'musik.example.com'**
  String get authServerAddressExample;

  /// No description provided for @spotifyTitle.
  ///
  /// In de, this message translates to:
  /// **'Von Spotify oder Apple Music importieren'**
  String get spotifyTitle;

  /// No description provided for @spotifyLinkHeading.
  ///
  /// In de, this message translates to:
  /// **'Playlist per Link importieren'**
  String get spotifyLinkHeading;

  /// No description provided for @spotifyLinksHint.
  ///
  /// In de, this message translates to:
  /// **'Füge Links zu öffentlichen Spotify- oder Apple-Music-Playlists ein, einen pro Zeile. Apple-Music-Playlists werden vollständig übernommen, bei Spotify ohne verbundenes Konto höchstens 100 Songs pro Playlist.'**
  String get spotifyLinksHint;

  /// No description provided for @spotifyLinkPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'https://open.spotify.com/playlist/… oder https://music.apple.com/…'**
  String get spotifyLinkPlaceholder;

  /// No description provided for @spotifyImport.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get spotifyImport;

  /// No description provided for @spotifyNotConfigured.
  ///
  /// In de, this message translates to:
  /// **'Spotify ist auf diesem Server noch nicht eingerichtet. Ein Admin kann das im Admin-Dashboard unter „Server“ erledigen.'**
  String get spotifyNotConfigured;

  /// No description provided for @spotifyConnectHint.
  ///
  /// In de, this message translates to:
  /// **'Verbinde dein Spotify-Konto, um deine Lieblingssongs und eigenen Playlists in Resonance zu übernehmen.'**
  String get spotifyConnectHint;

  /// No description provided for @spotifyConnect.
  ///
  /// In de, this message translates to:
  /// **'Mit Spotify verbinden'**
  String get spotifyConnect;

  /// No description provided for @spotifyWaiting.
  ///
  /// In de, this message translates to:
  /// **'Melde dich im geöffneten Fenster bei Spotify an und komm danach hierher zurück.'**
  String get spotifyWaiting;

  /// No description provided for @spotifyConnectedAs.
  ///
  /// In de, this message translates to:
  /// **'Verbunden als {name}'**
  String spotifyConnectedAs(String name);

  /// No description provided for @spotifyDisconnect.
  ///
  /// In de, this message translates to:
  /// **'Trennen'**
  String get spotifyDisconnect;

  /// No description provided for @spotifyLikedSongs.
  ///
  /// In de, this message translates to:
  /// **'Lieblingssongs'**
  String get spotifyLikedSongs;

  /// No description provided for @spotifyLikedHint.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Song} other{{count} Songs}} · werden in Resonance geliked'**
  String spotifyLikedHint(int count);

  /// No description provided for @spotifyPlaylistsHeading.
  ///
  /// In de, this message translates to:
  /// **'Deine Playlists'**
  String get spotifyPlaylistsHeading;

  /// No description provided for @spotifyPlaylistsNote.
  ///
  /// In de, this message translates to:
  /// **'Spotify gibt nur deine eigenen Playlists und solche frei, an denen du mitarbeitest.'**
  String get spotifyPlaylistsNote;

  /// No description provided for @spotifyPlaylistSubtitle.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Song} other{{count} Songs}} · {owner}'**
  String spotifyPlaylistSubtitle(int count, String owner);

  /// No description provided for @spotifyAlreadyImported.
  ///
  /// In de, this message translates to:
  /// **'bereits importiert – wird abgeglichen'**
  String get spotifyAlreadyImported;

  /// No description provided for @spotifyDownloadMissing.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Songs herunterladen'**
  String get spotifyDownloadMissing;

  /// No description provided for @spotifyDownloadMissingHint.
  ///
  /// In de, this message translates to:
  /// **'Songs, die noch nicht in der Bibliothek sind, werden angefragt und nach dem Download automatisch einsortiert.'**
  String get spotifyDownloadMissingHint;

  /// No description provided for @spotifyStart.
  ///
  /// In de, this message translates to:
  /// **'Import starten'**
  String get spotifyStart;

  /// No description provided for @spotifyNothingSelected.
  ///
  /// In de, this message translates to:
  /// **'Wähle die Lieblingssongs oder mindestens eine Playlist aus.'**
  String get spotifyNothingSelected;

  /// No description provided for @spotifyStarted.
  ///
  /// In de, this message translates to:
  /// **'Import gestartet'**
  String get spotifyStarted;

  /// No description provided for @spotifyHistory.
  ///
  /// In de, this message translates to:
  /// **'Bisherige Importe'**
  String get spotifyHistory;

  /// No description provided for @spotifyStatusQueued.
  ///
  /// In de, this message translates to:
  /// **'Wartet'**
  String get spotifyStatusQueued;

  /// No description provided for @spotifyStatusRunning.
  ///
  /// In de, this message translates to:
  /// **'Läuft'**
  String get spotifyStatusRunning;

  /// No description provided for @spotifyStatusDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get spotifyStatusDone;

  /// No description provided for @spotifyStatusFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagen'**
  String get spotifyStatusFailed;

  /// No description provided for @spotifyImportCounts.
  ///
  /// In de, this message translates to:
  /// **'{matched} von {total} gefunden · {missing} fehlen · {requested} angefragt'**
  String spotifyImportCounts(int matched, int total, int missing, int requested);

  /// No description provided for @spotifyShowMissing.
  ///
  /// In de, this message translates to:
  /// **'Fehlende anzeigen'**
  String get spotifyShowMissing;

  /// No description provided for @spotifySyncMenu.
  ///
  /// In de, this message translates to:
  /// **'Mit Spotify abgleichen'**
  String get spotifySyncMenu;

  /// No description provided for @spotifySyncTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit Spotify abgleichen'**
  String get spotifySyncTitle;

  /// No description provided for @spotifySyncConnectHint.
  ///
  /// In de, this message translates to:
  /// **'Verbinde dein Spotify-Konto, um diese Playlist nach Spotify zu exportieren oder mit einer Spotify-Playlist abzugleichen.'**
  String get spotifySyncConnectHint;

  /// No description provided for @spotifySyncReconnectHint.
  ///
  /// In de, this message translates to:
  /// **'Für den Export braucht Resonance zusätzlich Schreibrechte bei Spotify. Verbinde Spotify dafür einmal neu.'**
  String get spotifySyncReconnectHint;

  /// No description provided for @spotifySyncIntro.
  ///
  /// In de, this message translates to:
  /// **'Die Songs dieser Playlist werden auf Spotify gesucht und dort in eine Playlist übernommen. Songs, die Spotify nicht hat, werden übersprungen und unten angezeigt.'**
  String get spotifySyncIntro;

  /// No description provided for @spotifySyncNew.
  ///
  /// In de, this message translates to:
  /// **'Neue Spotify-Playlist anlegen'**
  String get spotifySyncNew;

  /// No description provided for @spotifySyncExisting.
  ///
  /// In de, this message translates to:
  /// **'Mit bestehender Spotify-Playlist verknüpfen'**
  String get spotifySyncExisting;

  /// No description provided for @spotifySyncPick.
  ///
  /// In de, this message translates to:
  /// **'Spotify-Playlist'**
  String get spotifySyncPick;

  /// No description provided for @spotifySyncTwoWay.
  ///
  /// In de, this message translates to:
  /// **'In beide Richtungen abgleichen'**
  String get spotifySyncTwoWay;

  /// No description provided for @spotifySyncTwoWayHint.
  ///
  /// In de, this message translates to:
  /// **'Alle 10 Minuten: Änderungen auf Spotify kommen nach Resonance (fehlende Songs werden heruntergeladen), Änderungen in Resonance nach Spotify.'**
  String get spotifySyncTwoWayHint;

  /// No description provided for @spotifySyncOneWayHint.
  ///
  /// In de, this message translates to:
  /// **'Nur Export: Songs aus Resonance werden zu Spotify übertragen, wenn du auf „Jetzt abgleichen“ tippst.'**
  String get spotifySyncOneWayHint;

  /// No description provided for @spotifySyncExport.
  ///
  /// In de, this message translates to:
  /// **'Nach Spotify exportieren'**
  String get spotifySyncExport;

  /// No description provided for @spotifySyncLink.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfen'**
  String get spotifySyncLink;

  /// No description provided for @spotifySyncFriendsHint.
  ///
  /// In de, this message translates to:
  /// **'Tipp: Lade Freunde in Spotify als Mitarbeitende zu der Playlist ein. Mit dem Abgleich in beide Richtungen landen ihre Songs dann auch hier.'**
  String get spotifySyncFriendsHint;

  /// No description provided for @spotifySyncLinked.
  ///
  /// In de, this message translates to:
  /// **'Mit Spotify verknüpft'**
  String get spotifySyncLinked;

  /// No description provided for @spotifySyncRunning.
  ///
  /// In de, this message translates to:
  /// **'Wird abgeglichen …'**
  String get spotifySyncRunning;

  /// No description provided for @spotifySyncFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {error}'**
  String spotifySyncFailed(String error);

  /// No description provided for @spotifySyncLast.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt abgeglichen: {time}'**
  String spotifySyncLast(String time);

  /// No description provided for @spotifySyncNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt abgleichen'**
  String get spotifySyncNow;

  /// No description provided for @spotifySyncOpen.
  ///
  /// In de, this message translates to:
  /// **'In Spotify öffnen'**
  String get spotifySyncOpen;

  /// No description provided for @spotifySyncUnlink.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfung lösen'**
  String get spotifySyncUnlink;

  /// No description provided for @spotifySyncUnlinkConfirm.
  ///
  /// In de, this message translates to:
  /// **'Die Playlist wird nicht mehr abgeglichen. Die Playlist auf Spotify bleibt bestehen.'**
  String get spotifySyncUnlinkConfirm;

  /// No description provided for @spotifySyncUnmatched.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Song nicht auf Spotify gefunden} other{{count} Songs nicht auf Spotify gefunden}}'**
  String spotifySyncUnmatched(int count);

  /// No description provided for @spotifyMissingTitle.
  ///
  /// In de, this message translates to:
  /// **'Nicht in der Bibliothek'**
  String get spotifyMissingTitle;

  /// No description provided for @adminSpotifyGroup.
  ///
  /// In de, this message translates to:
  /// **'Spotify-Import'**
  String get adminSpotifyGroup;

  /// No description provided for @adminSpotifyClientId.
  ///
  /// In de, this message translates to:
  /// **'Spotify Client ID'**
  String get adminSpotifyClientId;

  /// No description provided for @adminSpotifyClientSecret.
  ///
  /// In de, this message translates to:
  /// **'Spotify Client Secret'**
  String get adminSpotifyClientSecret;

  /// No description provided for @adminSpotifyHint.
  ///
  /// In de, this message translates to:
  /// **'developer.spotify.com/dashboard → App anlegen, Redirect URI: {uri}'**
  String adminSpotifyHint(String uri);

  /// No description provided for @audiobooksViewLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek'**
  String get audiobooksViewLibrary;

  /// No description provided for @audiobooksViewSeries.
  ///
  /// In de, this message translates to:
  /// **'Serien'**
  String get audiobooksViewSeries;

  /// No description provided for @audiobooksViewAuthors.
  ///
  /// In de, this message translates to:
  /// **'Autoren'**
  String get audiobooksViewAuthors;

  /// No description provided for @audiobooksViewNarrators.
  ///
  /// In de, this message translates to:
  /// **'Sprecher'**
  String get audiobooksViewNarrators;

  /// No description provided for @audiobooksBookCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Hörbuch} other{{count} Hörbücher}}'**
  String audiobooksBookCount(int count);

  /// No description provided for @albumFindMissing.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Songs suchen'**
  String get albumFindMissing;

  /// No description provided for @adminDeleteSong.
  ///
  /// In de, this message translates to:
  /// **'Song löschen'**
  String get adminDeleteSong;

  /// No description provided for @adminDeleteAlbum.
  ///
  /// In de, this message translates to:
  /// **'Album löschen'**
  String get adminDeleteAlbum;

  /// No description provided for @adminDeleteSongConfirm.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ wird endgültig vom Server gelöscht, auch die Datei.'**
  String adminDeleteSongConfirm(String title);

  /// No description provided for @adminDeleteAlbumConfirm.
  ///
  /// In de, this message translates to:
  /// **'Das Album „{title}“ wird mit allen Songs endgültig vom Server gelöscht, auch die Dateien.'**
  String adminDeleteAlbumConfirm(String title);

  /// No description provided for @adminDeleted.
  ///
  /// In de, this message translates to:
  /// **'Gelöscht'**
  String get adminDeleted;

  /// No description provided for @libraryShareWithUsers.
  ///
  /// In de, this message translates to:
  /// **'Mit bestimmten Nutzern teilen'**
  String get libraryShareWithUsers;

  /// No description provided for @libraryNoOtherUsers.
  ///
  /// In de, this message translates to:
  /// **'Es gibt noch keine anderen Nutzer.'**
  String get libraryNoOtherUsers;

  /// No description provided for @librarySharedWith.
  ///
  /// In de, this message translates to:
  /// **'Geteilt mit {names}'**
  String librarySharedWith(String names);

  /// No description provided for @albumMissingTitle.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Song nicht in deiner Bibliothek} other{{count} Songs nicht in deiner Bibliothek}}'**
  String albumMissingTitle(int count);

  /// No description provided for @radioStartSong.
  ///
  /// In de, this message translates to:
  /// **'Song-Radio starten'**
  String get radioStartSong;

  /// No description provided for @radioStartAlbum.
  ///
  /// In de, this message translates to:
  /// **'Album-Radio starten'**
  String get radioStartAlbum;

  /// No description provided for @radioKind.
  ///
  /// In de, this message translates to:
  /// **'Radio'**
  String get radioKind;

  /// No description provided for @radioKeep.
  ///
  /// In de, this message translates to:
  /// **'Als Playlist behalten'**
  String get radioKeep;

  /// No description provided for @radioDownloading.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 fehlender Song wird geladen und dann zum Radio hinzugefügt} other{{count} fehlende Songs werden geladen und dann zum Radio hinzugefügt}}'**
  String radioDownloading(int count);

  /// No description provided for @libraryRadios.
  ///
  /// In de, this message translates to:
  /// **'Radios'**
  String get libraryRadios;

  /// No description provided for @adminRadioMaxDownloads.
  ///
  /// In de, this message translates to:
  /// **'Max. Downloads pro Radio-Start'**
  String get adminRadioMaxDownloads;

  /// No description provided for @adminRadioPlaylistRetention.
  ///
  /// In de, this message translates to:
  /// **'Radios aufbewahren (Tage seit letzter Nutzung, 0 = immer)'**
  String get adminRadioPlaylistRetention;

  /// No description provided for @offlineBanner.
  ///
  /// In de, this message translates to:
  /// **'Offline – nur Heruntergeladenes'**
  String get offlineBanner;

  /// No description provided for @offlineEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Lade Alben, Playlists, Podcast-Folgen, Hörbücher und E-Books herunter, um sie offline zu nutzen.'**
  String get offlineEmptyHint;

  /// No description provided for @offlineDownloaded.
  ///
  /// In de, this message translates to:
  /// **'Heruntergeladen'**
  String get offlineDownloaded;

  /// No description provided for @offlineDownload.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen'**
  String get offlineDownload;

  /// No description provided for @offlineNotificationRunning.
  ///
  /// In de, this message translates to:
  /// **'Resonance: {numFinished} von {numTotal} Songs geladen'**
  String offlineNotificationRunning(String numFinished, String numTotal);

  /// No description provided for @offlineNotificationComplete.
  ///
  /// In de, this message translates to:
  /// **'Resonance: Downloads fertig'**
  String get offlineNotificationComplete;

  /// No description provided for @offlineRemoveTitle.
  ///
  /// In de, this message translates to:
  /// **'Download entfernen?'**
  String get offlineRemoveTitle;

  /// No description provided for @storageExport.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get storageExport;

  /// No description provided for @storageExportAll.
  ///
  /// In de, this message translates to:
  /// **'Alle exportieren'**
  String get storageExportAll;

  /// No description provided for @storageExportUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Exportieren braucht Android 10 oder neuer'**
  String get storageExportUnsupported;

  /// No description provided for @storageExportProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} Songs'**
  String storageExportProgress(int done, int total);

  /// No description provided for @storageExported.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Schon alles exportiert} =1{1 Song nach {folder} exportiert} other{{count} Songs nach {folder} exportiert}}'**
  String storageExported(int count, String folder);

  /// No description provided for @coverCropTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausschnitt wählen'**
  String get coverCropTitle;

  /// No description provided for @coverCropHint.
  ///
  /// In de, this message translates to:
  /// **'Bild verschieben und mit zwei Fingern oder dem Mausrad zoomen'**
  String get coverCropHint;

  /// No description provided for @storageOpenFolder.
  ///
  /// In de, this message translates to:
  /// **'Ordner öffnen'**
  String get storageOpenFolder;

  /// No description provided for @storageCollections.
  ///
  /// In de, this message translates to:
  /// **'Heruntergeladene Sammlungen'**
  String get storageCollections;

  /// No description provided for @storageFiles.
  ///
  /// In de, this message translates to:
  /// **'Dateien nach Größe'**
  String get storageFiles;

  /// No description provided for @offlineQuality.
  ///
  /// In de, this message translates to:
  /// **'Downloadqualität'**
  String get offlineQuality;

  /// No description provided for @offlineQualityNormal.
  ///
  /// In de, this message translates to:
  /// **'Normal (Opus 160 kbit/s)'**
  String get offlineQualityNormal;

  /// No description provided for @offlineQualityHigh.
  ///
  /// In de, this message translates to:
  /// **'Hoch (Opus 256 kbit/s)'**
  String get offlineQualityHigh;

  /// No description provided for @offlineQualityOriginal.
  ///
  /// In de, this message translates to:
  /// **'Original (verlustfrei, braucht viel Speicher)'**
  String get offlineQualityOriginal;

  /// No description provided for @offlineWifiOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur über WLAN herunterladen'**
  String get offlineWifiOnly;

  /// No description provided for @offlineStorage.
  ///
  /// In de, this message translates to:
  /// **'Speicherbelegung'**
  String get offlineStorage;

  /// No description provided for @offlineStorageUsed.
  ///
  /// In de, this message translates to:
  /// **'{size} • {count} Songs'**
  String offlineStorageUsed(String size, int count);

  /// No description provided for @offlineMegabytes.
  ///
  /// In de, this message translates to:
  /// **'{value} MB'**
  String offlineMegabytes(String value);

  /// No description provided for @offlineGigabytes.
  ///
  /// In de, this message translates to:
  /// **'{value} GB'**
  String offlineGigabytes(String value);

  /// No description provided for @offlineDownloading.
  ///
  /// In de, this message translates to:
  /// **'{count} Songs werden heruntergeladen'**
  String offlineDownloading(int count);

  /// No description provided for @offlineProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} heruntergeladen'**
  String offlineProgress(int done, int total);

  /// No description provided for @offlineClearAll.
  ///
  /// In de, this message translates to:
  /// **'Alle Downloads löschen'**
  String get offlineClearAll;

  /// No description provided for @offlineClearConfirm.
  ///
  /// In de, this message translates to:
  /// **'Alle Downloads löschen?'**
  String get offlineClearConfirm;

  /// No description provided for @mixKind.
  ///
  /// In de, this message translates to:
  /// **'Mix'**
  String get mixKind;

  /// No description provided for @mixSave.
  ///
  /// In de, this message translates to:
  /// **'Als Playlist speichern'**
  String get mixSave;

  /// No description provided for @homeMadeForYou.
  ///
  /// In de, this message translates to:
  /// **'Für dich erstellt'**
  String get homeMadeForYou;

  /// No description provided for @homeCharts.
  ///
  /// In de, this message translates to:
  /// **'Charts'**
  String get homeCharts;

  /// No description provided for @homeGenreMixes.
  ///
  /// In de, this message translates to:
  /// **'Deine Genres'**
  String get homeGenreMixes;

  /// No description provided for @homeDecadeMixes.
  ///
  /// In de, this message translates to:
  /// **'Deine Jahrzehnte'**
  String get homeDecadeMixes;

  /// No description provided for @lyricsTitle.
  ///
  /// In de, this message translates to:
  /// **'Songtext'**
  String get lyricsTitle;

  /// No description provided for @lyricsExpand.
  ///
  /// In de, this message translates to:
  /// **'Vollbild'**
  String get lyricsExpand;

  /// No description provided for @lyricsUnsynced.
  ///
  /// In de, this message translates to:
  /// **'Diese Songtexte sind nicht synchronisiert.'**
  String get lyricsUnsynced;

  /// No description provided for @lyricsInstrumental.
  ///
  /// In de, this message translates to:
  /// **'Instrumental'**
  String get lyricsInstrumental;

  /// No description provided for @lyricsNotFound.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Song gibt es keinen Songtext.'**
  String get lyricsNotFound;

  /// No description provided for @lyricsAttribution.
  ///
  /// In de, this message translates to:
  /// **'Songtext von LRCLIB'**
  String get lyricsAttribution;

  /// No description provided for @adminLyricsOnline.
  ///
  /// In de, this message translates to:
  /// **'Songtexte online suchen (LRCLIB)'**
  String get adminLyricsOnline;

  /// No description provided for @adminLyricsOnlineHint.
  ///
  /// In de, this message translates to:
  /// **'Für Songs ohne eigene Songtexte werden synchronisierte Texte von lrclib.net geladen.'**
  String get adminLyricsOnlineHint;

  /// No description provided for @redownloadMenu.
  ///
  /// In de, this message translates to:
  /// **'Falsche Version? Neu herunterladen'**
  String get redownloadMenu;

  /// No description provided for @redownloadTitle.
  ///
  /// In de, this message translates to:
  /// **'Neu herunterladen'**
  String get redownloadTitle;

  /// No description provided for @redownloadExplanation.
  ///
  /// In de, this message translates to:
  /// **'Der Song wird erneut gesucht und ersetzt. Die bisher verwendete Quelle wird übersprungen. Likes und Playlists bleiben erhalten.'**
  String get redownloadExplanation;

  /// No description provided for @redownloadYoutubeLabel.
  ///
  /// In de, this message translates to:
  /// **'YouTube-, SoundCloud- oder Bandcamp-Link (optional)'**
  String get redownloadYoutubeLabel;

  /// No description provided for @redownloadYoutubeHint.
  ///
  /// In de, this message translates to:
  /// **'Falls du eine bestimmte Version willst'**
  String get redownloadYoutubeHint;

  /// No description provided for @redownloadStarted.
  ///
  /// In de, this message translates to:
  /// **'Neu-Download gestartet'**
  String get redownloadStarted;

  /// No description provided for @redownloadAwaitingApproval.
  ///
  /// In de, this message translates to:
  /// **'Anfrage gesendet – ein Admin muss sie freigeben'**
  String get redownloadAwaitingApproval;

  /// No description provided for @downloadsRedownload.
  ///
  /// In de, this message translates to:
  /// **'Neu-Download'**
  String get downloadsRedownload;

  /// No description provided for @audioBrowseHome.
  ///
  /// In de, this message translates to:
  /// **'Startseite'**
  String get audioBrowseHome;

  /// No description provided for @settingsCrossfade.
  ///
  /// In de, this message translates to:
  /// **'Crossfade'**
  String get settingsCrossfade;

  /// No description provided for @settingsCrossfadeOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get settingsCrossfadeOff;

  /// No description provided for @settingsCrossfadeSeconds.
  ///
  /// In de, this message translates to:
  /// **'{seconds} s'**
  String settingsCrossfadeSeconds(int seconds);

  /// No description provided for @settingsVisualizer.
  ///
  /// In de, this message translates to:
  /// **'Visualizer'**
  String get settingsVisualizer;

  /// No description provided for @settingsVisualizerHint.
  ///
  /// In de, this message translates to:
  /// **'Zeigt beim Abspielen animierte Frequenzbalken im Player.'**
  String get settingsVisualizerHint;

  /// No description provided for @settingsVisualizerStyle.
  ///
  /// In de, this message translates to:
  /// **'Visualizer-Stil'**
  String get settingsVisualizerStyle;

  /// No description provided for @settingsVisualizerReflection.
  ///
  /// In de, this message translates to:
  /// **'Spiegelung'**
  String get settingsVisualizerReflection;

  /// No description provided for @settingsVisualizerReflectionHint.
  ///
  /// In de, this message translates to:
  /// **'Cover und Visualizer spiegeln'**
  String get settingsVisualizerReflectionHint;

  /// No description provided for @settingsCoverflow.
  ///
  /// In de, this message translates to:
  /// **'Coverflow'**
  String get settingsCoverflow;

  /// No description provided for @settingsCoverflowHint.
  ///
  /// In de, this message translates to:
  /// **'Cover der Warteschlange zum Wischen nebeneinander'**
  String get settingsCoverflowHint;

  /// No description provided for @settingsCoverflowFlip.
  ///
  /// In de, this message translates to:
  /// **'Cover umdrehen'**
  String get settingsCoverflowFlip;

  /// No description provided for @settingsCoverflowFlipHint.
  ///
  /// In de, this message translates to:
  /// **'Tippen auf das Cover zeigt die Songs des Albums'**
  String get settingsCoverflowFlipHint;

  /// No description provided for @visualizerThemeAuto.
  ///
  /// In de, this message translates to:
  /// **'Automatisch'**
  String get visualizerThemeAuto;

  /// No description provided for @visualizerThemeRetro.
  ///
  /// In de, this message translates to:
  /// **'Retro-Stereo'**
  String get visualizerThemeRetro;

  /// No description provided for @visualizerThemeSynthwave.
  ///
  /// In de, this message translates to:
  /// **'Synthwave'**
  String get visualizerThemeSynthwave;

  /// No description provided for @visualizerThemeNeon.
  ///
  /// In de, this message translates to:
  /// **'Neon'**
  String get visualizerThemeNeon;

  /// No description provided for @visualizerThemeOcean.
  ///
  /// In de, this message translates to:
  /// **'Ozean'**
  String get visualizerThemeOcean;

  /// No description provided for @visualizerThemeSunset.
  ///
  /// In de, this message translates to:
  /// **'Sonnenuntergang'**
  String get visualizerThemeSunset;

  /// No description provided for @visualizerThemeFire.
  ///
  /// In de, this message translates to:
  /// **'Feuer'**
  String get visualizerThemeFire;

  /// No description provided for @visualizerThemeMatrix.
  ///
  /// In de, this message translates to:
  /// **'Matrix'**
  String get visualizerThemeMatrix;

  /// No description provided for @visualizerThemeAurora.
  ///
  /// In de, this message translates to:
  /// **'Polarlicht'**
  String get visualizerThemeAurora;

  /// No description provided for @visualizerThemeMono.
  ///
  /// In de, this message translates to:
  /// **'Monochrom'**
  String get visualizerThemeMono;

  /// No description provided for @visualizerThemeRainbow.
  ///
  /// In de, this message translates to:
  /// **'Regenbogen'**
  String get visualizerThemeRainbow;

  /// No description provided for @settingsAutomix.
  ///
  /// In de, this message translates to:
  /// **'Automix'**
  String get settingsAutomix;

  /// No description provided for @settingsAutomixHint.
  ///
  /// In de, this message translates to:
  /// **'Übergänge wie bei einem DJ: Der nächste Song setzt im Takt ein und sein Tempo wird kurz angeglichen. Songs ohne Analyse (z. B. offline) werden einfach überblendet. Der Crossfade-Regler legt die Mindestlänge der Übergänge fest.'**
  String get settingsAutomixHint;

  /// No description provided for @settingsVocalSwap.
  ///
  /// In de, this message translates to:
  /// **'Gesangs-Tausch'**
  String get settingsVocalSwap;

  /// No description provided for @settingsVocalSwapHint.
  ///
  /// In de, this message translates to:
  /// **'Der nächste Song kommt ohne Gesang herein, sein Beat läuft unter dem Gesang des aktuellen Songs (nur PC, braucht die Song-Analyse auf dem Server)'**
  String get settingsVocalSwapHint;

  /// No description provided for @settingsKeyShift.
  ///
  /// In de, this message translates to:
  /// **'Tonart angleichen'**
  String get settingsKeyShift;

  /// No description provided for @settingsKeyShiftHint.
  ///
  /// In de, this message translates to:
  /// **'AutoMix verschiebt den nächsten Song um bis zu zwei Halbtöne, wenn die Tonarten nicht zusammenpassen'**
  String get settingsKeyShiftHint;

  /// No description provided for @equalizerTitle.
  ///
  /// In de, this message translates to:
  /// **'Equalizer'**
  String get equalizerTitle;

  /// No description provided for @equalizerOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get equalizerOff;

  /// No description provided for @equalizerPresetFlat.
  ///
  /// In de, this message translates to:
  /// **'Flach'**
  String get equalizerPresetFlat;

  /// No description provided for @equalizerPresetBass.
  ///
  /// In de, this message translates to:
  /// **'Bass-Boost'**
  String get equalizerPresetBass;

  /// No description provided for @equalizerPresetTreble.
  ///
  /// In de, this message translates to:
  /// **'Höhen'**
  String get equalizerPresetTreble;

  /// No description provided for @equalizerPresetVocal.
  ///
  /// In de, this message translates to:
  /// **'Stimme'**
  String get equalizerPresetVocal;

  /// No description provided for @equalizerPresetRock.
  ///
  /// In de, this message translates to:
  /// **'Rock'**
  String get equalizerPresetRock;

  /// No description provided for @equalizerPresetPop.
  ///
  /// In de, this message translates to:
  /// **'Pop'**
  String get equalizerPresetPop;

  /// No description provided for @equalizerPresetHiphop.
  ///
  /// In de, this message translates to:
  /// **'Hip-Hop'**
  String get equalizerPresetHiphop;

  /// No description provided for @equalizerPresetElectronic.
  ///
  /// In de, this message translates to:
  /// **'Electronic'**
  String get equalizerPresetElectronic;

  /// No description provided for @equalizerPresetAcoustic.
  ///
  /// In de, this message translates to:
  /// **'Akustik'**
  String get equalizerPresetAcoustic;

  /// No description provided for @equalizerPresetLoudness.
  ///
  /// In de, this message translates to:
  /// **'Loudness'**
  String get equalizerPresetLoudness;

  /// No description provided for @equalizerPresetCustom.
  ///
  /// In de, this message translates to:
  /// **'Eigene'**
  String get equalizerPresetCustom;

  /// No description provided for @equalizerPresets.
  ///
  /// In de, this message translates to:
  /// **'Voreinstellungen'**
  String get equalizerPresets;

  /// No description provided for @equalizerReset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get equalizerReset;

  /// No description provided for @equalizerDecibels.
  ///
  /// In de, this message translates to:
  /// **'{value} dB'**
  String equalizerDecibels(String value);

  /// No description provided for @equalizerBandLabel.
  ///
  /// In de, this message translates to:
  /// **'{frequency} Hz'**
  String equalizerBandLabel(int frequency);

  /// No description provided for @equalizerFrequencyK.
  ///
  /// In de, this message translates to:
  /// **'{frequency}k'**
  String equalizerFrequencyK(int frequency);

  /// No description provided for @settingsSubsonicTitle.
  ///
  /// In de, this message translates to:
  /// **'Andere Musik-Apps (Subsonic)'**
  String get settingsSubsonicTitle;

  /// No description provided for @settingsSubsonicSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Nutze Resonance in Apps wie Symfonium oder Feishin'**
  String get settingsSubsonicSubtitle;

  /// No description provided for @settingsSubsonicConnection.
  ///
  /// In de, this message translates to:
  /// **'Server: {serverUrl}\nBenutzername: {username}'**
  String settingsSubsonicConnection(String serverUrl, String username);

  /// No description provided for @settingsSubsonicConfigured.
  ///
  /// In de, this message translates to:
  /// **'Ein App-Passwort ist eingerichtet.'**
  String get settingsSubsonicConfigured;

  /// No description provided for @settingsSubsonicRegenerate.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort erzeugen'**
  String get settingsSubsonicRegenerate;

  /// No description provided for @settingsSubsonicRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get settingsSubsonicRemove;

  /// No description provided for @settingsSubsonicHint.
  ///
  /// In de, this message translates to:
  /// **'Erzeuge ein App-Passwort und gib es in der anderen App als Passwort ein. Dein normales Passwort funktioniert dort nicht.'**
  String get settingsSubsonicHint;

  /// No description provided for @settingsSubsonicGenerate.
  ///
  /// In de, this message translates to:
  /// **'Passwort erzeugen'**
  String get settingsSubsonicGenerate;

  /// No description provided for @settingsSubsonicCopied.
  ///
  /// In de, this message translates to:
  /// **'Kopiert'**
  String get settingsSubsonicCopied;

  /// No description provided for @settingsSubsonicShownOnce.
  ///
  /// In de, this message translates to:
  /// **'Wird nur jetzt angezeigt.'**
  String get settingsSubsonicShownOnce;

  /// No description provided for @adminIntegrations.
  ///
  /// In de, this message translates to:
  /// **'Integrationen'**
  String get adminIntegrations;

  /// No description provided for @adminDiscordClientId.
  ///
  /// In de, this message translates to:
  /// **'Discord-Anwendungs-ID'**
  String get adminDiscordClientId;

  /// No description provided for @adminDiscordClientIdHint.
  ///
  /// In de, this message translates to:
  /// **'Für den Discord-Status der Desktop-App. Anwendung unter discord.com/developers anlegen und die Application ID hier eintragen.'**
  String get adminDiscordClientIdHint;

  /// No description provided for @settingsDiscordPresence.
  ///
  /// In de, this message translates to:
  /// **'Discord-Status anzeigen'**
  String get settingsDiscordPresence;

  /// No description provided for @settingsDiscordPresenceHint.
  ///
  /// In de, this message translates to:
  /// **'Zeigt in Discord an, was du gerade hörst'**
  String get settingsDiscordPresenceHint;

  /// No description provided for @settingsDiscordNotConfigured.
  ///
  /// In de, this message translates to:
  /// **'Vom Admin noch nicht eingerichtet'**
  String get settingsDiscordNotConfigured;

  /// No description provided for @discordPresenceArtist.
  ///
  /// In de, this message translates to:
  /// **'von {artist}'**
  String discordPresenceArtist(String artist);

  /// No description provided for @playlistRemoveCover.
  ///
  /// In de, this message translates to:
  /// **'Cover entfernen'**
  String get playlistRemoveCover;

  /// No description provided for @playlistCoverRemoved.
  ///
  /// In de, this message translates to:
  /// **'Cover entfernt'**
  String get playlistCoverRemoved;

  /// No description provided for @editorLooksGood.
  ///
  /// In de, this message translates to:
  /// **'Passt so'**
  String get editorLooksGood;

  /// No description provided for @discoverWeekly.
  ///
  /// In de, this message translates to:
  /// **'Mix der Woche'**
  String get discoverWeekly;

  /// No description provided for @adminMixes.
  ///
  /// In de, this message translates to:
  /// **'Mixes'**
  String get adminMixes;

  /// No description provided for @adminDiscoverWeeklyHint.
  ///
  /// In de, this message translates to:
  /// **'Jeden Montag 30 neue Songs pro Nutzer, fehlende werden heruntergeladen'**
  String get adminDiscoverWeeklyHint;

  /// No description provided for @adminDiscoverDownloads.
  ///
  /// In de, this message translates to:
  /// **'Downloads pro Woche und Nutzer'**
  String get adminDiscoverDownloads;

  /// No description provided for @adminDiscoverSize.
  ///
  /// In de, this message translates to:
  /// **'Songs im Mix der Woche (10–100)'**
  String get adminDiscoverSize;

  /// No description provided for @adminChartsEnabled.
  ///
  /// In de, this message translates to:
  /// **'Charts-Playlists'**
  String get adminChartsEnabled;

  /// No description provided for @adminChartsEnabledHint.
  ///
  /// In de, this message translates to:
  /// **'Top 100 Deutschland und Global, täglich aktualisiert'**
  String get adminChartsEnabledHint;

  /// No description provided for @adminChartsDownloads.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Chart-Songs pro Tag laden'**
  String get adminChartsDownloads;

  /// No description provided for @adminEditorialEnabled.
  ///
  /// In de, this message translates to:
  /// **'Redaktionelle Playlists (Apple Music)'**
  String get adminEditorialEnabled;

  /// No description provided for @adminEditorialDownloads.
  ///
  /// In de, this message translates to:
  /// **'Songs pro Playlist nachladen'**
  String get adminEditorialDownloads;

  /// No description provided for @adminEditorialYears.
  ///
  /// In de, this message translates to:
  /// **'Jahres-Hits'**
  String get adminEditorialYears;

  /// No description provided for @worldRadioTitle.
  ///
  /// In de, this message translates to:
  /// **'Weltradio'**
  String get worldRadioTitle;

  /// No description provided for @worldRadioSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Sender suchen'**
  String get worldRadioSearchHint;

  /// No description provided for @worldRadioSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get worldRadioSearch;

  /// No description provided for @worldRadioPopularInCountry.
  ///
  /// In de, this message translates to:
  /// **'Beliebt in {country}'**
  String worldRadioPopularInCountry(String country);

  /// No description provided for @worldRadioGenres.
  ///
  /// In de, this message translates to:
  /// **'Genres'**
  String get worldRadioGenres;

  /// No description provided for @worldRadioAllGenres.
  ///
  /// In de, this message translates to:
  /// **'Alle Genres'**
  String get worldRadioAllGenres;

  /// No description provided for @worldRadioFavoriteHint.
  ///
  /// In de, this message translates to:
  /// **'Markiere Sender im Player mit dem Stern als Favorit'**
  String get worldRadioFavoriteHint;

  /// No description provided for @worldRadioFavorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get worldRadioFavorites;

  /// No description provided for @worldRadioStationCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Sender} other{{count} Sender}}'**
  String worldRadioStationCount(num count);

  /// No description provided for @worldRadioYourStations.
  ///
  /// In de, this message translates to:
  /// **'Deine Radiosender'**
  String get worldRadioYourStations;

  /// No description provided for @worldRadioUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Sender nicht erreichbar'**
  String get worldRadioUnavailable;

  /// No description provided for @worldRadioLive.
  ///
  /// In de, this message translates to:
  /// **'LIVE'**
  String get worldRadioLive;

  /// No description provided for @worldRadioCountry.
  ///
  /// In de, this message translates to:
  /// **'Land'**
  String get worldRadioCountry;

  /// No description provided for @worldRadioSearchCountry.
  ///
  /// In de, this message translates to:
  /// **'Land suchen'**
  String get worldRadioSearchCountry;

  /// No description provided for @jamTitle.
  ///
  /// In de, this message translates to:
  /// **'Jam'**
  String get jamTitle;

  /// No description provided for @jamIntro.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsam hören: Freunde treten mit einem Code bei, alle können Songs hinzufügen.'**
  String get jamIntro;

  /// No description provided for @jamStart.
  ///
  /// In de, this message translates to:
  /// **'Jam starten'**
  String get jamStart;

  /// No description provided for @jamJoin.
  ///
  /// In de, this message translates to:
  /// **'Jam beitreten'**
  String get jamJoin;

  /// No description provided for @jamCodeHint.
  ///
  /// In de, this message translates to:
  /// **'6-stelliger Zahlencode'**
  String get jamCodeHint;

  /// No description provided for @jamConnecting.
  ///
  /// In de, this message translates to:
  /// **'Verbinde …'**
  String get jamConnecting;

  /// No description provided for @jamCopyLink.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get jamCopyLink;

  /// No description provided for @jamLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert'**
  String get jamLinkCopied;

  /// No description provided for @jamMembers.
  ///
  /// In de, this message translates to:
  /// **'Teilnehmer'**
  String get jamMembers;

  /// No description provided for @jamHost.
  ///
  /// In de, this message translates to:
  /// **'Host'**
  String get jamHost;

  /// No description provided for @jamKick.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get jamKick;

  /// No description provided for @jamMembersControl.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder dürfen steuern'**
  String get jamMembersControl;

  /// No description provided for @jamListenHere.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät mithören'**
  String get jamListenHere;

  /// No description provided for @jamListenHereHint.
  ///
  /// In de, this message translates to:
  /// **'Aus: nur steuern, die Musik läuft auf einem anderen Gerät'**
  String get jamListenHereHint;

  /// No description provided for @jamLeave.
  ///
  /// In de, this message translates to:
  /// **'Jam verlassen'**
  String get jamLeave;

  /// No description provided for @jamEnd.
  ///
  /// In de, this message translates to:
  /// **'Jam beenden'**
  String get jamEnd;

  /// No description provided for @jamEndConfirm.
  ///
  /// In de, this message translates to:
  /// **'Den Jam für alle beenden?'**
  String get jamEndConfirm;

  /// No description provided for @jamEnded.
  ///
  /// In de, this message translates to:
  /// **'Der Jam wurde beendet'**
  String get jamEnded;

  /// No description provided for @jamNotConnected.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung zum Jam'**
  String get jamNotConnected;

  /// No description provided for @jamQueue.
  ///
  /// In de, this message translates to:
  /// **'Jam-Warteschlange'**
  String get jamQueue;

  /// No description provided for @jamAddedBy.
  ///
  /// In de, this message translates to:
  /// **'Hinzugefügt von {name}'**
  String jamAddedBy(String name);

  /// No description provided for @jamChip.
  ///
  /// In de, this message translates to:
  /// **'Jam · {count}'**
  String jamChip(int count);

  /// No description provided for @adminDuplicates.
  ///
  /// In de, this message translates to:
  /// **'Duplikate'**
  String get adminDuplicates;

  /// No description provided for @adminDuplicatesDifferentAlbums.
  ///
  /// In de, this message translates to:
  /// **'Verschiedene Alben · gleiche Aufnahme'**
  String get adminDuplicatesDifferentAlbums;

  /// No description provided for @adminDuplicatesPending.
  ///
  /// In de, this message translates to:
  /// **'Wird noch geprüft'**
  String get adminDuplicatesPending;

  /// No description provided for @adminDuplicatesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Duplikate gefunden'**
  String get adminDuplicatesEmpty;

  /// No description provided for @adminDuplicatesHint.
  ///
  /// In de, this message translates to:
  /// **'{groups} Songs liegen mehrfach vor. Behalten wird jeweils die beste Datei, die anderen werden gelöscht. Likes, Playlists und Verlauf gehen auf die behaltene Datei über. Playlists, Likes und Verlauf zeigen danach auf die behaltene Datei – du musst nichts neu hinzufügen. Bei verschiedenen Alben verschwindet der Song vom anderen Album.'**
  String adminDuplicatesHint(int groups);

  /// No description provided for @adminDuplicatesGroupTitle.
  ///
  /// In de, this message translates to:
  /// **'{artist} – {album}: {title}'**
  String adminDuplicatesGroupTitle(String artist, String album, String title);

  /// No description provided for @adminDuplicatesFile.
  ///
  /// In de, this message translates to:
  /// **'{marker} {codec} · {bitrate} kbps · {size}'**
  String adminDuplicatesFile(String marker, String codec, int bitrate, String size);

  /// No description provided for @adminDuplicatesDelete.
  ///
  /// In de, this message translates to:
  /// **'{n} Duplikate löschen'**
  String adminDuplicatesDelete(int n);

  /// No description provided for @adminDuplicatesConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Duplikate löschen?'**
  String get adminDuplicatesConfirmTitle;

  /// No description provided for @adminDuplicatesConfirmHint.
  ///
  /// In de, this message translates to:
  /// **'Die schlechteren Dateien werden endgültig gelöscht.'**
  String get adminDuplicatesConfirmHint;

  /// No description provided for @adminDuplicatesMerged.
  ///
  /// In de, this message translates to:
  /// **'{deleted} Dateien gelöscht, {freed} frei geworden'**
  String adminDuplicatesMerged(int deleted, String freed);

  /// No description provided for @updateRestarting.
  ///
  /// In de, this message translates to:
  /// **'Wird installiert, Resonance startet gleich neu …'**
  String get updateRestarting;

  /// No description provided for @shortcutsTitle.
  ///
  /// In de, this message translates to:
  /// **'Tastenkürzel'**
  String get shortcutsTitle;

  /// No description provided for @shortcutPlayPause.
  ///
  /// In de, this message translates to:
  /// **'Abspielen / Pause'**
  String get shortcutPlayPause;

  /// No description provided for @shortcutNextPrevious.
  ///
  /// In de, this message translates to:
  /// **'Nächster / vorheriger Song'**
  String get shortcutNextPrevious;

  /// No description provided for @shortcutSeek.
  ///
  /// In de, this message translates to:
  /// **'10 Sekunden vor / zurück'**
  String get shortcutSeek;

  /// No description provided for @shortcutVolume.
  ///
  /// In de, this message translates to:
  /// **'Lauter / leiser'**
  String get shortcutVolume;

  /// No description provided for @shortcutShuffle.
  ///
  /// In de, this message translates to:
  /// **'Zufallswiedergabe'**
  String get shortcutShuffle;

  /// No description provided for @shortcutRepeat.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen'**
  String get shortcutRepeat;

  /// No description provided for @shortcutSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get shortcutSearch;

  /// No description provided for @navBooks.
  ///
  /// In de, this message translates to:
  /// **'Bücher'**
  String get navBooks;

  /// No description provided for @booksEbooks.
  ///
  /// In de, this message translates to:
  /// **'Ebooks'**
  String get booksEbooks;

  /// No description provided for @booksSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Buch, Autor oder Serie suchen'**
  String get booksSearchHint;

  /// No description provided for @booksRecent.
  ///
  /// In de, this message translates to:
  /// **'Neu in der Bibliothek'**
  String get booksRecent;

  /// No description provided for @booksAuthors.
  ///
  /// In de, this message translates to:
  /// **'Autoren'**
  String get booksAuthors;

  /// No description provided for @booksSeries.
  ///
  /// In de, this message translates to:
  /// **'Serien'**
  String get booksSeries;

  /// No description provided for @booksRequests.
  ///
  /// In de, this message translates to:
  /// **'Anfragen'**
  String get booksRequests;

  /// No description provided for @booksImport.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get booksImport;

  /// No description provided for @booksAll.
  ///
  /// In de, this message translates to:
  /// **'Alle Bücher'**
  String get booksAll;

  /// No description provided for @booksEmptyLibrary.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bücher. Suche nach einem Buch, um es anzufragen, oder importiere eigene Dateien.'**
  String get booksEmptyLibrary;

  /// No description provided for @booksInLibrary.
  ///
  /// In de, this message translates to:
  /// **'In deiner Bibliothek'**
  String get booksInLibrary;

  /// No description provided for @booksFromCatalog.
  ///
  /// In de, this message translates to:
  /// **'Zum Anfragen'**
  String get booksFromCatalog;

  /// No description provided for @booksNoResults.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get booksNoResults;

  /// No description provided for @booksRequestFree.
  ///
  /// In de, this message translates to:
  /// **'Nicht dabei? Selbst anfragen'**
  String get booksRequestFree;

  /// No description provided for @booksRequest.
  ///
  /// In de, this message translates to:
  /// **'Anfragen'**
  String get booksRequest;

  /// No description provided for @booksRequested.
  ///
  /// In de, this message translates to:
  /// **'Angefragt: {title}'**
  String booksRequested(String title);

  /// No description provided for @booksRequestsDisabled.
  ///
  /// In de, this message translates to:
  /// **'Automatische Downloads sind auf diesem Server aus. Du kannst Bücher aber importieren.'**
  String get booksRequestsDisabled;

  /// No description provided for @booksLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get booksLanguage;

  /// No description provided for @booksLanguageDe.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get booksLanguageDe;

  /// No description provided for @booksLanguageEn.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get booksLanguageEn;

  /// No description provided for @booksLanguageAny.
  ///
  /// In de, this message translates to:
  /// **'Egal'**
  String get booksLanguageAny;

  /// No description provided for @booksVolume.
  ///
  /// In de, this message translates to:
  /// **'Band {number}'**
  String booksVolume(String number);

  /// No description provided for @booksDownload.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen'**
  String get booksDownload;

  /// No description provided for @booksEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get booksEdit;

  /// No description provided for @booksDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get booksDelete;

  /// No description provided for @booksDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ aus der Bibliothek löschen?'**
  String booksDeleteConfirm(String title);

  /// No description provided for @booksTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get booksTitle;

  /// No description provided for @booksAuthorsField.
  ///
  /// In de, this message translates to:
  /// **'Autoren (mit Komma getrennt)'**
  String get booksAuthorsField;

  /// No description provided for @booksSeriesField.
  ///
  /// In de, this message translates to:
  /// **'Serie'**
  String get booksSeriesField;

  /// No description provided for @booksSeriesIndex.
  ///
  /// In de, this message translates to:
  /// **'Band'**
  String get booksSeriesIndex;

  /// No description provided for @booksStatusPending.
  ///
  /// In de, this message translates to:
  /// **'Wartet auf Freigabe'**
  String get booksStatusPending;

  /// No description provided for @booksStatusQueued.
  ///
  /// In de, this message translates to:
  /// **'In der Warteschlange'**
  String get booksStatusQueued;

  /// No description provided for @booksStatusSearching.
  ///
  /// In de, this message translates to:
  /// **'Wird gesucht'**
  String get booksStatusSearching;

  /// No description provided for @booksStatusDownloading.
  ///
  /// In de, this message translates to:
  /// **'Lädt'**
  String get booksStatusDownloading;

  /// No description provided for @booksStatusImporting.
  ///
  /// In de, this message translates to:
  /// **'Wird importiert'**
  String get booksStatusImporting;

  /// No description provided for @booksStatusDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get booksStatusDone;

  /// No description provided for @booksStatusFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagen'**
  String get booksStatusFailed;

  /// No description provided for @booksStatusCancelled.
  ///
  /// In de, this message translates to:
  /// **'Abgebrochen'**
  String get booksStatusCancelled;

  /// No description provided for @booksStatusRejected.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get booksStatusRejected;

  /// No description provided for @booksCancelRequest.
  ///
  /// In de, this message translates to:
  /// **'Anfrage abbrechen'**
  String get booksCancelRequest;

  /// No description provided for @booksRemoveRequest.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get booksRemoveRequest;

  /// No description provided for @booksApprove.
  ///
  /// In de, this message translates to:
  /// **'Freigeben'**
  String get booksApprove;

  /// No description provided for @booksReject.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get booksReject;

  /// No description provided for @booksNoRequests.
  ///
  /// In de, this message translates to:
  /// **'Keine Anfragen'**
  String get booksNoRequests;

  /// No description provided for @booksAllUsers.
  ///
  /// In de, this message translates to:
  /// **'Alle Nutzer'**
  String get booksAllUsers;

  /// No description provided for @booksImportFiles.
  ///
  /// In de, this message translates to:
  /// **'Dateien hochladen'**
  String get booksImportFiles;

  /// No description provided for @booksImportFilesHint.
  ///
  /// In de, this message translates to:
  /// **'EPUB, AZW3, MOBI oder PDF'**
  String get booksImportFilesHint;

  /// No description provided for @booksImportUrl.
  ///
  /// In de, this message translates to:
  /// **'Von Link importieren'**
  String get booksImportUrl;

  /// No description provided for @booksImportUrlLabel.
  ///
  /// In de, this message translates to:
  /// **'Link zur Buchdatei'**
  String get booksImportUrlLabel;

  /// No description provided for @booksImporting.
  ///
  /// In de, this message translates to:
  /// **'Wird importiert …'**
  String get booksImporting;

  /// No description provided for @booksImported.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Buch importiert} other{{count} Bücher importiert}}'**
  String booksImported(int count);

  /// No description provided for @booksImportFailed.
  ///
  /// In de, this message translates to:
  /// **'{name}: {error}'**
  String booksImportFailed(String name, String error);

  /// No description provided for @adminBooksEnable.
  ///
  /// In de, this message translates to:
  /// **'Ebooks aktivieren'**
  String get adminBooksEnable;

  /// No description provided for @adminBooksEnableHint.
  ///
  /// In de, this message translates to:
  /// **'Bücher-Tab, OPDS-Katalog (/opds) und KOReader-Sync (/kosync). Anmeldung dort mit dem App-Passwort.'**
  String get adminBooksEnableHint;

  /// No description provided for @adminBooksLanguage.
  ///
  /// In de, this message translates to:
  /// **'Standardsprache für Anfragen'**
  String get adminBooksLanguage;

  /// No description provided for @adminBooksGoogleKey.
  ///
  /// In de, this message translates to:
  /// **'Google-Books-API-Schlüssel'**
  String get adminBooksGoogleKey;

  /// No description provided for @adminBooksGoogleKeyHint.
  ///
  /// In de, this message translates to:
  /// **'Optional – ohne Schlüssel wird nur Audible durchsucht'**
  String get adminBooksGoogleKeyHint;

  /// No description provided for @adminBooksDailyLimit.
  ///
  /// In de, this message translates to:
  /// **'Bücher pro Nutzer und Tag (0 = unbegrenzt)'**
  String get adminBooksDailyLimit;

  /// No description provided for @adminBooksTorrentsHint.
  ///
  /// In de, this message translates to:
  /// **'Automatische Downloads nutzen die Torrent-Einstellungen unter Downloads.'**
  String get adminBooksTorrentsHint;

  /// No description provided for @editorSourceApple.
  ///
  /// In de, this message translates to:
  /// **'Apple Music'**
  String get editorSourceApple;

  /// No description provided for @editorSourceDiscogs.
  ///
  /// In de, this message translates to:
  /// **'Discogs'**
  String get editorSourceDiscogs;

  /// No description provided for @editorSourceDeezer.
  ///
  /// In de, this message translates to:
  /// **'Deezer'**
  String get editorSourceDeezer;

  /// No description provided for @editorSourceMusicBrainz.
  ///
  /// In de, this message translates to:
  /// **'MusicBrainz'**
  String get editorSourceMusicBrainz;

  /// No description provided for @adminDiscogsToken.
  ///
  /// In de, this message translates to:
  /// **'Discogs-Token'**
  String get adminDiscogsToken;

  /// No description provided for @adminDiscogsHint.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos unter discogs.com → Einstellungen → Entwickler'**
  String get adminDiscogsHint;

  /// No description provided for @adminLastfmKey.
  ///
  /// In de, this message translates to:
  /// **'Last.fm API-Key'**
  String get adminLastfmKey;

  /// No description provided for @adminLastfmHint.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos unter last.fm/api'**
  String get adminLastfmHint;

  /// No description provided for @adminFanartKey.
  ///
  /// In de, this message translates to:
  /// **'fanart.tv API-Key'**
  String get adminFanartKey;

  /// No description provided for @adminFillGenres.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Genres ergänzen (Last.fm)'**
  String get adminFillGenres;

  /// No description provided for @artistAbout.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get artistAbout;

  /// No description provided for @artistShowMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr anzeigen'**
  String get artistShowMore;

  /// No description provided for @artistShowLess.
  ///
  /// In de, this message translates to:
  /// **'Weniger anzeigen'**
  String get artistShowLess;

  /// No description provided for @adminDuplicatesSelectAll.
  ///
  /// In de, this message translates to:
  /// **'Alle auswählen'**
  String get adminDuplicatesSelectAll;

  /// No description provided for @adminDuplicatesSelectNone.
  ///
  /// In de, this message translates to:
  /// **'Keine auswählen'**
  String get adminDuplicatesSelectNone;

  /// No description provided for @adminDuplicatesProgress.
  ///
  /// In de, this message translates to:
  /// **'Lösche … {done} von {total}'**
  String adminDuplicatesProgress(int done, int total);

  /// No description provided for @settingsTvMode.
  ///
  /// In de, this message translates to:
  /// **'TV-/Controller-Modus'**
  String get settingsTvMode;

  /// No description provided for @settingsTvModeHint.
  ///
  /// In de, this message translates to:
  /// **'Große Oberfläche für Fernbedienung und Controller'**
  String get settingsTvModeHint;

  /// No description provided for @tvPlay.
  ///
  /// In de, this message translates to:
  /// **'Abspielen'**
  String get tvPlay;

  /// No description provided for @tvPause.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get tvPause;

  /// No description provided for @tvBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get tvBack;

  /// No description provided for @tvPopularStations.
  ///
  /// In de, this message translates to:
  /// **'Beliebte Sender'**
  String get tvPopularStations;

  /// No description provided for @changelogTitle.
  ///
  /// In de, this message translates to:
  /// **'Neuigkeiten'**
  String get changelogTitle;

  /// No description provided for @changelogInstalled.
  ///
  /// In de, this message translates to:
  /// **'Installiert'**
  String get changelogInstalled;

  /// No description provided for @changelogNewVersion.
  ///
  /// In de, this message translates to:
  /// **'Neu in Version {version}'**
  String changelogNewVersion(String version);

  /// No description provided for @changelogAll.
  ///
  /// In de, this message translates to:
  /// **'Alle Neuigkeiten'**
  String get changelogAll;

  /// No description provided for @navPodcasts.
  ///
  /// In de, this message translates to:
  /// **'Podcasts'**
  String get navPodcasts;

  /// No description provided for @podcastsContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiterhören'**
  String get podcastsContinue;

  /// No description provided for @podcastsNewEpisodes.
  ///
  /// In de, this message translates to:
  /// **'Neue Folgen'**
  String get podcastsNewEpisodes;

  /// No description provided for @podcastsYourPodcasts.
  ///
  /// In de, this message translates to:
  /// **'Deine Podcasts'**
  String get podcastsYourPodcasts;

  /// No description provided for @podcastsCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get podcastsCategories;

  /// No description provided for @podcastsSubscriptions.
  ///
  /// In de, this message translates to:
  /// **'Abos'**
  String get podcastsSubscriptions;

  /// No description provided for @podcastsSearch.
  ///
  /// In de, this message translates to:
  /// **'Podcasts suchen'**
  String get podcastsSearch;

  /// No description provided for @podcastsSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Podcasts suchen'**
  String get podcastsSearchHint;

  /// No description provided for @podcastsAddRss.
  ///
  /// In de, this message translates to:
  /// **'Per RSS-Link hinzufügen'**
  String get podcastsAddRss;

  /// No description provided for @podcastsAddFeedByUrl.
  ///
  /// In de, this message translates to:
  /// **'RSS-Feed hinzufügen'**
  String get podcastsAddFeedByUrl;

  /// No description provided for @podcastsNoResults.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden. Podcasts, die nur bei Spotify erscheinen, haben keinen offenen Feed – kennst du die RSS-Adresse, füge sie oben rechts hinzu.'**
  String get podcastsNoResults;

  /// No description provided for @podcastsRssUrl.
  ///
  /// In de, this message translates to:
  /// **'RSS-Link'**
  String get podcastsRssUrl;

  /// No description provided for @podcastsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Abos. Suche nach einem Podcast oder füge einen RSS-Link hinzu.'**
  String get podcastsEmpty;

  /// No description provided for @podcastsSubscribe.
  ///
  /// In de, this message translates to:
  /// **'Abonnieren'**
  String get podcastsSubscribe;

  /// No description provided for @podcastsSubscribed.
  ///
  /// In de, this message translates to:
  /// **'Abonniert'**
  String get podcastsSubscribed;

  /// No description provided for @podcastsUnsubscribe.
  ///
  /// In de, this message translates to:
  /// **'Abo beenden'**
  String get podcastsUnsubscribe;

  /// No description provided for @podcastsDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get podcastsDescription;

  /// No description provided for @podcastsEpisodes.
  ///
  /// In de, this message translates to:
  /// **'Episoden'**
  String get podcastsEpisodes;

  /// No description provided for @podcastsEpisode.
  ///
  /// In de, this message translates to:
  /// **'Podcast-Episode'**
  String get podcastsEpisode;

  /// No description provided for @podcastsCompleted.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get podcastsCompleted;

  /// No description provided for @podcastsLoadMore.
  ///
  /// In de, this message translates to:
  /// **'Weitere Episoden laden'**
  String get podcastsLoadMore;

  /// No description provided for @podcastsOpen.
  ///
  /// In de, this message translates to:
  /// **'Podcast öffnen'**
  String get podcastsOpen;

  /// No description provided for @podcastsSkipBack.
  ///
  /// In de, this message translates to:
  /// **'15 Sekunden zurück'**
  String get podcastsSkipBack;

  /// No description provided for @podcastsMarkPlayed.
  ///
  /// In de, this message translates to:
  /// **'Als gehört markieren'**
  String get podcastsMarkPlayed;

  /// No description provided for @podcastsMarkUnplayed.
  ///
  /// In de, this message translates to:
  /// **'Als ungehört markieren'**
  String get podcastsMarkUnplayed;

  /// No description provided for @podcastsMarkAllPlayed.
  ///
  /// In de, this message translates to:
  /// **'Alle als gehört markieren'**
  String get podcastsMarkAllPlayed;

  /// No description provided for @podcastsMarkAllUnplayed.
  ///
  /// In de, this message translates to:
  /// **'Alle als ungehört markieren'**
  String get podcastsMarkAllUnplayed;

  /// No description provided for @podcastsSort.
  ///
  /// In de, this message translates to:
  /// **'Reihenfolge'**
  String get podcastsSort;

  /// No description provided for @podcastsNewestFirst.
  ///
  /// In de, this message translates to:
  /// **'Neueste zuerst'**
  String get podcastsNewestFirst;

  /// No description provided for @podcastsOldestFirst.
  ///
  /// In de, this message translates to:
  /// **'Älteste zuerst'**
  String get podcastsOldestFirst;

  /// No description provided for @podcastsEpisodeStats.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Folge} other{{count} Folgen}} · {played} gehört'**
  String podcastsEpisodeStats(int count, int played);

  /// No description provided for @podcastsTimeLeft.
  ///
  /// In de, this message translates to:
  /// **'noch {time}'**
  String podcastsTimeLeft(String time);

  /// No description provided for @podcastsPlayed.
  ///
  /// In de, this message translates to:
  /// **'Gehört'**
  String get podcastsPlayed;

  /// No description provided for @podcastsShowNotes.
  ///
  /// In de, this message translates to:
  /// **'Shownotes'**
  String get podcastsShowNotes;

  /// No description provided for @podcastsPlayEpisode.
  ///
  /// In de, this message translates to:
  /// **'Folge abspielen'**
  String get podcastsPlayEpisode;

  /// No description provided for @podcastsMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get podcastsMore;

  /// No description provided for @podcastsLess.
  ///
  /// In de, this message translates to:
  /// **'Weniger'**
  String get podcastsLess;

  /// No description provided for @podcastsPlayFirstUnplayed.
  ///
  /// In de, this message translates to:
  /// **'Nächste ungehörte Folge abspielen'**
  String get podcastsPlayFirstUnplayed;

  /// No description provided for @podcastsRemoveAds.
  ///
  /// In de, this message translates to:
  /// **'Eingespielte Werbung entfernen'**
  String get podcastsRemoveAds;

  /// No description provided for @podcastsRemoveAdsHint.
  ///
  /// In de, this message translates to:
  /// **'Neue Folgen liegen kurz nach Erscheinen ohne eingespielte Werbespots bereit. Werbung, die die Hosts selbst sprechen, bleibt drin.'**
  String get podcastsRemoveAdsHint;

  /// No description provided for @podcastsAdsRemoved.
  ///
  /// In de, this message translates to:
  /// **'{time} Werbung entfernt'**
  String podcastsAdsRemoved(String time);

  /// No description provided for @playerPodcastLoadError.
  ///
  /// In de, this message translates to:
  /// **'Die Podcast-Episode konnte nicht geladen werden. Bitte versuche es erneut.'**
  String get playerPodcastLoadError;

  /// No description provided for @connectPlayOn.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe auf…'**
  String get connectPlayOn;

  /// No description provided for @connectThisDevice.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät'**
  String get connectThisDevice;

  /// No description provided for @connectDeviceName.
  ///
  /// In de, this message translates to:
  /// **'Gerätename'**
  String get connectDeviceName;

  /// No description provided for @connectPlayingOn.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe auf {device}'**
  String connectPlayingOn(String device);

  /// No description provided for @connectAway.
  ///
  /// In de, this message translates to:
  /// **'{device} ist nicht verbunden · Play setzt hier fort'**
  String connectAway(String device);

  /// No description provided for @connectOffline.
  ///
  /// In de, this message translates to:
  /// **'Nicht verbunden'**
  String get connectOffline;

  /// No description provided for @connectJamHint.
  ///
  /// In de, this message translates to:
  /// **'Während eines Jams ist kein Gerätewechsel möglich.'**
  String get connectJamHint;

  /// No description provided for @connectMusicOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur Musik kann übertragen werden. Hörbücher, Podcasts und Radio bleiben auf diesem Gerät.'**
  String get connectMusicOnly;

  /// No description provided for @connectUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Gerät nicht verfügbar. Prüfe deine Verbindung.'**
  String get connectUnavailable;

  /// No description provided for @tvFavoriteRemove.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernen'**
  String get tvFavoriteRemove;

  /// No description provided for @tvFavoriteAdd.
  ///
  /// In de, this message translates to:
  /// **'Zu Favoriten hinzufügen'**
  String get tvFavoriteAdd;

  /// No description provided for @tvAmbientOn.
  ///
  /// In de, this message translates to:
  /// **'Ruhemodus an'**
  String get tvAmbientOn;

  /// No description provided for @tvAmbientOff.
  ///
  /// In de, this message translates to:
  /// **'Ruhemodus aus'**
  String get tvAmbientOff;

  /// No description provided for @settingsTvAmbient.
  ///
  /// In de, this message translates to:
  /// **'Ruhemodus'**
  String get settingsTvAmbient;

  /// No description provided for @settingsTvAmbientHint.
  ///
  /// In de, this message translates to:
  /// **'Bei Inaktivität nur Cover und Titel zeigen'**
  String get settingsTvAmbientHint;

  /// No description provided for @ringtoneMenu.
  ///
  /// In de, this message translates to:
  /// **'Als Klingelton verwenden'**
  String get ringtoneMenu;

  /// No description provided for @ringtoneLength.
  ///
  /// In de, this message translates to:
  /// **'Länge'**
  String get ringtoneLength;

  /// No description provided for @ringtoneSeconds.
  ///
  /// In de, this message translates to:
  /// **'{seconds} s'**
  String ringtoneSeconds(int seconds);

  /// No description provided for @ringtoneRange.
  ///
  /// In de, this message translates to:
  /// **'{start} – {end}'**
  String ringtoneRange(String start, String end);

  /// No description provided for @ringtoneSuggested.
  ///
  /// In de, this message translates to:
  /// **'Vorschlag: die vollste Stelle des Songs, meist der Refrain'**
  String get ringtoneSuggested;

  /// No description provided for @coverflowBackSongs.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Song} other{{count} Songs}}'**
  String coverflowBackSongs(int count);

  /// No description provided for @ringtoneBackToSuggestion.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Vorschlag'**
  String get ringtoneBackToSuggestion;

  /// No description provided for @ringtonePreview.
  ///
  /// In de, this message translates to:
  /// **'Probehören'**
  String get ringtonePreview;

  /// No description provided for @ringtoneStopPreview.
  ///
  /// In de, this message translates to:
  /// **'Probe stoppen'**
  String get ringtoneStopPreview;

  /// No description provided for @ringtoneTypeRingtone.
  ///
  /// In de, this message translates to:
  /// **'Klingelton'**
  String get ringtoneTypeRingtone;

  /// No description provided for @ringtoneTypeNotification.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigung'**
  String get ringtoneTypeNotification;

  /// No description provided for @ringtoneTypeAlarm.
  ///
  /// In de, this message translates to:
  /// **'Wecker'**
  String get ringtoneTypeAlarm;

  /// No description provided for @ringtoneApply.
  ///
  /// In de, this message translates to:
  /// **'Festlegen'**
  String get ringtoneApply;

  /// No description provided for @ringtoneDone.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ ist jetzt dein {type, select, notification{Benachrichtigungston} alarm{Weckton} other{Klingelton}}'**
  String ringtoneDone(String title, String type);

  /// No description provided for @ringtoneSaved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert – wähle „{title}“ in den Toneinstellungen aus'**
  String ringtoneSaved(String title);

  /// No description provided for @ringtonePermissionTitle.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung nötig'**
  String get ringtonePermissionTitle;

  /// No description provided for @ringtonePermissionText.
  ///
  /// In de, this message translates to:
  /// **'Damit Resonance den Ton direkt festlegen kann, erlaube „Systemeinstellungen ändern“. Der Song ist schon gespeichert – ohne die Berechtigung wählst du ihn selbst in den Toneinstellungen aus.'**
  String get ringtonePermissionText;

  /// No description provided for @ringtonePermissionAllow.
  ///
  /// In de, this message translates to:
  /// **'Erlauben'**
  String get ringtonePermissionAllow;

  /// No description provided for @ringtonePermissionManual.
  ///
  /// In de, this message translates to:
  /// **'Selbst auswählen'**
  String get ringtonePermissionManual;

  /// No description provided for @ringtoneUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Klingeltöne aus Songs brauchen Android 10 oder neuer'**
  String get ringtoneUnsupported;

  /// No description provided for @mediaDownload.
  ///
  /// In de, this message translates to:
  /// **'Aufs Gerät laden'**
  String get mediaDownload;

  /// No description provided for @mediaDownloaded.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Gerät'**
  String get mediaDownloaded;

  /// No description provided for @mediaDownloading.
  ///
  /// In de, this message translates to:
  /// **'Wird aufs Gerät geladen …'**
  String get mediaDownloading;

  /// No description provided for @mediaRemoveTitle.
  ///
  /// In de, this message translates to:
  /// **'Vom Gerät löschen?'**
  String get mediaRemoveTitle;

  /// No description provided for @mediaRemove.
  ///
  /// In de, this message translates to:
  /// **'Vom Gerät löschen'**
  String get mediaRemove;

  /// No description provided for @mediaFailed.
  ///
  /// In de, this message translates to:
  /// **'Download fehlgeschlagen – tippen zum Wiederholen'**
  String get mediaFailed;

  /// No description provided for @mediaSection.
  ///
  /// In de, this message translates to:
  /// **'Podcasts, Hörbücher & E-Books'**
  String get mediaSection;

  /// No description provided for @mediaSectionEpisodes.
  ///
  /// In de, this message translates to:
  /// **'Heruntergeladene Folgen'**
  String get mediaSectionEpisodes;

  /// No description provided for @mediaOfflineEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Folgen, Hörbücher oder E-Books auf dem Gerät. Lade sie mit dem Download-Symbol herunter, solange du online bist.'**
  String get mediaOfflineEmpty;

  /// No description provided for @mediaOpen.
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get mediaOpen;

  /// No description provided for @mediaOpenFailed.
  ///
  /// In de, this message translates to:
  /// **'Keine App zum Öffnen dieser Datei gefunden'**
  String get mediaOpenFailed;

  /// No description provided for @mediaStorage.
  ///
  /// In de, this message translates to:
  /// **'Podcasts, Hörbücher & E-Books'**
  String get mediaStorage;

  /// No description provided for @mediaStorageUsed.
  ///
  /// In de, this message translates to:
  /// **'{size} • {count} auf dem Gerät'**
  String mediaStorageUsed(String size, int count);

  /// No description provided for @mediaKindEpisode.
  ///
  /// In de, this message translates to:
  /// **'Podcast-Folge'**
  String get mediaKindEpisode;

  /// No description provided for @mediaKindEbook.
  ///
  /// In de, this message translates to:
  /// **'E-Book'**
  String get mediaKindEbook;

  /// No description provided for @settingsTransitionEditor.
  ///
  /// In de, this message translates to:
  /// **'Übergangs-Editor (Beta)'**
  String get settingsTransitionEditor;

  /// No description provided for @settingsTransitionEditorHint.
  ///
  /// In de, this message translates to:
  /// **'Playlists bekommen einen Mix-Knopf. Damit siehst du die Übergänge zwischen den Songs mit BPM und Tonart und kannst sie selbst einstellen.'**
  String get settingsTransitionEditorHint;

  /// No description provided for @transitionAuto.
  ///
  /// In de, this message translates to:
  /// **'Automatisch'**
  String get transitionAuto;

  /// No description provided for @transitionCrossfade.
  ///
  /// In de, this message translates to:
  /// **'Überblenden'**
  String get transitionCrossfade;

  /// No description provided for @transitionFadeIn.
  ///
  /// In de, this message translates to:
  /// **'Einblenden'**
  String get transitionFadeIn;

  /// No description provided for @transitionFadeOut.
  ///
  /// In de, this message translates to:
  /// **'Ausblenden'**
  String get transitionFadeOut;

  /// No description provided for @transitionFilter.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get transitionFilter;

  /// No description provided for @transitionBars.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Takt} other{{count} Takte}}'**
  String transitionBars(int count);

  /// No description provided for @transitionPresets.
  ///
  /// In de, this message translates to:
  /// **'Voreinstellungen'**
  String get transitionPresets;

  /// No description provided for @transitionVolume.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke'**
  String get transitionVolume;

  /// No description provided for @transitionEq.
  ///
  /// In de, this message translates to:
  /// **'EQ'**
  String get transitionEq;

  /// No description provided for @transitionVolumeAuto.
  ///
  /// In de, this message translates to:
  /// **'Passend zu den Songs'**
  String get transitionVolumeAuto;

  /// No description provided for @transitionVolumeCrossfade.
  ///
  /// In de, this message translates to:
  /// **'Gleichmäßig überblenden'**
  String get transitionVolumeCrossfade;

  /// No description provided for @transitionVolumeFadeIn.
  ///
  /// In de, this message translates to:
  /// **'Einblenden und hart ausblenden'**
  String get transitionVolumeFadeIn;

  /// No description provided for @transitionVolumeFadeOut.
  ///
  /// In de, this message translates to:
  /// **'Ausblenden, dann einblenden'**
  String get transitionVolumeFadeOut;

  /// No description provided for @transitionVolumeFilter.
  ///
  /// In de, this message translates to:
  /// **'Wegfiltern und schnell einblenden'**
  String get transitionVolumeFilter;

  /// No description provided for @transitionEqSwap.
  ///
  /// In de, this message translates to:
  /// **'Basswechsel in Übergangsmitte'**
  String get transitionEqSwap;

  /// No description provided for @transitionEqSweep.
  ///
  /// In de, this message translates to:
  /// **'Vom Bass aufwärts wegfiltern'**
  String get transitionEqSweep;

  /// No description provided for @transitionReset.
  ///
  /// In de, this message translates to:
  /// **'Auf Automatisch zurücksetzen'**
  String get transitionReset;

  /// No description provided for @transitionPreview.
  ///
  /// In de, this message translates to:
  /// **'Probehören'**
  String get transitionPreview;

  /// No description provided for @transitionStopPreview.
  ///
  /// In de, this message translates to:
  /// **'Probehören beenden'**
  String get transitionStopPreview;

  /// No description provided for @transitionNeedsAutomix.
  ///
  /// In de, this message translates to:
  /// **'Übergänge und Probehören brauchen AutoMix. Schalte es in den Einstellungen ein.'**
  String get transitionNeedsAutomix;

  /// No description provided for @transitionSaved.
  ///
  /// In de, this message translates to:
  /// **'Übergang gespeichert'**
  String get transitionSaved;

  /// No description provided for @transitionNotAnalyzed.
  ///
  /// In de, this message translates to:
  /// **'Die Songs sind noch nicht analysiert. Versuch es gleich noch einmal.'**
  String get transitionNotAnalyzed;

  /// No description provided for @transitionDragHint.
  ///
  /// In de, this message translates to:
  /// **'Ziehe eine Spur, um Start oder Einsatz zu verschieben.'**
  String get transitionDragHint;

  /// No description provided for @transitionViewOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur wer die Playlist bearbeiten darf, kann Übergänge ändern.'**
  String get transitionViewOnly;

  /// No description provided for @transitionEdit.
  ///
  /// In de, this message translates to:
  /// **'Übergang bearbeiten'**
  String get transitionEdit;

  /// No description provided for @transitionMixOn.
  ///
  /// In de, this message translates to:
  /// **'Mixen'**
  String get transitionMixOn;

  /// No description provided for @transitionMixOff.
  ///
  /// In de, this message translates to:
  /// **'Mixen beenden'**
  String get transitionMixOff;

  /// No description provided for @playlistRecommended.
  ///
  /// In de, this message translates to:
  /// **'Empfohlene Songs'**
  String get playlistRecommended;

  /// No description provided for @playlistRecommendedFromPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Basierend auf den Songs in dieser Playlist'**
  String get playlistRecommendedFromPlaylist;

  /// No description provided for @playlistRecommendedFromLikes.
  ///
  /// In de, this message translates to:
  /// **'Basierend auf deinen Lieblingssongs'**
  String get playlistRecommendedFromLikes;

  /// No description provided for @playlistNoRecommendations.
  ///
  /// In de, this message translates to:
  /// **'Gerade keine Empfehlungen.'**
  String get playlistNoRecommendations;

  /// No description provided for @playlistRefreshRecommendations.
  ///
  /// In de, this message translates to:
  /// **'Neue Vorschläge'**
  String get playlistRefreshRecommendations;

  /// No description provided for @playlistSearchSongs.
  ///
  /// In de, this message translates to:
  /// **'Nach Songs suchen'**
  String get playlistSearchSongs;

  /// No description provided for @playlistFindSomething.
  ///
  /// In de, this message translates to:
  /// **'Lass uns etwas für deine Playlist finden'**
  String get playlistFindSomething;

  /// No description provided for @playlistSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Songs suchen'**
  String get playlistSearchHint;

  /// No description provided for @playlistSearchEmpty.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Songs, um sie direkt zur Playlist hinzuzufügen.'**
  String get playlistSearchEmpty;

  /// No description provided for @playlistSearchNothing.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden für „{query}“'**
  String playlistSearchNothing(Object query);

  /// No description provided for @playlistAddSong.
  ///
  /// In de, this message translates to:
  /// **'Zur Playlist hinzufügen'**
  String get playlistAddSong;

  /// No description provided for @playlistAdded.
  ///
  /// In de, this message translates to:
  /// **'Hinzugefügt'**
  String get playlistAdded;

  /// No description provided for @transitionCustom.
  ///
  /// In de, this message translates to:
  /// **'Benutzerdefiniert'**
  String get transitionCustom;

  /// No description provided for @transitionNone.
  ///
  /// In de, this message translates to:
  /// **'Keine'**
  String get transitionNone;

  /// No description provided for @transitionFilterLane.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get transitionFilterLane;

  /// No description provided for @transitionEffects.
  ///
  /// In de, this message translates to:
  /// **'Effekte'**
  String get transitionEffects;

  /// No description provided for @transitionLooping.
  ///
  /// In de, this message translates to:
  /// **'Looping'**
  String get transitionLooping;

  /// No description provided for @transitionBeatmatching.
  ///
  /// In de, this message translates to:
  /// **'Beatmatching'**
  String get transitionBeatmatching;

  /// No description provided for @transitionBeatmatchingHint.
  ///
  /// In de, this message translates to:
  /// **'Gleicht das Tempo der Songs an, damit die Beats übereinander liegen.'**
  String get transitionBeatmatchingHint;

  /// No description provided for @transitionEchoOut.
  ///
  /// In de, this message translates to:
  /// **'Echo-Ausstieg'**
  String get transitionEchoOut;

  /// No description provided for @transitionLoopOut.
  ///
  /// In de, this message translates to:
  /// **'Loop-Ausstieg'**
  String get transitionLoopOut;

  /// No description provided for @transitionCut.
  ///
  /// In de, this message translates to:
  /// **'Harter Schnitt'**
  String get transitionCut;

  /// No description provided for @volumeSmooth.
  ///
  /// In de, this message translates to:
  /// **'Nahtlos überblenden'**
  String get volumeSmooth;

  /// No description provided for @volumeOverlap.
  ///
  /// In de, this message translates to:
  /// **'Überlappung'**
  String get volumeOverlap;

  /// No description provided for @volumeFadeInOut.
  ///
  /// In de, this message translates to:
  /// **'Einblenden und ausblenden'**
  String get volumeFadeInOut;

  /// No description provided for @volumeHardInFadeOut.
  ///
  /// In de, this message translates to:
  /// **'Hart einblenden und ausblenden'**
  String get volumeHardInFadeOut;

  /// No description provided for @volumeFadeInHardOut.
  ///
  /// In de, this message translates to:
  /// **'Einblenden und hart ausblenden'**
  String get volumeFadeInHardOut;

  /// No description provided for @volumeCenterCut.
  ///
  /// In de, this message translates to:
  /// **'Zentraler Schnitt'**
  String get volumeCenterCut;

  /// No description provided for @volumeCrossfade.
  ///
  /// In de, this message translates to:
  /// **'Überblenden'**
  String get volumeCrossfade;

  /// No description provided for @volumeFadeInQuickOut.
  ///
  /// In de, this message translates to:
  /// **'Einblenden und schnell ausblenden'**
  String get volumeFadeInQuickOut;

  /// No description provided for @volumeFadeInCutBar.
  ///
  /// In de, this message translates to:
  /// **'Einblenden, hart ausblenden, 1 Takt verbleibend'**
  String get volumeFadeInCutBar;

  /// No description provided for @volumeOverlapCutBar.
  ///
  /// In de, this message translates to:
  /// **'Überlappung, hart ausblenden, 1 Takt verbleibend'**
  String get volumeOverlapCutBar;

  /// No description provided for @eqSwapMiddle.
  ///
  /// In de, this message translates to:
  /// **'Basswechsel in Übergangsmitte'**
  String get eqSwapMiddle;

  /// No description provided for @eqSwapEnd.
  ///
  /// In de, this message translates to:
  /// **'Basswechsel am Übergangsende'**
  String get eqSwapEnd;

  /// No description provided for @eqSwapStart.
  ///
  /// In de, this message translates to:
  /// **'Basswechsel am Übergangsstart'**
  String get eqSwapStart;

  /// No description provided for @eqThreeBand.
  ///
  /// In de, this message translates to:
  /// **'3-Frequenz-Überblendung'**
  String get eqThreeBand;

  /// No description provided for @eqQuickBassCut.
  ///
  /// In de, this message translates to:
  /// **'Schnelle Bassabsenkung'**
  String get eqQuickBassCut;

  /// No description provided for @eqLongBassCut.
  ///
  /// In de, this message translates to:
  /// **'Lange Bassabsenkung'**
  String get eqLongBassCut;

  /// No description provided for @eqBassFadeOut.
  ///
  /// In de, this message translates to:
  /// **'Bass ausblenden'**
  String get eqBassFadeOut;

  /// No description provided for @filterLowpassOut.
  ///
  /// In de, this message translates to:
  /// **'Tiefpassfilter ausgehend'**
  String get filterLowpassOut;

  /// No description provided for @filterLowpassIn.
  ///
  /// In de, this message translates to:
  /// **'Tiefpassfilter eingehend'**
  String get filterLowpassIn;

  /// No description provided for @filterLowpassInOut.
  ///
  /// In de, this message translates to:
  /// **'Tiefpassfilter eingehend und ausgehend'**
  String get filterLowpassInOut;

  /// No description provided for @filterLowpassInHighpassOut.
  ///
  /// In de, this message translates to:
  /// **'Tiefpass eingehend, Hochpass ausgehend'**
  String get filterLowpassInHighpassOut;

  /// No description provided for @filterHighpassOut.
  ///
  /// In de, this message translates to:
  /// **'Hochpassfilter ausgehend'**
  String get filterHighpassOut;

  /// No description provided for @filterHighpassIn.
  ///
  /// In de, this message translates to:
  /// **'Hochpassfilter eingehend'**
  String get filterHighpassIn;

  /// No description provided for @filterHighpassInOut.
  ///
  /// In de, this message translates to:
  /// **'Hochpassfilter eingehend und ausgehend'**
  String get filterHighpassInOut;

  /// No description provided for @filterHighpassInLowpassOut.
  ///
  /// In de, this message translates to:
  /// **'Hochpass eingehend, Tiefpass ausgehend'**
  String get filterHighpassInLowpassOut;

  /// No description provided for @filterHighpassHalf.
  ///
  /// In de, this message translates to:
  /// **'Sanfter Hochpassfilter ausgehend'**
  String get filterHighpassHalf;

  /// No description provided for @filterNoiseEnd.
  ///
  /// In de, this message translates to:
  /// **'Rauschen am Übergangsende'**
  String get filterNoiseEnd;

  /// No description provided for @effectFlanger.
  ///
  /// In de, this message translates to:
  /// **'Flanger (nur PC)'**
  String get effectFlanger;

  /// No description provided for @effectPhaser.
  ///
  /// In de, this message translates to:
  /// **'Phaser (nur PC)'**
  String get effectPhaser;

  /// No description provided for @effectGate.
  ///
  /// In de, this message translates to:
  /// **'Gater auf Achteln (nur PC)'**
  String get effectGate;

  /// No description provided for @effectBeatRoll.
  ///
  /// In de, this message translates to:
  /// **'Beat-Roll: 1 → 1/16 Schlag (nur PC)'**
  String get effectBeatRoll;

  /// No description provided for @transitionZoomIn.
  ///
  /// In de, this message translates to:
  /// **'Heranzoomen'**
  String get transitionZoomIn;

  /// No description provided for @transitionZoomOut.
  ///
  /// In de, this message translates to:
  /// **'Herauszoomen'**
  String get transitionZoomOut;

  /// No description provided for @transitionDraw.
  ///
  /// In de, this message translates to:
  /// **'Kurven zeichnen'**
  String get transitionDraw;

  /// No description provided for @transitionBass.
  ///
  /// In de, this message translates to:
  /// **'Bass'**
  String get transitionBass;

  /// No description provided for @transitionDrawn.
  ///
  /// In de, this message translates to:
  /// **'Von Hand gezeichnet'**
  String get transitionDrawn;

  /// No description provided for @transitionDrawReset.
  ///
  /// In de, this message translates to:
  /// **'Kurve zurücksetzen'**
  String get transitionDrawReset;

  /// No description provided for @transitionDrawHint.
  ///
  /// In de, this message translates to:
  /// **'Klicken setzt einen Punkt, Ziehen verschiebt ihn, Rechtsklick oder langes Drücken entfernt ihn. Oben der aktuelle Song, unten der nächste.'**
  String get transitionDrawHint;

  /// No description provided for @effectBrake.
  ///
  /// In de, this message translates to:
  /// **'Bremse wie am Plattenspieler (nur PC)'**
  String get effectBrake;

  /// No description provided for @effectReverbMiddle.
  ///
  /// In de, this message translates to:
  /// **'Hall, Song endet in der Mitte'**
  String get effectReverbMiddle;

  /// No description provided for @effectReverbCut.
  ///
  /// In de, this message translates to:
  /// **'Hall, Schnitt am Übergangsende'**
  String get effectReverbCut;

  /// No description provided for @effectReverbTail.
  ///
  /// In de, this message translates to:
  /// **'Hall klingt bis zum Übergangsende aus'**
  String get effectReverbTail;

  /// No description provided for @effectEchoCut.
  ///
  /// In de, this message translates to:
  /// **'Echo pro {beat} Beat, Schnitt am Übergangsende'**
  String effectEchoCut(Object beat);

  /// No description provided for @effectEchoTail.
  ///
  /// In de, this message translates to:
  /// **'Echo pro {beat} Beat klingt bis zum Übergangsende aus'**
  String effectEchoTail(Object beat);

  /// No description provided for @effectDelayCut.
  ///
  /// In de, this message translates to:
  /// **'Verzögerung pro {beat} Beat, Schnitt am Übergangsende'**
  String effectDelayCut(Object beat);

  /// No description provided for @loopBeats.
  ///
  /// In de, this message translates to:
  /// **'{count}-Beat-Loop'**
  String loopBeats(int count);

  /// No description provided for @transitionFxUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Effekte, Filter und Loops gehen auf diesem Gerät nicht; du hörst nur die Lautstärke.'**
  String get transitionFxUnavailable;

  /// No description provided for @creditsTitle.
  ///
  /// In de, this message translates to:
  /// **'Mitwirkende'**
  String get creditsTitle;

  /// No description provided for @creditsShow.
  ///
  /// In de, this message translates to:
  /// **'Mitwirkende anzeigen'**
  String get creditsShow;

  /// No description provided for @creditsShowAll.
  ///
  /// In de, this message translates to:
  /// **'Alle anzeigen'**
  String get creditsShowAll;

  /// No description provided for @creditsPerformers.
  ///
  /// In de, this message translates to:
  /// **'Interpretiert von'**
  String get creditsPerformers;

  /// No description provided for @creditsWriters.
  ///
  /// In de, this message translates to:
  /// **'Geschrieben von'**
  String get creditsWriters;

  /// No description provided for @creditsProducers.
  ///
  /// In de, this message translates to:
  /// **'Produziert von'**
  String get creditsProducers;

  /// No description provided for @creditsEngineers.
  ///
  /// In de, this message translates to:
  /// **'Technik'**
  String get creditsEngineers;

  /// No description provided for @creditsLabel.
  ///
  /// In de, this message translates to:
  /// **'Label'**
  String get creditsLabel;

  /// No description provided for @creditsSources.
  ///
  /// In de, this message translates to:
  /// **'Quelle: {sources}'**
  String creditsSources(Object sources);

  /// No description provided for @creditsSourceTags.
  ///
  /// In de, this message translates to:
  /// **'Dateiinfos'**
  String get creditsSourceTags;

  /// No description provided for @creditRoleArtist.
  ///
  /// In de, this message translates to:
  /// **'Künstler'**
  String get creditRoleArtist;

  /// No description provided for @creditRoleFeatured.
  ///
  /// In de, this message translates to:
  /// **'Gastkünstler'**
  String get creditRoleFeatured;

  /// No description provided for @creditRoleComposer.
  ///
  /// In de, this message translates to:
  /// **'Komposition'**
  String get creditRoleComposer;

  /// No description provided for @creditRoleLyricist.
  ///
  /// In de, this message translates to:
  /// **'Text'**
  String get creditRoleLyricist;

  /// No description provided for @creditRoleWriter.
  ///
  /// In de, this message translates to:
  /// **'Songwriter'**
  String get creditRoleWriter;

  /// No description provided for @creditRoleArranger.
  ///
  /// In de, this message translates to:
  /// **'Arrangement'**
  String get creditRoleArranger;

  /// No description provided for @creditRoleProducer.
  ///
  /// In de, this message translates to:
  /// **'Produktion'**
  String get creditRoleProducer;

  /// No description provided for @creditRoleCoProducer.
  ///
  /// In de, this message translates to:
  /// **'Co-Produktion'**
  String get creditRoleCoProducer;

  /// No description provided for @creditRoleExecutiveProducer.
  ///
  /// In de, this message translates to:
  /// **'Executive Producer'**
  String get creditRoleExecutiveProducer;

  /// No description provided for @creditRoleMix.
  ///
  /// In de, this message translates to:
  /// **'Mixing'**
  String get creditRoleMix;

  /// No description provided for @creditRoleMastering.
  ///
  /// In de, this message translates to:
  /// **'Mastering'**
  String get creditRoleMastering;

  /// No description provided for @creditRoleRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme'**
  String get creditRoleRecording;

  /// No description provided for @creditRoleEngineer.
  ///
  /// In de, this message translates to:
  /// **'Toningenieur'**
  String get creditRoleEngineer;

  /// No description provided for @creditRoleProgramming.
  ///
  /// In de, this message translates to:
  /// **'Programmierung'**
  String get creditRoleProgramming;

  /// No description provided for @creditRoleVocals.
  ///
  /// In de, this message translates to:
  /// **'Gesang'**
  String get creditRoleVocals;

  /// No description provided for @creditRoleBackgroundVocals.
  ///
  /// In de, this message translates to:
  /// **'Hintergrundgesang'**
  String get creditRoleBackgroundVocals;

  /// No description provided for @creditRolePerformer.
  ///
  /// In de, this message translates to:
  /// **'Musiker'**
  String get creditRolePerformer;

  /// No description provided for @libraryCreate.
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get libraryCreate;

  /// No description provided for @blendCreate.
  ///
  /// In de, this message translates to:
  /// **'Blend'**
  String get blendCreate;

  /// No description provided for @blendKind.
  ///
  /// In de, this message translates to:
  /// **'Blend'**
  String get blendKind;

  /// No description provided for @blendPickUser.
  ///
  /// In de, this message translates to:
  /// **'Blend mit …'**
  String get blendPickUser;

  /// No description provided for @blendHint.
  ///
  /// In de, this message translates to:
  /// **'Eine gemeinsame Playlist aus eurem Geschmack, jeden Tag neu. Ihr seht sie beide unter „Für dich“.'**
  String get blendHint;

  /// No description provided for @blendNoUsers.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Server gibt es niemanden, mit dem du einen Blend machen kannst.'**
  String get blendNoUsers;

  /// No description provided for @blendWaiting.
  ///
  /// In de, this message translates to:
  /// **'Blend mit {name} erstellt. Sobald ihr beide etwas gehört oder geliked habt, erscheint er unter „Für dich“.'**
  String blendWaiting(Object name);

  /// No description provided for @blendLeave.
  ///
  /// In de, this message translates to:
  /// **'Blend verlassen'**
  String get blendLeave;

  /// No description provided for @blendLeaveConfirm.
  ///
  /// In de, this message translates to:
  /// **'Der Blend mit {name} wird für euch beide gelöscht.'**
  String blendLeaveConfirm(Object name);

  /// No description provided for @releaseRadar.
  ///
  /// In de, this message translates to:
  /// **'Neuerscheinungen'**
  String get releaseRadar;

  /// No description provided for @adminReleaseRadarHint.
  ///
  /// In de, this message translates to:
  /// **'Jeden Freitag neue Songs der meistgehörten Künstler jedes Nutzers, fehlende werden heruntergeladen'**
  String get adminReleaseRadarHint;

  /// No description provided for @adminReleaseRadarSize.
  ///
  /// In de, this message translates to:
  /// **'Songs in den Neuerscheinungen (10–100)'**
  String get adminReleaseRadarSize;

  /// No description provided for @wrappedSettingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Jahresrückblick'**
  String get wrappedSettingsTitle;

  /// No description provided for @wrappedSettingsHint.
  ///
  /// In de, this message translates to:
  /// **'Deine meistgehörten Songs, Künstler und Genres des Jahres'**
  String get wrappedSettingsHint;

  /// No description provided for @wrappedBannerTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein {year} in Musik'**
  String wrappedBannerTitle(Object year);

  /// No description provided for @wrappedBannerText.
  ///
  /// In de, this message translates to:
  /// **'Dein Jahresrückblick ist da – sieh dir an, was du gehört hast.'**
  String get wrappedBannerText;

  /// No description provided for @wrappedEmpty.
  ///
  /// In de, this message translates to:
  /// **'Für {year} gibt es noch keine Wiedergaben.'**
  String wrappedEmpty(Object year);

  /// No description provided for @wrappedYearButton.
  ///
  /// In de, this message translates to:
  /// **'Rückblick {year} ansehen'**
  String wrappedYearButton(Object year);

  /// No description provided for @wrappedIntroKicker.
  ///
  /// In de, this message translates to:
  /// **'Dein Jahresrückblick'**
  String get wrappedIntroKicker;

  /// No description provided for @wrappedIntroTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein {year} in Musik'**
  String wrappedIntroTitle(Object year);

  /// No description provided for @wrappedIntroHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe rechts für weiter, links für zurück. Halte gedrückt zum Anhalten.'**
  String get wrappedIntroHint;

  /// No description provided for @wrappedMinutesBefore.
  ///
  /// In de, this message translates to:
  /// **'Dieses Jahr hast du'**
  String get wrappedMinutesBefore;

  /// No description provided for @wrappedMinutesAfter.
  ///
  /// In de, this message translates to:
  /// **'Minuten Musik gehört.'**
  String get wrappedMinutesAfter;

  /// No description provided for @wrappedMinutesDays.
  ///
  /// In de, this message translates to:
  /// **'Das sind {days} Tage am Stück.'**
  String wrappedMinutesDays(Object days);

  /// No description provided for @wrappedTopDay.
  ///
  /// In de, this message translates to:
  /// **'Am meisten am {day}: {minutes} Minuten an einem Tag.'**
  String wrappedTopDay(Object day, Object minutes);

  /// No description provided for @wrappedGenresTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Top-Genres'**
  String get wrappedGenresTitle;

  /// No description provided for @wrappedTopArtistKicker.
  ///
  /// In de, this message translates to:
  /// **'Dein Künstler des Jahres'**
  String get wrappedTopArtistKicker;

  /// No description provided for @wrappedArtistStats.
  ///
  /// In de, this message translates to:
  /// **'{plays} Wiedergaben · {minutes} Minuten'**
  String wrappedArtistStats(Object minutes, Object plays);

  /// No description provided for @wrappedTopArtistsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Top-Künstler'**
  String get wrappedTopArtistsTitle;

  /// No description provided for @wrappedPlays.
  ///
  /// In de, this message translates to:
  /// **'{plays} Wiedergaben'**
  String wrappedPlays(Object plays);

  /// No description provided for @wrappedTopSongKicker.
  ///
  /// In de, this message translates to:
  /// **'Dein Song des Jahres'**
  String get wrappedTopSongKicker;

  /// No description provided for @wrappedSongStats.
  ///
  /// In de, this message translates to:
  /// **'{plays}-mal gehört'**
  String wrappedSongStats(Object plays);

  /// No description provided for @wrappedPlay.
  ///
  /// In de, this message translates to:
  /// **'Abspielen'**
  String get wrappedPlay;

  /// No description provided for @wrappedTopSongsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Top-Songs'**
  String get wrappedTopSongsTitle;

  /// No description provided for @wrappedClockKicker.
  ///
  /// In de, this message translates to:
  /// **'Du hörst am liebsten'**
  String get wrappedClockKicker;

  /// No description provided for @wrappedMorning.
  ///
  /// In de, this message translates to:
  /// **'morgens'**
  String get wrappedMorning;

  /// No description provided for @wrappedAfternoon.
  ///
  /// In de, this message translates to:
  /// **'tagsüber'**
  String get wrappedAfternoon;

  /// No description provided for @wrappedEvening.
  ///
  /// In de, this message translates to:
  /// **'abends'**
  String get wrappedEvening;

  /// No description provided for @wrappedNight.
  ///
  /// In de, this message translates to:
  /// **'nachts'**
  String get wrappedNight;

  /// No description provided for @wrappedPeakHour.
  ///
  /// In de, this message translates to:
  /// **'Die meiste Musik lief um {time} Uhr.'**
  String wrappedPeakHour(Object time);

  /// No description provided for @wrappedBestMonth.
  ///
  /// In de, this message translates to:
  /// **'Dein stärkster Monat: {month}'**
  String wrappedBestMonth(Object month);

  /// No description provided for @wrappedVarietyKicker.
  ///
  /// In de, this message translates to:
  /// **'Du warst neugierig'**
  String get wrappedVarietyKicker;

  /// No description provided for @wrappedDifferentSongs.
  ///
  /// In de, this message translates to:
  /// **'verschiedene Songs'**
  String get wrappedDifferentSongs;

  /// No description provided for @wrappedDifferentArtists.
  ///
  /// In de, this message translates to:
  /// **'verschiedene Künstler'**
  String get wrappedDifferentArtists;

  /// No description provided for @wrappedNewArtists.
  ///
  /// In de, this message translates to:
  /// **'{count} davon hast du dieses Jahr zum ersten Mal gehört.'**
  String wrappedNewArtists(Object count);

  /// No description provided for @wrappedFirstSong.
  ///
  /// In de, this message translates to:
  /// **'Dein erster Song des Jahres'**
  String get wrappedFirstSong;

  /// No description provided for @wrappedSummaryTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein {year}'**
  String wrappedSummaryTitle(Object year);

  /// No description provided for @wrappedMinutesLabel.
  ///
  /// In de, this message translates to:
  /// **'Minuten gehört'**
  String get wrappedMinutesLabel;

  /// No description provided for @wrappedTopGenreLabel.
  ///
  /// In de, this message translates to:
  /// **'Top-Genre'**
  String get wrappedTopGenreLabel;

  /// No description provided for @wrappedSavePlaylist.
  ///
  /// In de, this message translates to:
  /// **'Top-Songs als Playlist'**
  String get wrappedSavePlaylist;

  /// No description provided for @wrappedOpenPlaylist.
  ///
  /// In de, this message translates to:
  /// **'Playlist öffnen'**
  String get wrappedOpenPlaylist;

  /// No description provided for @wrappedUpdatePlaylist.
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get wrappedUpdatePlaylist;

  /// No description provided for @wrappedReplay.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get wrappedReplay;

  /// No description provided for @wrappedPlaylistName.
  ///
  /// In de, this message translates to:
  /// **'Deine Top-Songs {year}'**
  String wrappedPlaylistName(Object year);

  /// No description provided for @wrappedPlaylistDescription.
  ///
  /// In de, this message translates to:
  /// **'Deine 100 meistgehörten Songs {year}'**
  String wrappedPlaylistDescription(Object year);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
