import 'package:flutter/material.dart';
import '../models/note.dart';
import '../helpers/database_helper.dart';
import '../services/security_service.dart';

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({super.key, this.note});

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final SecurityService _securityService = SecurityService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }

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
    _titleController.dispose();
    _contentController.dispose();
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

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      if (widget.note == null) {
        // Tambah catatan baru
        final newNote = Note(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await _databaseHelper.insertNote(newNote);
      } else {
        // Update catatan yang ada
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: now,
        );
        await _databaseHelper.updateNote(updatedNote);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8D5FF),
        elevation: 0,
        title: Text(
          widget.note == null ? 'Tambah Catatan' : 'Edit Catatan',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveNote,
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
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
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Catatan',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
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
                  child: TextFormField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      labelText: 'Isi Catatan',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Isi catatan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
