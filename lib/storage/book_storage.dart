import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class BookStorage {
  static const _key = 'books';

  static Future<void> save(List<Book> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(books.map((b) => b.toJson()).toList());
      await prefs.setString(_key, jsonString);
    } catch (e) {
      print('Error saving books: $e');
    }
  }

  static Future<List<Book>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data == null) return [];

      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }

  static Future<void> addBook(Book book) async {
    final books = await load();
    books.add(book);
    await save(books);
  }

  static Future<void> updateBook(Book updatedBook) async {
    final books = await load();
    final index = books.indexWhere((b) => b.id == updatedBook.id);
    if (index != -1) {
      books[index] = updatedBook;
      await save(books);
    }
  }

  static Future<void> removeBook(String bookId) async {
    final books = await load();
    books.removeWhere((b) => b.id == bookId);
    await save(books);
  }
}