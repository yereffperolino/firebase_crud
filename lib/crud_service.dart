import 'package:cloud_firestore/cloud_firestore.dart';

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  // CREATE
  Future<DocumentReference> addItem(String name, int quantity) {
    return items.add({
      'name': name,
      'quantity': quantity,
      'favorite': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // READ
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  // UPDATE
  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  Future<void> toggleFavorite(String id, bool favorite) {
    return items.doc(id).update({'favorite': !favorite});
  }

  // DELETE
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}