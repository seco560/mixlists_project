import 'package:flutter/material.dart';
import 'package:mixlists_project/data/library/library_record.dart';

extension on LibraryOrigin {
  String get label => switch (this) {
    LibraryOrigin.bundled => 'Bundled',
    LibraryOrigin.spotifyImport => 'From Spotify',
    LibraryOrigin.csvImport => 'From CSV',
  };
}

class LibraryTile extends StatelessWidget {
  const LibraryTile({
    super.key,
    required this.library,
    required this.isActive,
    required this.onTap,
    this.onRename,
    this.onDelete,
    this.onExport,
  });

  final LibraryRecord library;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle : Icons.library_music_outlined,
        ),
        title: Text(
          library.displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${library.origin.label} · ${library.createdAt.toString().split(' ').first}',
        ),
        trailing: (onRename == null && onDelete == null && onExport == null)
            ? null
            : PopupMenuButton<VoidCallback>(
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  if (onExport != null)
                    PopupMenuItem(value: onExport, child: const Text('Export')),
                  if (onRename != null)
                    PopupMenuItem(value: onRename, child: const Text('Rename')),
                  if (onDelete != null)
                    PopupMenuItem(value: onDelete, child: const Text('Delete')),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}
