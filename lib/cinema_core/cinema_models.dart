import 'package:flutter/material.dart';

enum DialogueRole {
  narrator,
  hero,
  heroine,
  villain,
  thought,
}

class BubbleAnnotation {
  final String id;
  final String speechText;
  final DialogueRole role;
  final Rect boundingBox; // Normalized 0.0 - 1.0 coordinate
  final double pauseSeconds;
  final String sfxPrompt;

  const BubbleAnnotation({
    required this.id,
    required this.speechText,
    required this.role,
    required this.boundingBox,
    this.pauseSeconds = 1.0,
    this.sfxPrompt = '',
  });
}

class WebtoonPageItem {
  final int pageIndex;
  final String imageUrl;
  final List<BubbleAnnotation> bubbles;

  const WebtoonPageItem({
    required this.pageIndex,
    required this.imageUrl,
    this.bubbles = const [],
  });
}

class PanelKeyframe {
  final String panelId;
  final Rect panelRect;
  final List<BubbleAnnotation> bubbles;
  final double zoomFactor;

  const PanelKeyframe({
    required this.panelId,
    required this.panelRect,
    required this.bubbles,
    this.zoomFactor = 1.25,
  });
}

class MangaStoryChapter {
  final String title;
  final String episodeNumber;
  final String sourceUrl;
  final List<String> stripImages;
  final List<WebtoonPageItem> pages;
  final List<PanelKeyframe> keyframes;

  const MangaStoryChapter({
    required this.title,
    required this.episodeNumber,
    this.sourceUrl = '',
    required this.stripImages,
    this.pages = const [],
    required this.keyframes,
  });
}
