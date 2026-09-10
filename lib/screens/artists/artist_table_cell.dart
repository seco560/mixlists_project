import 'package:flutter/material.dart';

class ArtistTableHeaderCell extends StatelessWidget {
  const ArtistTableHeaderCell({
    super.key,
    required this.width,
    required this.label,
    required this.textStyle,
    required this.numeric,
    required this.isSorted,
    required this.sortAscending,
    this.onTap,
  });

  final double width;
  final String label;
  final TextStyle textStyle;
  final bool numeric;
  final bool isSorted;
  final bool sortAscending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: numeric
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSorted) ...[
            const SizedBox(width: 4),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
          ],
        ],
      ),
    );
    return SizedBox(
      width: width,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class ArtistTableCell extends StatelessWidget {
  const ArtistTableCell({
    super.key,
    required this.width,
    required this.numeric,
    required this.child,
  });

  final double width;
  final bool numeric;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Align(
          alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}
