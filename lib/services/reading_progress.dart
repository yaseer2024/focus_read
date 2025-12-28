import '../models/book.dart';
import '../storage/book_storage.dart';

class ReadingProgress {
  static double progress(Book book) {
    if (book.totalPages == 0) return 0;
    return (book.lastPage + 1) / book.totalPages;
  }

  static Future<void> update(
      List<Book> books,
      Book book,
      int page,
      int total,
      ) async {
    final index = books.indexWhere((b) => b.path == book.path);
    if (index == -1) return;

    books[index].lastPage = page;
    books[index].totalPages = total;

    await BookStorage.save(books);
  }
}