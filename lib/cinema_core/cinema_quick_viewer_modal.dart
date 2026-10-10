import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mangayomi/cinema_core/cinema_models.dart';
import 'package:mangayomi/cinema_core/manga_url_loader_service.dart';

class CinemaQuickViewerModal extends StatefulWidget {
  const CinemaQuickViewerModal({super.key});

  @override
  State<CinemaQuickViewerModal> createState() =>
      _CinemaQuickViewerModalState();
}

class _CinemaQuickViewerModalState
    extends State<CinemaQuickViewerModal> {
  final _urlController = TextEditingController();
  final _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  String? _errorMessage;
  MangaStoryChapter? _chapter;

  static const List<Map<String, String>> _sampleCatalog = [
    {
      'title': 'The Return of the Frozen Player',
      'source': 'Up-Manga',
      'url':
          'https://www.up-manga.com/return-of-the-frozen-%e0%b8%95%e0%b8%ad%e0%b8%99%e0%b8%97%e0%b8%b5%e0%b9%88-182/',
    },
    {
      'title': 'The Return of the Scorned Genius',
      'source': 'SiamWebtoon',
      'url':
          'https://siamwebtoon.com/title/the-return-of-the-scorned-genius/%E0%B8%95%E0%B8%AD%E0%B8%99%E0%B8%97%E0%B8%B5%E0%B9%88-1',
    },
    {
      'title': 'The Return of the Scorned Genius',
      'source': 'ToonXD',
      'url': 'https://toonxd.co/series/the-return-of-the-scorned-genius/1',
    },
    {
      'title': 'The Return of the Scorned Genius',
      'source': 'DukeToon',
      'url':
          'https://duketoon.com/content/the-return-of-the-scorned-genius/1',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('th-TH');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndStart(String targetUrl) async {
    final cleaned = targetUrl.trim();
    if (cleaned.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loadedChapter =
          await MangaUrlLoaderService.loadFromUrl(cleaned);
      if (!mounted) return;

      setState(() {
        _chapter = loadedChapter;
        _isLoading = false;
        _isPlaying = true;
      });

      _playCinemaFlow(loadedChapter);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'โหลดข้อมูลไม่สำเร็จ: $e';
      });
    }
  }

  Future<void> _playCinemaFlow(MangaStoryChapter story) async {
    for (int i = 0; i < story.stripImages.length; i++) {
      if (!mounted || !_isPlaying) break;

      if (_scrollController.hasClients) {
        final targetOffset = i * 650.0;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOutCubic,
        );
      }

      final pageText = 'หน้าที่ ${i + 1} จากทั้งหมด ${story.stripImages.length} หน้า';
      await _flutterTts.speak(pageText);
      await Future.delayed(const Duration(milliseconds: 2600));
    }

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying && _chapter != null) {
      _playCinemaFlow(_chapter!);
    } else {
      _flutterTts.stop();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        title: Text(
          _chapter?.title ?? 'Cinema Webtoon Mode',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'เลือกการ์ตูนแนะนำ',
            icon: const Icon(Icons.explore_rounded, color: Colors.amberAccent),
            onPressed: _showCatalogModal,
          ),
          IconButton(
            tooltip: 'เปิดด้วยลิงก์ URL',
            icon: const Icon(Icons.add_link_rounded, color: Colors.cyanAccent),
            onPressed: _showUrlInputDialog,
          ),
          IconButton(
            tooltip: _isFullscreen ? 'ย่อหน้าจอ' : 'เต็มหน้าจอ',
            icon: Icon(_isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded),
            onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.amberAccent),
                  SizedBox(height: 16),
                  Text('กำลังเชื่อมต่อและดึงภาพต้นฉบับ...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 54),
                    const SizedBox(height: 12),
                    Text(_errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showCatalogModal,
                      child: const Text('เลือกมังงะเรื่องอื่น'),
                    )
                  ],
                ),
              ),
            )
          else if (_chapter == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.movie_filter_rounded,
                        color: Colors.amberAccent, size: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'ยินดีต้อนรับสู่โหมดภาพยนตร์การ์ตูนพากย์เสียง',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เลือกการ์ตูนยอดนิยม หรือ วางลิงก์เว็บการ์ตูนเพื่อเริ่มรับชมทันที',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                          onPressed: _showCatalogModal,
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: const Text('เลือกมังงะยอดนิยม',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: _showUrlInputDialog,
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('วางลิงก์เว็บ'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              controller: _scrollController,
              itemCount: _chapter!.stripImages.length,
              itemBuilder: (context, index) {
                final imgUrl = _chapter!.stripImages[index];
                return Image.network(
                  imgUrl,
                  headers: MangaUrlLoaderService.defaultHeaders,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 320,
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        color: Colors.amberAccent.withValues(alpha: 0.5),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: Text('ภาพที่ ${index + 1} โหลดไม่สำเร็จ',
                        style: const TextStyle(color: Colors.white38)),
                  ),
                );
              },
            ),

          if (_chapter != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: Colors.amberAccent,
                        size: 38,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isPlaying
                                ? 'กำลังพากย์เสียง & เลื่อนภาพอัตโนมัติ'
                                : 'หยุดชั่วคราว',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text(
                            'จำนวน ${_chapter!.stripImages.length} ภาพ',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.explore_rounded,
                          color: Colors.white70),
                      onPressed: _showCatalogModal,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCatalogModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.auto_stories, color: Colors.amberAccent),
                    SizedBox(width: 10),
                    Text('เลือกมังงะยอดนิยม (Up-Manga, Siam, ToonXD)',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 24),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sampleCatalog.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, idx) {
                    final item = _sampleCatalog[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amberAccent.withValues(alpha: 0.15),
                        child: Text('${idx + 1}',
                            style:
                                const TextStyle(color: Colors.amberAccent)),
                      ),
                      title: Text(item['title']!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${item['source']} • แตะเพื่อเริ่มพากย์เสียงทันที',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.play_circle_fill_rounded,
                          color: Colors.amberAccent),
                      onTap: () {
                        Navigator.pop(ctx);
                        _fetchAndStart(item['url']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    _urlController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('ใส่ลิงก์เว็บการ์ตูน',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รองรับ: Up-Manga, SiamWebtoon, ToonXD, DukeToon ฯลฯ',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://www.up-manga.com/...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final target = _urlController.text.trim();
              Navigator.pop(ctx);
              if (target.isNotEmpty) {
                _fetchAndStart(target);
              }
            },
            child: const Text('เริ่มอ่าน & พากย์',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
