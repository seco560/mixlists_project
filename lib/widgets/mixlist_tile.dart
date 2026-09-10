import 'package:flutter/material.dart';
import 'package:mixlists_project/models/entities/mixlist.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';

class MixlistTile extends StatelessWidget {
  final Mixlist mixlist;

  const MixlistTile({super.key, required this.mixlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("${mixlist.id}) ${mixlist.title}", style: TextStyle(fontSize: 20, fontWeight: .bold)),
      subtitle: Text(mixlist.dateCreated.split('T')[0], style: TextStyle(fontSize: 16, fontWeight: .w600)),
      onTap: () {
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
