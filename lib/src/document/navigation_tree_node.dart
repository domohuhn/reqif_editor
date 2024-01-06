// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/document/document_controller.dart';
import 'package:reqif_editor/src/reqif/flat_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';

class NavigationTreeNode {
  const NavigationTreeNode({
    required this.parent,
    required this.controller,
    required this.content,
    this.children = const <NavigationTreeNode>[],
  });

  final NavigationTreeNode? parent;
  final DocumentController controller;
  final dynamic content;
  final List<NavigationTreeNode> children;

  bool get isFile => content is DocumentData;
  bool get isPart => content is ReqIfDocumentPart;
  bool get isNode => content is ReqIfDocumentElement;

  DocumentData get document {
    if (isFile) {
      return content as DocumentData;
    }
    var up = parent;
    while (up != null) {
      if (up.isFile) {
        return up.content as DocumentData;
      }
      up = up.parent;
    }
    throw ReqIfError("Internal error: tree is built wrong - no document");
  }

  ReqIfDocumentPart get part {
    if (isPart) {
      return content as ReqIfDocumentPart;
    }
    var up = parent;
    while (up != null) {
      if (up.isPart) {
        return up.content as ReqIfDocumentPart;
      }
      up = up.parent;
    }
    throw ReqIfError("Internal error: tree is built wrong - no part");
  }

  ReqIfDocumentElement get element => content as ReqIfDocumentElement;

  String? get displayText {
    assert(content is DocumentData ||
        content is ReqIfDocumentPart ||
        content is ReqIfDocumentElement);
    if (isFile) {
      return "${document.flatDocument.title}\n${document.path}";
    } else if (isPart) {
      return part.name;
    } else {
      final p = part;
      final doc = document;
      final index = p.index;
      final headerColumn = doc.headings[index].$2;
      final value = element.object[headerColumn];
      if (value == null) {
        return null;
      }
      if (element.prefix != null) {
        return "${element.prefix}  $value";
      } else {
        return value.toString();
      }
    }
  }

  @override
  String toString() {
    return 'NODE: $displayText';
  }

  static List<NavigationTreeNode> buildNavigationTree(
      DocumentController controller) {
    List<NavigationTreeNode> roots = [];
    for (final document in controller.documents) {
      roots.add(NavigationTreeNode(
          parent: null,
          content: document,
          controller: controller,
          children: []));
      roots.last.children
          .addAll(_buildDocumentParts(roots.last, controller, document));
    }
    return roots;
  }

  static List<NavigationTreeNode> _buildDocumentParts(NavigationTreeNode parent,
      DocumentController controller, DocumentData document) {
    List<NavigationTreeNode> parts = [];
    for (final part in document.flatDocument.parts) {
      parts.add(NavigationTreeNode(
          parent: parent, content: part, controller: controller, children: []));
      _buildDocumentOutlineElements(parts.last, controller, part);
    }
    return parts;
  }

  static void _buildDocumentOutlineElements(NavigationTreeNode startParent,
      DocumentController controller, ReqIfDocumentPart part) {
    NavigationTreeNode? current;
    int lastLevel = 0;
    NavigationTreeNode parent = startParent;
    for (final element in part.outline) {
      final level = element.level;
      if (level < 0) {
        throw ReqIfError(
            "Flat document is build wrong! Level cannot be negative");
      }
      if (current == null && level != lastLevel) {
        throw ReqIfError(
            "Flat document is build wrong! First level must be 0! Last $lastLevel and ${element.level}");
      }
      if (level > lastLevel) {
        if (lastLevel + 1 == level) {
          lastLevel += 1;
          parent = current!;
        } else {
          throw ReqIfError(
              "Flat document is build wrong! Level can only increase by 1!");
        }
      } else if (level < lastLevel) {
        while (lastLevel > level) {
          lastLevel -= 1;
          current = parent;
          if (current.parent != null) {
            parent = current.parent!;
          } else {
            throw ReqIfError(
                "Flat document is build wrong! Parent is null -> should not be possible");
          }
        }
      }
      current = NavigationTreeNode(
          parent: parent,
          controller: controller,
          content: element,
          children: []);
      parent.children.add(current);
    }
  }
}
