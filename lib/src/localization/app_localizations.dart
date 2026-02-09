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
/// import 'localization/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Provides a string to disable spellcheck in the json. NOT FOR USE IN THE APPLICATION
  ///
  /// In en, this message translates to:
  /// **''**
  String get disableSpellCheck;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'ReqIf Editor'**
  String get appTitle;

  /// Main menu item
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// Text for a menu entry to see information about the application
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Text for a menu entry to see a help page
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Text for a menu entry to open a new file
  ///
  /// In en, this message translates to:
  /// **'Open File...'**
  String get openFile;

  /// Text for a menu entry to save the file
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Text for a menu entry to save the file as
  ///
  /// In en, this message translates to:
  /// **'Save as...'**
  String get saveAs;

  /// Text for a menu entry to quit the application
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Text for a menu entry to get to the settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Text for a menu entry to select the light theme
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// Text for a menu entry to select the dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// Text for a menu entry to select the automatic theme
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// Text for a menu entry to select the theme
  ///
  /// In en, this message translates to:
  /// **'Theme:'**
  String get themeSelection;

  /// Heading for the general settings block
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSettings;

  /// Heading for the appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Heading for the save section
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// Description for a settings checkbox
  ///
  /// In en, this message translates to:
  /// **'Update the document\'s UUID when saving'**
  String get settingsSaveUpdateUUID;

  /// Description for a settings checkbox
  ///
  /// In en, this message translates to:
  /// **'Update the document\'s creation time when saving'**
  String get settingsSaveUpdateTime;

  /// Description for a settings checkbox
  ///
  /// In en, this message translates to:
  /// **'Update the tool ID when saving'**
  String get settingsSaveUpdateTool;

  /// Description for a settings combobox
  ///
  /// In en, this message translates to:
  /// **'Select the line endings to use:'**
  String get settingsLineEndings;

  /// Text for a cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Text for a save button
  ///
  /// In en, this message translates to:
  /// **'Save and quit'**
  String get saveAndExit;

  /// Text for a quit button
  ///
  /// In en, this message translates to:
  /// **'Quit without saving'**
  String get quitWithoutSaving;

  /// Title for the unsaved changes dialog
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// Title for the edit comment text field
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Text for the file edit modal dialog
  ///
  /// In en, this message translates to:
  /// **'File properties'**
  String get modalEditFileText;

  /// Text for the part edit modal dialog
  ///
  /// In en, this message translates to:
  /// **'Properties of this specification part:'**
  String get modalEditPartText;

  /// Text for close buttons
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Tooltip for the navigation button
  ///
  /// In en, this message translates to:
  /// **'Toggle navigation'**
  String get navigationToolTip;

  /// Body for the unsaved changes dialog
  ///
  /// In en, this message translates to:
  /// **'There are unsaved changes to one of the documents. Do you want to save the changes?'**
  String get unsavedChangesText;

  /// Fallback text if a document part is not named
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get part;

  /// Fallback text if a document element is not named
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// Tooltip for box to select headings column
  ///
  /// In en, this message translates to:
  /// **'Column with the text of the Headings'**
  String get headingsTooltip;

  /// Text in front of dropdown for headings
  ///
  /// In en, this message translates to:
  /// **'Headings:'**
  String get headings;

  /// Text after the button to active row merging, and in front of dropdown for headings
  ///
  /// In en, this message translates to:
  /// **'merge with:'**
  String get mergeWith;

  /// Tooltip for box to select the merge text column
  ///
  /// In en, this message translates to:
  /// **'Column with the text to merge with the Headings'**
  String get mergeTooltip;

  /// description for open documents
  ///
  /// In en, this message translates to:
  /// **'Open documents'**
  String get openDocuments;

  /// Title for failed load dialog
  ///
  /// In en, this message translates to:
  /// **'Failed to import file'**
  String get failedToLoad;

  /// Body for failed load dialog
  ///
  /// In en, this message translates to:
  /// **'An exception was thrown during import:'**
  String get failedToLoadBody;

  /// Hint for filter text
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get contains;

  /// Tooltip for filter button
  ///
  /// In en, this message translates to:
  /// **'Toggle filter'**
  String get toggleFilter;

  /// Tooltip for search button
  ///
  /// In en, this message translates to:
  /// **'Toggle search'**
  String get toggleSearch;

  /// Word of
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofSearchBox;

  /// Word matches
  ///
  /// In en, this message translates to:
  /// **'matches'**
  String get matches;

  /// Checkbox text to trigger case sensitive on/off
  ///
  /// In en, this message translates to:
  /// **'Case sensitive'**
  String get caseSensitive;

  /// Status text for no matches
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// text for empty search field
  ///
  /// In en, this message translates to:
  /// **'Search page'**
  String get searchPage;

  /// text above column reorder widget
  ///
  /// In en, this message translates to:
  /// **'Order of columns:'**
  String get columnOrder;

  /// Text for the button to reset the order of columns
  ///
  /// In en, this message translates to:
  /// **'Reset order of columns'**
  String get resetColumnOrder;

  /// text above the 'column reorder widget' column that can set columns to editable
  ///
  /// In en, this message translates to:
  /// **'Editable'**
  String get editable;

  /// text above the 'column reorder widget' column that can set columns to visible
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// Text for the button to reset the visibility of columns
  ///
  /// In en, this message translates to:
  /// **'Reset visibility'**
  String get resetVisibility;

  /// text for last used field
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// text for the context menu item that copies the content of a cell to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy cell'**
  String get copyCell;

  /// text for the open recent menu item
  ///
  /// In en, this message translates to:
  /// **'Open recent'**
  String get openRecent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

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
      'that was used.');
}
