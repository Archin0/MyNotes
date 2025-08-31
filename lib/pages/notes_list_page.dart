import 'package:flutter/material.dart';
import '../models/note.dart';
import '../helpers/database_helper.dart';
import '../services/security_service.dart';
import 'add_edit_note_page.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage>
    with WidgetsBindingObserver {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final SecurityService _securityService = SecurityService();
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotes();

    // Listen to authentication changes
    _securityService.authStream.listen((isAuthenticated) {
      if (!isAuthenticated && mounted) {
        // If not authenticated, pop all routes and go back to auth wrapper
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _securityService.onAppResume();
        break;
      case AppLifecycleState.paused:
        _securityService.onAppPause();
        break;
      case AppLifecycleState.inactive:
        // Do nothing for inactive state
        break;
      case AppLifecycleState.detached:
        _securityService.logout();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _databaseHelper.getAllNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Apakah Anda yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && note.id != null) {
      try {
        await _databaseHelper.deleteNote(note.id!);
        _loadNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddEditNote([Note? note]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => AddEditNotePage(note: note)),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hari ini';
    } else if (difference == 1) {
      return 'Kemarin';
    } else if (difference < 7) {
      return '$difference hari yang lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8D5FF),
        elevation: 0,
        title: const Text(
          'Catatan Harianku',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada catatan',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tambahkan catatan pertama Anda',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          note.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(note.updatedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNote(note),
                    ),
                    onTap: () => _navigateToAddEditNote(note),
                  ),
                );
              },
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddEditNote(),
          backgroundColor: const Color(0xFFE8D5FF),
          foregroundColor: Colors.black,
          label: const Text(
            'Tambah Catatan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
