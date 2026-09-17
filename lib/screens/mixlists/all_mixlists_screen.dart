import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/screens/mixlists/add_mixlist_screen.dart';
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

  Future<void> _openAddMixlistScreen() async {
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddMixlistScreen()),
    );
    if (imported == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Mixlists"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Mixlist',
            onPressed: _openAddMixlistScreen,
          ),
        ],
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
