import 'package:flutter/material.dart';
import 'package:mixlists_project/helpers/get_it_init.dart';
import 'package:mixlists_project/helpers/music_library_repository.dart';
import 'package:mixlists_project/models/mixlist.dart';
import 'package:mixlists_project/screens/mixlist_detail_screen.dart';

class AllMixlistsScreen extends StatefulWidget {
  const AllMixlistsScreen({super.key});

  @override
  State<AllMixlistsScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<AllMixlistsScreen> {
  List<Mixlist> _mixlists = []; // can be refactored with FutureBuilder
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await getIt<MusicLibraryRepository>().mixlists.getAll();

      setState(() {
        _mixlists = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading playlists: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Mixlists"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mixlists.isEmpty
          ? const Center(child: Text("No data found"))
          : ListView.separated(
              separatorBuilder: (_, _) => Divider(color: Colors.blueGrey),
              itemCount: _mixlists.length,
              itemBuilder: (context, index) =>
                  MixlistTile(mixlist: _mixlists[index]),
            ),
    );
  }
}

class MixlistTile extends StatelessWidget {
  final Mixlist mixlist;

  const MixlistTile({super.key, required this.mixlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("${mixlist.id} - ${mixlist.title}", style: TextStyle(fontSize: 20, fontWeight: .bold)),
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
