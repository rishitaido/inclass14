import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'item.dart';
import 'firestore_service.dart';
import 'add_edit_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 175, 175, 175), 
      ),
      home: const InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key, required this.title});
  final String title;

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final _service = FirestoreService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF2F4F7), // consistent background color
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search by item name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Item>>(
                stream: _service.getItemsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final items = (snap.data ?? []);
                  final filtered = (_search.isEmpty)
                      ? items
                      : items
                          .where((i) => i.name.toLowerCase().contains(_search))
                          .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No items found.'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final totalValue = (item.quantity * item.price);
                      
                      final cardColor = index.isEven
                          ? const Color.fromARGB(255, 81, 0, 0)
                          : const Color.fromARGB(255, 1, 34, 4);

                      return Card(
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          subtitle: Text(
                            'Qty: ${item.quantity} • \$${item.price.toStringAsFixed(2)}'
                            ' • Total: \$${totalValue.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, item),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditItemScreen(item: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _InventoryFooter(service: _service),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteItem(item.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InventoryFooter extends StatelessWidget {
  const _InventoryFooter({required this.service});
  final FirestoreService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Item>>(
      stream: service.getItemsStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        final totalUnique = items.length;
        final totalValue = items.fold<double>(0, (sum, it) => sum + (it.price * it.quantity));
        final outOfStock = items.where((it) => it.quantity <= 0).length;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items: $totalUnique',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Value: \$${totalValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Out: $outOfStock',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
