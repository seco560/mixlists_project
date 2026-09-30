import 'dart:collection';
import 'dart:math';

import 'package:mixlists_core/mixlists_core.dart';

/// An artist's first song (by position) on one mixlist -- the raw input to
/// [ArtistConnectionGraph.fromAppearances].
class ConnectionAppearance {
  const ConnectionAppearance({
    required this.mixlistId,
    required this.artistId,
    required this.artistName,
    required this.songId,
    required this.songName,
    this.coverImageURL,
  });

  final int mixlistId;
  final int artistId;
  final String artistName;
  final int songId;
  final String songName;
  final String? coverImageURL;
}

class ConnectionArtist {
  const ConnectionArtist({
    required this.id,
    required this.name,
    required this.coverImageUrls,
  });

  final int id;
  final String name;

  /// Up to 4 distinct album covers, for the mosaic.
  final List<String?> coverImageUrls;
}

/// One step of a chain: [from] and [to] both have a song on [mixlist].
class ConnectionHop {
  const ConnectionHop({
    required this.mixlist,
    required this.position,
    required this.from,
    required this.to,
  });

  final Mixlist mixlist;

  /// 1-based position under the filter, as shown elsewhere.
  final int position;
  final ConnectionAppearance from;
  final ConnectionAppearance to;
}

class ConnectionPath {
  const ConnectionPath({
    required this.artists,
    required this.hops,
    required this.shortestRouteCount,
  });

  /// `hops.length + 1` artists, from source to target.
  final List<ConnectionArtist> artists;
  final List<ConnectionHop> hops;

  /// How many distinct shortest chains exist (this is one of them).
  final int shortestRouteCount;

  int get degrees => hops.length;
}

/// Artists linked by sharing a mixlist, for "Six Degrees". Bipartite
/// (artists <-> mixlists) so a chain can say which mixlist each hop used.
class ArtistConnectionGraph {
  ArtistConnectionGraph._(
    this.artists,
    this._artistById,
    this._mixlistById,
    this._mixlistsByArtist,
    this._artistsByMixlist,
    this._appearanceByPair,
  );

  /// [mixlists] in id order (positions come from it); [appearances] in
  /// position order within each mixlist, so the first per artist wins.
  factory ArtistConnectionGraph.fromAppearances({
    required List<Mixlist> mixlists,
    required List<ConnectionAppearance> appearances,
  }) {
    final mixlistById = {
      for (var i = 0; i < mixlists.length; i++)
        mixlists[i].id: (mixlists[i], i + 1),
    };
    final appearanceByPair = <(int, int), ConnectionAppearance>{};
    final covers = <int, LinkedHashSet<String?>>{};
    final names = <int, String>{};
    for (final a in appearances) {
      if (!mixlistById.containsKey(a.mixlistId)) continue;
      appearanceByPair.putIfAbsent((a.artistId, a.mixlistId), () => a);
      names[a.artistId] = a.artistName;
      final artistCovers = covers.putIfAbsent(a.artistId, LinkedHashSet.new);
      if (artistCovers.length < 4) artistCovers.add(a.coverImageURL);
    }

    final mixlistsByArtist = <int, List<int>>{};
    final artistsByMixlist = <int, List<int>>{};
    for (final (artistId, mixlistId) in appearanceByPair.keys) {
      mixlistsByArtist.putIfAbsent(artistId, () => []).add(mixlistId);
      artistsByMixlist.putIfAbsent(mixlistId, () => []).add(artistId);
    }
    // Earliest mixlist first, so the default route prefers older mixlists.
    for (final list in mixlistsByArtist.values) {
      list.sort((a, b) => mixlistById[a]!.$2.compareTo(mixlistById[b]!.$2));
    }

    final artistById = {
      for (final id in names.keys)
        id: ConnectionArtist(
          id: id,
          name: names[id]!,
          coverImageUrls: covers[id]!.toList(),
        ),
    };
    final artists = artistById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ArtistConnectionGraph._(
      artists,
      artistById,
      mixlistById,
      mixlistsByArtist,
      artistsByMixlist,
      appearanceByPair,
    );
  }

  /// Every artist with an appearance, sorted by name.
  final List<ConnectionArtist> artists;

