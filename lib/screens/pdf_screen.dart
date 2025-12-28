import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import '../models/book.dart';
import '../storage/book_storage.dart';

class PdfScreen extends StatefulWidget {
  final Book book;
  const PdfScreen({super.key, required this.book});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  late PageController pageController;
  bool darkMode = false;
  bool showUI = true;
  int currentPage = 0;
  int totalPages = 0;
  bool isLoading = true;

  final Map<int, PdfPageImage> _pageCache = {};
  PdfDocument? _pdfDocument;

  @override
  void initState() {
    super.initState();
    currentPage = widget.book.lastPage;
    pageController = PageController(initialPage: widget.book.lastPage);
    _initPdf();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initPdf() async {
    try {
      _pdfDocument = await PdfDocument.openFile(widget.book.path);
      setState(() {
        totalPages = _pdfDocument!.pagesCount;
        widget.book.totalPages = totalPages;
        isLoading = false;
      });
      await _saveProgress();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  Future<void> _saveProgress() async {
    final books = await BookStorage.load();
    final index = books.indexWhere((b) => b.id == widget.book.id);
    if (index != -1) {
      books[index].lastPage = currentPage;
      books[index].totalPages = totalPages;
      await BookStorage.save(books);
    }
  }

  Future<PdfPageImage?> _loadPage(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber];
    }

    if (_pdfDocument == null) return null;

    try {
      final page = await _pdfDocument!.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: darkMode ? '#000000' : '#FFFFFF',
      );
      await page.close();

      if (_pageCache.length > 3) {
        _pageCache.remove(_pageCache.keys.first);
      }
      if (pageImage != null) {
        _pageCache[pageNumber] = pageImage;
      }

      return pageImage;
    } catch (e) {
      return null;
    }
  }

  void _toggleUI() {
    setState(() => showUI = !showUI);
    if (showUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    pageController.dispose();
    _pageCache.clear();
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5EFE6),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : const Color(0xFFF5EFE6),
      body: Stack(
        children: [
          // PDF Pages (Reel-style)
          GestureDetector(
            onTap: _toggleUI,
            child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) {
                setState(() => currentPage = page);
                _saveProgress();

                // Preload next page
                if (page + 1 < totalPages) {
                  _loadPage(page + 2);
                }
              },
              itemCount: totalPages,
              itemBuilder: (context, index) {
                return FutureBuilder<PdfPageImage?>(
                  future: _loadPage(index + 1),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: darkMode ? Colors.black : const Color(0xFFF5EFE6),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return Container(
                        color: darkMode ? Colors.black : const Color(0xFFF5EFE6),
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      );
                    }

                    return Container(
                      color: darkMode ? Colors.black : const Color(0xFFF5EFE6),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.memory(
                            snapshot.data!.bytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Top Gradient
          if (showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Page Counter
          if (showUI)
            Positioned(
              top: 40,
              left: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentPage + 1} / $totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Dark Mode Toggle
          if (showUI)
            Positioned(
              top: 40,
              right: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      darkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => darkMode = !darkMode);
                      _pageCache.clear(); // Clear cache to re-render
                    },
                  ),
                ),
              ),
            ),

          // Back Button
          if (showUI)
            Positioned(
              top: 40,
              left: 70,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

          // Progress Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: Colors.grey.withOpacity(0.2),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: totalPages == 0 ? 0 : (currentPage + 1) / totalPages,
                child: Container(
                  color: darkMode ? Colors.white : Colors.brown.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}