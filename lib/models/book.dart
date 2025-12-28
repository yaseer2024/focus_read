class Book {
  final String id;
  final String title;
  final String path;
  int lastPage;
  int totalPages;

  Book({
    required this.id,
    required this.title,
    required this.path,
    this.lastPage = 0,
    this.totalPages = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'lastPage': lastPage,
      'totalPages': totalPages,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown',
      path: json['path'] ?? '',
      lastPage: json['lastPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  double get progress {
    if (totalPages == 0) return 0;
    return (lastPage + 1) / totalPages;
  }

  String get progressPercent {
    return '${(progress * 100).toInt()}%';
  }
}