  final Map<int, ConnectionArtist> _artistById;
  final Map<int, (Mixlist, int)> _mixlistById;
  final Map<int, List<int>> _mixlistsByArtist;
  final Map<int, List<int>> _artistsByMixlist;
  final Map<(int, int), ConnectionAppearance> _appearanceByPair;

  ConnectionArtist? artistById(int id) => _artistById[id];

  /// Breadth-first search from [sourceId], stopping after the level that
  /// reaches [targetId] (if given). Returns each reached artist's distance
  /// and every (predecessor artist, mixlist) one step closer to the source.
  (Map<int, int>, Map<int, List<(int, int)>>) _search(
    int sourceId, {
    int? targetId,
  }) {
    final distance = {sourceId: 0};
    final predecessors = <int, List<(int, int)>>{};
    final mixlistLevel = <int, int>{};
    var frontier = [sourceId];
    var level = 0;
    while (frontier.isNotEmpty && !distance.containsKey(targetId)) {
      final next = <int>[];
      for (final u in frontier) {
        for (final m in _mixlistsByArtist[u] ?? const <int>[]) {
          final seenAt = mixlistLevel[m];
          if (seenAt != null && seenAt < level) continue;
          mixlistLevel[m] = level;
          for (final v in _artistsByMixlist[m]!) {
            final d = distance[v];
            if (d == null) {
              distance[v] = level + 1;
              next.add(v);
            }
            if (d == null || d == level + 1) {
              predecessors.putIfAbsent(v, () => []).add((u, m));
            }
          }
        }
      }
      frontier = next;
      level++;
    }
    return (distance, predecessors);
  }

  /// A shortest chain from [sourceId] to [targetId], or null if they're not
  /// connected. With [random], picks uniformly among the shortest chains;
  /// otherwise the one through the earliest mixlists.
  ConnectionPath? shortestPath(int sourceId, int targetId, {Random? random}) {
    final source = _artistById[sourceId];
    final target = _artistById[targetId];
    if (source == null || target == null) return null;
    if (sourceId == targetId) {
      return ConnectionPath(
        artists: [source],
        hops: const [],
        shortestRouteCount: 1,
      );
    }
    final (distance, predecessors) = _search(sourceId, targetId: targetId);
    if (!distance.containsKey(targetId)) return null;

    // Routes into each artist, counted level by level from the source.
    final routeCount = <int, int>{sourceId: 1};
    int countRoutes(int v) => routeCount[v] ??= predecessors[v]!.fold(
      0,
      (sum, p) => sum + countRoutes(p.$1),
    );
    final total = countRoutes(targetId);

    final hops = <ConnectionHop>[];
    final chain = [target];
    var current = targetId;
    while (current != sourceId) {
      final options = predecessors[current]!;
      var (previous, mixlistId) = options.first;
      if (random != null) {
        // Weighted by routes through each option, so every chain is equally
        // likely rather than every step.
        var pick = random.nextInt(countRoutes(current));
        for (final option in options) {
          pick -= countRoutes(option.$1);
          if (pick < 0) {
            (previous, mixlistId) = option;
            break;
          }
        }
      }
      final (mixlist, position) = _mixlistById[mixlistId]!;
      hops.add(
        ConnectionHop(
          mixlist: mixlist,
          position: position,
          from: _appearanceByPair[(previous, mixlistId)]!,
          to: _appearanceByPair[(current, mixlistId)]!,
        ),
      );
      chain.add(_artistById[previous]!);
      current = previous;
    }
    return ConnectionPath(
      artists: chain.reversed.toList(),
      hops: hops.reversed.toList(),
      shortestRouteCount: total,
    );
  }

  /// The artists furthest (in hops) from [sourceId] that are still
  /// connected to it, with that distance. Empty if it connects to no one.
  (List<ConnectionArtist>, int) farthestFrom(int sourceId) {
    final (distance, _) = _search(sourceId);
    final maxDistance = distance.values.fold(0, max);
    if (maxDistance == 0) return (const [], 0);
    return (
      [
        for (final entry in distance.entries)
          if (entry.value == maxDistance) _artistById[entry.key]!,
      ],
      maxDistance,
    );
  }
}
