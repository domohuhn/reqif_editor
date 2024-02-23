// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/navigation_tree_node.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';

class NavigationTreeTile extends StatefulWidget {
  final DocumentController documentController;
  final double width;
  const NavigationTreeTile(
      {super.key,
      required this.entry,
      required this.onTap,
      required this.documentController,
      required this.width});

  final TreeEntry<NavigationTreeNode> entry;
  final VoidCallback onTap;

  NavigationTreeNode get node => entry.node;

  @override
  State<NavigationTreeTile> createState() => _NavigationTreeTileState();

  void setHeaderColumn(int docId, int partId, (String, int) heading) {
    documentController.setHeaderColumn(docId, partId, heading);
  }
}

class _NavigationTreeTileState extends State<NavigationTreeTile> {
  static const double filePadding = 90;
  static const double indentAmount = 24;

  double get widthReduction =>
      widget.node.isFile ? filePadding : filePadding + indentAmount;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    final node = widget.node;
    if (node.isFile) {
      children.add(Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
          child: CircleAvatar(
            foregroundImage: widget.entry.isExpanded
                ? const AssetImage('assets/images/document_open.png')
                : const AssetImage('assets/images/document_closed.png'),
            radius: 16,
          )));
    } else if (node.isPart) {
      children.add(FolderButton(
        isOpen: widget.entry.hasChildren ? widget.entry.isExpanded : null,
        onPressed: widget.entry.hasChildren ? widget.onTap : null,
        openedIcon: Icon(
          Icons.data_object,
          color: Theme.of(context).colorScheme.primary,
        ),
        closedIcon: Icon(
          Icons.data_object,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ));
    } else {
      children.add(FolderButton(
        isOpen: widget.entry.hasChildren ? widget.entry.isExpanded : null,
        onPressed: widget.entry.hasChildren ? widget.onTap : null,
        openedIcon: Icon(
          Icons.data_array,
          color: Theme.of(context).colorScheme.primary,
        ),
        closedIcon: Icon(
          Icons.data_array_outlined,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ));
    }
    if (node.isFile || node.isPart) {
      children.add(Container(
          width: max(widget.width - widthReduction, 20),
          decoration: const BoxDecoration(),
          clipBehavior: Clip.hardEdge,
          child: Text(
            "${node.displayText}",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )));
    } else {
      children.add(Text(
        "${node.displayText}",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ));
    }
    if (node.isFile || node.isPart) {
      children.add(const Spacer());
      children.add(IconButton(
          onPressed: () {
            _dialogBuilder(context, widget.node);
          },
          icon: const Icon(Icons.settings)));
    }

    return InkWell(
      onTap: () {
        if (node.isPart || node.isNode) {
          final focus = FocusScope.of(context);
          focus.unfocus();
          widget.documentController.setPosition(
              document: node.document.index,
              part: node.part.index,
              row: node.isNode ? node.element.position : null);
        }
        if (node.isFile) {
          widget.onTap();
        }
      },
      child: TreeIndentation(
        entry: widget.entry,
        guide: const IndentGuide.connectingLines(indent: indentAmount),
        child: Row(
          children: children,
        ),
      ),
    );
  }

  Widget _getLeadingImage(BuildContext context, bool isFile) {
    if (isFile) {
      return const Padding(
          padding: EdgeInsets.fromLTRB(5, 0, 8, 0),
          child: CircleAvatar(
            foregroundImage: AssetImage('assets/images/document.png'),
            radius: 16,
          ));
    } else {
      return Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
          child: Icon(
            Icons.data_object,
            color: Theme.of(context).colorScheme.primary,
          ));
    }
  }

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.node.isFile && widget.node.document.comment != null) {
      _controller.text = widget.node.document.comment!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          controller: _controller,
          onChanged: (value) {
            node.document.comment = value;
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
    return Column(
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
        Text(AppLocalizations.of(context)!.columnOrder),
        _buildReorderBox(context, part)
      ],
    );
  }

  Widget _buildReorderBox(BuildContext context, NavigationTreeNode part) {
    final documentPart = part.part;
    final partNumber = documentPart.index;
    final document = part.document;
    final map = document.columnMapping[partNumber];
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
            final column = map.remap(index);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () {
                      widget.documentController.moveColumn(
                          document: document.index,
                          part: partNumber,
                          column: index,
                          move: -1);
                    },
                    icon: const Icon(Icons.keyboard_arrow_up)),
                IconButton(
                    onPressed: () {
                      widget.documentController.moveColumn(
                          document: document.index,
                          part: partNumber,
                          column: index,
                          move: 1);
                    },
                    icon: const Icon(Icons.keyboard_arrow_down)),
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Text(documentPart.columnNames[column])),
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
            _getLeadingImage(context, node.isFile),
            Text(node.isFile
                ? node.document.flatDocument.title
                : node.part.name ??
                    "${AppLocalizations.of(context)!.part} ${node.part.index}")
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
