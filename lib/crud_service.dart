import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

// HELPER MODEL FOR PICKED IMAGE AND UPLOAD URL
class PickedImage {
  final File file;
  final String url;

  PickedImage({required this.file, required this.url});
}

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'ehjspc4t',
    'flutter_notes_preset', // Ensure this matches your Cloudinary unsigned preset name
    cache: false,
  );

  final ImagePicker picker = ImagePicker();

  // PICK AND UPLOAD IMAGE TO CLOUDINARY
  Future<PickedImage?> pickImageForAddItem() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final file = File(pickedFile.path);
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    return PickedImage(file: file, url: response.secureUrl);
  }

  // CREATE ITEM WITH IMAGE URL
  Future<DocumentReference> addItemWithImage(
      String name, int quantity, String? imageUrl) async {
    return await items.add({
      'name': name,
      'quantity': quantity,
      'imageUrl': imageUrl ?? '',
      'favorite': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // CREATE STANDARD ITEM (WITHOUT IMAGE)
  Future<DocumentReference> addItem(String name, int quantity) {
    return items.add({
      'name': name,
      'quantity': quantity,
      'favorite': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // READ ITEMS STREAM
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  // UPDATE ITEM
  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  // TOGGLE FAVORITE STATUS
  Future<void> toggleFavorite(String id, bool favorite) {
    return items.doc(id).update({'favorite': !favorite});
  }

  // DELETE ITEM
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}
