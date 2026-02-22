import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

class WifiConnectionScreen extends StatelessWidget {
  final String hotelName;

  const WifiConnectionScreen({super.key, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          "WiFi Connection",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.sp(context, 18)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: DatabaseService().getHotelWifiInfo(hotelName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final wifiData = snapshot.data;
          if (wifiData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey[400]),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  Text(
                    "No WiFi information available",
                    style: TextStyle(color: Colors.grey[600], fontSize: ResponsiveUtils.sp(context, 16)),
                  ),
                ],
              ),
            );
          }

          final ssid = wifiData['ssid'] ?? 'Unknown';
          final password = wifiData['password'] ?? '';
          final encryption = wifiData['encryption'] ?? 'WPA';

          // Format for WiFi QR code: WIFI:S:MySSID;T:WPA;P:MyPass;;
          final qrData = 'WIFI:S:$ssid;T:$encryption;P:$password;;';

          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24.0)),
            child: Column(
              children: [
                SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                // QR Code Card
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0057FF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi,
                          color: Color(0xFF0057FF),
                          size: ResponsiveUtils.iconSize(context) * (32 / 24),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: ResponsiveUtils.iconSize(context) * (200.0 / 24),
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0057FF),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      Text(
                        "Scan to Connect",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 20),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        "Point your camera at the QR code to connect to the WiFi automatically",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 14),
                          color: Colors.grey[500],
                          height: ResponsiveUtils.hp(context, 1.5 / 844),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                // Details Card
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(context, "Network Name", ssid, Icons.wifi),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      _buildInfoRow(context, "Password", password, Icons.lock_outline),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
          ),
          child: Icon(icon, color: Colors.grey[600], size: ResponsiveUtils.iconSize(context) * (20 / 24)),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 13),
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 4)),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 16),
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


