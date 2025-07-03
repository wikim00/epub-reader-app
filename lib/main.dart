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
  Timer? _debounceTimer;
  final Duration _debounceDuration = Duration(seconds: 2);

  // These IDs identify user and book in Firestore (customize as needed)
  final String _bookId = 'BloodMeridian';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBook();

    _scrollController.addListener(() {
      _onScrollChanged(_scrollController.offset);
    });
  }

  Future<void> _loadBook() async {
    try {
      final data = await rootBundle.load('assets/BloodMeridian.epub');
      final book = await EpubReader.readBook(data.buffer.asUint8List());

      // Load saved progress from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('reading_progress')
          .doc(_bookId)
          .get();

      int savedChapter = 0;
      double savedOffset = 0.0;

      if (doc.exists) {
        final data = doc.data();
        savedChapter = data?['chapterIndex'] ?? 0;
        savedOffset = (data?['scrollOffset'] ?? 0).toDouble();
      }

      setState(() {
        _book = book;
        _currentChapterIndex = savedChapter;
      });

      // Delay scroll until after layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(savedOffset);
      });
    } catch (e) {
      print('Error loading book: $e');
    }
  }

  Future<int?> _loadProgress() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('reading_progress')
          .doc(_bookId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['chapterIndex'] != null) {
          return data['chapterIndex'] as int;
        }
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
    return null;
  }

  Future<void> _saveProgress(int chapterIndex, double scrollOffset) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('reading_progress')
          .doc(_bookId)
          .set({
        'chapterIndex': chapterIndex,
        'scrollOffset': scrollOffset,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to save progress: $e');
    }
  }

  // When scrolling
  void _onScrollChanged(double offset) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(_debounceDuration, () {
      _saveProgress(_currentChapterIndex, offset);
    });
  }

  // When changing chapters
  void _nextChapter() {
    if (_book?.Chapters == null) return;
    if (_currentChapterIndex < _book!.Chapters!.length - 1) {
      setState(() {
        _currentChapterIndex++;
      });
      _saveProgress(_currentChapterIndex, 0.0).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading progress saved'),
            duration: Duration(seconds: 1),
          ),
        );
      });
    }
  }

  void _prevChapter() {
    if (_book == null) return;
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
      _saveProgress(_currentChapterIndex, 0.0).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading progress saved'),
            duration: Duration(seconds: 1),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_book == null || _book!.Chapters == null || _book!.Chapters!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading EPUB...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chapter = _book!.Chapters![_currentChapterIndex];
    final chapterTitle = chapter.Title ?? 'Chapter ${_currentChapterIndex + 1}';
    final chapterText = chapter.HtmlContent ?? '[No content]';

    return Scaffold(
      appBar: AppBar(title: Text(chapterTitle)),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          // Basic HTML tags will be shown raw, for better formatting consider flutter_html package
          chapterText.replaceAll(RegExp(r'<[^>]*>'), ''),
          style: const TextStyle(fontSize: 16),
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
              '${_currentChapterIndex + 1} / ${_book!.Chapters?.length ?? 0}',
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
}
