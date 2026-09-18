import 'package:flutter/foundation.dart';
import 'mixlist_filter.dart';

/// App-wide, in-memory (not persisted) current [MixlistFilter], shared
/// across every screen that filters by it -- set it once, it stays put
/// as you navigate, rather than resetting per screen. Registered as a
/// getIt singleton; screens add/remove a listener to reload their data
/// when it changes, and [MixlistFilterToggle] reads/writes it directly.
class MixlistFilterController extends ValueNotifier<MixlistFilter> {
  MixlistFilterController() : super(MixlistFilter.mixlistsOnly);
}
