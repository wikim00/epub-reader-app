import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'services/firestore_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'EPUB Reader Web',
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
  final String _bookId = 'BloodMeridian';

  @override
  void initState() {
    super.initState();
    _initEpub();
  }

  Future<void> _initEpub() async {
    final bytes = await rootBundle.load('assets/BloodMeridian.epub');
    final lastChapterIndex = await FirestoreService.getLastLocation(_bookId);
    print('Loaded lastChapterIndex: $lastChapterIndex');

    final controller = EpubController(
      document: EpubReader.readBook(bytes.buffer.asUint8List()),
    );

    controller.currentValueListenable.addListener(() {
      final locator = controller.currentValueListenable.value;
      final chapterIndex = locator?.chapter?.index;
      print('Saving chapterIndex: $chapterIndex');
      if (chapterIndex != null) {
        FirestoreService.saveLocation(_bookId, chapterIndex);
      }
    });

    setState(() {
      _epubController = controller;
      _isLoading = false;
    });

    if (lastChapterIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('Going to chapter: $lastChapterIndex');
        controller.gotoChapter(lastChapterIndex);
      });
    }
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
        title: const Text('EPUB Reader Web'),
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
