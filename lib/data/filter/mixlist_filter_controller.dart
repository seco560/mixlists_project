import 'package:flutter/foundation.dart';
import 'mixlist_filter.dart';

/// App-wide, non-persisted current [MixlistFilter] that survives navigation.
/// Screens listen to reload; [MixlistFilterToggle] reads/writes it directly.
class MixlistFilterController extends ValueNotifier<MixlistFilter> {
  MixlistFilterController() : super(MixlistFilter.mixlistsOnly);
}
