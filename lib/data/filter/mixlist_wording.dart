import 'mixlist_filter.dart';

/// User-facing noun for playlists under a filter: "Mixlist" for the default
/// favorites view, "Playlist" otherwise. Not used for the marking feature's
/// own words (toggle labels, "Mark Mixlists"), which always say mixlist.
extension MixlistFilterWording on MixlistFilter {
  bool get _isMixlistsOnly => this == MixlistFilter.mixlistsOnly;

  String get playlistNounSingular => _isMixlistsOnly ? 'Mixlist' : 'Playlist';
  String get playlistNounPlural => _isMixlistsOnly ? 'Mixlists' : 'Playlists';
  String get playlistNounSingularLower =>
      _isMixlistsOnly ? 'mixlist' : 'playlist';
  String get playlistNounPluralLower =>
      _isMixlistsOnly ? 'mixlists' : 'playlists';

  /// All Mixlists screen header: a three-way split that keeps "Non-Mixlists"
  /// rather than "Non-Playlists".
  String get allScreenHeader => switch (this) {
    MixlistFilter.all => 'All Playlists',
    MixlistFilter.mixlistsOnly => 'Mixlists',
    MixlistFilter.nonMixlistsOnly => 'Non-Mixlists',
  };
}
