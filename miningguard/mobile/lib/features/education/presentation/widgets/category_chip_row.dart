import 'package:flutter/material.dart';

import '../../domain/safety_video.dart';

class CategoryChip {
  const CategoryChip({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

/// Horizontally scrolling row of filter chips for the Education tab.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.selected,
    required this.onChange,
    required this.labels,
  });

  final String selected;
  final ValueChanged<String> onChange;

  /// Localized labels keyed by chip id. Must contain entries for `'all'` and
  /// each [VideoCategory] value.
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final chips = <CategoryChip>[
      CategoryChip(
        id: 'all',
        label: labels['all'] ?? 'All',
        icon: Icons.dashboard,
      ),
      CategoryChip(
        id: VideoCategory.ppe,
        label: labels[VideoCategory.ppe] ?? 'PPE',
        icon: Icons.security,
      ),
      CategoryChip(
        id: VideoCategory.gasVentilation,
        label: labels[VideoCategory.gasVentilation] ?? 'Gas',
        icon: Icons.air,
      ),
      CategoryChip(
        id: VideoCategory.roofSupport,
        label: labels[VideoCategory.roofSupport] ?? 'Roof',
        icon: Icons.architecture,
      ),
      CategoryChip(
        id: VideoCategory.emergency,
        label: labels[VideoCategory.emergency] ?? 'Emergency',
        icon: Icons.emergency,
      ),
      CategoryChip(
        id: VideoCategory.machinery,
        label: labels[VideoCategory.machinery] ?? 'Machinery',
        icon: Icons.precision_manufacturing,
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = chips[i];
          final isSelected = c.id == selected;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 16),
                const SizedBox(width: 6),
                Text(c.label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onChange(c.id),
          );
        },
      ),
    );
  }
}
