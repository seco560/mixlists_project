/// Spotify HTML-escapes some description characters (`//` -> `&#x2F;&#x2F;`);
/// numeric plus a few named entities suffice, no `package:html` needed.
final _numericEntity = RegExp(r'&#(x?)([0-9a-fA-F]+);');

const _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
};

String unescapeHtmlEntities(String input) {
  var result = input.replaceAllMapped(_numericEntity, (match) {
    final isHex = match.group(1) == 'x';
    final code = int.parse(match.group(2)!, radix: isHex ? 16 : 10);
    return String.fromCharCode(code);
  });
  for (final entry in _namedEntities.entries) {
    result = result.replaceAll('&${entry.key};', entry.value);
  }
  return result;
}
