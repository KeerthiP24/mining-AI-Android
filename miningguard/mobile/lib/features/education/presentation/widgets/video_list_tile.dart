import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/safety_video.dart';
import 'source_badge.dart';

/// Compact tile for browse lists and the Continue Watching strip.
///
/// Pass [progressPercent] (0–100) to render a thin progress bar across the
/// bottom of the thumbnail. Omit it for normal browse rows.
class VideoListTile extends StatelessWidget {
  const VideoListTile({
    super.key,
    required this.video,
    required this.languageCode,
    required this.onTap,
    this.progressPercent,
    this.compact = false,
  });

  final SafetyVideo video;
  final String languageCode;
  final VoidCallback onTap;
  final int? progressPercent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildRow(context);
  }

  Widget _buildRow(BuildContext context) {
    final theme = Theme.of(context);
    final title = localizeMap(video.title, languageCode);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: Color(0xFF202030)),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF202030),
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 28),
                    ),
                  ),
                  if (progressPercent != null && progressPercent! > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        value: (progressPercent! / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFF5A623),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SourceBadge(source: video.source),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule,
                            size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 3),
                        Text(
                          _formatDuration(video.durationSeconds),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final title = localizeMap(video.title, languageCode);

    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 8),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const ColoredBox(color: Color(0xFF202030)),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Color(0xFF202030),
                        child: Icon(Icons.broken_image,
                            color: Colors.white54),
                      ),
                    ),
                    if (progressPercent != null && progressPercent! > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          value: (progressPercent! / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.black26,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFF5A623),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--:--';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
