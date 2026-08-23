import 'package:flutter/material.dart';
import 'package:jetkiz_mobile/core/localization/localizedText.dart';
import 'package:jetkiz_mobile/features/reviews/domain/restaurantReview.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewMediaBlocks extends StatelessWidget {
  const ReviewMediaBlocks({
    super.key,
    required this.items,
  });

  final List<ReviewMediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.map((item) {
        if (item.isImage) {
          return _ReviewImageBlock(item: item);
        }
        if (item.isVideo) {
          return _ReviewVideoBlock(item: item);
        }
        if (item.isAudio) {
          return _ReviewAudioBlock(item: item);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

class _ReviewImageBlock extends StatelessWidget {
  const _ReviewImageBlock({
    required this.item,
  });

  final ReviewMediaItem item;

  @override
  Widget build(BuildContext context) {
    final preview = (item.previewUrl ?? item.url).trim();
    final original = item.url.trim();

    return GestureDetector(
      onTap: original.isEmpty
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _FullScreenImagePage(
                    imageUrl: original,
                  ),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 16 / 11,
          child: Image.network(
            preview.isNotEmpty ? preview : original,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF3F4F6),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                size: 34,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewVideoBlock extends StatelessWidget {
  const _ReviewVideoBlock({
    required this.item,
  });

  final ReviewMediaItem item;

  Future<void> _openVideo(BuildContext context) async {
    final url = item.url.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showError(context, 'Не удалось открыть видео');
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      _showError(context, 'Не удалось открыть видео');
    }
  }

  void _showError(BuildContext context, String text) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: LocalizedText(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = widgetPreviewUrl(item);

    return GestureDetector(
      onTap: () => _openVideo(context),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: preview != null
                    ? Image.network(
                        preview,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF111827),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF111827),
                      ),
              ),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xF2FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 36,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      LocalizedText(
                        'Открыть видео',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewAudioBlock extends StatelessWidget {
  const _ReviewAudioBlock({
    required this.item,
  });

  final ReviewMediaItem item;

  Future<void> _openAudio(BuildContext context) async {
    final url = item.url.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showError(context, 'Не удалось открыть аудио');
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      _showError(context, 'Не удалось открыть аудио');
    }
  }

  void _showError(BuildContext context, String text) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: LocalizedText(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAudio(context),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0x1A489F2A),
              Color(0x0D489F2A),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0x33489F2A),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF489F2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: 0.35,
                  backgroundColor: Color(0x66FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF489F2A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x99FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    size: 16,
                    color: Color(0xFF374151),
                  ),
                  SizedBox(width: 6),
                  LocalizedText(
                    'Открыть аудио',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: const Color(0x66000000),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? widgetPreviewUrl(ReviewMediaItem item) {
  final raw = (item.previewUrl ?? '').trim();
  if (raw.isNotEmpty) return raw;

  final url = item.url.trim();
  if (url.isNotEmpty) return url;

  return null;
}
