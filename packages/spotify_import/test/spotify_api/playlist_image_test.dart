import 'package:spotify_import/spotify_import.dart';
import 'package:test/test.dart';

List<Object?> _images(String url) => [
  {'url': url, 'height': 640, 'width': 640},
];

void main() {
  test('keeps uploaded covers, drops generated mosaics and album covers', () {
    const uploaded =
        'https://image-cdn-ak.spotifycdn.com/image/ab67706c0000d72cb110d63cf1c10e6c26bb9659';
    expect(customPlaylistImageUrl(_images(uploaded)), uploaded);
    expect(
      customPlaylistImageUrl(
        _images('https://mosaic.scdn.co/640/ab67616d00001e02431ac6e6f393acf4'),
      ),
      isNull,
    );
    expect(
      customPlaylistImageUrl(
        _images('https://i.scdn.co/image/ab67616d00001e022bed16beaa8689df'),
      ),
      isNull,
    );
    expect(customPlaylistImageUrl(null), isNull);
    expect(customPlaylistImageUrl(const []), isNull);
  });
}
