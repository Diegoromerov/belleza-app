// lib/services/firestore_service.dart
// Servicio simple para operaciones CRUD en Cloud Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ejemplo: colección de "providers"
  static CollectionReference get providers => _db.collection('providers');

  static Future<void> addProvider(Map<String, dynamic> data) async {
    try {
      await providers.add(data);
    } catch (e) {
      debugPrint('Error adding provider: $e');
    }
  }

  static Stream<QuerySnapshot> streamProviders() => providers.snapshots();

  static Future<void> updateProvider(String docId, Map<String, dynamic> data) async {
    try {
      await providers.doc(docId).update(data);
    } catch (e) {
      debugPrint('Error updating provider $docId: $e');
    }
  }

  static Future<void> deleteProvider(String docId) async {
    try {
      await providers.doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting provider $docId: $e');
    }
  }
}
