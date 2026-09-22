import 'package:flutter/foundation.dart';

import 'library_record.dart';

/// The active [LibraryRecord], shared like [MixlistFilterController];
/// screens listen to reload on a library switch.
class ActiveLibraryController extends ValueNotifier<LibraryRecord> {
  ActiveLibraryController(super.initial);
}
