// import 'package:flutter/material.dart';
// import 'spa_wellness_booking_screen.dart';

// // Spa tedavi modeli
// class SpaTreatment {
//   final String name;
//   final String description;
//   final double price;
//   final int duration; // dakika cinsinden
//   final String? imagePath;

//   const SpaTreatment({
//     required this.name,
//     required this.description,
//     required this.price,
//     required this.duration,
//     this.imagePath,
//   });
// }

// // Spa tedavi kategorisi modeli
// class SpaTreatmentCategory {
//   final String name;
//   final List<SpaTreatment> treatments;

//   const SpaTreatmentCategory({
//     required this.name,
//     required this.treatments,
//   });
// }

// // Özel paket modeli
// class SpaSpecialPackage {
//   final String name;
//   final String description;
//   final double originalPrice;
//   final double discountedPrice;
//   final String? imagePath;

//   const SpaSpecialPackage({
//     required this.name,
//     required this.description,
//     required this.originalPrice,
//     required this.discountedPrice,
//     this.imagePath,
//   });
// }

// // Spa merkezi modeli
// class SpaVenue {
//   final String name;
//   final String description;
//   final String? headerImagePath;
//   final List<SpaTreatmentCategory> treatmentCategories;
//   final List<SpaSpecialPackage> specialPackages;
//   final List<String> procedureInfo;

//   const SpaVenue({
//     required this.name,
//     required this.description,
//     this.headerImagePath,
//     required this.treatmentCategories,
//     this.specialPackages = const [],
//     this.procedureInfo = const [],
//   });
// }

// // Spa verileri
// class SpaData {
//   static final Map<String, SpaVenue> venues = {
//     'Serenity Spa': SpaVenue(
//       name: 'Serenity Spa',
//       description: 'Indulge in our signature treatments and find your inner peace.',
//       headerImagePath: 'assets/images/arkaplanyok1.png',
//       treatmentCategories: [
//         SpaTreatmentCategory(
//           name: 'Masaj Terapileri',
//           treatments: [
//             SpaTreatment(
//               name: 'İsveç Masajı',
//               description: 'Kasları gevşetmek, kan dolaşımını artırmak ve stresi azaltmak için tasarlanmış klasik bir masaj tekniğidir. Vücudunuza tam bir rahatlama ve yenilenme sağlar.',
//               price: 95,
//               duration: 60,
//               imagePath: 'assets/images/arkaplanyok1.png',
//             ),
//             SpaTreatment(
//               name: 'Derin Doku Masajı',
//               description: 'Kronik kas gerginliklerini ve ağrılarını hedef alan, daha yoğun basınç uygulanan bir masaj türüdür. Özellikle sporcular ve yoğun fiziksel aktivite yapanlar için idealdir.',
//               price: 120,
//               duration: 75,
//               imagePath: 'assets/images/arkaplanyok1.png',
//             ),
//             SpaTreatment(
//               name: 'Aromaterapi Masajı',
//               description: 'Uçucu yağlar kullanılarak yapılan, hem fiziksel hem de duygusal rahatlama sağlayan masaj türü.',
//               price: 110,
//               duration: 60,
//               imagePath: 'assets/images/arkaplanyok1.png',
//             ),
//             SpaTreatment(
//               name: 'Hot Stone Masajı',
//               description: 'Isıtılmış volkanik taşlar kullanılarak yapılan, derin kas gevşemesi sağlayan terapi.',
//               price: 140,
//               duration: 90,
//               imagePath: 'assets/images/arkaplanyok1.png',
//             ),
//           ],
//         ),
//         SpaTreatmentCategory(
//           name: 'Yüz Bakımları',
//           treatments: [
//             SpaTreatment(
//               name: 'Klasik Yüz Bakımı',
//               description: 'Cildinizi temizleyen, nemlendiren ve canlandıran temel yüz bakımı.',
//               price: 75,
//               duration: 45,
//             ),
//             SpaTreatment(
//               name: 'Anti-Aging Bakımı',
//               description: 'Yaşlanma belirtilerini azaltan, cildi sıkılaştıran özel formüllü bakım.',
//               price: 150,
//               duration: 60,
//             ),
//             SpaTreatment(
//               name: 'Hydrafacial',
//               description: 'Derin temizlik ve yoğun nemlendirme sağlayan ileri teknoloji yüz bakımı.',
//               price: 185,
//               duration: 75,
//             ),
//           ],
//         ),
//         SpaTreatmentCategory(
//           name: 'Vücut Bakımları',
//           treatments: [
//             SpaTreatment(
//               name: 'Vücut Peelingi',
//               description: 'Ölü deri hücrelerini temizleyen, cildi yumuşatan ve parlaklık kazandıran bakım.',
//               price: 65,
//               duration: 45,
//             ),
//             SpaTreatment(
//               name: 'Detox Vücut Sargısı',
//               description: 'Vücuttaki toksinleri atarak cilde sıkılık ve canlılık kazandıran bakım.',
//               price: 95,
//               duration: 60,
//             ),
//             SpaTreatment(
//               name: 'Çikolata Terapisi',
//               description: 'Kakao ile zenginleştirilmiş, cildi besleyen ve nemlendiren lüks bakım.',
//               price: 125,
//               duration: 75,
//             ),
//           ],
//         ),
//       ],
//       specialPackages: [
//         SpaSpecialPackage(
//           name: 'Yenilenme Paketi',
//           description: '60 dakikalık tam vücut masajı ve 30 dakikalık canlandırıcı yüz bakımını içeren bu özel paketle kendinizi şımartın.',
//           originalPrice: 180,
//           discountedPrice: 150,
//           imagePath: 'assets/images/arkaplanyok1.png',
//         ),
//         SpaSpecialPackage(
//           name: 'Romantik Çift Paketi',
//           description: 'İki kişilik özel odada yan yana masaj ve şampanya ikramı.',
//           originalPrice: 320,
//           discountedPrice: 280,
//           imagePath: 'assets/images/arkaplanyok1.png',
//         ),
//       ],
//       procedureInfo: [
//         'Randevunuza 15 dakika erken gelerek spa olanaklarından faydalanabilirsiniz.',
//         'Herhangi bir sağlık sorununuz veya alerjiniz varsa terapistinize önceden bildirin.',
//         'Bakım sonrası bol su içilmesi ve dinlenmesi tavsiye edilir.',
//         'Randevu iptallerinin en az 24 saat önceden yapılması gerekmektedir.',
//       ],
//     ),
//   };

