/// Provides an abstract class that models a table document.
///
/// Subclasses can implement features like sorting and filtering
/// by modifying the indexes and row and column counts.
abstract class TableModel {
  /// Returns the number of rows in the table.
  int rows();

  /// Return the number of columns in the table.
  int columns();
}
