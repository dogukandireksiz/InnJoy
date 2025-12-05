import 'package:flutter/material.dart';
import 'package:login_page/l10n/app_localizations.dart'; // Çeviri paketi şart

class MenuItem {
  final String name;
  final String description;
  final double price;
  final String? imagePath;

  const MenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.imagePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// ARTIK LIST DEĞİL, FONKSİYON KULLANIYORUZ
// Çünkü "texts" değişkenine ihtiyacımız var.

List<MenuItem> getBreakfastItems(AppLocalizations texts) => [
  MenuItem(
    name: texts.menu_spreadBreakfast,
    description: texts.desc_spreadBreakfast,
    price: 450,
  ),
  MenuItem(
    name: texts.menu_pancake,
    description: texts.desc_pancake,
    price: 280,
  ),
  MenuItem(
    name: texts.menu_avocado,
    description: texts.desc_avocado,
    price: 250,
  ),
  MenuItem(
    name: texts.menu_friedEgg,
    description: texts.desc_friedEgg,
    price: 220,
  ),
  MenuItem(
    name: texts.menu_cheeseSandwich,
    description: texts.desc_cheeseSandwich,
    price: 180,
  ),
  MenuItem(
    name: texts.menu_orangeJuice,
    description: texts.desc_orangeJuice,
    price: 120,
  ),
];

List<MenuItem> getLunchDinnerItems(AppLocalizations texts) => [
  MenuItem(
    name: texts.menu_meatballs,
    description: texts.desc_meatballs,
    price: 380,
  ),
  MenuItem(
    name: texts.menu_chickenSkewers,
    description: texts.desc_chickenSkewers,
    price: 350,
  ),
  MenuItem(
    name: texts.menu_mixedPizza,
    description: texts.desc_mixedPizza,
    price: 320,
  ),
  MenuItem(
    name: texts.menu_caesarSalad,
    description: texts.desc_caesarSalad,
    price: 280,
  ),
  MenuItem(
    name: texts.menu_risotto,
    description: texts.desc_risotto,
    price: 340,
  ),
  MenuItem(name: texts.menu_burger, description: texts.desc_burger, price: 290),
];

List<MenuItem> getBeverageItems(AppLocalizations texts) => [
  MenuItem(
    name: texts.menu_turkishCoffee,
    description: texts.desc_turkishCoffee,
    price: 80,
  ),
  MenuItem(name: texts.menu_latte, description: texts.desc_latte, price: 95),
  MenuItem(
    name: texts.menu_lemonade,
    description: texts.desc_lemonade,
    price: 90,
  ),
  MenuItem(
    name: texts.menu_smoothie,
    description: texts.desc_smoothie,
    price: 130,
  ),
  MenuItem(name: texts.menu_iceTea, description: texts.desc_iceTea, price: 70),
  MenuItem(name: texts.menu_water, description: texts.desc_water, price: 40),
];

List<MenuItem> getNightMenuItems(AppLocalizations texts) => [
  MenuItem(name: texts.menu_fries, description: texts.desc_fries, price: 120),
  MenuItem(name: texts.menu_wings, description: texts.desc_wings, price: 220),
  MenuItem(name: texts.menu_toast, description: texts.desc_toast, price: 150),
  MenuItem(
    name: texts.menu_souffle,
    description: texts.desc_souffle,
    price: 180,
  ),
  MenuItem(
    name: texts.menu_fruitPlate,
    description: texts.desc_fruitPlate,
    price: 160,
  ),
  MenuItem(
    name: texts.menu_iceCream,
    description: texts.desc_iceCream,
    price: 110,
  ),
];

IconData getIconForItem(String name) {
  final lowerName = name.toLowerCase();
  // İkon mantığı aynı kalabilir çünkü anahtar kelimeler (kahve, coffee, pizza vb.) evrensel veya benzer.
  // Ancak çok dilli olduğu için her iki dili de kontrol etmek daha sağlıklı olur.

  if (lowerName.contains('kahve') ||
      lowerName.contains('coffee') ||
      lowerName.contains('latte')) {
    return Icons.coffee;
  }
  if (lowerName.contains('çay') || lowerName.contains('tea')) {
    return Icons.local_cafe;
  }
  if (lowerName.contains('su') ||
      lowerName.contains('water') ||
      lowerName.contains('limonata') ||
      lowerName.contains('lemonade') ||
      lowerName.contains('smoothie')) {
    return Icons.local_drink;
  }
  if (lowerName.contains('kahvaltı') ||
      lowerName.contains('breakfast') ||
      lowerName.contains('yumurta') ||
      lowerName.contains('egg')) {
    return Icons.egg_alt;
  }
  if (lowerName.contains('tost') ||
      lowerName.contains('toast') ||
      lowerName.contains('sandviç') ||
      lowerName.contains('sandwich')) {
    return Icons.bakery_dining;
  }
  if (lowerName.contains('pizza')) {
    return Icons.local_pizza;
  }
  if (lowerName.contains('burger')) {
    return Icons.lunch_dining;
  }
  if (lowerName.contains('salata') || lowerName.contains('salad')) {
    return Icons.grass;
  }
  if (lowerName.contains('meyve') || lowerName.contains('fruit')) {
    return Icons.apple;
  }
  if (lowerName.contains('dondurma') ||
      lowerName.contains('ice cream') ||
      lowerName.contains('sufle') ||
      lowerName.contains('souffle')) {
    return Icons.icecream;
  }
  if (lowerName.contains('köfte') ||
      lowerName.contains('meatball') ||
      lowerName.contains('tavuk') ||
      lowerName.contains('chicken') ||
      lowerName.contains('kanat') ||
      lowerName.contains('wing') ||
      lowerName.contains('risotto') ||
      lowerName.contains('steak')) {
    return Icons.restaurant;
  }
  if (lowerName.contains('patates') || lowerName.contains('fries')) {
    return Icons.fastfood;
  }
  if (lowerName.contains('pancake')) {
    return Icons.breakfast_dining;
  }
  return Icons.restaurant_menu;
}
