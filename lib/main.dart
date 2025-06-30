import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  @override
  void initState() {
    super.initState();
    _initEpub();
  }

  Future<void> _initEpub() async {
    final bytes = await rootBundle.load('assets/BloodMeridian.epub');
    setState(() {
      _epubController = EpubController(
        document: EpubReader.readBook(bytes.buffer.asUint8List()),
      );
      _isLoading = false;
    });
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
