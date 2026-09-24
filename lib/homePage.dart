import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'crud_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  bool showFavorites = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  void confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  bool isFavorite(DocumentSnapshot item) {
    final data = item.data();
    return data is Map && data['favorite'] == true;
  }

  void openAddDialog(BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();

    File? selectedImageFile;
    String? selectedImageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // IMAGE PREVIEW IF PICKED
                if (selectedImageFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      selectedImageFile!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // UPLOAD BUTTON / SPINNER
                if (isUploading)
                  const CircularProgressIndicator()
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      selectedImageFile == null
                          ? "Upload Image"
                          : "Change Image",
                    ),
                    onPressed: () async {
                      setDialogState(() => isUploading = true);
                      final picked = await service.pickImageForAddItem();
                      if (picked != null) {
                        setDialogState(() {
                          selectedImageFile = picked.file;
                          selectedImageUrl = picked.url;
                          isUploading = false;
                        });
                      } else {
                        setDialogState(() => isUploading = false);
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isUploading
                  ? null
                  : () async {
                      if (nameCtrl.text.isNotEmpty &&
                          qtyCtrl.text.isNotEmpty) {
                        final quantity = int.tryParse(qtyCtrl.text) ?? 0;
                        if (selectedImageUrl != null &&
                            selectedImageUrl!.isNotEmpty) {
                          await service.addItemWithImage(
                            nameCtrl.text,
                            quantity,
                            selectedImageUrl,
                          );
                        } else {
                          await service.addItem(nameCtrl.text, quantity);
                        }
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void openEditDialog(BuildContext context, DocumentSnapshot item) {
    // DocumentSnapshot's [] operator throws StateError on a missing field,
    // so read through the raw map instead.
    final data = item.data() as Map<String, dynamic>?;
    nameCtrl.text = data?['name']?.toString() ?? '';
    qtyCtrl.text = data?['quantity']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                service.updateItem(
                  item.id,
                  nameCtrl.text,
                  int.tryParse(qtyCtrl.text) ?? 0,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('firebase | Perolino'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            tooltip: 'Show favorite items',
            icon: Icon(
              showFavorites ? Icons.favorite : Icons.favorite_border,
              color: showFavorites ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              setState(() => showFavorites = !showFavorites);
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openAddDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((item) {
            return !showFavorites || isFavorite(item);
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                showFavorites ? "No favorite items found" : "No items found",
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var item = docs[index];
              final data = item.data() as Map<String, dynamic>?;
              final favorite = isFavorite(item);
              final imageUrl = data != null && data.containsKey('imageUrl')
                  ? data['imageUrl'] as String?
                  : null;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  // SHOW IMAGE THUMBNAIL IF AVAILABLE
                  leading: (imageUrl != null && imageUrl.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported,
                                    size: 40, color: Colors.grey),
                          ),
                        )
                      : null,
                  title: Text(
                    data?['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Quantity: ${data?['quantity'] ?? 0}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: favorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        icon: Icon(
                          favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                        onPressed: () =>
                            service.toggleFavorite(item.id, favorite),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => openEditDialog(context, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(context, item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
