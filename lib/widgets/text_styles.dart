import 'package:flutter/material.dart';

// Text scale shared by any screen listing a song alongside the mixlist(s)
// it's featured on -- originally introduced on `MixlistDetailScreen`'s
// track tiles, kept here so `ArtistDetailScreen`/`AlbumDetailScreen` don't
// drift out of step with each other or the rest of the app.
const titleTextStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
const subtitleTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
const metaTextStyle = TextStyle(fontSize: 12);
const compactTitleTextStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
