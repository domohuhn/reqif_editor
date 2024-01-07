// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/reqif/reqif_attribute_values.dart';
import 'package:reqif_editor/src/reqif/reqif_common.dart';
import 'package:reqif_editor/src/reqif/reqif_document.dart';
import 'package:xml/xml.dart' as xml;

void main() {
  group('read node with image', () {
    final parentXml = xml.XmlDocument.parse(xmlParent);
    ReqIfIdentifiable parent = ReqIfIdentifiable.parse(
        parentXml.firstElementChild!, ReqIfElementTypes.specificationObject);
    ReqIfDocument doc = ReqIfDocument();
    test('xhtml failed parse - no data type', () {
      final document = xml.XmlDocument.parse(xmlWithObject);
      expect(
          () => ReqIfAttributeValueXhtml.parse(
              parent: parent,
              element: document.firstElementChild!,
              document: doc),
          throwsException);
    });
  });
}

const String xmlParent = """
<SPEC-OBJECT LAST-CHANGE="2023-11-22T11:42:13+01:00" IDENTIFIER="_2d00e38a-082d-4b8f-92f2-e924fc864832" LONG-NAME="REQ_13"></SPEC-OBJECT>""";

const String xmlWithObject = """<ATTRIBUTE-VALUE-XHTML>
<DEFINITION>
<ATTRIBUTE-DEFINITION-XHTML-REF>_0db30098-9450-4a8a-bdcb-9be6bd8ddf40</ATTRIBUTE-DEFINITION-XHTML-REF>
</DEFINITION>
<THE-VALUE><reqif-xhtml:div>A typical use case might look like this:<reqif-xhtml:br/><reqif-xhtml:object type="application/rtf" data="images/use-case-exchange.ole"><reqif-xhtml:object type="image/png" data="images/use-case-exchange.png">Usecase document exchange</reqif-xhtml:object></reqif-xhtml:object><reqif-xhtml:br/><reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>
</ATTRIBUTE-VALUE-XHTML>""";
