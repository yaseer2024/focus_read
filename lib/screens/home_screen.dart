import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../storage/book_storage.dart';
import 'pdf_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => isLoading = true);
    final loadedBooks = await BookStorage.load();
    setState(() {
      books = loadedBooks;
      isLoading = false;
    });
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final dir = await getApplicationDocumentsDirectory();

      String cleanName = result.files.single.name
          .replaceAll(' ', '_')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll('[', '')
          .replaceAll(']', '');

      final newPath = '${dir.path}/$cleanName';
      final saved = await file.copy(newPath);

      final newBook = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result.files.single.name.replaceAll('.pdf', ''),
        path: saved.path,
      );

      await BookStorage.addBook(newBook);
      await _loadBooks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final file = File(book.path);
        if (await file.exists()) {
          await file.delete();
        }
        await BookStorage.removeBook(book.id);
        await _loadBooks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
      ),
      body: books.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories,
              size: 80,
              color: Colors.brown.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No books yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.brown.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first book',
              style: TextStyle(
                fontSize: 14,
                color: Colors.brown.shade400,
              ),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (_, i) {
          final book = books[i];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfScreen(book: book),
                ),
              );
              await _loadBooks();
            },
            onLongPress: () => _deleteBook(book),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Book cover
                Container(
                  height: 180,
                  width: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.brown.shade600,
                        Colors.brown.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      if (book.totalPages > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: book.progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade300,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Book title
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (book.totalPages > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${book.lastPage + 1} / ${book.totalPages}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade400,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickPdf,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
        backgroundColor: Colors.brown.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }
}