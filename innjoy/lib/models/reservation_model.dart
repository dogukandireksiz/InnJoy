import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String pnr;
  final String roomNumber;
  final String guestName;
  final DateTime checkOutDate;
  final String status; // 'active', 'used', 'cancelled'
  final String? usedBy;
  final DateTime createdAt;

  ReservationModel({
    required this.pnr,
    required this.roomNumber,
    required this.guestName,
    required this.checkOutDate,
    this.status = 'active',
    this.usedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'pnr': pnr,
      'roomNumber': roomNumber,
      'guestName': guestName,
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'status': status,
      'usedBy': usedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      pnr: map['pnr'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      guestName: map['guestName'] ?? '',
      checkOutDate: (map['checkOutDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'active',
      usedBy: map['usedBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}








