// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/navigation_tree_node.dart';
import 'package:reqif_editor/src/localization/app_localizations.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';

import 'package:flutter/gestures.dart';

class NavigationTreeView extends StatefulWidget {
  final DocumentController controller;
  final double width;

  const NavigationTreeView(
      {super.key, required this.controller, required this.width});

  @override
  State<NavigationTreeView> createState() => NavigationTreeViewState();

  void setHeaderColumn(int docId, int partId, (String, int) heading) {
    controller.setHeaderColumn(docId, partId, heading);
  }

  void documentWasModified(int idx) {
    controller.documentWasModified(idx);
  }

  void forceRedraw() {
    controller.forceRedraw();
  }
}

class NavigationTreeViewState extends State<NavigationTreeView> {
  final TreeViewController treeController = TreeViewController();
  final ScrollController horizontalController = ScrollController();
  TreeViewNode<NavigationTreeNode>? _selectedNode;
  final ScrollController _verticalController = ScrollController();

  List<TreeViewNode<NavigationTreeNode>> _tree =
      <TreeViewNode<NavigationTreeNode>>[];
  String _errorText = "";

  void _buildTree() {
    try {
      _tree = NavigationTreeNode.convertNavigationTree(
          NavigationTreeNode.buildNavigationTree(widget.controller));
      disposeTextEditingControllers();
      for (final documentNode in _tree) {
        _textEditingControllers.add(TextEditingController());
        if (documentNode.content.isFile &&
            documentNode.content.document.comment != null) {
          _textEditingControllers.last.text =
              documentNode.content.document.comment!;
        }
      }
    } catch (e) {
      _tree.clear();
      _errorText = e.toString();
    }
  }

  void _updateTree() {
    if (widget.controller.length == _tree.length) {
      return;
    }
    _buildTree();
  }

