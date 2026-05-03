import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../domain/safety_video.dart';
import '../../providers/education_providers.dart';
import '../widgets/category_chip_row.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/video_list_tile.dart';
import '../widgets/video_of_day_card.dart';

/// Root screen for the Education tab. Hosts:
///  1. The "Video of the Day" hero card
///  2. Continue Watching strip (auto-hides when empty)
///  3. Category chip row + filtered list
class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final lang = user?.preferredLanguage ?? 'en';

    final selectedCategory = ref.watch(selectedCategoryProvider);
    final videoOfDayAsync = ref.watch(videoOfDayProvider);
    final filteredAsync = ref.watch(videosByCategoryProvider(selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.education_tab_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.workerHome),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(videoOfDayProvider);
          ref.invalidate(videoLibraryProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: videoOfDayAsync.when(
                data: (video) => video == null
                    ? _EmptyHero(message: l10n.education_empty_library)
                    : VideoOfDayCard(
                        video: video,
                        languageCode: lang,
                        label: l10n.video_of_day_label,
                        watchLabel: l10n.watch_now_button,
                        onTap: () => _openPlayer(context, video),
                      ),
                loading: () => const _HeroSkeleton(),
                error: (_, __) =>
                    _EmptyHero(message: l10n.education_empty_library),
              ),
            ),
            SliverToBoxAdapter(
              child: ContinueWatchingSection(
                languageCode: lang,
                label: l10n.continue_watching_label,
                onVideoTap: (v) => _openPlayer(context, v),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text(
                  l10n.browse_by_category_label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryChipRow(
                selected: selectedCategory,
                onChange: (id) =>
                    ref.read(selectedCategoryProvider.notifier).state = id,
                labels: {
                  'all': l10n.category_all,
                  VideoCategory.ppe: l10n.category_ppe,
                  VideoCategory.gasVentilation: l10n.category_gas_ventilation,
                  VideoCategory.roofSupport: l10n.category_roof_support,
                  VideoCategory.emergency: l10n.category_emergency,
                  VideoCategory.machinery: l10n.category_machinery,
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            filteredAsync.when(
              data: (videos) => _buildVideoList(
                context,
                videos: videos,
                languageCode: lang,
                videoOfDayId: videoOfDayAsync.valueOrNull?.videoId,
                emptyText: l10n.education_empty_library,
              ),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList(
    BuildContext context, {
    required List<SafetyVideo> videos,
    required String languageCode,
    required String? videoOfDayId,
    required String emptyText,
  }) {
    final filtered = videoOfDayId == null
        ? videos
        : videos.where((v) => v.videoId != videoOfDayId).toList();
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: Text(emptyText)),
        ),
      );
    }
    return SliverList.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final v = filtered[i];
        return VideoListTile(
          video: v,
          languageCode: languageCode,
          onTap: () => _openPlayer(context, v),
        );
      },
    );
  }

  void _openPlayer(BuildContext context, SafetyVideo video) {
    context.push('${AppRoutes.education}/player', extra: video);
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
