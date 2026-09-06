class Artist {
  final int id;
  final String spotifyURI;
  final String name;

  Artist({required this.id, required this.spotifyURI, required this.name});

  factory Artist.fromMap(Map<String, Object?> map) {
    return Artist(
      id: map['id'] as int,
      spotifyURI: map['spotifyURI'] as String,
      name: map['name'] as String,
    );
  }
 
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'spotifyURI': spotifyURI,
      'name': name,
    };
  }
}
