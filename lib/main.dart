import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:epubz/epubz.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB Reader with User Login',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return EpubReaderPage(userId: snapshot.data!.uid);
          } else {
            return LoginPage(
              onLoginSuccess: () {},
            );
          }
        },
      ),
    );
  }
}

class EpubReaderPage extends StatefulWidget {
  final String userId;
  const EpubReaderPage({super.key, required this.userId});

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubBook? _book;
  int _currentChapterIndex = 0;
  int _currentPageIndex = 0;
  List<String> _pages = [];
  PageController _pageController = PageController();
  Timer? _debounceTimer;
  final Duration _debounceDuration = Duration(seconds: 2);

  final String _bookId = 'BloodMeridian';
  final ScrollController _scrollController = ScrollController();

  List<String> _splitIntoPages(String text, {int maxLength = 1000}) {
    final cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');
    final result = <String>[];
    for (int i = 0; i < cleaned.length; i += maxLength) {
      result
          .add(cleaned.substring(i, (i + maxLength).clamp(0, cleaned.length)));
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  Future<void> _loadBook() async {
    try {
      final data = await rootBundle.load('assets/BloodMeridian.epub');
      final book = await EpubReader.readBook(data.buffer.asUint8List());

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('reading_progress')
          .doc(_bookId)
          .get();

      int savedChapter = 0;
      int savedPageIndex = 0;

      if (doc.exists) {
        final data = doc.data();
        savedChapter = data?['chapterIndex'] ?? 0;
        savedPageIndex = data?['pageIndex'] ?? 0;
      }

      final chapter = book.Chapters![savedChapter];

      setState(() {
        _book = book;
        _currentChapterIndex = savedChapter;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final size = MediaQuery.of(context).size;
        final double pageWidth = size.width > 600 ? 600 : size.width;
        _pages = await paginateText(
          fullText: chapter.HtmlContent ?? '',
          style: const TextStyle(fontSize: 16),
          pageHeight: size.height,
          pageWidth: pageWidth,
        );
        setState(() {
          _currentPageIndex = savedPageIndex;
        });
      });
    } catch (e) {
      print('Error loading book: $e');
    }
  }

  Future<void> _saveProgress(int chapterIndex, int pageIndex) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('reading_progress')
          .doc(_bookId)
          .set({
        'chapterIndex': chapterIndex,
        'pageIndex': pageIndex,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to save progress: $e');
    }
  }

  void _nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
      _saveProgress(_currentChapterIndex, _currentPageIndex);
    } else {
      _nextChapter();
    }
  }

  void _prevPage() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
      _saveProgress(_currentChapterIndex, _currentPageIndex);
    } else {
      _prevChapter();
    }
  }

  void _nextChapter() {
    if (_book?.Chapters == null) return;
    if (_currentChapterIndex < _book!.Chapters!.length - 1) {
      setState(() {
        _currentChapterIndex++;
        _pages = _splitIntoPages(
            _book!.Chapters![_currentChapterIndex].HtmlContent ?? '');
        _currentPageIndex = 0;
      });
      _saveProgress(_currentChapterIndex, 0);
    }
  }

  void _prevChapter() {
    if (_book == null) return;
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
        _pages = _splitIntoPages(
            _book!.Chapters![_currentChapterIndex].HtmlContent ?? '');
        _currentPageIndex = 0;
      });
      _saveProgress(_currentChapterIndex, 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux;

    final textStyle = TextStyle(fontSize: isDesktop ? 20 : 16);

    if (_book == null || _book!.Chapters == null || _book!.Chapters!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading EPUB...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chapterTitle = _book!.Chapters![_currentChapterIndex].Title ??
        'Chapter ${_currentChapterIndex + 1}';

    return Scaffold(
      appBar: AppBar(
        title: Text(chapterTitle),
        actions: [
          if (FirebaseAuth.instance.currentUser?.photoURL != null &&
              FirebaseAuth.instance.currentUser!.photoURL!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                backgroundImage:
                    NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dx = details.localPosition.dx;

          if (dx < screenWidth * 0.3) {
            _prevPage();
          } else {
            _nextPage();
          }
        },
        child: Container(
          alignment: Alignment.topCenter,
          width: double.infinity,
          height: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.topLeft,
              child: SelectableText(
                _pages.isNotEmpty ? _pages[_currentPageIndex] : '',
                style: textStyle,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _prevChapter,
            ),
            Text(
              'Chapter ${_currentChapterIndex + 1} / ${_book!.Chapters?.length ?? 0} - Page ${_currentPageIndex + 1} / ${_pages.length}',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _nextChapter,
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> paginateText({
    required String fullText,
    required TextStyle style,
    required double pageHeight,
    required double pageWidth,
    double padding = 16,
  }) async {
    final text = fullText.replaceAll(RegExp(r'<[^>]*>'), '');
    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    final List<String> pages = [];
    int start = 0;

    while (start < text.length) {
      int end = text.length;
      int low = start;
      int high = end;

      // Binary search to fit text into height
      while (low < high) {
        int mid = (low + high) ~/ 2;
        final testSpan = TextSpan(
          text: text.substring(start, mid),
          style: style,
        );
        painter.text = testSpan;
        painter.layout(maxWidth: pageWidth - padding * 2);

        if (painter.height > pageHeight - padding * 2) {
          high = mid - 1;
        } else {
          low = mid + 1;
        }
      }

      int pageEnd = low - 1;
      if (pageEnd <= start) break; // Prevent infinite loop
      pages.add(text.substring(start, pageEnd));
      start = pageEnd;
    }

    return pages;
  }
}
