import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';

class FirestoreService {
  // Create collection reference for 'items'
  final CollectionReference _itemsCollection =
      FirebaseFirestore.instance.collection('items');

  // Add Item to Firestore
  Future<void> addItem(Item item) async {
    await _itemsCollection.add(item.toMap());
  }

  // Get Items Stream (Real-time updates)
  Stream<List<Item>> getItemsStream() {
    return _itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Update Item
  Future<void> updateItem(Item item) async {
    if (item.id != null) {
      await _itemsCollection.doc(item.id).update(item.toMap());
    }
  }

  // Delete Item
  Future<void> deleteItem(String itemId) async {
    await _itemsCollection.doc(itemId).delete();
  }
}