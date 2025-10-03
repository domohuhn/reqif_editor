// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:reqif_editor/src/reqif/reqif_attribute_definitions.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:reqif_editor/src/reqif/reqif_error.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_hierarchy.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_object_type.dart';
import 'package:reqif_editor/src/reqif/reqif_spec_objects.dart';

/// types of flat document elements.
enum ReqIfFlatDocumentElementType {
  /// Nodes with children
  heading,

  /// Nodes without children
  normal
}

class ValueIterator implements Iterator<ReqIfAttributeValue?> {
  int _current = -1;
  final ReqIfSpecificationObject element;

  ValueIterator(this.element);

  @override
  bool moveNext() {
    _current++;
    return _current < element.columnCount;
  }

  @override
  ReqIfAttributeValue? get current => element.valueOrDefault(_current);
}

/// Represents an element
class ReqIfDocumentElement extends Iterable<ReqIfAttributeValue?> {
  /// Type of the node. If the value is heading, then the node would have children
  /// in a hierarchical representation.
  ReqIfFlatDocumentElementType type;

  /// Set to a string formatted like "1.2.3.4" representing the hierarchical position.
  String? prefix;

  /// The hierarchical level of this element.
  int level = 0;

  /// The contents of this object / line.
  ReqIfSpecificationObject object;

  /// The position in the elements list of the page. You can use this
  /// value if an element in the outline was selected to jump to the correct position.
  int position = 0;

  /// This value is set to true if the reqif document has marked this row as editable.
  bool isEditable;

  ReqIfDocumentElement(
      {required this.type,
      required this.object,
      required this.level,
      this.prefix,
      required this.isEditable});

  ReqIfDocumentElement.copyWith(ReqIfDocumentElement other,
      {required this.position})
      : type = other.type,
        object = other.object,
        level = other.level,
        prefix = other.prefix,
        isEditable = other.isEditable;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeAll(["[", position, "] | "]);
    if (type == ReqIfFlatDocumentElementType.heading) {
      buffer.write(prefix);
    }
    buffer.write(" | ");
    buffer.write(object);
    return buffer.toString();
  }

  @override
  Iterator<ReqIfAttributeValue?> get iterator => ValueIterator(object);
}

/// A page is a set of document elements that are defined in the same
/// SpecificationObjectType / Specification element and can be displayed
/// in a single table.
class ReqIfDocumentPart {
  /// Name of the page. The value is optional in the document, so it might not be set.
  String? name;

  /// Description of the contents of this page. Especially the contents of the columns
  /// are described here.
  final ReqIfSpecificationObjectType type;

  /// Description of the contents and datatypes in each column.
  Iterable<ReqIfAttributeDefinition> get attributeDefinitions =>
      type.attributeDefinitions;

  final List<ReqIfDocumentElement> _elements;
  final List<ReqIfDocumentElement> _outline;

  /// The position in the original document
  final int index;

  /// All elements to display on this page.
  Iterable<ReqIfDocumentElement> get elements =>
      _filterActive ? _filteredElements : _elements;

  /// All headings on this page.
  Iterable<ReqIfDocumentElement> get outline =>
      _filterActive ? _filteredOutline : _outline;

  int get rowCount =>
      _filterActive ? _filteredElements.length : _elements.length;
  int get columnCount => type.attributeDefinitions.length;

  String columnName(int columnIndex) {
    if (columnIndex >= type.children.length) {
      throw RangeError.index(columnIndex, type.children);
    }
    final datatype = type[columnIndex];
    if (datatype.name != null) {
      return datatype.name!;
    }
    return "<Nameless column $columnIndex>";
  }

  /// Gets the names of the columns in order of their definition.
  List<String> get columnNames {
    List<String> rv = [];
    for (int i = 0; i < type.children.length; ++i) {
      rv.add(columnName(i));
    }
    return rv;
  }

  ReqIfDocumentPart(this.type, {required this.index, this.name})
      : _elements = [],
        _outline = [];

  void add(ReqIfDocumentElement element) {
    element.position = _elements.length;
    _elements.add(element);
    if (element.type == ReqIfFlatDocumentElementType.heading) {
      _outline.add(element);
    }
  }

  ReqIfDocumentElement operator [](int i) {
    return _filterActive ? _filteredElements[i] : _elements[i];
  }

  bool _filterActive = false;

  final List<int> _mapOriginalToFilter = [];
  final List<int> _mapFilteredToOriginal = [];
  final List<ReqIfDocumentElement> _filteredElements = [];
  final List<ReqIfDocumentElement> _filteredOutline = [];

  /// Filtered elements to display on this page.
  Iterable<ReqIfDocumentElement> get filteredElements => _filteredElements;

  /// Filtered headings on this page.
  Iterable<ReqIfDocumentElement> get filteredOutline => _filteredOutline;

