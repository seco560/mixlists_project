/// Flutter-free core shared by the app and the `mixlists_importer` CLI:
/// sqlite schema, entities, CSV parsing, and get-or-create ingestion.
library;

export 'src/database/schema_v2.dart';
export 'src/database/schema_v3.dart';
export 'src/database/schema_v4.dart';
export 'src/database/schema_v5.dart';

export 'src/entities/album.dart';
export 'src/entities/artist.dart';
export 'src/entities/mixlist.dart';
export 'src/entities/song.dart';
export 'src/entities/song_audio_features.dart';
export 'src/entities/song_extra_data.dart';
export 'src/entities/song_mixlist.dart';

export 'src/csv/mixlist_csv_merge.dart';
export 'src/csv/mixlist_csv_parser.dart';

export 'src/repository/mixlist_ingestion.dart';
export 'src/repository/mixlist_supplement.dart';
