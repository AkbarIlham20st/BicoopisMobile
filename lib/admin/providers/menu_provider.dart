import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

class MenuProvider with ChangeNotifier {
  final MenuService _menuService = MenuService();
  List<MenuModel> _menus = [];

  List<MenuModel> get menus => _menus;
  bool isLoading = false;

  Future<void> fetchMenus(String category) async {
    isLoading = true;
    notifyListeners();
    try {
      _menus = await _menuService.fetchMenusByCategory(category);
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      _menus = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> addMenu(MenuModel menu) async {
    await _menuService.addMenu(menu);
    await fetchMenus(menu.category);
  }

  Future<void> updateMenu(String id, MenuModel menu) async {
    await _menuService.updateMenu(id, menu);
    await fetchMenus(menu.category);
  }

  Future<void> deleteMenu(String id, String category) async {
    await _menuService.deleteMenu(id);
    await fetchMenus(category);
  }
}
