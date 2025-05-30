import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';

class EditMenuPage extends StatefulWidget {
  final MenuModel? menu;

  const EditMenuPage({Key? key, this.menu}) : super(key: key);

  @override
  _EditMenuPageState createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  String _selectedCategory = 'Food';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.menu?.title ?? '');
    _descriptionController = TextEditingController(text: widget.menu?.description ?? '');
    _priceController = TextEditingController(
        text: widget.menu?.price.toStringAsFixed(2) ?? '');
    _imageUrlController = TextEditingController(text: widget.menu?.imageUrl ?? '');
    _selectedCategory = widget.menu?.category ?? 'Food';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  int _getCategoryId(String category) {
    switch (category) {
      case 'Food':
        return 1;
      case 'Drink':
        return 2;
      case 'Snack':
        return 3;
      default:
        return 0;
    }
  }

  void _saveMenu() async {
    if (_formKey.currentState!.validate()) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final menu = MenuModel(
        id: widget.menu?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: _imageUrlController.text.trim(),
        category: _selectedCategory,
        categoryId: _getCategoryId(_selectedCategory),
      );

      if (widget.menu == null) {
        await menuProvider.addMenu(menu);
        Navigator.pop(context, 'added'); // <== kirim flag 'added'
      } else {
        await menuProvider.updateMenu(widget.menu!.id!, menu);
        Navigator.pop(context, 'updated'); // <== kirim flag 'updated'
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menu != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu' : 'Add Menu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['Food', 'Drink', 'Snack']
                    .map((e) => DropdownMenuItem(child: Text(e), value: e))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMenu,
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
