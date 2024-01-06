// Copyright 2023, domohuhn.
// SPDX-License-Identifier: BSD-3-Clause
// See LICENSE for the full text of the license

import 'package:flutter_test/flutter_test.dart';
import 'package:reqif_editor/src/reqif/conversions.dart';
import 'package:xml/xml.dart' as xml;

void main() {
  group('Roundtrip', () {
    test('xhtml to delta 1', () {
      final document = xml.XmlDocument.parse(xmlStringSimple1);
      final delta = deltaFromReqIfNode(document.firstChild!);
      final fragment = deltaToXhtml(delta);

      final compare = xmlStringSimple1.substring(
          xmlStringSimple1.indexOf("<reqif-xhtml:div>"),
          xmlStringSimple1.indexOf("</THE-VALUE>"));
      expect(fragment.toXmlString(), compare);
    });

    test('xhtml to delta 2', () {
      final document = xml.XmlDocument.parse(xmlStringSimple2);
      final delta = deltaFromReqIfNode(document.firstChild!);
      final fragment = deltaToXhtml(delta);
      final compare = xmlStringSimple2.substring(
          xmlStringSimple2.indexOf("<reqif-xhtml:div>"),
          xmlStringSimple2.indexOf("</THE-VALUE>"));
      expect(fragment.toXmlString(), compare);
    });

    test('xhtml to delta 3', () {
      final document = xml.XmlDocument.parse(xmlStringSimple3);
      final delta = deltaFromReqIfNode(document.firstChild!);
      final fragment = deltaToXhtml(delta);
      final compare = xmlStringSimple3.substring(
          xmlStringSimple3.indexOf("<reqif-xhtml:div>"),
          xmlStringSimple3.indexOf("</THE-VALUE>"));
      expect(fragment.toXmlString(), compare);
    });

    test('xhtml to delta 4', () {
      final document = xml.XmlDocument.parse(xmlString);
      final delta = deltaFromReqIfNode(document.firstChild!);
      final fragment = deltaToXhtml(delta);
      final compare = xmlString.substring(
          xmlString.indexOf("<reqif-xhtml:div>"),
          xmlString.indexOf("</THE-VALUE>"));
      expect(fragment.toXmlString(), compare);
    });

    test('xhtml to delta 5', () {
      final document = xml.XmlDocument.parse(xmlString2);
      final delta = deltaFromReqIfNode(document.firstChild!);
      final fragment = deltaToXhtml(delta);
      final compare = xmlString2.substring(
          xmlString2.indexOf("<reqif-xhtml:div>"),
          xmlString2.indexOf("</THE-VALUE>"));
      expect(fragment.toXmlString(), compare);
    });
  });

  group('conversions', () {
    test('xhtml to delta s1', () {
      final document = xml.XmlDocument.parse(xmlStringSimple1);
      final delta = deltaFromReqIfNode(document.firstChild!);
      expect(delta.operations.length, 1);
      int i = 0;
      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value,
          "A round trip \nmust produce equivalent output.\n");
      expect(delta.operations[i++].attributes, null);
    });
    test('xhtml to delta', () {
      final document = xml.XmlDocument.parse(xmlString);
      final delta = deltaFromReqIfNode(document.firstChild!);
      expect(delta.operations.length, 15);
      int i = 0;
      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "A round trip ");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "testing strike through");
      expect(delta.operations[i++].attributes, {"strike": true});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, " consisting of loading a ");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "file ");
      expect(delta.operations[i++].attributes, {"italic": true});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "and");
      expect(delta.operations[i++].attributes,
          {"italic": true, "underline": true});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, " saving");
      expect(delta.operations[i++].attributes, {"italic": true});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, " it must produce ");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "equivalent");
      expect(delta.operations[i++].attributes, {"bold": true});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value,
          " output. Only these fields shall be modified:\nLAST-CHANGE");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "\n");
      expect(delta.operations[i++].attributes, {"list": "bullet"});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "COMMENT");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "\n");
      expect(delta.operations[i++].attributes, {"list": "bullet"});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "SOURCE-TOOL-ID");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "\n");
      expect(delta.operations[i++].attributes, {"list": "bullet"});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "\n");
      expect(delta.operations[i++].attributes, null);
    });

    test('xhtml to delta 2', () {
      final document = xml.XmlDocument.parse(xmlString2);
      final delta = deltaFromReqIfNode(document.firstChild!);
      expect(delta.operations.length, 7);
      int i = 0;
      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value,
          "Only these fields shall be modified:\nHere are ");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "nested");
      expect(delta.operations[i++].attributes, {"bold": true});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, " tags");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "\n");
      expect(delta.operations[i++].attributes, {"list": "bullet"});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "COMMENT");
      expect(delta.operations[i++].attributes, null);

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "\n");
      expect(delta.operations[i++].attributes, {"list": "bullet"});

      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value, "\n");
      expect(delta.operations[i++].attributes, null);
    });

    test('xhtml to delta 3', () {
      final document = xml.XmlDocument.parse(xmlStringSimple4);
      final delta = deltaFromReqIfNode(document.firstChild!);
      expect(delta.operations.length, 1);
      int i = 0;
      expect(delta.operations[i].key, "insert");
      expect(delta.operations[i].value,
          "[brackets]\tSome non ascii characters: äö\n");
      expect(delta.operations[i++].attributes, null);
    });
  });
}

