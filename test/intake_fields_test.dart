import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/intake_fields.dart';
import 'package:kallisto_design_system/client/pages/brief_structured_editor.dart';
import 'package:kallisto_design_system/client/pages/brief_records_editor.dart';
import 'package:kallisto_design_system/design_system/tokens.dart';

void main() {
  test(
    'all 77 fields are represented, with protected uploads explicitly unavailable',
    () {
      final spec = File('docs/MASTER_SPEC.md').readAsStringSync();
      final section = spec.substring(
        spec.indexOf('### E.3'),
        spec.indexOf('### E.4'),
      );
      final expected = RegExp(
        r'\| (brief\.[a-z_.]+) \|',
      ).allMatches(section).map((m) => m[1]).toSet();
      expect(briefFields.map((f) => f.path).toSet(), expected);
      expect(briefFields.length, 77);
      expect(
        briefFields
            .singleWhere((f) => f.path == 'brief.documents.attachment_refs')
            .kind,
        BriefFieldKind.attachments,
      );
    },
  );
  test(
    'validates precision and impossible calendar dates without normalizing',
    () {
      final f = briefFields.singleWhere(
        (f) => f.path == 'brief.timing.start_preference',
      );
      expect(
        validateStructuredBrief(
          f,
          jsonEncode({
            'kind': 'month',
            'value': '2027-02',
            'raw_phrase': 'February',
          }),
        ),
        isNull,
      );
      expect(
        validateStructuredBrief(
          f,
          jsonEncode({
            'kind': 'date',
            'value': '2027-02-30',
            'raw_phrase': 'February 30',
          }),
        ),
        isNotNull,
      );
    },
  );
  testWidgets(
    'phone entry editor adds and edits an item without changing its ID',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final field = briefFields.singleWhere(
        (f) => f.path == 'brief.building.future_expansion',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: KTokens.theme(Brightness.light),
          home: Scaffold(
            body: BriefRecordsEditor(
              field: field,
              controller: controller,
              enabled: true,
              onChanged: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add entry'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Future wish'),
        'Future study',
      );
      await tester.tap(find.text('Use this entry'));
      await tester.pumpAndSettle();
      final first = (jsonDecode(controller.text) as List).single as Map;
      await tester.tap(find.text('Edit entry'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Future wish'),
        'Future studio',
      );
      await tester.tap(find.text('Use this entry'));
      await tester.pumpAndSettle();
      final revised = (jsonDecode(controller.text) as List).single as Map;
      expect(revised['entry_id'], first['entry_id']);
      expect(revised['description'], 'Future studio');
      expect(tester.takeException(), isNull);
    },
  );
}
