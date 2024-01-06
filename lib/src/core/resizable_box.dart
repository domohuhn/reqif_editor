// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';

import 'package:flutter/material.dart';

/// Width must be tracked in parent.
class HorizontalResizableBox extends StatelessWidget {
  /// Total width of the widget.
  final double width;

  /// Total width of the widget.
  final double? height;

  /// Width of the clickable border
  final double widthBorder;

  /// Color of the clickable borders.
  final Color borderColor;

  /// The child whose size is controlled.
  final Widget child;
  final void Function(DragStartDetails)? onHorizontalDragStart;
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;

  const HorizontalResizableBox({
    super.key,
    required this.width,
    this.height,
    required this.child,
    this.widthBorder = 2.0,
    this.borderColor = Colors.red,
    this.onHorizontalDragStart,
    required this.onHorizontalDragUpdate,
  });

  double get contentWidth {
    return max(width - widthBorder, 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: width,
        height: height,
        child: Row(
          children: [
            SizedBox(
              width: contentWidth,
              height: height,
              child: child,
            ),
            MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  onHorizontalDragStart: onHorizontalDragStart,
                  onHorizontalDragUpdate: onHorizontalDragUpdate,
                  child: SizedBox(
                    width: widthBorder,
                    height: height,
                    child: Container(
                      color: borderColor,
                    ),
                  ),
                )),
          ],
        ));
  }
}

/// Height must be tracked in parent.
class VerticallyResizableBox extends StatelessWidget {
  /// Total width of the widget.
  final double? width;

  /// Total width of the widget.
  final double height;

  /// Width of the clickable border
  final double widthBorder;

  /// Color of the clickable borders.
  final Color borderColor;

  /// If set to true, a drag-able border is drawn at the top.
  final bool resizableBorderAtTop;

  /// If set to true, a drag-able border is drawn at the bottom.
  final bool resizableBorderAtBottom;

  /// The child whose size is controlled.
  final Widget child;
  final void Function(DragStartDetails)? onVerticalDragStart;
  final void Function(DragUpdateDetails) onVerticalDragUpdate;

  const VerticallyResizableBox({
    super.key,
    this.width,
    required this.height,
    required this.child,
    this.widthBorder = 2.0,
    this.borderColor = Colors.pink,
    this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    this.resizableBorderAtBottom = true,
    this.resizableBorderAtTop = true,
  });
  bool get drawBothBorders => resizableBorderAtTop && resizableBorderAtBottom;
  bool get drawAnyBorder => resizableBorderAtTop || resizableBorderAtBottom;
  double get contentHeight {
    if (drawBothBorders) {
      return max(height - 2 * widthBorder, 0);
    } else if (drawAnyBorder) {
      return max(height - widthBorder, 0);
    }
    return height;
  }

  void _addMouseRegionAndBorder(
      BuildContext context, List<Widget> widgets, bool add) {
    if (add) {
      widgets.add(
        MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              onVerticalDragStart: onVerticalDragStart,
              onVerticalDragUpdate: onVerticalDragUpdate,
              child: SizedBox(
                width: width,
                height: widthBorder,
                child: Container(
                  color: borderColor,
                ),
              ),
            )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    _addMouseRegionAndBorder(context, widgets, resizableBorderAtTop);
    widgets.add(SizedBox(width: width, height: contentHeight, child: child));
    _addMouseRegionAndBorder(context, widgets, resizableBorderAtBottom);
    return SizedBox(
        height: height,
        width: width,
        child: Column(
          children: widgets,
        ));
  }
}

class ResizableBox extends StatelessWidget {
  /// Total width of the widget.
  final double width;

  /// Width of the clickable border
  final double widthBorder;

  /// Color of the clickable borders.
  final Color borderColor;

  /// The child whose size is controlled.
  final Widget child;
  final void Function(DragStartDetails)? onHorizontalDragStart;
  final void Function(DragUpdateDetails)? onHorizontalDragUpdate;

  /// Total width of the widget.
  final double height;

  final void Function(DragStartDetails)? onVerticalDragStart;
  final void Function(DragUpdateDetails)? onVerticalDragUpdate;

  const ResizableBox({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.widthBorder = 2.0,
    this.borderColor = Colors.pink,
    this.onVerticalDragUpdate,
    this.onHorizontalDragUpdate,
    this.onVerticalDragStart,
    this.onHorizontalDragStart,
  });

  @override
  Widget build(BuildContext context) {
    if (onVerticalDragUpdate != null && onHorizontalDragUpdate != null) {
      return VerticallyResizableBox(
        height: height,
        width: width,
        widthBorder: widthBorder,
        borderColor: borderColor,
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate!,
        resizableBorderAtTop: false,
        child: HorizontalResizableBox(
          width: width,
          height: height - widthBorder,
          onHorizontalDragStart: onHorizontalDragStart,
          onHorizontalDragUpdate: onHorizontalDragUpdate!,
          widthBorder: widthBorder,
          borderColor: borderColor,
          child: child,
        ),
      );
    } else if (onVerticalDragUpdate != null) {
      return VerticallyResizableBox(
          height: height,
          width: width,
          resizableBorderAtTop: false,
          widthBorder: widthBorder,
          borderColor: borderColor,
          onVerticalDragStart: onVerticalDragStart,
          onVerticalDragUpdate: onVerticalDragUpdate!,
          child: child);
    } else if (onHorizontalDragUpdate != null) {
      return HorizontalResizableBox(
        height: height,
        width: width,
        onHorizontalDragStart: onHorizontalDragStart,
        onHorizontalDragUpdate: onHorizontalDragUpdate!,
        widthBorder: widthBorder,
        borderColor: borderColor,
        child: child,
      );
    } else {
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }
  }
}
