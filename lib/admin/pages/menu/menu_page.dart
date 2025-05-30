import 'package:flutter/material.dart';
import 'edit_menu_page.dart';
import 'menu_tab_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Menu Page"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Food"),
              Tab(text: "Drink"),
              Tab(text: "Snack"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MenuTabPage(category: 'Food'),
            MenuTabPage(category: 'Drink'),
            MenuTabPage(category: 'Snack'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditMenuPage()),
            );
            if (result == 'added') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu berhasil ditambahkan')),
              );
            } else if (result == 'updated') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu berhasil diperbarui')),
              );
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}