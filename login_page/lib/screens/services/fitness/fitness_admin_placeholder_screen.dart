import 'package:flutter/material.dart';
import 'fitness_new_service_screen.dart';
import 'fitness_edit_service_screen.dart';

class FitnessAdminPlaceholderScreen extends StatelessWidget {
  const FitnessAdminPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Fitness Management'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Header(),
          SizedBox(height: 12),
          _FitnessCard(
            imageAsset: 'assets/images/fitness_gym.jpg',
            title: 'Gym Access',
            subtitle: 'Daily 6:00 AM - 10:00 PM',
          ),
          SizedBox(height: 12),
          _FitnessCard(
            imageAsset: 'assets/images/fitness_pilates.jpg',
            title: 'Pilates Class',
            subtitle: 'Mon, Wed, Fri • 9:00 AM',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FitnessNewServiceScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Manage Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text(
          'Edit existing fitness offerings or add new classes and facility access options.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _FitnessCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  const _FitnessCard({required this.imageAsset, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FitnessEditServiceScreen(
                title: title,
                subtitle: subtitle,
                imageAsset: imageAsset,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(imageAsset, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FitnessEditServiceScreen(
                            title: title,
                            subtitle: subtitle,
                            imageAsset: imageAsset,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.black87),
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
