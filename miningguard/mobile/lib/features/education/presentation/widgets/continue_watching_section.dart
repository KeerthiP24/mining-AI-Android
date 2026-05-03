import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/safety_video.dart';
import '../../domain/video_watch.dart';
import '../../providers/education_providers.dart';
import 'video_list_tile.dart';

/// Horizontally scrolling row of in-progress videos. Hides itself entirely
/// when there are no partially-watched videos so we never show an empty
/// state on the Education tab.
class ContinueWatchingSection extends ConsumerWidget {
  const ContinueWatchingSection({
    super.key,
    required this.languageCode,
    required this.label,
    required this.onVideoTap,
  });

  final String languageCode;

  /// Localized "Continue Watching" heading.
  final String label;

  final void Function(SafetyVideo video) onVideoTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchesAsync = ref.watch(continueWatchingProvider);
    final libraryAsync = ref.watch(videoLibraryProvider);

    final watches = watchesAsync.valueOrNull ?? const <VideoWatch>[];
    final library = libraryAsync.valueOrNull ?? const <SafetyVideo>[];
    if (watches.isEmpty || library.isEmpty) return const SizedBox.shrink();

    final videoById = {for (final v in library) v.videoId: v};
    final pairs = <({SafetyVideo video, VideoWatch watch})>[];
    for (final w in watches) {
      final v = videoById[w.videoId];
      if (v != null && w.completionPercent > 0 && w.completionPercent < 90) {
        pairs.add((video: v, watch: w));
      }
    }
    if (pairs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 12),
            itemCount: pairs.length,
            itemBuilder: (context, i) {
              final pair = pairs[i];
              return VideoListTile(
                video: pair.video,
                languageCode: languageCode,
                progressPercent: pair.watch.completionPercent,
                compact: true,
                onTap: () => onVideoTap(pair.video),
              );
            },
          ),
        ),
      ],
    );
  }
}
