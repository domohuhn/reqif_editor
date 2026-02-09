// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get disableSpellCheck => '';

  @override
  String get appTitle => 'ReqIf Editor';

  @override
  String get file => 'File';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';

  @override
  String get openFile => 'Open File...';

  @override
  String get save => 'Save';

  @override
  String get saveAs => 'Save as...';

  @override
  String get exit => 'Exit';

  @override
  String get settings => 'Settings';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get themeSelection => 'Theme:';

  @override
  String get generalSettings => 'General';

  @override
  String get appearance => 'Appearance';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsSaveUpdateUUID =>
      'Update the document\'s UUID when saving';

  @override
  String get settingsSaveUpdateTime =>
      'Update the document\'s creation time when saving';

  @override
  String get settingsSaveUpdateTool => 'Update the tool ID when saving';

  @override
  String get settingsLineEndings => 'Select the line endings to use:';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveAndExit => 'Save and quit';

  @override
  String get quitWithoutSaving => 'Quit without saving';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get comment => 'Comment';

  @override
  String get modalEditFileText => 'File properties';

  @override
  String get modalEditPartText => 'Properties of this specification part:';

  @override
  String get close => 'Close';

  @override
  String get navigationToolTip => 'Toggle navigation';

  @override
  String get unsavedChangesText =>
      'There are unsaved changes to one of the documents. Do you want to save the changes?';

  @override
  String get part => 'Part';

  @override
  String get section => 'Section';

  @override
  String get headingsTooltip => 'Column with the text of the Headings';

  @override
  String get headings => 'Headings:';

  @override
  String get mergeWith => 'merge with:';

  @override
  String get mergeTooltip => 'Column with the text to merge with the Headings';

  @override
  String get openDocuments => 'Open documents';

  @override
  String get failedToLoad => 'Failed to import file';

  @override
  String get failedToLoadBody => 'An exception was thrown during import:';

  @override
  String get contains => 'Contains';

  @override
  String get toggleFilter => 'Toggle filter';

  @override
  String get toggleSearch => 'Toggle search';

  @override
  String get ofSearchBox => 'of';

  @override
  String get matches => 'matches';

  @override
  String get caseSensitive => 'Case sensitive';

  @override
  String get noMatches => 'No matches';

  @override
  String get searchPage => 'Search page';

  @override
  String get columnOrder => 'Order of columns:';

  @override
  String get resetColumnOrder => 'Reset order of columns';

  @override
  String get editable => 'Editable';

  @override
  String get visible => 'Visible';

  @override
  String get resetVisibility => 'Reset visibility';

  @override
  String get lastUsed => 'Last used';

  @override
  String get copyCell => 'Copy cell';

  @override
  String get openRecent => 'Open recent';
}
