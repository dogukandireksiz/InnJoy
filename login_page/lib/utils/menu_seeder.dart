import '../model/menu_item_model.dart';

class MenuSeeder {
  static List<MenuItem> getSeedItems() {
    return [
      // Starters
      MenuItem(
        id: 'lentil_soup',
        name: 'Lentil Soup',
        description: 'Traditional red lentil soup served with lemon and croutons.',
        price: 150.0,
        imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=500&q=80', // Fixed URL
        category: 'Starters',
        isActive: true,
      ),
      MenuItem(
        id: 'caesar_salad',
        name: 'Caesar Salad',
        description: 'Crisp romaine lettuce, parmesan cheese, croutons, and Caesar dressing.',
        price: 250.0,
        imageUrl: 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?auto=format&fit=crop&w=500&q=80',
        category: 'Starters',
        isActive: true,
      ),
      MenuItem(
        id: 'bruschetta',
        name: 'Tomato Bruschetta',
        description: 'Grilled bread rubbed with garlic and topped with diced tomatoes and basil.',
        price: 180.0,
        imageUrl: 'https://images.unsplash.com/photo-1572695157363-bc31c5dd931b?auto=format&fit=crop&w=500&q=80', // Switched to alternative
        category: 'Starters',
        isActive: true,
      ),

      // Main Courses
      MenuItem(
        id: 'classic_burger',
        name: 'Classic Burger',
        description: 'Juicy beef patty with fresh lettuce, tomato, and our secret sauce.',
        price: 350.0,
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=500&q=80',
        category: 'Main Courses',
        isActive: true,
      ),
      MenuItem(
        id: 'cheeseburger',
        name: 'Cheeseburger',
        description: 'Classic burger topped with melted cheddar cheese and pickles.',
        price: 380.0,
        imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=500&q=80', 
        category: 'Main Courses',
        isActive: true,
      ),
      MenuItem(
        id: 'margarita_pizza',
        name: 'Margarita Pizza',
        description: 'Tomato sauce, fresh mozzarella, and basil.',
        price: 320.0,
        imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=500&q=80',
        category: 'Main Courses',
        isActive: true,
      ),
      MenuItem(
        id: 'grilled_salmon',
        name: 'Grilled Salmon',
        description: 'Fresh salmon fillet grilled to perfection, served with vegetables.',
        price: 550.0,
        imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=500&q=80', // New Salmon URL
        category: 'Main Courses',
        isActive: true,
      ),
      MenuItem(
        id: 'steak_frites',
        name: 'Steak Frites',
        description: 'Grilled sirloin steak served with crispy french fries.',
        price: 600.0,
        imageUrl: 'https://images.unsplash.com/photo-1600891964092-4316c288032e?auto=format&fit=crop&w=500&q=80',
        category: 'Main Courses',
        isActive: true,
      ),

      // Breakfast
      MenuItem(
        id: 'pancakes',
        name: 'Fluffy Pancakes',
        description: 'Stack of pancakes with maple syrup and berries.',
        price: 200.0,
        imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=500&q=80',
        category: 'Breakfast',
        isActive: true,
      ),

      // Snacks
      MenuItem(
        id: 'nachos',
        name: 'Loaded Nachos',
        description: 'Tortilla chips with melted cheese, jalapenos, and salsa.',
        price: 220.0,
        imageUrl: 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?auto=format&fit=crop&w=500&q=80', // New Nachos URL
        category: 'Snacks',
        isActive: true,
      ),

      // Kids
      MenuItem(
        id: 'chicken_nuggets',
        name: 'Chicken Nuggets',
        description: 'Crispy chicken nuggets served with ketchup and fries.',
        price: 180.0,
        imageUrl: 'https://images.unsplash.com/photo-1562967963-ed7852c3cc8c?auto=format&fit=crop&w=500&q=80', // Kept same but verified, fallback if needed
        category: 'Kids Menu',
        isActive: true,
      ),

      // Desserts
      MenuItem(
        id: 'tiramisu',
        name: 'Tiramisu',
        description: 'Classic Italian dessert with coffee-soaked ladyfingers.',
        price: 220.0,
        imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?auto=format&fit=crop&w=500&q=80',
        category: 'Desserts',
        isActive: true,
      ),
      MenuItem(
        id: 'cheesecake',
        name: 'New York Cheesecake',
        description: 'Creamy cheesecake with a graham cracker crust and berry topping.',
        price: 240.0,
        imageUrl: 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=500&q=80',
        category: 'Desserts',
        isActive: true,
      ),

      // Drinks
      MenuItem(
        id: 'coca_cola',
        name: 'Coca Cola',
        description: 'Chilled 330ml can.',
        price: 80.0,
        imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=500&q=80',
        category: 'Non-Alcoholic Drinks',
        isActive: true,
      ),
      MenuItem(
        id: 'orange_juice',
        name: 'Fresh Orange Juice',
        description: 'Freshly squeezed orange juice.',
        price: 90.0,
        imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=500&q=80',
        category: 'Non-Alcoholic Drinks',
        isActive: true,
      ),
      MenuItem(
        id: 'iced_caffe_latte',
        name: 'Iced Caffe Latte',
        description: 'Espresso with cold milk and ice.',
        price: 140.0,
        imageUrl: 'https://plus.unsplash.com/premium_photo-1663933534177-33ea425ebcb3?auto=format&fit=crop&w=500&q=80', // New Latte URL
        category: 'Non-Alcoholic Drinks',
        isActive: true,
      ),
      MenuItem(
        id: 'mojito',
        name: 'Mojito',
        description: 'Refreshing cocktail with mint, lime, and rum.',
        price: 300.0,
        imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=500&q=80', // New Mojito URL
        category: 'Alcoholic Drinks',
        isActive: true,
      ),
      MenuItem(
        id: 'red_wine',
        name: 'House Red Wine',
        description: 'Glass of our finest house red wine.',
        price: 350.0,
        imageUrl: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=500&q=80',
        category: 'Alcoholic Drinks',
        isActive: true,
      ),
    ];
  }
}
