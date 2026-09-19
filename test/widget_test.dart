// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mixlists_project/data/database/app_database.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/library/library_record.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/main.dart';

void main() {
  setUp(() {
    // Normally done by main() -- HomeScreen's MixlistFilterToggle and
    // active-library subtitle need these registered, and this test pumps
    // MixlistsMain directly rather than going through main().
    getIt.registerSingleton<MixlistFilterController>(MixlistFilterController());
    getIt.registerSingleton<ActiveLibraryController>(
      ActiveLibraryController(
        LibraryRecord(
          id: bundledLibraryId,
          displayName: 'Mixlists (Bundled)',
          dbFileName: bundledLibraryDbFileName,
          createdAt: DateTime.now(),
          origin: LibraryOrigin.bundled,
        ),
      ),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MixlistsMain());

    // Look for the header text
    expect(find.text('The Mixlists Project'), findsOneWidget);
  });
}