//   static SpaVenue? getVenue(String name) => venues[name];
// }

// class SpaWellnessPricelistScreen extends StatefulWidget {
//   final String venueName;

//   const SpaWellnessPricelistScreen({
//     super.key,
//     required this.venueName,
//   });

//   @override
//   State<SpaWellnessPricelistScreen> createState() => _SpaWellnessPricelistScreenState();
// }

// class _SpaWellnessPricelistScreenState extends State<SpaWellnessPricelistScreen> {
//   int _selectedCategoryIndex = 0;

//   SpaVenue? get _venue => SpaData.getVenue(widget.venueName);

//   @override
//   Widget build(BuildContext context) {
//     final venue = _venue;

//     if (venue == null) {
//       return Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: const Center(
//           child: Text('Spa merkezi bulunamadı'),
//         ),
//       );
//     }

//     final categories = venue.treatmentCategories;
//     final selectedCategory = categories.isNotEmpty ? categories[_selectedCategoryIndex] : null;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7FB),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Spa Fiyat Listesi',
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Kategori seçimi
//             Container(
//               color: Colors.white,
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   children: List.generate(categories.length, (index) {
//                     final isSelected = index == _selectedCategoryIndex;
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: GestureDetector(
//                         onTap: () => setState(() => _selectedCategoryIndex = index),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                           decoration: BoxDecoration(
//                             color: isSelected ? const Color(0xFF1677FF) : Colors.white,
//                             borderRadius: BorderRadius.circular(25),
//                             border: Border.all(
//                               color: isSelected ? const Color(0xFF1677FF) : Colors.grey[300]!,
//                             ),
//                           ),
//                           child: Text(
//                             categories[index].name,
//                             style: TextStyle(
//                               color: isSelected ? Colors.white : Colors.black87,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Tedavi listesi
//             if (selectedCategory != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       selectedCategory.name,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     ...selectedCategory.treatments.map((treatment) => _TreatmentCard(
//                       treatment: treatment,
//                       onBookTap: () => _showBookingConfirmation(treatment),
//                     )),
//                   ],
//                 ),
//               ),

//             // Özel Teklifler
//             if (venue.specialPackages.isNotEmpty) ...[
//               const SizedBox(height: 24),
//               const Divider(height: 1),
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Özel Teklifler',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ...venue.specialPackages.map((pkg) => _SpecialPackageCard(
//                       package: pkg,
//                       onDetailsTap: () {},
//                     )),
//                   ],
//                 ),
//               ),
//             ],

//             // Prosedür Bilgisi
//             if (venue.procedureInfo.isNotEmpty) ...[
//               const SizedBox(height: 24),
//               const Divider(height: 1),
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Prosedür Bilgisi',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: venue.procedureInfo.map((info) => Padding(
//                           padding: const EdgeInsets.only(bottom: 12),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                               Expanded(
//                                 child: Text(
//                                   info,
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey[700],
//                                     height: 1.4,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )).toList(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showBookingConfirmation(SpaTreatment treatment) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => SpaWellnessBookingScreen(
//           preselectedTreatment: treatment.name,
//           preselectedDuration: '${treatment.duration} dakika',
//           preselectedPrice: treatment.price,
//         ),
//       ),
//     );
//   }
// }

// class _TreatmentCard extends StatelessWidget {
//   final SpaTreatment treatment;
//   final VoidCallback onBookTap;

//   const _TreatmentCard({
//     required this.treatment,
//     required this.onBookTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       treatment.name,
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       treatment.description,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey[600],
//                         height: 1.4,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (treatment.imagePath != null) ...[
//                 const SizedBox(width: 12),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.asset(
//                     treatment.imagePath!,
//                     width: 80,
//                     height: 80,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '\$${treatment.price.toStringAsFixed(0)}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF1677FF),
//                     ),
//                   ),
//                   Text(
//                     '${treatment.duration} dk',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                 ],
//               ),
//               const Spacer(),
//               ElevatedButton(
//                 onPressed: onBookTap,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1677FF),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 ),
//                 child: const Text(
//                   'Rezervasyon Yap',
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SpecialPackageCard extends StatelessWidget {
//   final SpaSpecialPackage package;
//   final VoidCallback onDetailsTap;

//   const _SpecialPackageCard({
//     required this.package,
//     required this.onDetailsTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (package.imagePath != null)
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//               child: Image.asset(
//                 package.imagePath!,
//                 height: 150,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   package.name,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   package.description,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                     height: 1.4,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Text(
//                       '\$${package.discountedPrice.toStringAsFixed(0)}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF1677FF),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '\$${package.originalPrice.toStringAsFixed(0)}',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[500],
//                         decoration: TextDecoration.lineThrough,
//                       ),
//                     ),
//                     const Spacer(),
//                     OutlinedButton(
//                       onPressed: onDetailsTap,
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: Color(0xFF1677FF)),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                       child: const Text('Detayları Gör'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class SpaWellnessPricelistScreen extends StatelessWidget {
  const SpaWellnessPricelistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hata vermemesi için verileri geçici olarak buraya, liste halinde koyuyoruz.
    // İstersen ileride bunları da Firebase'den çekebiliriz.
    final List<Map<String, dynamic>> spaServices = [
      {'name': 'Masaj Terapisi', 'price': 1200, 'duration': '60 dk'},
      {'name': 'Cilt Bakımı', 'price': 850, 'duration': '45 dk'},
      {'name': 'Sauna & Buhar', 'price': 400, 'duration': '30 dk'},
      {'name': 'Aroma Terapi', 'price': 1500, 'duration': '60 dk'},
      {'name': 'Türk Hamamı', 'price': 600, 'duration': '45 dk'},
      {'name': 'Manikür & Pedikür', 'price': 350, 'duration': '45 dk'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spa Fiyat Listesi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: spaServices.length,
        itemBuilder: (context, index) {
          final service = spaServices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa, color: Colors.teal),
              ),
              title: Text(
                service['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                service['duration'],
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Text(
                "${service['price']} ₺",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}