  Map<Type, GestureRecognizerFactory> _getTapRecognizer(
    TreeViewNode<NavigationTreeNode> node,
  ) {
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(),
        (TapGestureRecognizer t) => t.onTap = () {
          setState(() {
            _selectedNode = node;
            if (node.content.isPart || node.content.isNode) {
              final focus = FocusScope.of(context);
              focus.unfocus();
              widget.controller.setPosition(
                  document: node.content.document.index,
                  part: node.content.part.index,
                  row: node.content.isNode
                      ? node.content.element.position
                      : null);
            }
            if (node.content.isFile) {
              treeController.toggleNode(node);
            }
          });
        },
      ),
    };
  }

  static const double filePadding = 90;
  static const double indentAmount = 24;
  static const double widthVisibleColumn = 60;

  double widthReduction(TreeViewNode<NavigationTreeNode> node) =>
      node.content.isFile ? filePadding : filePadding + indentAmount;

  Widget _treeNodeBuilder(
    BuildContext context,
    TreeViewNode<NavigationTreeNode> node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final bool isParentNode = node.children.isNotEmpty;
    final displayText = node.content.displayText ?? "null";
    const double iconSize = 20;
    const double indentationWidth = 8.0;
    const double widthReductionToPreventScrollbar = 5;
    return SizedBox(
        width: widget.width - widthReductionToPreventScrollbar,
        child: Row(
          children: <Widget>[
            SizedBox(width: indentationWidth * node.depth! + indentationWidth),
            if (isParentNode)
              TreeView.wrapChildToToggleNode(
                  node: node,
                  child: SizedBox.square(
                    dimension: iconSize,
                    child: _getLeadingIcon(
                        node.content.isFile,
                        node.content.isPart,
                        isParentNode,
                        node.isExpanded,
                        iconSize),
                  ))
            else
              SizedBox.square(
                dimension: iconSize,
                child: _getLeadingIcon(node.content.isFile, node.content.isPart,
                    isParentNode, true, iconSize),
              ),
            const SizedBox(width: indentationWidth),
            Container(
                width: max(widget.width - widthReduction(node), 20),
                decoration: const BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                child: Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )),
            if (node.content.isFile || node.content.isPart) const Spacer(),
            if (node.content.isFile || node.content.isPart)
              IconButton(
                  onPressed: () {
                    _dialogBuilder(context, node.content);
                  },
                  icon: const Icon(Icons.settings))
          ],
        ));
  }

  Widget _getLeadingIcon(
      bool isFile, bool isPart, bool isParent, bool isExpanded, double size) {
    final color = isExpanded
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;
    if (isFile) {
      return CircleAvatar(
          foregroundImage: isExpanded
              ? const AssetImage('assets/images/document_open.png')
              : const AssetImage('assets/images/document_closed.png'),
          radius: size / 2);
    } else if (isPart) {
      return Icon(
        Icons.data_object,
        color: color,
        size: size,
      );
    } else if (isParent) {
      return Icon(
        Icons.data_array,
        color: color,
        size: size,
      );
    } else {
      return Icon(
        Icons.text_snippet,
        color: color,
        size: size,
      );
    }
  }

  Span _treeRowBuilder(TreeViewNode<NavigationTreeNode> node) {
    if (_selectedNode == node) {
      return TreeRow(
        extent: FixedTreeRowExtent(
          node.children.isNotEmpty ? 60.0 : 50.0,
        ),
        recognizerFactories: _getTapRecognizer(node),
        backgroundDecoration: TreeRowDecoration(
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        foregroundDecoration: const TreeRowDecoration(
          border: TreeRowBorder.all(BorderSide()),
        ),
      );
    }
    return TreeRow(
      extent: FixedTreeRowExtent(
        node.children.isNotEmpty ? 60.0 : 50.0,
      ),
      recognizerFactories: _getTapRecognizer(node),
    );
  }

  Widget _getTreeView() {
    return Scrollbar(
      controller: horizontalController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        child: TreeView<NavigationTreeNode>(
          controller: treeController,
          verticalDetails: ScrollableDetails.vertical(
            controller: _verticalController,
          ),
          horizontalDetails: ScrollableDetails.horizontal(
            controller: horizontalController,
          ),
          tree: _tree,
          onNodeToggle: (TreeViewNode<NavigationTreeNode> node) {
            setState(() {
              _selectedNode = node;
            });
          },
          treeNodeBuilder: _treeNodeBuilder,
          treeRowBuilder: _treeRowBuilder,
          indentation: TreeViewIndentationType.none,
        ),
      ),
    );
  }

  Widget _wrapInBox(Widget w) {
    return SizedBox(
        width: widget.width,
        height: 600,
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all()),
          child: w,
        ));
  }

  @override
  void dispose() {
    _verticalController.dispose();
    horizontalController.dispose();
    disposeTextEditingControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateTree();
    if (_tree.isEmpty) {
      return _wrapInBox(Text("Error: no data - '$_errorText'"));
    } else {
      return _wrapInBox(_getTreeView());
    }
  }

  final List<TextEditingController> _textEditingControllers = [];
  void disposeTextEditingControllers() {
    for (final ctrl in _textEditingControllers) {
      ctrl.dispose();
    }
    _textEditingControllers.clear();
  }

  Widget _buildFileCommentEditor(
      BuildContext context, NavigationTreeNode node) {
    final textTheme = Theme.of(context).textTheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(AppLocalizations.of(context)!.modalEditFileText),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: TextField(
          style: textTheme.bodySmall,
          controller: _textEditingControllers[node.document.index],
          onChanged: (value) {
            node.document.comment = value;
            if (mounted) {
              widget.documentWasModified(node.document.index);
            }
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(gapPadding: 1.0),
            hintText: AppLocalizations.of(context)!.comment,
            labelText: AppLocalizations.of(context)!.comment,
          ),
        ),
      )
    ]);
  }

  Widget _buildPartDialogContents(
      BuildContext context, NavigationTreeNode part) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final parent = part.parent;
    if (parent == null || !parent.isFile) {
      throw ReqIfError("Internal error: navigation tree is built wrong!");
    }
    final headerColumn = parent.document.headings;
    final documentPart = part.part;
    final partNumber = documentPart.index;
    List<DropdownMenuItem<String>> dropDownWidgets = [];
    for (final name in documentPart.columnNames) {
      dropDownWidgets
          .add(DropdownMenuItem<String>(value: name, child: Text(name)));
    }
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.modalEditPartText),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text(AppLocalizations.of(context)!.headingsTooltip)),
          Tooltip(
              message: AppLocalizations.of(context)!.headingsTooltip,
              child: DropdownButton<String>(
                  items: dropDownWidgets,
                  style: textTheme.bodySmall,
                  onChanged: (v) {
                    if (v != null && v != headerColumn[partNumber].$1) {
                      setState(() {
                        int idx = dropDownWidgets
                            .indexWhere((element) => element.value == v);
                        if (idx >= 0 &&
                            idx < dropDownWidgets.length &&
                            dropDownWidgets[idx].value != null) {
                          widget.setHeaderColumn(parent.document.index,
                              partNumber, (dropDownWidgets[idx].value!, idx));
                        }
                      });
                    }
                  },
                  value: headerColumn[partNumber].$1))
        ]),
        Row(mainAxisSize: MainAxisSize.max, children: [
          Text(AppLocalizations.of(context)!.columnOrder),
          const Spacer(),
          SizedBox(
              width: widthVisibleColumn,
              child: Text(AppLocalizations.of(context)!.visible)),
          Text(AppLocalizations.of(context)!.editable)
        ]),
        _buildReorderBox(context, part),
        TextButton(
          child: Text(AppLocalizations.of(context)!.resetColumnOrder),
          onPressed: () {
            widget.controller.resetColumnOrder(
                document: part.document.index, part: partNumber);
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.resetVisibility),
          onPressed: () {
            widget.controller.resetVisibility(
                document: part.document.index, part: partNumber);
          },
        )
      ],
    ));
  }

  Widget _buildReorderBox(BuildContext context, NavigationTreeNode part) {
    final documentPart = part.part;
    final partNumber = documentPart.index;
    final document = part.document;
    final filter = document.partColumnFilter[partNumber];
    final map = document.partColumnOrder[partNumber];
    final attributes =
        documentPart.attributeDefinitions.toList(growable: false);
    return Container(
        margin: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        height: 300,
        width: 500,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            border: Border.all(width: 2)),
        child: ListView.builder(
          itemCount: documentPart.columnCount,
          itemBuilder: (BuildContext ctx, int index) {
            final int realModelIndex = index + 1;
            final column =
                map.map(TableVicinity(row: 0, column: realModelIndex)).column -
                    1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () {
                      widget.controller.moveColumn(
                          document: document.index,
                          part: partNumber,
                          column: realModelIndex,
                          move: -1);
                    },
                    icon: const Icon(Icons.keyboard_arrow_up)),
                IconButton(
                    onPressed: () {
                      widget.controller.moveColumn(
                          document: document.index,
                          part: partNumber,
                          column: realModelIndex,
                          move: 1);
                    },
                    icon: const Icon(Icons.keyboard_arrow_down)),
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Text(documentPart.columnNames[column])),
                const Spacer(),
                SizedBox(
                    width: widthVisibleColumn + indentAmount,
                    child: Checkbox.adaptive(
                        value: filter.isVisible(realModelIndex),
                        onChanged: (val) {
                          if (val != null &&
                              val != filter.isVisible(realModelIndex) &&
                              mounted) {
                            widget.controller.setColumnVisibility(
                                document: document.index,
                                part: partNumber,
                                column: realModelIndex,
                                visible: val);
                          }
                        })),
                Checkbox.adaptive(
                    value: attributes[column].isEditable,
                    onChanged: (val) {
                      if (val != null &&
                          val != attributes[column].isEditable &&
                          mounted) {
                        attributes[column].editable = val;
                        widget.forceRedraw();
                      }
                    })
              ],
            );
          },
        ));
  }

  Future<void> _dialogBuilder(BuildContext context, NavigationTreeNode node) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            _getLeadingIcon(node.isFile, node.isPart, false, true, 20.0),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                child: Text(node.isFile
                    ? node.document.flatDocument.title
                    : node.part.name ??
                        "${AppLocalizations.of(context)!.part} ${node.part.index}"))
          ]),
          content: node.isFile
              ? _buildFileCommentEditor(context, node)
              : _buildPartDialogContents(context, node),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(AppLocalizations.of(context)!.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
