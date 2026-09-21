import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/get_it_init.dart';

/// The Home screen's nav-card label for the playlists list, swapping
/// between "Mixlists" and "Playlists" as [MixlistFilterController]
/// changes. Landing on "Mixlists" (the default, favorites-only state)
/// plays a zippy, energetic pop; landing on "Playlists" (all or
/// non-mixlists) plays a muted, low-energy fade -- the motion itself
/// hints at which state is the "special" one.
class PlaylistsFilterLabel extends StatefulWidget {
  const PlaylistsFilterLabel({super.key});

  @override
  State<PlaylistsFilterLabel> createState() => _PlaylistsFilterLabelState();
}

class _PlaylistsFilterLabelState extends State<PlaylistsFilterLabel> {
  bool _zippy = true;

  bool get _currentIsMixlistsOnly =>
      getIt<MixlistFilterController>().value == MixlistFilter.mixlistsOnly;

  @override
  void initState() {
    super.initState();
    _zippy = _currentIsMixlistsOnly;
    getIt<MixlistFilterController>().addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    getIt<MixlistFilterController>().removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() {
    final isMixlistsOnly = _currentIsMixlistsOnly;
    if (isMixlistsOnly == _zippy) return;
    setState(() => _zippy = isMixlistsOnly);
  }

  @override
  Widget build(BuildContext context) {
    final label = getIt<MixlistFilterController>().value.playlistNounPlural;
    final normalColor =
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;

    return AnimatedSwitcher(
      duration: Duration(milliseconds: _zippy ? 450 : 500),
      switchInCurve: _zippy ? Curves.elasticOut : Curves.easeOutCubic,
      switchOutCurve: _zippy ? Curves.easeIn : Curves.easeInCubic,
      // AnimatedSwitcher's default layoutBuilder stacks old/new children
      // with Alignment.center, which centers the shorter "Mixlists" under
      // the wider "Playlists" instead of keeping both flush left like
      // every other ListTile title on the home screen.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) {
        if (_zippy) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        }
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) => DefaultTextStyle.merge(
              style: TextStyle(
                color: Color.lerp(Colors.grey, normalColor, animation.value),
              ),
              child: child!,
            ),
          ),
        );
      },
      child: Text(
        label,
        key: ValueKey(label),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
