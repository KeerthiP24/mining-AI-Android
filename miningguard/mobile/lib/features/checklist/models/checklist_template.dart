import 'package:cloud_firestore/cloud_firestore.dart';

/// A single item definition from the master checklist template.
class ChecklistTemplateItem {
  const ChecklistTemplateItem({
    required this.itemId,
    required this.category,
    required this.labelKey,
    required this.mandatory,
    required this.order,
  });

  final String itemId;
  final String category;  // ppe | machinery | environment | emergency | supervisor
  final String labelKey;  // ARB key e.g. "checklist_ppe_helmet"
  final bool mandatory;
  final int order;

  factory ChecklistTemplateItem.fromMap(Map<String, dynamic> map) {
    return ChecklistTemplateItem(
      itemId: map['itemId'] as String,
      category: map['category'] as String,
      labelKey: map['labelKey'] as String,
      mandatory: map['mandatory'] as bool? ?? false,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'category': category,
      'labelKey': labelKey,
      'mandatory': mandatory,
      'order': order,
    };
  }
}

/// Master checklist template stored in `checklist_templates/{mineId}_{role}`.
/// Never mutated by workers — only admins write here.
class ChecklistTemplate {
  const ChecklistTemplate({
    required this.templateId,
    required this.mineId,
    required this.role,
    required this.version,
    required this.items,
  });

  final String templateId;
  final String mineId;
  final String role;  // worker | supervisor
  final int version;
  final List<ChecklistTemplateItem> items;

  factory ChecklistTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return ChecklistTemplate(
      templateId: doc.id,
      mineId: data['mineId'] as String,
      role: data['role'] as String,
      version: data['version'] as int? ?? 1,
      items: rawItems
          .map((e) =>
              ChecklistTemplateItem.fromMap(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'templateId': templateId,
      'mineId': mineId,
      'role': role,
      'version': version,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  /// All distinct categories in display order.
  List<String> get categories {
    final seen = <String>{};
    return items
        .map((e) => e.category)
        .where(seen.add)
        .toList();
  }

  /// Items filtered by category, sorted by order.
  List<ChecklistTemplateItem> itemsForCategory(String category) {
    return items.where((e) => e.category == category).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
