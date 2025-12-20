import 'package:flutter/material.dart';
import 'dart:async';
import 'dining/dining_booking_screen.dart';

import '../dining/customer_menu_screen.dart';
import 'spa_wellness/spa_wellness_screen.dart';
import 'fitness/details/fitness_details_screen.dart';
import '../../service/database_service.dart';

class ServiceScreen extends StatefulWidget {
  final String? hotelName;
  const ServiceScreen({super.key, this.hotelName});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  String? _selectedCategory; // null => show all services

  @override
  void initState() {
    super.initState();
    // Auto-seed default data if missing (Self-healing)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _db.seedDefaultServices(widget.hotelName ?? 'Grand Hayat Otel');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Combine 3 streams: Restaurant, Spa, Fitness
    final hotelName = widget.hotelName ?? 'Grand Hayat Otel';

    // We can use a StreamBuilder that listens to a combined stream
    // Since we don't want to add huge dependencies, we can use a nested approach or a simple combinator.
    // Here, let's use a nested approach as it's standard and robust without external deps for just 3 items.
    // Or better, use a StreamZip-like logic if we had 'async' package.
    // Let's stick to the simplest flutter way: Nested StreamBullets or just standard data fetching.
    // Actually, distinct StreamBuilders for each section is cleaner UI-wise but the list needs to be sorted/filtered.
    // So distinct is hard if we want a unified list.
    // Let's use `StreamGroup` from `dart:async`? No, `StreamZip`.
    // Let's just create a custom stream that merges them.

    return StreamBuilder<List<Map<String, dynamic>?>>(
      stream: _getCombinedServices(hotelName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List<Map<String, dynamic>?> dataList = snapshot.data!;
        // dataList[0] = Restaurant, [1] = Spa, [2] = Fitness

        final restSettings = dataList[0];
        final spaSettings = dataList[1];
        final fitnessSettings = dataList[2];

        // 1. Restaurant Item
        final String restName = restSettings?['name'] ?? 'Aurora Restaurant';
        final String restDesc =
            restSettings?['description'] ??
            'Fine dining with a panoramic city view, featuring a modern European menu.';
        final String restImage =
            restSettings?['imageUrl'] ?? 'assets/images/rest.png';

        final _ServiceItem restaurantItem = _ServiceItem(
          title: restName,
          description: restDesc,
          imagePath:
              restImage, // DB triggers asset load if string starts with assets/
          badgeText: 'Reservations Recommended',
          category: 'Dining',
          primaryAction: 'Menu',
          secondaryAction: 'Book Table',
          onCardTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerMenuScreen(
                  hotelName: hotelName,
                  restaurantName: restName,
                  restaurantId: 'Aurora Restaurant',
                ),
              ),
            );
          },
        );

        // 2. Spa Item
        final String spaTitle = spaSettings?['title'] ?? 'Serenity Spa';
        final String spaDesc =
            spaSettings?['description'] ??
            'Indulge in our signature treatments.';
        final String spaImage =
            spaSettings?['imageUrl'] ?? 'assets/images/spa_service.png';

