import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';
import '../../pages/menu/edit_menu_page.dart';

class SnackTab extends StatelessWidget {
  const SnackTab({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final snackItems = menuProvider.menus.where((menu) => menu.category == 'Snack').toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          runSpacing: 10,
          children: snackItems.map((menu) => MenuCard(menu: menu)).toList(),
        ),
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final MenuModel menu;
  const MenuCard({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.network(
              menu.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menu.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(menu.description),
                  Text('Harga: Rp${menu.price.toStringAsFixed(0)}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditMenuPage(menu: menu),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await menuProvider.deleteMenu(menu.id!, menu.category);
              },
            ),
          ],
        ),
      ),
    );
  }
}
