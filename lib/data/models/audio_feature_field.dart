/// Spotify audio-feature fields available to chart, in picker order.
enum AudioFeatureField {
  danceability('Danceability'),
  energy('Energy'),
  valence('Valence'),
  acousticness('Acousticness'),
  instrumentalness('Instrumentalness'),
  liveness('Liveness'),
  speechiness('Speechiness'),
  loudness('Loudness'),
  tempo('Tempo'),
  key('Key'),
  mode('Mode'),
  timeSignature('Time Signature');

  const AudioFeatureField(this.label);
  final String label;

  /// False for categorical fields (key/mode/time signature), whose mean
  /// across tracks means nothing.
  bool get isContinuous => this != key && this != mode && this != timeSignature;
}
