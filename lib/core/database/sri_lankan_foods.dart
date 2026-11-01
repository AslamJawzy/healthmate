import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// Built-in list of common Sri Lankan foods with APPROXIMATE calories
/// per typical portion. Values are estimates for guidance only; real
/// calories depend on recipe, oil and portion size.
class SriLankanFoods {
  SriLankanFoods._();

  // [name, category, portion, kcal]
  static const List<List<Object>> _foods = [
    // Rice & mains
    ['White rice', 'Rice & Mains', '1 cup cooked', 205],
    ['Red rice', 'Rice & Mains', '1 cup cooked', 215],
    ['Rice and curry (vegetable)', 'Rice & Mains', '1 plate', 650],
    ['Rice and curry (chicken)', 'Rice & Mains', '1 plate', 750],
    ['Rice and curry (fish)', 'Rice & Mains', '1 plate', 700],
    ['Fried rice (chicken)', 'Rice & Mains', '1 plate', 700],
    ['Chicken biriyani', 'Rice & Mains', '1 plate', 800],
    ['Lamprais', 'Rice & Mains', '1 packet', 900],
    ['Chicken kottu', 'Rice & Mains', '1 plate', 850],
    ['Cheese kottu', 'Rice & Mains', '1 plate', 1050],
    ['Egg kottu', 'Rice & Mains', '1 plate', 750],
    ['Vegetable kottu', 'Rice & Mains', '1 plate', 650],
    ['String hoppers', 'Rice & Mains', '10 pieces', 350],
    ['Plain hopper', 'Rice & Mains', '1 hopper', 90],
    ['Egg hopper', 'Rice & Mains', '1 hopper', 160],
    ['Milk hopper', 'Rice & Mains', '1 hopper', 130],
    ['Pittu', 'Rice & Mains', '1 cup', 300],
    ['Kiribath (milk rice)', 'Rice & Mains', '2 pieces', 330],
    ['Pol roti', 'Rice & Mains', '1 roti', 180],
    ['Godamba roti', 'Rice & Mains', '1 roti', 250],
    ['Parotta', 'Rice & Mains', '1 parotta', 300],
    ['Kurakkan roti', 'Rice & Mains', '1 roti', 150],
    ['Dosa (thosai)', 'Rice & Mains', '1 dosa', 170],
    ['Idli', 'Rice & Mains', '2 pieces', 120],
    ['Vegetable noodles', 'Rice & Mains', '1 plate', 450],
    ['Bread (white)', 'Rice & Mains', '2 slices', 160],
    // Curries & sides
    ['Dhal curry (parippu)', 'Curries & Sides', '1 cup', 230],
    ['Chicken curry', 'Curries & Sides', '1 serving', 280],
    ['Fish curry', 'Curries & Sides', '1 serving', 220],
    ['Fish ambul thiyal', 'Curries & Sides', '1 serving', 200],
    ['Beef curry', 'Curries & Sides', '1 serving', 320],
    ['Egg curry', 'Curries & Sides', '1 egg', 160],
    ['Potato curry', 'Curries & Sides', '1 cup', 230],
    ['Jackfruit curry (polos)', 'Curries & Sides', '1 cup', 220],
    ['Pumpkin curry', 'Curries & Sides', '1 cup', 150],
    ['Devilled chicken', 'Curries & Sides', '1 serving', 400],
    ['Gotukola sambol', 'Curries & Sides', '1/2 cup', 60],
    ['Pol sambol', 'Curries & Sides', '2 tbsp', 90],
    ['Seeni sambol', 'Curries & Sides', '2 tbsp', 120],
    ['Mallum (green leaves)', 'Curries & Sides', '1/2 cup', 70],
    ['Papadam', 'Curries & Sides', '2 pieces', 90],
    ['Boiled egg', 'Curries & Sides', '1 egg', 78],
    // Short eats
    ['Fish bun', 'Short Eats', '1 bun', 250],
    ['Chinese roll (fish)', 'Short Eats', '1 roll', 220],
    ['Vegetable roti', 'Short Eats', '1 piece', 180],
    ['Samosa', 'Short Eats', '1 piece', 150],
    ['Patties', 'Short Eats', '1 piece', 200],
    ['Fish cutlet', 'Short Eats', '1 piece', 90],
    ['Parippu vadai', 'Short Eats', '1 vadai', 120],
    ['Ulundu vadai', 'Short Eats', '1 vadai', 130],
    ['Isso vadai', 'Short Eats', '1 vadai', 200],
    ['Kimbula banis', 'Short Eats', '1 bun', 280],
    // Sweets
    ['Kavum', 'Sweets', '1 piece', 180],
    ['Kokis', 'Sweets', '2 pieces', 150],
    ['Aluwa', 'Sweets', '1 piece', 150],
    ['Watalappan', 'Sweets', '1 serving', 300],
    ['Pani pol pancake', 'Sweets', '1 pancake', 200],
    ['Curd with treacle', 'Sweets', '1 cup', 300],
    // Drinks
    ['Plain tea with sugar', 'Drinks', '1 cup', 50],
    ['Milk tea', 'Drinks', '1 cup', 110],
    ['Coffee with milk', 'Drinks', '1 cup', 100],
    ['King coconut water', 'Drinks', '1 nut', 60],
    ['Faluda', 'Drinks', '1 glass', 350],
    ['Wood apple juice', 'Drinks', '1 glass', 180],
    ['Ginger beer', 'Drinks', '1 bottle (400 ml)', 170],
    ['Milo', 'Drinks', '1 cup', 180],
    // Fruits & snacks
    ['Banana (ambul)', 'Fruits & Snacks', '1 banana', 80],
    ['Mango', 'Fruits & Snacks', '1 medium', 200],
    ['Papaya', 'Fruits & Snacks', '1 cup', 60],
    ['Pineapple', 'Fruits & Snacks', '1 cup', 80],
    ['Rambutan', 'Fruits & Snacks', '10 fruits', 120],
    ['Boiled chickpeas (kadala)', 'Fruits & Snacks', '1 cup', 270],
    ['Boiled manioc', 'Fruits & Snacks', '1 cup', 330],
    ['Yoghurt', 'Fruits & Snacks', '1 cup', 150],
  ];

  static Future<void> insertInto(Database db) async {
    final batch = db.batch();
    for (final f in _foods) {
      batch.insert(DatabaseHelper.tableFoods, {
        'name': f[0],
        'category': f[1],
        'portion': f[2],
        'calories': f[3],
      });
    }
    await batch.commit(noResult: true);
  }

  static int get count => _foods.length;
}
