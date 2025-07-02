import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // your generated Firebase config

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
    return const MaterialApp(
      title: 'EPUB Reader with Firestore Sync',
      home: EpubReaderPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EpubReaderPage extends StatefulWidget {
  const EpubReaderPage({super.key});

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubController? _epubController;
  bool _isLoading = true;

  // Example user/book ids for Firestore
  final String _userId = 'user123';
  final String _bookId = 'BloodMeridian';

  @override
  void initState() {
    super.initState();
    _initEpub();
  }

  Future<void> _initEpub() async {
    try {
      final bytes = await rootBundle.load('assets/BloodMeridian.epub');
      final bookData = bytes.buffer.asUint8List();

      // Initialize controller with the book
      _epubController = EpubController(document: EpubReader.readBook(bookData));

      // Load saved CFI from Firestore
      final savedCfi = await _loadProgress();

      // Jump to saved CFI if available
      if (savedCfi != null && savedCfi.isNotEmpty) {
        _epubController!.gotoCfi(savedCfi);
      }

      // Listen for CFI changes and save progress
      _epubController!.cfiStream.listen((cfi) {
        _saveProgress(cfi);
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing EPUB: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgress(String cfi) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reading_progress')
          .doc(_bookId)
          .set({'cfi': cfi});
      print('Saved progress CFI: $cfi');
    } catch (e) {
      print('Failed to save progress: $e');
    }
  }

  Future<String?> _loadProgress() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reading_progress')
          .doc(_bookId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['cfi'] != null) {
          return data['cfi'] as String;
        }
      }
    } catch (e) {
      print('Failed to load progress: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _epubController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Reader with Firestore Sync'),
      ),
      body: EpubView(controller: _epubController!),
    );
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }
}
