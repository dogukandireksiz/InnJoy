import 'package:flutter/material.dart';

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
      identical(this, other) || other is MenuItem && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// Kahvaltı menüsü
const breakfastItems = [
  MenuItem(
    name: 'Serpme Kahvaltı',
    description: 'Zengin çeşitli geleneksel kahvaltı',
    price: 450,
  ),
  MenuItem(
    name: 'Pancake Kulesi',
    description: 'Akçaağaç şurubu ve taze meyveler',
    price: 280,
  ),
  MenuItem(
    name: 'Avokado Tost',
    description: 'Ezine peyniri ve cherry domates',
    price: 250,
  ),
  MenuItem(
    name: 'Sahanda Yumurta',
    description: 'Sucuklu veya pastırmalı seçenekli',
    price: 220,
  ),
  MenuItem(
    name: 'Beyaz Peynirli Sandviç',
    description: 'Hafif ve doyurucu bir atıştırmalık',
    price: 180,
  ),
  MenuItem(
    name: 'Taze Sıkma Portakal Suyu',
    description: 'Güne zinde başlangıç',
    price: 120,
  ),
];

// Öğle/Akşam yemeği
const lunchDinnerItems = [
  MenuItem(
    name: 'Izgara Köfte',
    description: 'Pilav ve közlenmiş sebze ile',
    price: 380,
  ),
  MenuItem(
    name: 'Tavuk Şiş',
    description: 'Marine edilmiş tavuk, pilav ve salata',
    price: 350,
  ),
  MenuItem(
    name: 'Karışık Pizza',
    description: 'Sucuk, mantar, mısır, zeytin',
    price: 320,
  ),
  MenuItem(
    name: 'Caesar Salata',
    description: 'Izgara tavuk, parmesan, kruton',
    price: 280,
  ),
  MenuItem(
    name: 'Mantarlı Risotto',
    description: 'Kremalı İtalyan pilavı',
    price: 340,
  ),
  MenuItem(
    name: 'Burger Menü',
    description: 'Patates kızartması ve içecek dahil',
    price: 290,
  ),
];

// İçecekler
const beverageItems = [
  MenuItem(
    name: 'Türk Kahvesi',
    description: 'Geleneksel köpüklü kahve',
    price: 80,
  ),
  MenuItem(
    name: 'Latte',
    description: 'Espresso ve kremamsı süt',
    price: 95,
  ),
  MenuItem(
    name: 'Taze Limonata',
    description: 'Nane yaprakları ile',
    price: 90,
  ),
  MenuItem(
    name: 'Smoothie',
    description: 'Muz, çilek, yaban mersini',
    price: 130,
  ),
  MenuItem(
    name: 'Soğuk Çay',
    description: 'Şeftali veya limon aromalı',
    price: 70,
  ),
  MenuItem(
    name: 'Su (1L)',
    description: 'Doğal kaynak suyu',
    price: 40,
  ),
];

// Gece menüsü
const nightMenuItems = [
  MenuItem(
    name: 'Patates Kızartması',
    description: 'Çıtır ve lezzetli',
    price: 120,
  ),
  MenuItem(
    name: 'Kanat Tabağı',
    description: 'Acılı veya BBQ soslu',
    price: 220,
  ),
  MenuItem(
    name: 'Tost Çeşitleri',
    description: 'Kaşarlı veya karışık',
    price: 150,
  ),
  MenuItem(
    name: 'Çikolatalı Sufle',
    description: 'Sıcak servis, dondurma ile',
    price: 180,
  ),
  MenuItem(
    name: 'Meyve Tabağı',
    description: 'Mevsim meyveleri',
    price: 160,
  ),
  MenuItem(
    name: 'Dondurma',
    description: '3 top, çeşitli aromalar',
    price: 110,
  ),
];

IconData getIconForItem(String name) {
  final lowerName = name.toLowerCase();
  if (lowerName.contains('kahve') || lowerName.contains('latte')) return Icons.coffee;
  if (lowerName.contains('çay')) return Icons.local_cafe;
  if (lowerName.contains('su') || lowerName.contains('limonata') || lowerName.contains('smoothie')) return Icons.local_drink;
  if (lowerName.contains('kahvaltı') || lowerName.contains('yumurta')) return Icons.egg_alt;
  if (lowerName.contains('tost') || lowerName.contains('sandviç')) return Icons.bakery_dining;
  if (lowerName.contains('pizza')) return Icons.local_pizza;
  if (lowerName.contains('burger')) return Icons.lunch_dining;
  if (lowerName.contains('salata')) return Icons.grass;
  if (lowerName.contains('meyve')) return Icons.apple;
  if (lowerName.contains('dondurma') || lowerName.contains('sufle')) return Icons.icecream;
  if (lowerName.contains('köfte') || lowerName.contains('tavuk') || lowerName.contains('kanat')) return Icons.restaurant;
  if (lowerName.contains('patates')) return Icons.fastfood;
  if (lowerName.contains('pancake')) return Icons.breakfast_dining;
  return Icons.restaurant_menu;
}
