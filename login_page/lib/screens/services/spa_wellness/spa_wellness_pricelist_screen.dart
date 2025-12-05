import 'package:flutter/material.dart';
import 'package:login_page/l10n/app_localizations.dart'; // Çeviri
import 'spa_wellness_booking_screen.dart';

class SpaTreatment {
  final String name;
  final String description;
  final double price;
  final int duration;
  final String? imagePath;
  const SpaTreatment({
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.imagePath,
  });
}

class SpaTreatmentCategory {
  final String name;
  final List<SpaTreatment> treatments;
  const SpaTreatmentCategory({required this.name, required this.treatments});
}

class SpaSpecialPackage {
  final String name;
  final String description;
  final double originalPrice;
  final double discountedPrice;
  final String? imagePath;
  const SpaSpecialPackage({
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    this.imagePath,
  });
}

class SpaVenue {
  final String name;
  final String description;
  final String? headerImagePath;
  final List<SpaTreatmentCategory> treatmentCategories;
  final List<SpaSpecialPackage> specialPackages;
  final List<String> procedureInfo;
  const SpaVenue({
    required this.name,
    required this.description,
    this.headerImagePath,
    required this.treatmentCategories,
    this.specialPackages = const [],
    this.procedureInfo = const [],
  });
}

// Global fonksiyon
Map<String, SpaVenue> getSpaVenues(AppLocalizations texts) {
  return {
    'Serenity Spa': SpaVenue(
      name: 'Serenity Spa',
      description: texts.serenitySpaDesc,
      headerImagePath: 'assets/images/arkaplanyok1.png',
      treatmentCategories: [
        SpaTreatmentCategory(
          name: 'Masaj Terapileri',
          treatments: [
            SpaTreatment(
              name: 'İsveç Masajı',
              description: 'Klasik rahatlama masajı...',
              price: 95,
              duration: 60,
              imagePath: 'assets/images/arkaplanyok1.png',
            ),
            SpaTreatment(
              name: 'Derin Doku Masajı',
              description: 'Kronik gerginlikler için...',
              price: 120,
              duration: 75,
              imagePath: 'assets/images/arkaplanyok1.png',
            ),
          ],
        ),
      ],
      specialPackages: [
        SpaSpecialPackage(
          name: 'Yenilenme Paketi',
          description: 'Masaj ve yüz bakımı...',
          originalPrice: 180,
          discountedPrice: 150,
          imagePath: 'assets/images/arkaplanyok1.png',
        ),
      ],
      procedureInfo: [
        'Randevudan 15 dk önce gelin.',
        'Sağlık sorunlarını bildirin.',
      ],
    ),
  };
}

class SpaWellnessPricelistScreen extends StatefulWidget {
  final String venueName;
  const SpaWellnessPricelistScreen({super.key, required this.venueName});

  @override
  State<SpaWellnessPricelistScreen> createState() =>
      _SpaWellnessPricelistScreenState();
}

class _SpaWellnessPricelistScreenState
    extends State<SpaWellnessPricelistScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context)!;
    final venues = getSpaVenues(texts);
    final venue = venues[widget.venueName];

    if (venue == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Spa not found')),
      );
    }

    final categories = venue.treatmentCategories;
    final selectedCategory = categories.isNotEmpty
        ? categories[_selectedCategoryIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          texts.spaPricelist,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: List.generate(categories.length, (index) {
                    final isSelected = index == _selectedCategoryIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategoryIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1677FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1677FF)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            categories[index].name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (selectedCategory != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCategory.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...selectedCategory.treatments.map(
                      (treatment) => _TreatmentCard(
                        treatment: treatment,
                        onBookTap: () =>
                            _showBookingConfirmation(treatment, texts),
                      ),
                    ),
                  ],
                ),
              ),
            if (venue.specialPackages.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texts.specialOffers,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...venue.specialPackages.map(
                      (pkg) => _SpecialPackageCard(
                        package: pkg,
                        onDetailsTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation(
    SpaTreatment treatment,
    AppLocalizations texts,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpaWellnessBookingScreen(
          preselectedTreatment: treatment.name,
          preselectedDuration: '${treatment.duration} dakika',
          preselectedPrice: treatment.price,
        ),
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final SpaTreatment treatment;
  final VoidCallback onBookTap;
  const _TreatmentCard({required this.treatment, required this.onBookTap});
  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      treatment.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (treatment.imagePath != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    treatment.imagePath!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '\$${treatment.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1677FF),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onBookTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1677FF),
                ),
                child: Text(
                  texts.makeReservation,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecialPackageCard extends StatelessWidget {
  final SpaSpecialPackage package;
  final VoidCallback onDetailsTap;
  const _SpecialPackageCard({
    required this.package,
    required this.onDetailsTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (package.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.asset(
                package.imagePath!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(package.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
