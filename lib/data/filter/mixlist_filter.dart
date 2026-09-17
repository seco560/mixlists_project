/// Which playlists (by `Mixlists.is_mixlists`) a screen should show/scope
/// its data to. Deliberately just this one fixed three-way split, not a
/// general tagging/categories system -- there's no need for one yet.
enum MixlistFilter { mixlistsOnly, all, nonMixlistsOnly }
