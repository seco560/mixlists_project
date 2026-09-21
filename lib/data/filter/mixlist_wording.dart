import 'mixlist_filter.dart';

/// The user-facing word for a playlist entity under a given
/// [MixlistFilter] scope -- "Mixlist" while browsing the marked-favorites
/// default view, "Playlist" once the view includes anything that isn't a
/// favorite (`all` or `nonMixlistsOnly`). This is the generic renaming the
/// app applies everywhere it talks about playlist entities in general;
/// it's deliberately *not* used for the mixlist-marking feature's own
/// vocabulary (the filter toggle's own labels, "Mark Mixlists", etc.),
/// which always says "mixlist" regardless of the current filter.
extension MixlistFilterWording on MixlistFilter {
  bool get _isMixlistsOnly => this == MixlistFilter.mixlistsOnly;

  String get playlistNounSingular => _isMixlistsOnly ? 'Mixlist' : 'Playlist';
  String get playlistNounPlural => _isMixlistsOnly ? 'Mixlists' : 'Playlists';
  String get playlistNounSingularLower =>
      _isMixlistsOnly ? 'mixlist' : 'playlist';
  String get playlistNounPluralLower =>
      _isMixlistsOnly ? 'mixlists' : 'playlists';

  /// The All Mixlists/Playlists screen's header -- a three-way split
  /// distinct from the two-way getters above: "Non-Mixlists" keeps the
  /// filtering feature's own word for the not-marked state rather than
  /// becoming "Non-Playlists".
  String get allScreenHeader => switch (this) {
    MixlistFilter.all => 'All Playlists',
    MixlistFilter.mixlistsOnly => 'Mixlists',
    MixlistFilter.nonMixlistsOnly => 'Non-Mixlists',
  };
}
