import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';

class MixlistTile extends StatelessWidget {
  final Mixlist mixlist;
  final bool isMarking;
  final bool isMarked;
  final ValueChanged<int>? onToggleMarked;

  const MixlistTile({
    super.key,
    required this.mixlist,
    this.isMarking = false,
    this.isMarked = false,
    this.onToggleMarked,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: isMarking
          ? Checkbox(
              value: isMarked,
              onChanged: (_) => onToggleMarked?.call(mixlist.id),
            )
          : null,
      title: Text("${mixlist.id}) ${mixlist.title}", style: TextStyle(fontSize: 20, fontWeight: .bold)),
      subtitle: Text(mixlist.dateCreated.split('T')[0], style: TextStyle(fontSize: 16, fontWeight: .w600)),
      onTap: isMarking
          ? () => onToggleMarked?.call(mixlist.id)
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MixlistDetailScreen(mixlist: mixlist),
                ),
              );
            },
    );
  }
}
