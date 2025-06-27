import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import '../services/firestore_service.dart';

class ReaderScreen extends StatefulWidget {
  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late EpubController _epubController;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController(
      document: EpubDocument.openAsset('assets/sample.epub'),
    );

    _loadProgress();
  }

  void _loadProgress() async {
    final cfi = await FirestoreService.getLastLocation('sample.epub');
    if (cfi != null) {
      _epubController.gotoEpubCfi(cfi);
    }
  }

  void _saveProgress(String cfi) {
    FirestoreService.saveLocation('sample.epub', cfi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EPUB Reader')),
      body: EpubView(
        controller: _epubController,
        onDocumentLoaded: (_) => print("Document Loaded"),
        onChapterChanged: (_) {
          final cfi = _epubController.generateEpubCfi();
          if (cfi != null) _saveProgress(cfi);
        },
      ),
    );
  }
}