const String xmlString = """<ATTRIBUTE-VALUE-XHTML>
<DEFINITION>
<ATTRIBUTE-DEFINITION-XHTML-REF>_0db30098-9450-4a8a-bdcb-9be6bd8ddf40</ATTRIBUTE-DEFINITION-XHTML-REF>
</DEFINITION>
<THE-VALUE><reqif-xhtml:div>A round trip <reqif-xhtml:cite style="text-decoration:line-through">testing strike through</reqif-xhtml:cite> consisting of loading a <reqif-xhtml:i>file <reqif-xhtml:cite style="text-decoration:underline">and</reqif-xhtml:cite> saving</reqif-xhtml:i> it must produce <reqif-xhtml:strong>equivalent</reqif-xhtml:strong> output. Only these fields shall be modified:<reqif-xhtml:br/><reqif-xhtml:ul><reqif-xhtml:li>LAST-CHANGE</reqif-xhtml:li><reqif-xhtml:li>COMMENT</reqif-xhtml:li><reqif-xhtml:li>SOURCE-TOOL-ID</reqif-xhtml:li></reqif-xhtml:ul><reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>
</ATTRIBUTE-VALUE-XHTML>""";

const String xmlString2 = """<ATTRIBUTE-VALUE-XHTML>
<DEFINITION>
<ATTRIBUTE-DEFINITION-XHTML-REF>_0db30098-9450-4a8a-bdcb-9be6bd8ddf40</ATTRIBUTE-DEFINITION-XHTML-REF>
</DEFINITION>
<THE-VALUE><reqif-xhtml:div>Only these fields shall be modified:<reqif-xhtml:br/><reqif-xhtml:ul><reqif-xhtml:li>Here are <reqif-xhtml:strong>nested</reqif-xhtml:strong> tags</reqif-xhtml:li><reqif-xhtml:li>COMMENT</reqif-xhtml:li></reqif-xhtml:ul><reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>
</ATTRIBUTE-VALUE-XHTML>""";

const String xmlStringSimple1 = """<ATTRIBUTE-VALUE-XHTML>
<DEFINITION>
<ATTRIBUTE-DEFINITION-XHTML-REF>_0db30098-9450-4a8a-bdcb-9be6bd8ddf40</ATTRIBUTE-DEFINITION-XHTML-REF>
</DEFINITION>
<THE-VALUE><reqif-xhtml:div>A round trip <reqif-xhtml:br/>must produce equivalent output.<reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>
</ATTRIBUTE-VALUE-XHTML>""";

const String xmlStringSimple2 = """<ATTRIBUTE-VALUE-XHTML>
<DEFINITION>
<ATTRIBUTE-DEFINITION-XHTML-REF>_0db30098-9450-4a8a-bdcb-9be6bd8ddf40</ATTRIBUTE-DEFINITION-XHTML-REF>
</DEFINITION>
<THE-VALUE><reqif-xhtml:div>A round trip <reqif-xhtml:cite style="text-decoration:line-through">testing strike through</reqif-xhtml:cite> consisting of loading a <reqif-xhtml:i>file <reqif-xhtml:cite style="text-decoration:underline">and</reqif-xhtml:cite> saving</reqif-xhtml:i> it must produce <reqif-xhtml:strong>equivalent</reqif-xhtml:strong> output. Only these fields shall be modified:<reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>
</ATTRIBUTE-VALUE-XHTML>""";

const String xmlStringSimple3 = """<ATTRIBUTE-VALUE-XHTML>
<DEFINITION>
<ATTRIBUTE-DEFINITION-XHTML-REF>_0db30098-9450-4a8a-bdcb-9be6bd8ddf40</ATTRIBUTE-DEFINITION-XHTML-REF>
</DEFINITION>
<THE-VALUE><reqif-xhtml:div><reqif-xhtml:strong><reqif-xhtml:i><reqif-xhtml:cite style="text-decoration:underline">A round trip must produce equivalent output.</reqif-xhtml:cite></reqif-xhtml:i></reqif-xhtml:strong><reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>
</ATTRIBUTE-VALUE-XHTML>""";

const String xmlStringSimple4 = """<ATTRIBUTE-VALUE-XHTML>
<DEFINITION>
<ATTRIBUTE-DEFINITION-XHTML-REF>_0db30098-9450-4a8a-bdcb-9be6bd8ddf40</ATTRIBUTE-DEFINITION-XHTML-REF>
</DEFINITION>
<THE-VALUE><reqif-xhtml:div>&#91;brackets&#93;&#9;Some non ascii characters: &#228;&#246;<reqif-xhtml:br/></reqif-xhtml:div></THE-VALUE>
</ATTRIBUTE-VALUE-XHTML>""";
