import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_codebar_scanner/services/app_info.dart';
import 'package:md_codebar_scanner/widgets/app_bar_title.dart';
import 'package:package_info_plus/package_info_plus.dart';

Widget _app(Widget title) =>
    MaterialApp(home: Scaffold(appBar: AppBar(title: title)));

void main() {
  tearDown(() => AppInfo.set(version: ''));

  group('AppInfo.label', () {
    test('version y build', () {
      AppInfo.set(version: '2.0.3', buildNumber: '105');
      expect(AppInfo.label, 'v2.0.3 (105)');
    });

    test('sin build number', () {
      AppInfo.set(version: '2.0.3');
      expect(AppInfo.label, 'v2.0.3');
    });

    test('vacio si no hay version', () {
      AppInfo.set(version: '', buildNumber: '105');
      expect(AppInfo.label, '');
    });

    test('load() lee PackageInfo', () async {
      PackageInfo.setMockInitialValues(
        appName: 'md_codebar_scanner',
        packageName: 'com.example.md_codebar_scanner',
        version: '2.0.3',
        buildNumber: '105',
        buildSignature: '',
      );
      await AppInfo.load();
      expect(AppInfo.label, 'v2.0.3 (105)');
    });
  });

  group('AppBarTitle', () {
    testWidgets('muestra titulo y version', (tester) async {
      AppInfo.set(version: '2.0.3', buildNumber: '105');
      await tester.pumpWidget(_app(const AppBarTitle('Escanner')));

      expect(find.text('Escanner'), findsOneWidget);
      expect(find.text('v2.0.3 (105)'), findsOneWidget);
    });

    testWidgets('solo el titulo si no hay version', (tester) async {
      await tester.pumpWidget(_app(const AppBarTitle('Escanner')));

      expect(find.text('Escanner'), findsOneWidget);
      expect(find.byType(Column), findsNothing);
    });
  });
}
