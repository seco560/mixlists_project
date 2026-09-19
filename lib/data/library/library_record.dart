/// The fixed id of the maintainer's bundled dataset -- always resolvable
/// as the fallback library, even if every user-imported one goes missing.
const String bundledLibraryId = 'bundled';

/// Where a library's data came from -- shown as a badge in the library
/// picker.
enum LibraryOrigin { bundled, spotifyImport, csvImport }

/// One entry in `libraries/manifest.json`: a named library backed by its
/// own sqlite file, reusing the same schema as every other library.
class LibraryRecord {
  const LibraryRecord({
    required this.id,
    required this.displayName,
    required this.dbFileName,
    required this.createdAt,
    required this.origin,
  });

  final String id;
  final String displayName;
  final String dbFileName;
  final DateTime createdAt;
  final LibraryOrigin origin;

  LibraryRecord copyWith({String? displayName}) => LibraryRecord(
    id: id,
    displayName: displayName ?? this.displayName,
    dbFileName: dbFileName,
    createdAt: createdAt,
    origin: origin,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'dbFileName': dbFileName,
    'createdAt': createdAt.toIso8601String(),
    'origin': origin.name,
  };

  factory LibraryRecord.fromJson(Map<String, Object?> json) => LibraryRecord(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    dbFileName: json['dbFileName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    origin: LibraryOrigin.values.byName(json['origin'] as String),
  );
}
