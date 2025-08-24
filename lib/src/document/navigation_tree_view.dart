// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/navigation_tree_node.dart';
//import 'package:reqif_editor/src/document/navigation_tree_tile.dart';

import 'package:flutter/gestures.dart';

/*
class NavigationTreeView extends StatefulWidget {
  final DocumentController controller;
  final double width;
  const NavigationTreeView(
      {super.key, required this.controller, required this.width});

  @override
  State<NavigationTreeView> createState() => _NavigationTreeViewState();
}

class _NavigationTreeViewState extends State<NavigationTreeView> {
  late List<NavigationTreeNode> roots;
 // late TreeController<NavigationTreeNode> treeController;
  final List<int> lastOutlineLengths = [];

  @override
  void initState() {
    super.initState();
    _buildTree();
  }

  @override
  void dispose() {
  //  treeController.dispose();
    super.dispose();
  }

  void _buildTree() {
    roots = NavigationTreeNode.buildNavigationTree(widget.controller);
   // treeController = TreeController<NavigationTreeNode>(
   //   roots: roots,
   //   childrenProvider: (NavigationTreeNode node) => node.children,
   // );
   // treeController.expandAll();
  }

  void _updateTree() {
    if (widget.controller.length == roots.length) {
      return;
    }
  //  treeController.dispose();
    _buildTree();
  }

  @override
  Widget build(BuildContext context) {
    _updateTree();
    return Text("TODO");/*TreeView<NavigationTreeNode>(
      treeController: treeController,
      nodeBuilder: (BuildContext context, TreeEntry<NavigationTreeNode> entry) {
        return NavigationTreeTile(
          key: ValueKey(entry.node),
          entry: entry,
          onTap: () => treeController.toggleExpansion(entry.node),
          documentController: widget.controller,
          width: widget.width,
        );
      },
    );*/
  }
}
*/

class NavigationTreeView extends StatefulWidget {
  final DocumentController controller;
  final double width;

  const NavigationTreeView(
      {super.key, required this.controller, required this.width});

  @override
  State<NavigationTreeView> createState() => TreeExampleState();
}

class TreeExampleState extends State<NavigationTreeView> {
  final TreeViewController treeController = TreeViewController();
  final ScrollController horizontalController = ScrollController();
  TreeViewNode<NavigationTreeNode>? _selectedNode;
  final ScrollController _verticalController = ScrollController();

  List<TreeViewNode<NavigationTreeNode>> _tree =
      <TreeViewNode<NavigationTreeNode>>[];

  void _buildTree() {
    _tree = NavigationTreeNode.convertNavigationTree(
        NavigationTreeNode.buildNavigationTree(widget.controller));
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

  Widget _treeNodeBuilder(
    BuildContext context,
    TreeViewNode<NavigationTreeNode> node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final bool isParentNode = node.children.isNotEmpty;
    final displayText = node.content.displayText ?? "null";
    const double iconSize = 20;
    const double indentationWidth = 8.0;
    return Row(
      children: <Widget>[
        SizedBox(width: indentationWidth * node.depth! + indentationWidth),
        if (isParentNode)
          TreeView.wrapChildToToggleNode(
              node: node,
              child: SizedBox.square(
                dimension: iconSize,
                child: _getLeadingIcon(node.content.isFile, node.content.isPart,
                    isParentNode, node.isExpanded, iconSize),
              ))
        else
          SizedBox.square(
            dimension: iconSize,
            child: _getLeadingIcon(node.content.isFile, node.content.isPart,
                isParentNode, true, iconSize),
          ),
        const SizedBox(width: indentationWidth),
        Text(displayText),
      ],
    );
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

  Widget _getTree() {
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

          treeRowBuilder: (TreeViewNode<NavigationTreeNode> node) {
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
          },
          // No internal indentation, the custom treeNodeBuilder applies its
          // own indentation to decorate in the indented space.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateTree();
    if (_tree.isEmpty) {
      return _wrapInBox(Text(""));
    } else {
      return _wrapInBox(_getTree());
    }
  }
}
