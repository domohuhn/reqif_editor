// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/document/navigation_tree_node.dart';
import 'package:reqif_editor/src/document/navigation_tree_tile.dart';

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
  late TreeController<NavigationTreeNode> treeController;
  final List<int> lastOutlineLengths = [];

  @override
  void initState() {
    super.initState();
    _buildTree();
  }

  @override
  void dispose() {
    treeController.dispose();
    super.dispose();
  }

  void _buildTree() {
    roots = NavigationTreeNode.buildNavigationTree(widget.controller);
    treeController = TreeController<NavigationTreeNode>(
      roots: roots,
      childrenProvider: (NavigationTreeNode node) => node.children,
    );
    treeController.expandAll();
  }

  void _updateTree() {
    if (widget.controller.length == roots.length) {
      return;
    }
    treeController.dispose();
    _buildTree();
  }

  @override
  Widget build(BuildContext context) {
    _updateTree();
    return TreeView<NavigationTreeNode>(
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
    );
  }
}
