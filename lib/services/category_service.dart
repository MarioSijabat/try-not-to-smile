// lib/services/category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream daftar kategori, diurutkan by field `order`
  Stream<List<CategoryModel>> getCategories() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Tambah kategori baru (untuk admin)
  Future<void> addCategory(CategoryModel category) async {
    await _db.collection('categories').doc(category.id).set(category.toMap());
  }

  /// Hapus kategori
  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }
}
