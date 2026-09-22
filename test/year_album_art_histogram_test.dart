import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/year_album_art_histogram.dart';

AlbumArtHistogramEntry _entry(String label, {VoidCallback? onTap}) {
  return AlbumArtHistogramEntry(imageUrl: null, tooltip: label, onTap: onTap);
}

Future<void> _pump(
  WidgetTester tester,
  Map<int, List<AlbumArtHistogramEntry>> entriesByYear,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: YearAlbumArtHistogram(entriesByYear: entriesByYear)),
    ),
  );
}

void main() {
  testWidgets('renders nothing for an empty map', (tester) async {
    await _pump(tester, {});
    expect(find.byType(AlbumArtThumbnail), findsNothing);
    expect(find.byType(Scrollbar), findsNothing);
  });

  testWidgets('a year with zero entries still shows its count and year label', (
    tester,
  ) async {
    await _pump(tester, {2020: []});
    expect(find.text('0'), findsOneWidget);
    expect(find.text('2020'), findsOneWidget);
    expect(find.byType(AlbumArtThumbnail), findsNothing);
  });

  testWidgets(
    'renders exactly one thumbnail per entry, across multiple years',
    (tester) async {
      await _pump(tester, {
        2019: [_entry('a'), _entry('b')],
        2020: [_entry('c'), _entry('d'), _entry('e')],
      });
      expect(find.byType(AlbumArtThumbnail), findsNWidgets(5));
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2019'), findsOneWidget);
      expect(find.text('2020'), findsOneWidget);
      // One continuous horizontal divider across the whole histogram, not
      // one per year (VerticalDivider is a distinct type, not counted here).
      expect(find.byType(Divider), findsOneWidget);
    },
  );

  testWidgets(
    'a year with more than 6 entries wraps into a new sub-column, column-major',
    (tester) async {
      final entries = [for (var i = 0; i < 13; i++) _entry('entry-$i')];
      await _pump(tester, {2021: entries});

      // All 13 render -- wrapping must not drop or cap entries.
      expect(find.byType(AlbumArtThumbnail), findsNWidgets(13));
      expect(find.text('13'), findsOneWidget);

      // Column-major fill: entries 0-5 are the first sub-column (same x,
      // increasing y), entry 6 starts a second sub-column (same y as entry
      // 0 -- top of its column -- but a larger x).
      final first = tester.getTopLeft(find.byTooltip('entry-0'));
      final sixth = tester.getTopLeft(find.byTooltip('entry-5'));
      final seventh = tester.getTopLeft(find.byTooltip('entry-6'));

      expect(
        sixth.dx,
        first.dx,
        reason: 'entry 5 stays in the same sub-column as entry 0',
      );
      expect(
        sixth.dy,
        greaterThan(first.dy),
        reason: 'entry 5 is below entry 0 within the sub-column',
      );

      expect(
        seventh.dx,
        greaterThan(first.dx),
        reason: 'entry 6 starts a new sub-column to the right',
      );
      expect(
        seventh.dy,
        first.dy,
        reason:
            'entry 6 starts at the top of its sub-column, level with entry 0',
      );
    },
  );

  testWidgets(
    'a year with exactly 12 entries produces two full 6-row sub-columns, no more',
    (tester) async {
      final entries = [for (var i = 0; i < 12; i++) _entry('entry-$i')];
      await _pump(tester, {2022: entries});
      expect(find.byType(AlbumArtThumbnail), findsNWidgets(12));

      final first = tester.getTopLeft(find.byTooltip('entry-0'));
      final twelfth = tester.getTopLeft(find.byTooltip('entry-11'));
      // entry-11 is the last row of the second sub-column: same x as
      // entry-6 (start of the second sub-column), well below entry-0.
      final seventh = tester.getTopLeft(find.byTooltip('entry-6'));
      expect(twelfth.dx, seventh.dx);
      expect(twelfth.dy, greaterThan(first.dy));
    },
  );

  testWidgets(
    'a short trailing sub-column bottom-aligns with the full ones instead of floating at the top',
    (tester) async {
      // 13 entries -> sub-columns of [6, 6, 1]. The lone entry in the third
      // (1-row) sub-column should settle to the bottom row, landing at the
      // same y as the last row of a full 6-row sub-column -- not the top.
      final entries = [for (var i = 0; i < 13; i++) _entry('entry-$i')];
      await _pump(tester, {2023: entries});

      final lastRowOfFullColumn = tester.getTopLeft(find.byTooltip('entry-5'));
      final loneEntryInShortColumn = tester.getTopLeft(
        find.byTooltip('entry-12'),
      );

      expect(
        loneEntryInShortColumn.dy,
        lastRowOfFullColumn.dy,
        reason:
            'the short sub-column\'s single entry sits at the bottom row, '
            'level with the last row of a full sub-column',
      );
    },
  );

  testWidgets('tapping a thumbnail calls its onTap', (tester) async {
    var tapped = false;
    await _pump(tester, {
      2018: [_entry('tap-me', onTap: () => tapped = true)],
    });
    await tester.tap(find.byTooltip('tap-me'));
    expect(tapped, isTrue);
  });
}
