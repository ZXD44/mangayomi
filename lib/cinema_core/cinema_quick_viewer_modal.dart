import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mangayomi/cinema_core/cinema_models.dart';
import 'package:mangayomi/cinema_core/manga_url_loader_service.dart';

class CinemaQuickViewerModal extends StatefulWidget {
  const CinemaQuickViewerModal({super.key});

  @override
  State<CinemaQuickViewerModal> createState() => _CinemaQuickViewerModalState();
}

class _CinemaQuickViewerModalState extends State<CinemaQuickViewerModal> {
  final _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  String? _errorMessage;
  MangaStoryChapter? _chapter;
  String _currentSubtitle = '';
  int _currentPageIndex = 1;

  List<AutoMangaItem> _mangaList = [];
  bool _isLoadingList = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadMangaFeed();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage('th-TH');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.0);
    } catch (_) {
      try {
        await _flutterTts.setLanguage('th');
      } catch (_) {}
    }
  }

  Future<void> _loadMangaFeed() async {
    setState(() => _isLoadingList = true);
    final items = await MangaUrlLoaderService.fetchLatestUpdates();
    if (!mounted) return;
    setState(() {
      _mangaList = items;
      _isLoadingList = false;
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndStart(String targetUrl) async {
    final cleaned = targetUrl.trim();
    if (cleaned.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentSubtitle = 'กำลังโหลดข้อมูลมังงะและเตรียมบทพากย์...';
    });

    try {
      final loadedChapter = await MangaUrlLoaderService.loadFromUrl(cleaned);
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

      setState(() {
        _currentPageIndex = i + 1;
      });

      if (_scrollController.hasClients) {
        final targetOffset = i * 650.0;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
      }

      String narrationText = 'หน้าที่ ${i + 1} จากทั้งหมด ${story.stripImages.length} หน้า';
      if (i < story.pages.length && story.pages[i].bubbles.isNotEmpty) {
        narrationText = story.pages[i].bubbles.first.speechText;
      }

      if (mounted) {
        setState(() {
          _currentSubtitle = narrationText;
        });
      }

      try {
        await _flutterTts.speak(narrationText);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentSubtitle = 'จบการพากย์เสียงในตอนนี้เรียบร้อยแล้ว';
      });
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
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF141419),
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chapter?.title ?? 'โรงภาพยนตร์การ์ตูน (Cinema Mode)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text(
                    'พัฒนาโดย ZirconX (ZXD44) • ระบบดึงมังงะและพากย์เสียงอัตโนมัติ',
                    style: TextStyle(fontSize: 10, color: Colors.amberAccent),
                  ),
                ],
              ),
              actions: [
                if (_chapter != null)
                  IconButton(
                    tooltip: 'กลับไปหน้ารวมการ์ตูน',
                    icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
                    onPressed: () {
                      _flutterTts.stop();
                      setState(() {
                        _isPlaying = false;
                        _chapter = null;
                      });
                    },
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
                  Text('กำลังดึงภาพการ์ตูนต้นฉบับอัตโนมัติ...',
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => setState(() => _errorMessage = null),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('เลือกเรื่องอื่น'),
                    )
                  ],
                ),
              ),
            )
          else if (_chapter == null)
            _buildAutoMangaFeed()
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
                    child: Text('ภาพที่ ${index + 1} กำลังโหลด...',
                        style: const TextStyle(color: Colors.white38)),
                  ),
                );
              },
            ),

          // แถบแสดงบทพากย์ / ซับไตเติลแบบ Real-time
          if (_chapter != null && _currentSubtitle.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: AnimatedOpacity(
                opacity: _isPlaying ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.amberAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'บทพากย์ภาษาไทย [หน้า $_currentPageIndex/${_chapter!.stripImages.length}]',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _currentSubtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // แถบควบคุมด้านล่างเมื่อกำลังเล่น
          if (_chapter != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
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
                            'จำนวน ${_chapter!.stripImages.length} หน้า • สร้างโดย ZirconX',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'กลับไปเลือกเรื่องใหม่',
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () {
                        _flutterTts.stop();
                        setState(() {
                          _isPlaying = false;
                          _chapter = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoMangaFeed() {
    if (_isLoadingList) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.amberAccent),
            SizedBox(height: 16),
            Text('กำลังดึงการ์ตูนอัปเดตล่าสุดจากหน้าเว็บ...',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF191920),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.amberAccent, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'การ์ตูนตอนใหม่ล่าสุด (แตะเพื่อเริ่มดูและพากย์เสียงทันที)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white70, size: 20),
                onPressed: _loadMangaFeed,
                tooltip: 'รีเฟรชข้อมูลล่าสุด',
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _mangaList.length,
            itemBuilder: (context, idx) {
              final item = _mangaList[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _fetchAndStart(item.detailUrl),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.coverUrl,
                              headers: MangaUrlLoaderService.defaultHeaders,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: Colors.white10,
                                alignment: Alignment.center,
                                child: const Icon(Icons.movie_creation_outlined,
                                    color: Colors.amberAccent, size: 40),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.sourceName,
                                  style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.play_arrow_rounded,
                                    color: Colors.black, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