  /// Applies or disables the [filter] to the document based on the [active] value.
  /// The filter is a list of regular expressions that are matched to the raw text
  /// contents of each column. Elements are filtered if nothing matches. An empty
  /// String will always match. The filter list is applied in column order.
  void applyFilter(bool active, List<String> filter, {List<int>? columnsToOr}) {
    if (filter.every((element) => element == "")) {
      _filterActive = false;
      return;
    }
    _filterActive = active;
    _filteredElements.clear();
    _mapOriginalToFilter.clear();
    _mapFilteredToOriginal.clear();
    final List<RegExp> regexFilter =
        filter.map((e) => RegExp(e, caseSensitive: false)).toList();
    int position = 0;
    for (final val in _elements) {
      if (_matches(val, regexFilter, columnsToOr)) {
        _filteredElements
            .add(ReqIfDocumentElement.copyWith(val, position: position));
        _mapFilteredToOriginal.add(_mapOriginalToFilter.length);
        _mapOriginalToFilter.add(position);
        ++position;
      } else {
        _mapOriginalToFilter.add(-1);
      }
    }

    _filteredOutline.clear();

    for (int i = 0; i < _outline.length; ++i) {
      final childMatches = _outlineChildMatches(
          _outline[i], _outline[i].position, regexFilter, columnsToOr);
      if (_matches(_outline[i], regexFilter, columnsToOr) || childMatches.$1) {
        _filteredOutline.add(ReqIfDocumentElement.copyWith(_outline[i],
            position: _findNextPositionInFilteredList(_outline[i].position)));
      }
    }
  }

  int mapFilteredPositionToOriginalPosition(int idx) {
    if (!_filterActive) {
      return idx;
    }
    if (idx < _mapFilteredToOriginal.length) {
      return _mapFilteredToOriginal[idx];
    }
    return -1;
  }

  int _findNextPositionInFilteredList(int start) {
    for (int i = start; i < _mapOriginalToFilter.length; ++i) {
      if (_mapOriginalToFilter[i] >= 0) {
        return _mapOriginalToFilter[i];
      }
    }
    return -1;
  }

  bool _matches(ReqIfDocumentElement element, List<RegExp> filter,
      List<int>? columnsToOr) {
    List<bool> matches = filter.map((e) => e.pattern == "").toList();
    for (final attribute in element) {
      if (attribute == null) {
        continue;
      }
      final index = attribute.column;
      final value = attribute;
      if (index < filter.length && filter[index].pattern != "") {
        matches[index] = filter[index].hasMatch(value.toStringWithNewlines());
      }
    }
    if (columnsToOr == null || columnsToOr.isEmpty) {
      return matches.every((element) => element);
    } else {
      bool columnsOr = false;
      bool columnsAnd = true;
      for (int i = 0; i < matches.length; ++i) {
        if (columnsToOr.contains(i)) {
          columnsOr = columnsOr || matches[i];
        } else {
          columnsAnd = columnsAnd && matches[i];
        }
      }
      return columnsOr && columnsAnd;
    }
  }

  (bool, int) _outlineChildMatches(ReqIfDocumentElement element, int start,
      List<RegExp> filter, List<int>? columnsToOr) {
    int levelToStop = element.level;
    for (int i = start + 1; i < _elements.length; ++i) {
      final compare = _elements[i];
      if (compare.level <= levelToStop) {
        break;
      }
      if (_matches(compare, filter, columnsToOr)) {
        return (true, compare.position);
      }
    }
    return (false, -1);
  }
}

/// The ReqIf document in a flat representation without having to handle the hierarchical elements
/// or resolving any links. This class does not allow changing the layout or adding new requirements.
/// You can edit the existing pages and requirements.
///
/// Sections have an appropriate numbering with the following layout "1.2.3.4" as prefix string.
class ReqIfFlatDocument {
  final String title;
  final List<ReqIfDocumentPart> _parts;
  Iterable<ReqIfDocumentPart> get parts => _parts;
  int get partCount => _parts.length;

  ReqIfDocumentPart operator [](int i) {
    return _parts[i];
  }

  ReqIfFlatDocument(
      {required this.title, required List<ReqIfDocumentPart> parts})
      : _parts = parts;

  static ReqIfFlatDocument buildFlatDocument(ReqIfDocument doc) {
    List<ReqIfDocumentPart> parts = [];
    for (var specIdx in doc.specifications.indexed) {
      final spec = specIdx.$2;
      if (spec.specificationObjectTypes.length != 1) {
        throw ReqIfError(
            "Currently every specification only supports one type, but ${spec.name} has ${spec.specificationObjectTypes.length}");
      }
      ReqIfDocumentPart part = ReqIfDocumentPart(
          spec.specificationObjectTypes.first,
          name: spec.name,
          index: specIdx.$1);
      spec.visit(visitor: (position, element) {
        if (element is! ReqIfSpecHierarchy) {
          return;
        }
        part.add(ReqIfDocumentElement(
            type: element.hasChildren
                ? ReqIfFlatDocumentElementType.heading
                : ReqIfFlatDocumentElementType.normal,
            object: element.specificationObject,
            level: position.position.length - 2,
            prefix: position.toSection(),
            isEditable: element.isEditable));
      });
      parts.add(part);
    }
    return ReqIfFlatDocument(title: doc.header.title, parts: parts);
  }

  /// Returns the raw text of the specification as unformatted text.
  /// Any external content will be stripped and xhtml newlines etc are lost.
  ///
  /// The fields are separated by | signs. The String will start with
  /// the part number, then the line number, the heading numbers, then
  /// the content of the reqif file.
  @override
  String toString() {
    final buffer = StringBuffer();
    int partNo = 1;
    for (final part in parts) {
      for (final line in part.elements) {
        buffer.writeAll(["[", partNo, "] | ", line, "\n"]);
      }
      partNo++;
    }
    return buffer.toString();
  }
}
