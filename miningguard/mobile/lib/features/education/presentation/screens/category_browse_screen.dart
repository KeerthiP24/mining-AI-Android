import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../domain/safety_video.dart';
import '../../providers/education_providers.dart';
import '../widgets/video_list_tile.dart';

/// Optional full-screen browse view for a single category. The Education
/// screen handles in-place filtering for short libraries; this screen is
/// only used for deep-linking via `/worker/education/category/:id`.
class CategoryBrowseScreen extends ConsumerWidget {
  const CategoryBrowseScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final lang = user?.preferredLanguage ?? 'en';

    final videosAsync = ref.watch(videosByCategoryProvider(category));

    return Scaffold(
      appBar: AppBar(title: Text(_categoryLabel(category, l10n))),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return Center(child: Text(l10n.education_empty_library));
          }
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, i) {
              final v = videos[i];
              return VideoListTile(
                video: v,
                languageCode: lang,
                onTap: () =>
                    context.push('${AppRoutes.education}/player', extra: v),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _categoryLabel(String category, AppLocalizations l10n) {
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
        return l10n.browse_by_category_label;
    }
  }
}
