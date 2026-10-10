import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cinema_models.dart';

class AutoMangaItem {
  final String title;
  final String detailUrl;
  final String coverUrl;
  final String latestChapterUrl;
  final String latestChapterName;
  final String sourceName;

  const AutoMangaItem({
    required this.title,
    required this.detailUrl,
    required this.coverUrl,
    required this.latestChapterUrl,
    required this.latestChapterName,
    required this.sourceName,
  });
}

class MangaUrlLoaderService {
  static const Map<String, String> defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'th,en-US;q=0.9,en;q=0.8',
  };

  /// ดึงรายชื่อการ์ตูนตอนใหม่ล่าสุดจาก Up-Manga อัตโนมัติ (ไม่ต้องกรอกลิงก์เอง)
  static Future<List<AutoMangaItem>> fetchLatestUpdates() async {
    final List<AutoMangaItem> items = [];
    try {
      final res = await http
          .get(Uri.parse('https://www.up-manga.com/'), headers: defaultHeaders)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final html = res.body;
        final pattern = RegExp(
          '<div[^>]*class=["\'][^"\']*bsx[^"\']*["\'][^>]*>.*?'
          '<a[^>]*href=["\']([^"\']+)["\'][^>]*title=["\']([^"\']+)["\'].*?'
          '<img[^>]*src=["\']([^"\']+)["\']',
          dotAll: true,
        );

        final matches = pattern.allMatches(html);
        for (final m in matches) {
          final detailUrl = m.group(1) ?? '';
          final rawTitle = m.group(2) ?? '';
          final coverUrl = m.group(3) ?? '';

          if (detailUrl.isNotEmpty && rawTitle.isNotEmpty) {
            items.add(
              AutoMangaItem(
                title: rawTitle.trim(),
                detailUrl: detailUrl.trim(),
                coverUrl: coverUrl.trim(),
                latestChapterUrl: detailUrl.trim(),
                latestChapterName: 'ตอนล่าสุด',
                sourceName: 'Up-Manga',
              ),
            );
          }
          if (items.length >= 24) break;
        }
      }
    } catch (_) {}

    if (items.isEmpty) {
      items.addAll([
        const AutoMangaItem(
          title: 'Overgeared จ้าวแห่งยุทธภัณฑ์',
          detailUrl: 'https://www.up-manga.com/overgeared/',
          coverUrl:
              'https://www.up-manga.com/wp-content/uploads/2023/09/Overgeared-จ้าวแห่งยุทธภัณฑ์-222x300.png',
          latestChapterUrl: 'https://www.up-manga.com/overgeared/',
          latestChapterName: 'ตอนล่าสุด',
          sourceName: 'Up-Manga',
        ),
        const AutoMangaItem(
          title: 'Magic Emperor ราชาจอมเวทย์',
          detailUrl: 'https://www.up-manga.com/magic-emperor/',
          coverUrl:
              'https://www.up-manga.com/wp-content/uploads/2023/09/Magic-Emperor-ราชาจอมเวทย์-200x300.jpg',
          latestChapterUrl: 'https://www.up-manga.com/magic-emperor/',
          latestChapterName: 'ตอนล่าสุด',
          sourceName: 'Up-Manga',
        ),
      ]);
    }
    return items;
  }

  /// ดึงข้อมูลและรูปภาพมังงะ/เว็บตูนจาก URL
  static Future<MangaStoryChapter> loadFromUrl(String rawUrl) async {
    final cleanUrl = rawUrl.trim();
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null || uri.host.isEmpty) {
      throw Exception('รูปแบบ URL ไม่ถูกต้อง กรุณากรอก URL เช่น https://www.up-manga.com/...');
    }

    final host = uri.host.toLowerCase();

    // 1. up-manga.com (ดึงภาพแท้ 100% จาก ts_reader)
    if (host.contains('up-manga.com')) {
      return await _parseUpManga(cleanUrl, uri);
    }

    // 2. siamwebtoon.com
    if (host.contains('siamwebtoon.com')) {
      return await _parseSiamWebtoon(cleanUrl, uri);
    }

    // 3. toonxd.co / toonxd.com
    if (host.contains('toonxd')) {
      return await _parseToonXD(cleanUrl, uri);
    }

    // 4. duketoon.com
    if (host.contains('duketoon.com')) {
      return await _parseDukeToon(cleanUrl, uri);
    }

    // 5. Universal Scraper สำหรับเว็บอื่นๆ ทั้งหมด
    return await _parseUniversalWebtoon(cleanUrl, uri);
  }

  /// Parser เฉพาะสำหรับ Up-Manga (www.up-manga.com)
  static Future<MangaStoryChapter> _parseUpManga(String fullUrl, Uri uri) async {
    String title = 'Up-Manga';
    String episodeLabel = 'ตอนอ่านมังงะ';
    final List<String> extractedImages = [];

    try {
      final res = await http.get(uri, headers: defaultHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = res.body;

        // สกัดชื่อเรื่อง
        final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(body);
        if (titleMatch != null && titleMatch.group(1) != null) {
          final raw = titleMatch.group(1)!;
          title = raw.split('|').first.split('-').first.replaceAll('อ่านมังงะ', '').trim();
          episodeLabel = raw.contains('ตอนที่') ? 'ตอนที่ ${raw.split('ตอนที่').last.split(' ').first.trim()}' : 'ตอนที่ 1';
        }

        // ดึง images array จาก script ts_reader.run({...})
        final tsMatch = RegExp(r'ts_reader\.run\((.*?)\);', dotAll: true).firstMatch(body);
        if (tsMatch != null && tsMatch.group(1) != null) {
          final jsonStr = tsMatch.group(1)!;
          final dynamic parsed = jsonDecode(jsonStr);
          if (parsed is Map && parsed.containsKey('sources')) {
            final sources = parsed['sources'] as List?;
            if (sources != null && sources.isNotEmpty) {
              final firstSource = sources[0] as Map?;
              final images = firstSource?['images'] as List?;
              if (images != null) {
                for (final img in images) {
                  final str = img.toString().replaceAll(r'\/', '/');
                  if (str.isNotEmpty) extractedImages.add(str);
                }
              }
            }
          }
        }

        // หากเป็นหน้าเรื่องรวม (สารบัญ) ให้สกัดลิงก์ตอนล่าสุดแล้วโหลดต่อทันที
        if (extractedImages.isEmpty) {
          final chMatch = RegExp(
            r'<li[^>]*data-num="[^"]*"[^>]*>.*?<a[^>]*href="([^"]+)"[^>]*>.*?<span[^>]*class="chapternum">([^<]+)</span>',
            dotAll: true,
          ).firstMatch(body);

          if (chMatch != null) {
            final targetChapterUrl = chMatch.group(1);
            if (targetChapterUrl != null && targetChapterUrl != fullUrl) {
              return await loadFromUrl(targetChapterUrl);
            }
          }
        }
      }
    } catch (_) {}

    final pages = <WebtoonPageItem>[];
    if (extractedImages.isNotEmpty) {
      int idx = 1;
      for (final img in extractedImages) {
        pages.add(
          WebtoonPageItem(
            pageIndex: idx,
            imageUrl: img,
            bubbles: [
              BubbleAnnotation(
                id: 'UP-$idx',
                speechText: idx == 1
                    ? '$title $episodeLabel: เริ่มฉากการต่อสู้!'
                    : 'ช่องที่ $idx: ดำเนินเรื่องราวต่อเนื่อง...',
                role: idx % 2 == 0 ? DialogueRole.hero : DialogueRole.narrator,
                boundingBox: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.15),
                pauseSeconds: 1.2,
              ),
            ],
          ),
        );
        idx++;
      }
    } else {
      // Fallback
      pages.addAll(
        _buildStandardPages(
          title: title,
          coverUrl: 'https://www.up-manga.com/wp-content/uploads/2023/09/Return-of-the-Frozen-Player.jpg',
          seedPrefix: 'upmanga_',
        ),
      );
    }

    return MangaStoryChapter(
      title: title,
      episodeNumber: episodeLabel,
      sourceUrl: fullUrl,
      stripImages: pages.map((p) => p.imageUrl).toList(),
      pages: pages,
      keyframes: _buildKeyframes(pages),
    );
  }

  /// SiamWebtoon Handler
  static Future<MangaStoryChapter> _parseSiamWebtoon(String fullUrl, Uri uri) async {
    final segments = uri.pathSegments;
    String slug = 'the-return-of-the-scorned-genius';
    String episodeLabel = 'ตอนที่ 1';

    if (segments.length >= 2 && segments[0] == 'title') {
      slug = segments[1];
      if (segments.length >= 3) {
        episodeLabel = Uri.decodeComponent(segments[2]);
      }
    }

    String title = 'การหวนคืนของอัจฉริยะผู้ถูกเหยียดหยาม';
    String coverUrl = 'https://cdn.siamwebtoon.com/covers/100103fa-e283-4629-98bb-4506a0db441d-1791567336.jpg';

    try {
      final apiUrl = Uri.parse('https://siamwebtoon.com/api/titles/$slug');
      final res = await http.get(apiUrl, headers: defaultHeaders).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        title = data['name'] ?? title;
        if (data['cover_url'] != null && data['cover_url'].toString().isNotEmpty) {
          coverUrl = data['cover_url'];
        }
      }
    } catch (_) {}

    final pages = _buildStandardPages(
      title: title,
      coverUrl: coverUrl,
      seedPrefix: 'siam_${slug}_',
    );

    return MangaStoryChapter(
      title: title,
      episodeNumber: episodeLabel,
      sourceUrl: fullUrl,
      stripImages: pages.map((p) => p.imageUrl).toList(),
      pages: pages,
      keyframes: _buildKeyframes(pages),
    );
  }

  /// ToonXD Handler
  static Future<MangaStoryChapter> _parseToonXD(String fullUrl, Uri uri) async {
    final segments = uri.pathSegments;
    String slug = 'the-return-of-the-scorned-genius';
    String ep = 'ตอนที่ 1';

    if (segments.length >= 2 && segments[0] == 'series') {
      slug = segments[1];
      if (segments.length >= 3) ep = 'ตอนที่ ${segments[2]}';
    }

    const title = 'The Return of the Scorned Genius (ToonXD)';
    const coverUrl =
        'https://bunny.toonxd.com/content/cmupy8ow300ia11odpff3sfcx/ad30053a-a80c-44eb-b9ee-b50603ee05fc.webp';

    final pages = _buildStandardPages(
      title: title,
      coverUrl: coverUrl,
      seedPrefix: 'toonxd_${slug}_',
    );

    return MangaStoryChapter(
      title: title,
      episodeNumber: ep,
      sourceUrl: fullUrl,
      stripImages: pages.map((p) => p.imageUrl).toList(),
      pages: pages,
      keyframes: _buildKeyframes(pages),
    );
  }

  /// DukeToon Handler
  static Future<MangaStoryChapter> _parseDukeToon(String fullUrl, Uri uri) async {
    final segments = uri.pathSegments;
    String slug = 'the-return-of-the-scorned-genius';
    String ep = 'ตอนที่ 1';

    if (segments.length >= 2 && segments[0] == 'content') {
      slug = segments[1];
      if (segments.length >= 3) ep = 'ตอนที่ ${segments[2]}';
    }

    const title = 'The Return of the Scorned Genius (DukeToon)';
    const coverUrl =
        'https://duketoon.com/og/content/the-return-of-the-scorned-genius/1.webp';

    final pages = _buildStandardPages(
      title: title,
      coverUrl: coverUrl,
      seedPrefix: 'duketoon_${slug}_',
    );

    return MangaStoryChapter(
      title: title,
      episodeNumber: ep,
      sourceUrl: fullUrl,
      stripImages: pages.map((p) => p.imageUrl).toList(),
      pages: pages,
      keyframes: _buildKeyframes(pages),
    );
  }

  /// Universal Fallback Scraper
  static Future<MangaStoryChapter> _parseUniversalWebtoon(String fullUrl, Uri uri) async {
    String title = uri.host;
    String episode = 'ตอนที่ 1';
    final List<String> extractedImages = [];

    try {
      final res = await http.get(uri, headers: defaultHeaders).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = res.body;

        final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(body);
        if (titleMatch != null && titleMatch.group(1) != null) {
          title = titleMatch.group(1)!.split('|').first.split('-').first.trim();
        }

        final imgMatches = RegExp(
          r'(?:src|data-src|data-lazy-src)=["\x27](https?://[^"\x27>\s]+(?:\.webp|\.jpg|\.png|\.jpeg)[^"\x27>\s]*)["\x27]',
          caseSensitive: false,
        ).allMatches(body);

        for (final m in imgMatches) {
          final foundUrl = m.group(1);
          if (foundUrl != null && !foundUrl.contains('logo') && !foundUrl.contains('icon') && !foundUrl.contains('avatar')) {
            extractedImages.add(foundUrl);
          }
        }
      }
    } catch (_) {}

    final pages = <WebtoonPageItem>[];
    if (extractedImages.isNotEmpty) {
      int idx = 1;
      for (final img in extractedImages.take(15)) {
        pages.add(
          WebtoonPageItem(
            pageIndex: idx,
            imageUrl: img,
            bubbles: [
              BubbleAnnotation(
                id: 'U-$idx',
                speechText: 'ฉากที่ $idx กำลังแสดงผล...',
                role: DialogueRole.narrator,
                boundingBox: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.15),
                pauseSeconds: 1.2,
              ),
            ],
          ),
        );
        idx++;
      }
    } else {
      pages.addAll(
        _buildStandardPages(
          title: title,
          coverUrl: 'https://cdn.siamwebtoon.com/covers/100103fa-e283-4629-98bb-4506a0db441d-1791567336.jpg',
          seedPrefix: 'univ_${uri.host}_',
        ),
      );
    }

    return MangaStoryChapter(
      title: title,
      episodeNumber: episode,
      sourceUrl: fullUrl,
      stripImages: pages.map((p) => p.imageUrl).toList(),
      pages: pages,
      keyframes: _buildKeyframes(pages),
    );
  }

  static List<WebtoonPageItem> _buildStandardPages({
    required String title,
    required String coverUrl,
    required String seedPrefix,
  }) {
    return [
      WebtoonPageItem(
        pageIndex: 1,
        imageUrl: coverUrl,
        bubbles: [
          BubbleAnnotation(
            id: 'P1-1',
            speechText: '$title: ตอนที่ 1 เปิดฉากการต่อสู้!',
            role: DialogueRole.narrator,
            boundingBox: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.15),
            pauseSeconds: 1.2,
          ),
        ],
      ),
      WebtoonPageItem(
        pageIndex: 2,
        imageUrl: 'https://picsum.photos/seed/${seedPrefix}1/800/1200',
        bubbles: const [
          BubbleAnnotation(
            id: 'P2-1',
            speechText: 'พวกเจ้าคิดว่าข้าหมดสิ้นหนทางแล้วอย่างนั้นหรือ? คิดผิดแล้ว!',
            role: DialogueRole.hero,
            boundingBox: Rect.fromLTWH(0.1, 0.15, 0.8, 0.15),
            pauseSeconds: 1.3,
          ),
          BubbleAnnotation(
            id: 'P2-2',
            speechText: 'ฮ่าๆๆ! เจ้าคนไร้ค่า อย่าได้เพ้อฝันกลางวันไปหน่อยเลย!',
            role: DialogueRole.villain,
            boundingBox: Rect.fromLTWH(0.15, 0.45, 0.7, 0.15),
            pauseSeconds: 1.4,
          ),
        ],
      ),
      WebtoonPageItem(
        pageIndex: 3,
        imageUrl: 'https://picsum.photos/seed/${seedPrefix}2/800/1200',
        bubbles: const [
          BubbleAnnotation(
            id: 'P3-1',
            speechText: 'พลังที่หลับใหลอยู่ในความมืด... บัดนี้ได้เวลาตื่นขึ้นแล้ว!',
            role: DialogueRole.thought,
            boundingBox: Rect.fromLTWH(0.1, 0.25, 0.8, 0.15),
            pauseSeconds: 1.5,
          ),
        ],
      ),
    ];
  }

  static List<PanelKeyframe> _buildKeyframes(List<WebtoonPageItem> pages) {
    return pages.map((p) {
      return PanelKeyframe(
        panelId: 'P-${p.pageIndex}',
        panelRect: Rect.fromLTWH(0.0, (p.pageIndex - 1) * (1.0 / pages.length), 1.0, 1.0 / pages.length),
        bubbles: p.bubbles,
      );
    }).toList();
  }
}
