// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:reqif_editor/src/core/resizable_box.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

enum CellAttributes { heading, added, removed, modified, normal }

/// Return value of the builder methods.
class CellContents {
  /// The widget that should be rendered in the cell
  final Widget? child;

  /// A special attribute for this cell.
  /// If this value is not null and not normal,
  /// then a special decoration is drawn as background.
  final CellAttributes? attribute;
  CellContents({this.child, this.attribute});
}

enum CellState { selected, deselected }

/// Return value of the builder methods.
class TableViewScrollControllers {
  ScrollController vertical;
  ScrollController horizontal;
  TableViewScrollControllers(
      {required this.horizontal, required this.vertical});
}

/// The class containing the TableView with resizable rows
/// and columns.
class ResizableTableView extends StatefulWidget {
  const ResizableTableView(
      {super.key,
      this.columnHeaderBuilder,
      this.initialColumnWidths,
      this.onSelectionChanged,
      this.selection,
      this.initialRowHeights,
      this.cellBuilder,
      required this.rowCount,
      required this.columnCount,
      required this.selectAble,
      this.defaultColumnWidth = 160,
      this.minColumnWidth = 100,
      this.defaultRowHeight = 40,
      this.minRowHeight = 40,
      this.borderWidth = 3.0,
      this.columnWidthsProvider,
      this.rowHeightsProvider,
      this.scrollControllerBuilder,
      this.rowPositionBuilder,
      required this.searchPosition});

  /// If this function is provided, it be used to build the cell entries in row 0.
  /// It will be wrapped with borders and receive a background.
  final Widget? Function(BuildContext context, TableVicinity vicinity)?
      columnHeaderBuilder;

  /// If this function is provided, it be used to build the cell entries in column 0.
  /// It will be wrapped with borders and receive a background.
  final Widget? Function(BuildContext context, TableVicinity vicinity)?
      rowPositionBuilder;

  /// This method is used to build the widgets in the cells if the row and column
  /// index are larger than 0.
  /// The returned Widget will be wrapped with borders, receive a background and a
  /// gesture detector monitoring taps and double taps.
  ///
  /// The argument [vicinity] contains the cell position. The argument [selected]
  /// is true if the user has selected the cell by tapping on it. Indices start at
  /// 1 and will be in the inclusive range [1, length]. If you are using them to
  /// look up values in an array, you will likely have to subtract one from the row
  /// and column value.
  ///
  /// If the builder returns null, then an empty box will be shown as placeholder.
  final CellContents? Function(
      BuildContext context, TableVicinity vicinity, bool selected)? cellBuilder;

  /// This callback is invoked whenever the selection changes.
  ///
  /// [vicinity] ranges from [1, rowCount] and [1, colCount]
  final void Function(TableVicinity vicinity, CellState state)?
      onSelectionChanged;

  /// This callback is invoked whenever the selected position is needed.
  ///
  /// The return value [vicinity] must range from [1, rowCount] and [1, colCount] inclusive.
  final TableVicinity Function()? selection;

  /// This callback is invoked whenever the current search position is needed.
  ///
  /// The return value [vicinity] must range from [1, rowCount] and [1, colCount] inclusive.
  final TableVicinity Function()? searchPosition;

  /// If this function is provided, it is called once to initialize the widths of the resizable columns.
  /// Column 0 is always fixed and contains the current row number.
  ///
  /// It should return a list with length columnCount.
  /// If not enough entries are returned, then the rest of the list is filled with the default value.
  final List<double> Function()? initialColumnWidths;

  /// If this function is provided, it is called once to initialize the heights of the resizable columns.
  /// Row 0 is always fixed and contains the current column or a custom widget if [columnHeaderBuilder] is provided.
  /// Row 1 is your first data column.
  ///
  /// The callback should return a list with length rowCount+1 if [columnHeaderBuilder] is provided, otherwise rowCount.
  /// If not enough entries are returned, then the rest of the list is filled with the default value.
  final List<double> Function()? initialRowHeights;

