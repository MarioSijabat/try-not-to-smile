// lib/models/category_model.dart

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] as String? ?? id,
      icon: data['icon'] as String? ?? '🎬',
      order: data['order'] as int? ?? 99,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'order': order,
      };
}
