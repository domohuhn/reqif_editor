## 0.6.4

- bugfix: vertical size computation for cells provides more room 
- bugfix: long column names are truncated in the specification options

## 0.6.3

- character escapes when saving files are more consistent
- bugfix: clicking a node in the navigation tree will move the focus to the correct element 

## 0.6.2

- embedded objects that fail to load should now be visible as error message, even if they provide no alternatives
- bugfix: Row filter works again if no columns are merged.
- bugfix: Swapping rows with invisible rows should work while column merging is active.
- bugfix: Resetting the column order will preserve visibilities of columns

## 0.6.1

- bugfix: The navigation tree should no longer become invisible when a filter is applied
- bugfix: The part edit window should no longer crash
- bugfix: filtering works when two columns are merged
- bugfix: Reordering columns works when two columns are merged and some are invisible

## 0.6.0

- For a better experience when working with files exported by DOORs, it is now possible to merge two columns in the display.
- The custom order of the columns of a document is stored in the persistent settings database
- The visibility of columns can be modified
- Integer, Bools, and Real values can be modified
- bugfix: Fixed reported version in the about dialog
- bugfix: Fixed line endings when saving files

## 0.5.1

- Filter and search works with default values

## 0.5.0

- Default values for enums are now displayed and editing them inserts them into the document.

## 0.4.0

- Added a menu entry allowing to open recently used files
- All data types specified for the reqif document format are now displayed
- Added a loading screen
- Added an icon for the ubuntu application

## 0.3.1

- Fixed section number for objects with mixed descendant levels

## 0.3.0

- Bugfixes for text selection
- Columns can be marked as editable

## 0.2.1

- Bugfixes for text selection
- Updated dependencies
- Performance improvements

## 0.2.0

- Text is selectable

## 0.1.5

- Modified string escapes
- Fixed bugs

## 0.1.4

- Modified string escapes
- Added Integer fields as read only

## 0.1.3

- Empty xhtml columns can be edited

## 0.1.2

- Fixed display of empty columns
- Columns can be reordered

## 0.1.1

- Fixed wrong link in example files


## 0.1.0

- Initial version. Opening and editing ReqIF files with Xhtml and enums works.
