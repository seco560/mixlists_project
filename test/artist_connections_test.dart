import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/models/artist_connections.dart';

Mixlist _mixlist(int id) => Mixlist(
  id: id,
  title: 'Mixlist $id',
  description: '',
  dateCreated: '2020-01-01T00:00:00Z',
);

ConnectionAppearance _on(int mixlistId, int artistId, {int? songId}) =>
    ConnectionAppearance(
      mixlistId: mixlistId,
      artistId: artistId,
      artistName: 'Artist $artistId',
      songId: songId ?? artistId * 100 + mixlistId,
      songName: 'Song $artistId/$mixlistId',
    );

ArtistConnectionGraph _graph(
  List<int> mixlistIds,
  List<ConnectionAppearance> appearances,
) => ArtistConnectionGraph.fromAppearances(
  mixlists: [for (final id in mixlistIds) _mixlist(id)],
  appearances: appearances,
);

void main() {
  // 1-2 share #1, 2-3 #2, 3-4 #3 and 2-4 #4: 1->4 is 2 hops via 2.
  final chain = _graph(
    [1, 2, 3, 4],
    [
      _on(1, 1), _on(1, 2), //
      _on(2, 2), _on(2, 3), //
      _on(3, 3), _on(3, 4), //
      _on(4, 2), _on(4, 4), //
    ],
  );

  test('direct neighbours are 1 degree, via their shared mixlist', () {
    final path = chain.shortestPath(1, 2)!;
    expect(path.degrees, 1);
    expect(path.hops.single.mixlist.id, 1);
    expect(path.hops.single.from.artistId, 1);
    expect(path.hops.single.to.artistId, 2);
  });

  test('takes the shortest chain', () {
    final path = chain.shortestPath(1, 4)!;
    expect(path.degrees, 2);
    expect([for (final a in path.artists) a.id], [1, 2, 4]);
    expect([for (final h in path.hops) h.mixlist.id], [1, 4]);
    expect(path.shortestRouteCount, 1);
  });

  test('counts and samples every equally short route', () {
    // 1 and 2 share two mixlists, so two distinct 1-hop routes.
    final graph = _graph([1, 2], [_on(1, 1), _on(1, 2), _on(2, 1), _on(2, 2)]);
    expect(graph.shortestPath(1, 2)!.shortestRouteCount, 2);
    expect(graph.shortestPath(1, 2)!.hops.single.mixlist.id, 1);
    final seen = {
      for (var seed = 0; seed < 50; seed++)
        graph.shortestPath(1, 2, random: Random(seed))!.hops.single.mixlist.id,
    };
    expect(seen, {1, 2});
  });

  test('same artist is 0 degrees; unconnected artists have no path', () {
    final graph = _graph([1, 2], [_on(1, 1), _on(1, 2), _on(2, 3)]);
    expect(graph.shortestPath(1, 1)!.degrees, 0);
    expect(graph.shortestPath(1, 3), isNull);
  });

  test('ignores appearances on mixlists outside the filter', () {
    final graph = _graph([1], [_on(1, 1), _on(2, 1), _on(2, 2)]);
    expect(graph.artistById(2), isNull);
  });

  test('farthestFrom finds the end of the chain', () {
    final line = _graph([1, 2], [_on(1, 1), _on(1, 2), _on(2, 2), _on(2, 3)]);
    final (farthest, distance) = line.farthestFrom(1);
    expect(distance, 2);
    expect([for (final a in farthest) a.id], [3]);
  });
}