        final _ServiceItem spaItem = _ServiceItem(
          title: spaTitle,
          description: spaDesc,
          imagePath: spaImage,
          badgeText: 'Appointments Only',
          category: 'Spa & Wellness',
          primaryAction: 'Info & Pricelist & Book',
          secondaryAction: null,
          onCardTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SpaWellnessScreen(hotelName: hotelName),
              ),
            );
          },
        );

        // 3. Fitness Item
        final String fitTitle =
            fitnessSettings?['title'] ?? '24/7 Fitness Center';
        final String fitDesc =
            fitnessSettings?['description'] ?? 'State-of-the-art equipment.';
        final String fitImage =
            fitnessSettings?['imageUrl'] ?? 'assets/images/fitness.png';

        final _ServiceItem fitnessItem = _ServiceItem(
          title: fitTitle,
          description: fitDesc,
          imagePath: fitImage,
          badgeText: 'Open 24 Hours',
          category: 'Fitness',
          primaryAction: 'View Details',
          secondaryAction: null,
          onCardTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FitnessDetailsScreen(hotelName: hotelName),
              ),
            );
          },
        );

        // Combine
        final List<_ServiceItem> allServices = [
          restaurantItem,
          spaItem,
          fitnessItem,
        ];

        final q = _searchController.text.trim().toLowerCase();
        final filteredServices = allServices.where((s) {
          final matchesCategory =
              _selectedCategory == null || s.category == _selectedCategory;
          if (!matchesCategory) return false;
          if (q.isEmpty) return true;
          return s.title.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFf6f7f8),
          appBar: AppBar(
            title: const Text('Our Services'),
            centerTitle: true,
            backgroundColor: const Color(0xFFf6f7f8),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _CategoryChips(
                selected: _selectedCategory,
                onSelected: (value) =>
                    setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 16),
              for (final s in filteredServices) ...[
                _ServiceCard(
                  title: s.title,
                  badgeText: s.badgeText,
                  imagePath: s.imagePath,
                  description: s.description,
                  primaryAction: s.primaryAction,
                  secondaryAction: s.secondaryAction,
                  category: s.category,
                  onCardTap: s.onCardTap,
                  onPrimaryAction: () {
                    // Action Logic
                    if (s.category == 'Dining' && s.primaryAction == 'Menu') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerMenuScreen(
                            hotelName: hotelName,
                            restaurantName: s.title,
                            restaurantId: 'Aurora Restaurant',
                          ),
                        ),
                      );
                    } else if (s.category == 'Spa & Wellness') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SpaWellnessScreen(hotelName: hotelName),
                        ),
                      );
                    } else if (s.category == 'Fitness') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FitnessDetailsScreen(hotelName: hotelName),
                        ),
                      );
                    }
                  },
                  onSecondaryAction: () {
                    if (s.category == 'Dining' &&
                        s.secondaryAction == 'Book Table') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DiningBookingScreen(
                            hotelName: hotelName,
                            restaurantName: s.title,
                            restaurantId: 'Aurora Restaurant',
                            imageUrl: s.imagePath.startsWith('http')
                                ? s.imagePath
                                : null,
                          ),
                        ),
                      );
                    } else if (s.category == 'Spa & Wellness') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SpaWellnessScreen(hotelName: hotelName),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (filteredServices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No services found for this category.'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper to combine streams using rxdart-like behavior manually
  Stream<List<Map<String, dynamic>?>> _getCombinedServices(String hotelName) {
    // We need to merge 3 streams into a List<Map?>
    // Since we don't have Rx.combineLatest3, we'll implement a simple combinator using StreamZip or manual listening.
    // Actually, StreamZip waits for all to emit. This is fine for initial load.
    // But `package:async` might not be imported.
    // Use a custom generator.

    final s1 = _db.getRestaurantSettings(hotelName, 'Aurora Restaurant');
    final s2 = _db.getSpaInfo(hotelName);
    final s3 = _db.getFitnessInfo(hotelName);

    // Simple custom combine
    return StreamBuilderCombiner.combine3(s1, s2, s3);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  const _SearchBar({this.controller, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search for services...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _CategoryChips({required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    final categories = ['Dining', 'Spa & Wellness', 'Fitness', 'Recreation'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in categories) ...[
            GestureDetector(
              onTap: () => onSelected(selected == c ? null : c),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == c
                      ? const Color(0xFF137fec) // Primary Blue
                      : const Color(0xFFe2e8f0), // Slate-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected == c
                        ? Colors.white
                        : const Color(0xFF334155), // Slate-700
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final String badgeText;
  final String? primaryAction;
  final String? secondaryAction;
  final String? category;
  final VoidCallback? onCardTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.badgeText,
    this.primaryAction,
    this.secondaryAction,
    this.category,
    this.onCardTap,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath.startsWith('http'))
              Image.network(
                imagePath,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              )
            else
              Image.asset(
                imagePath,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (primaryAction != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onPrimaryAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF137fec,
                              ).withOpacity(0.1),
                              foregroundColor: const Color(0xFF137fec),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              splashFactory: InkRipple.splashFactory,
                              overlayColor: const Color(
                                0xFF137fec,
                              ).withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  primaryAction!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (secondaryAction != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onSecondaryAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF137fec,
                              ).withOpacity(0.1),
                              foregroundColor: const Color(0xFF137fec),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              splashFactory: InkRipple.splashFactory,
                              overlayColor: const Color(
                                0xFF137fec,
                              ).withOpacity(0.1),
                            ),
                            child: Text(
                              secondaryAction!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String description;
  final String imagePath;
  final String badgeText;
  final String category;
  final String? primaryAction;
  final String? secondaryAction;
  final VoidCallback? onCardTap;
  const _ServiceItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.badgeText,
    required this.category,
    this.primaryAction,
    this.secondaryAction,
    this.onCardTap,
  });
}

// Simple Helper to combine 3 streams

class StreamBuilderCombiner {
  static Stream<List<T?>> combine3<T>(
    Stream<T?> s1,
    Stream<T?> s2,
    Stream<T?> s3,
  ) {
    final controller = StreamController<List<T?>>();
    List<T?> values = [null, null, null];
    // Track if streams have emitted at least once if needed, but for now we just emit on any change
    // Using simple listen setup

    // We need to manage subscriptions
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;

    void updateVal(int index, T? val) {
      values[index] = val;
      if (!controller.isClosed) controller.add(List.from(values));
    }

    controller.onListen = () {
      sub1 = s1.listen((data) => updateVal(0, data));
      sub2 = s2.listen((data) => updateVal(1, data));
      sub3 = s3.listen((data) => updateVal(2, data));
    };

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
      sub3?.cancel();
    };

    return controller.stream;
  }
}
