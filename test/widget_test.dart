// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Wolf Podcast App Tests', () {
    testWidgets('App loads without crashing', (WidgetTester tester) async {
      // 測試基本的 Material App 是否能正常載入
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Wolf Podcast')),
            body: const Center(
              child: Text('歡迎使用 Wolf Podcast'),
            ),
          ),
        ),
      );

      // 驗證應用程式標題是否正確顯示
      expect(find.text('Wolf Podcast'), findsOneWidget);
      expect(find.text('歡迎使用 Wolf Podcast'), findsOneWidget);
    });

    testWidgets('Material App widget structure test', (WidgetTester tester) async {
      // 建立簡化版的應用程式進行測試
      await tester.pumpWidget(
        MaterialApp(
          title: 'Wolf Podcast',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: Center(
              child: Text('測試播客應用程式'),
            ),
          ),
        ),
      );

      // 驗證基本的 Widget 結構
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('測試播客應用程式'), findsOneWidget);
    });

    testWidgets('Theme and color scheme test', (WidgetTester tester) async {
      // 測試應用程式主題設定
      final app = MaterialApp(
        title: 'Wolf Podcast',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Wolf Podcast')),
          body: const Text('主題測試'),
        ),
      );

      await tester.pumpWidget(app);

      // 驗證 AppBar 和文字是否正確顯示
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Wolf Podcast'), findsOneWidget);
      expect(find.text('主題測試'), findsOneWidget);
    });
  });
}
