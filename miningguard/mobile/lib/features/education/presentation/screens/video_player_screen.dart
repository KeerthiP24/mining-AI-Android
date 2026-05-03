import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../domain/safety_video.dart';
import '../../providers/video_player_provider.dart';
import '../widgets/quiz_overlay.dart';
import '../widgets/source_badge.dart';

/// Embedded YouTube player + watch-progress tracking + quiz launcher.
///
/// All Firestore writes go through [VideoWatchNotifier] (provider:
/// `videoWatchStateProvider`) so this widget stays focused on player UI
/// and lifecycle.
class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key, required this.video});

  final SafetyVideo video;

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  VideoWatchNotifier? _notifier;
  bool _restored = false;
  bool _quizShown = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: false,
      ),
    );
    _controller.addListener(_onPlayerEvent);
  }

  /// Effective video duration in seconds. Prefer the YouTube player's
  /// reported metadata duration once it loads — Firestore's `durationSeconds`
  /// is metadata-only and can disagree with the actual file (which makes
  /// percent-completion calculations off-by-enough that the 90% threshold
  /// never fires). Fall back to the seed value while metadata is still
  /// loading or for unit tests where metadata is empty.
  int _effectiveDurationSeconds() {
    final live = _controller.metadata.duration.inSeconds;
    if (live > 0) return live;
    return widget.video.durationSeconds;
  }

  void _onPlayerEvent() {
    final value = _controller.value;
    if (!value.isReady) return;

    final notifier = _notifier;
    if (notifier == null) return;

    // Read the current watch via the provider (state is @protected on the
    // notifier itself).
    final watch = ref.read(videoWatchStateProvider(widget.video.videoId));
    if (watch == null) return; // init() still pending — wait

    final duration = _effectiveDurationSeconds();
    if (duration <= 0) return; // metadata not yet loaded

    // Restore saved position once after both watch state and player metadata
    // are available, only if the user is mid-watch.
    if (!_restored) {
      _restored = true;
      if (watch.completionPercent > 0 && watch.completionPercent < 90) {
        final resumeAt = (watch.completionPercent / 100.0) * duration;
        _controller.seekTo(Duration(seconds: resumeAt.toInt()));
      }
    }

    final positionSeconds = value.position.inSeconds;
    final percent = ((positionSeconds / duration) * 100)
        .clamp(0, 100)
        .toInt();

    final crossed = notifier.reportProgress(percent);
    if (crossed && !_quizShown && !notifier.alreadyCompletedToday) {
      _quizShown = true;
      _controller.pause();
      _showQuiz();
    }
  }

  Future<void> _showQuiz() async {
    if (widget.video.quizQuestions.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserModelProvider).valueOrNull;
    final lang = user?.preferredLanguage ?? 'en';
    final notifier = _notifier;
    if (notifier == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: QuizOverlay(
              questions: widget.video.quizQuestions,
              languageCode: lang,
              videoTitle: localizeMap(widget.video.title, lang),
              headingLabel: l10n.quiz_heading,
              questionOfTotal: l10n.quiz_question_of_total,
              submitLabel: l10n.quiz_submit_button,
              passHeading: l10n.quiz_well_done_heading,
              failHeading: l10n.quiz_try_again_heading,
              pointsAwardedLabel: l10n.quiz_points_awarded,
              continueLabel: l10n.quiz_continue_button,
              onComplete: (score) async {
                await notifier.submitQuiz(
                  score: score,
                  totalQuestions: widget.video.quizQuestions.length,
                );
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              },
            ),
          ),
        );
      },
    );

    if (mounted) _controller.play();
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerEvent);
    // Persist whatever progress is pending. Use the cached notifier ref —
    // ref.read after super.dispose ordering can throw on autoDispose.
    _notifier?.flushNow();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch keeps the autoDispose notifier alive for the lifetime of
    // this screen and lets us cache the notifier reference for use inside
    // the (very hot) player listener.
    ref.watch(videoWatchStateProvider(widget.video.videoId));
    _notifier ??=
        ref.read(videoWatchStateProvider(widget.video.videoId).notifier);

    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final lang = user?.preferredLanguage ?? 'en';
    final title = localizeMap(widget.video.title, lang);
    final description = localizeMap(widget.video.description, lang);
    final theme = Theme.of(context);

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFF5A623),
        onReady: () {
          // Force a listener fire so seek-restoration runs as soon as
          // metadata is available.
          _onPlayerEvent();
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(title, maxLines: 1)),
          body: ListView(
            children: [
              player,
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SourceBadge(source: widget.video.source),
                        const SizedBox(width: 10),
                        Text(
                          _categoryLabel(widget.video.category, context),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _categoryLabel(String category, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case VideoCategory.ppe:
        return l10n.category_ppe;
      case VideoCategory.gasVentilation:
        return l10n.category_gas_ventilation;
      case VideoCategory.roofSupport:
        return l10n.category_roof_support;
      case VideoCategory.emergency:
        return l10n.category_emergency;
      case VideoCategory.machinery:
        return l10n.category_machinery;
      default:
        return category;
    }
  }
}
