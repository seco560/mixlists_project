import 'package:flutter_test/flutter_test.dart';

import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/data/database/app_database.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/library/library_record.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/main.dart';
import 'package:mixlists_project/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // Normally done by main() -- HomeScreen's MixlistFilterToggle,
    // active-library subtitle, and theme toggle need these registered, and
    // this test pumps MixlistsMain directly rather than going through main().
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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<ThemeController>(ThemeController.load(prefs));
    // BreadcrumbOverlay (wrapped around MaterialApp's content via
    // MaterialApp.builder) needs this registered too.
    getIt.registerSingleton<BreadcrumbController>(BreadcrumbController());
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
