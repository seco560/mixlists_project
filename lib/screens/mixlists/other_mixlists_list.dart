import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/mixlist_summary.dart';

class OtherMixlistsList extends StatelessWidget {
  const OtherMixlistsList({super.key, required this.mixlists, required this.onTap});

  final List<MixlistSummary> mixlists;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: .only(top: 4, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: .circular(12),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: .only(left: 12, top: 8, right: 12, bottom: 4),
            child: Text(
              'Also appears in',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final mixlist in mixlists)
            Material(
              child: ListTile(
                dense: true,
                visualDensity: .compact,
                title: Text(
                  "${mixlist.id}) ${mixlist.title}",
                  style: TextStyle(fontSize: 12, fontWeight: .w600),
                ),
                onTap: () => onTap(mixlist.id),
              ),
            ),
        ],
      ),
    );
  }
}
