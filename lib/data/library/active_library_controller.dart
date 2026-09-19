import 'package:flutter/foundation.dart';

import 'library_record.dart';

/// The currently-active [LibraryRecord], shared across the app the same
/// way [MixlistFilterController] shares the current filter -- screens
/// that need to reload when the library changes (e.g. after a switch)
/// add/remove a listener the same way they already do for filter changes.
class ActiveLibraryController extends ValueNotifier<LibraryRecord> {
  ActiveLibraryController(super.initial);
}