  /// The number of rows in the data
  final int rowCount;

  /// The number of columns in the data
  final int columnCount;

  /// The initial column width if [columnWidths] is not provided.
  final double defaultColumnWidth;

  /// The minimal column width when the user tries to resize the
  /// columns.
  final double minColumnWidth;

  /// The initial row height if [rowHeights] is not provided.
  final double defaultRowHeight;

  /// The minimal row width when the user tries to resize the
  /// row.
  final double minRowHeight;

  /// The width of the drag able borders in the table view.
  final double borderWidth;

  final bool selectAble;

  /// A callback to access the list where the actual column widths are stored.
  /// The widget will either use the list provided by the callback
  /// or create a new one if it is null.
  final List<double> Function()? columnWidthsProvider;

  /// A callback to access the list where the actual row heights are stored.
  /// The widget will either use the list provided by the callback
  /// or create a new one if it is null.
  final List<double> Function()? rowHeightsProvider;

  final TableViewScrollControllers Function()? scrollControllerBuilder;

  @override
  State<ResizableTableView> createState() => _ResizableTableViewState();
}

class _ResizableTableViewState extends State<ResizableTableView> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

  final List<double> _columnWidths = <double>[];
  final List<double> _rowHeights = <double>[];

  final GlobalKey<State<ResizableTableView>> tableViewKey =
      GlobalKey<State<ResizableTableView>>(debugLabel: "resizableTableView");

  List<double> get columnWidths {
    if (widget.columnWidthsProvider != null) {
      return widget.columnWidthsProvider!();
    }
    return _columnWidths;
  }

  List<double> get rowHeights {
    if (widget.rowHeightsProvider != null) {
      return widget.rowHeightsProvider!();
    }
    return _rowHeights;
  }

  /// The width of the first column. This column is fixed and contains the line number.
  static const double _rowNumberIndicatorWidth = 64;

  /// The height of the first row. This row is fixed and contains the headings.
  /// Only relevant if the user did not provide a builder for the column headers.
  static const double _columnHeaderHeight = 64;

  void _fillColumnWidthsWithDefaultWidth() {
    for (int i = columnWidths.length; i <= widget.columnCount; ++i) {
      columnWidths.add(widget.defaultColumnWidth);
    }
  }

  void _fillRowHeightsWithDefaultHeight() {
    for (int i = rowHeights.length; i <= widget.rowCount; ++i) {
      rowHeights.add(widget.defaultRowHeight);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.scrollControllerBuilder != null) {
      final controls = widget.scrollControllerBuilder!();
      _verticalController = controls.vertical;
      _horizontalController = controls.horizontal;
    } else {
      _verticalController = ScrollController();
      _horizontalController = ScrollController();
    }
    ensureSizesInitialized();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void ensureSizesInitialized() {
    if (columnWidths.isEmpty) {
      columnWidths.add(_rowNumberIndicatorWidth);
      if (widget.initialColumnWidths != null) {
        columnWidths.addAll(widget.initialColumnWidths!());
      }
    }
    if (columnWidths.length < widget.columnCount) {
      _fillColumnWidthsWithDefaultWidth();
    }
    if (rowHeights.isEmpty) {
      if (widget.columnHeaderBuilder == null) {
        rowHeights.add(_columnHeaderHeight);
      }
      if (widget.initialRowHeights != null) {
        rowHeights.addAll(widget.initialRowHeights!());
      }
    }
    if (rowHeights.length < widget.rowCount) {
      _fillRowHeightsWithDefaultHeight();
    }
  }

  @override
  Widget build(BuildContext context) {
    ensureSizesInitialized();
    final tableView = KeyedSubtree(
        key: tableViewKey,
        child: TableView.builder(
          pinnedRowCount: 1,
          pinnedColumnCount: 1,
          verticalDetails:
              ScrollableDetails.vertical(controller: _verticalController),
          horizontalDetails:
              ScrollableDetails.horizontal(controller: _horizontalController),
          cellBuilder: _buildCell,
          columnCount: widget.columnCount + 1,
          columnBuilder: _buildColumnSpan,
          rowCount: widget.rowCount + 1,
          rowBuilder: _buildRowSpan,
        ));

    return NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          // TODO: This is required to work aorund bug
          // https://github.com/flutter/flutter/issues/137112
          if (scrollNotification is ScrollStartNotification) {
            _unfocus();
          }
          return false;
        },
        child: Scrollbar(
          thumbVisibility: true,
          controller: _horizontalController,
          child: Scrollbar(
              thumbVisibility: true,
              controller: _verticalController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
                // TODO: this throws exception with duplicate global keys
                child: widget.selectAble
                    ? SelectionArea(child: tableView)
                    : tableView,
              )),
        ));
  }

  TableVicinity get selection => widget.selection != null
      ? widget.selection!()
      : const TableVicinity(column: -1, row: -1);

  TableVicinity get searchPosition => widget.searchPosition != null
      ? widget.searchPosition!()
      : const TableVicinity(column: -1, row: -1);

  Widget _wrapInClickDetection(
      {required Widget child,
      Color? color,
      required int column,
      required int row,
      required bool tapDetection}) {
    final contents = Container(
        decoration: BoxDecoration(color: color),
        clipBehavior: Clip.hardEdge,
        child: child);
    if (tapDetection) {
      return GestureDetector(
          onTap: () {
            setState(() {
              FocusScope.of(context).unfocus();
              if (widget.onSelectionChanged != null) {
                widget.onSelectionChanged!(
                    TableVicinity(row: row, column: column),
                    CellState.selected);
              }
            });
          },
          onSecondaryTap: () {
            _unfocus();
          },
          child: contents);
    } else {
      return contents;
    }
  }

  Widget _wrapInResizableBox(
      {required Widget contents,
      required Color borderColor,
      Color? color,
      required int column,
      required int row,
      bool horizontal = true,
      bool vertical = true,
      bool tapDetection = true}) {
    if (column < columnWidths.length && row < rowHeights.length) {
      return _wrapInClickDetection(
          child: ResizableBox(
              width: columnWidths[column],
              height: rowHeights[row],
              widthBorder: widget.borderWidth,
              borderColor: borderColor,
              onHorizontalDragStart: horizontal
                  ? (details) {
                      _unfocus();
                    }
                  : null,
              onHorizontalDragUpdate: horizontal
                  ? (details) {
                      setState(() {
                        columnWidths[column] += details.delta.dx;
                        columnWidths[column] =
                            max(widget.minColumnWidth, columnWidths[column]);
                      });
                    }
                  : null,
              onVerticalDragStart: vertical
                  ? (details) {
                      _unfocus();
                    }
                  : null,
              onVerticalDragUpdate: vertical
                  ? (details) {
                      setState(() {
                        rowHeights[row] += details.delta.dy;
                        rowHeights[row] =
                            max(widget.minRowHeight, rowHeights[row]);
                      });
                    }
                  : null,
              child: contents),
          color: color,
          column: column,
          row: row,
          tapDetection: tapDetection);
    }
    return SizedBox(
        width: widget.defaultColumnWidth,
        height: widget.defaultRowHeight,
        child: contents);
  }

  void _unfocus() {
    setState(() {
      if (widget.onSelectionChanged != null) {
        widget.onSelectionChanged!(
            const TableVicinity(row: -1, column: -1), CellState.deselected);
      }
      FocusScope.of(context).unfocus();
    });
  }

  static const _letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  String _indexToLetters(int index) {
    assert(index > 0);
    if (index < 27) {
      return _letters[index - 1];
    }
    var rv = <String>[];
    do {
      index -= 1;
      rv.add(_letters[index.remainder(26)]);
      index ~/= 26;
    } while (index > 0);
    return rv.reversed.join("");
  }

  Widget _buildFixedCell(BuildContext context, TableVicinity vicinity) {
    final fixedColumColor = Theme.of(context).colorScheme.secondaryContainer;
    final borderColor = Theme.of(context).colorScheme.onSecondaryContainer;
    // Top left corner: always empty
    if ((vicinity.row == 0 && vicinity.column == 0) ||
        vicinity.row < 0 ||
        vicinity.column < 0) {
      return Container(
          decoration: BoxDecoration(
              color: fixedColumColor,
              border: Border(
                  bottom: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor))),
          child: const SizedBox.shrink());
    }

    // Top row: use external builder if provided, else just write a letter in
    // the cell.
    if (vicinity.row == 0 && vicinity.column != 0) {
      Widget? contents;
      if (widget.columnHeaderBuilder != null) {
        contents = widget.columnHeaderBuilder!(context, vicinity);
      }
      contents ??= Center(
        child: Text(_indexToLetters(vicinity.column)),
      );
      return _wrapInResizableBox(
          contents: contents,
          color: fixedColumColor,
          column: vicinity.column,
          row: vicinity.row,
          vertical: false,
          tapDetection: false,
          borderColor: borderColor);
    }

    assert(vicinity.column == 0,
        "The builder for fixed cells should only be called when a row or a column is 0");
    // first column:
    // Use external build if provided.
    // otherwise, fill with numbers.
    Widget? contents;
    if (widget.rowPositionBuilder != null) {
      contents = widget.rowPositionBuilder!(context, vicinity);
    }
    contents ??= Center(
      child: Text('${vicinity.row}'),
    );
    return _wrapInResizableBox(
        contents: contents,
        color: fixedColumColor,
        column: vicinity.column,
        row: vicinity.row,
        horizontal: false,
        tapDetection: false,
        borderColor: borderColor);
  }

  Widget _buildCell(BuildContext context, TableVicinity vicinity) {
    if (vicinity.column == 0 || vicinity.row == 0) {
      return _buildFixedCell(context, vicinity);
    }
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    final selected = vicinity == selection;
    var color = selected ? Theme.of(context).colorScheme.inversePrimary : null;
    if (vicinity == searchPosition) {
      color = Theme.of(context).colorScheme.inversePrimary;
    }
    Widget? contents;
    if (widget.cellBuilder != null) {
      final cell = widget.cellBuilder!(context, vicinity, selected);
      if (cell != null) {
        contents = cell.child;
        color ??= cell.attribute == CellAttributes.heading
            ? Theme.of(context).colorScheme.onInverseSurface
            : color;
      }
    }
    contents ??= const SizedBox.shrink();
    return _wrapInResizableBox(
        contents: contents,
        color: color,
        column: vicinity.column,
        row: vicinity.row,
        borderColor: borderColor);
  }

  TableSpan _buildColumnSpan(int index) {
    const TableSpanDecoration decoration = TableSpanDecoration(
      border: TableSpanBorder(
        trailing: BorderSide.none,
        leading: BorderSide.none,
      ),
    );
    final double selectedWidth = index < columnWidths.length
        ? columnWidths[index]
        : widget.minColumnWidth;
    return TableSpan(
      backgroundDecoration: decoration,
      extent: FixedTableSpanExtent(selectedWidth),
    );
  }

  TableSpan _buildRowSpan(int index) {
    const TableSpanDecoration decoration = TableSpanDecoration(
      border: TableSpanBorder(
        trailing: BorderSide.none,
        leading: BorderSide.none,
      ),
    );
    final double height =
        index < rowHeights.length ? rowHeights[index] : widget.minRowHeight;
    return TableSpan(
      backgroundDecoration: decoration,
      extent: FixedTableSpanExtent(height),
    );
  }
}
