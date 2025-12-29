import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/main.dart';
import 'package:tracking_app/pages/home_page.dart';
import 'package:tracking_app/pages/journal_page.dart';

// Mock HTTP Client (Reuse from previous step)
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockImageHttpClient(context);
  }
}

HttpClient _createMockImageHttpClient(SecurityContext? context) {
  final client = MockHttpClient();
  return client;
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

const List<int> kTransparentImage = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('Navigation Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify MainScaffold is showing HomePage by default
    expect(find.byType(MainScaffold), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(
      find.byType(JournalPage),
      findsNothing,
    ); // IndexedStack hides offstage widgets, but they are built. Wait, IndexedStack keeps state, but Offstage widget is involved.
    // Finder findsWidgets finds all widgets unless skipOffstage is true (default).
    // However, IndexedStack paints only one child.

    // Tap on Journal Icon (Index 1)
    // CustomBottomNav has icons: home, menu_book (journal), bar_chart, settings
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    // Verify JournalPage is now the top of the stack (visible)
    // Checking visibility with visibility checkers or just finding the unique text in JournalPage
    expect(find.text('My Journal'), findsOneWidget);
    expect(find.text('Quick Journal'), findsOneWidget);

    // Tap on Settings Icon (Index 3)
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Verify SettingsPage
    expect(find.text('Settings Page - Placeholder'), findsOneWidget);
  });
}
