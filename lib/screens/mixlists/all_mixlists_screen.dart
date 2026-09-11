import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/models/entities/mixlist.dart';
import 'package:mixlists_project/widgets/mixlist_tile.dart';

class AllMixlistsScreen extends StatefulWidget {
  const AllMixlistsScreen({super.key});

  @override
  State<AllMixlistsScreen> createState() => _AllMixlistsScreenState();
}

class _AllMixlistsScreenState extends State<AllMixlistsScreen> {
  List<Mixlist> _mixlists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await getIt<MusicLibraryRepository>().getAllMixlists();

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
