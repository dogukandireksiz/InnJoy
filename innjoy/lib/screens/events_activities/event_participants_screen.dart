import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/responsive_utils.dart';

class EventParticipantsScreen extends StatelessWidget {
  final String hotelName;
  final String eventId;
  final String eventTitle;

  const EventParticipantsScreen({
    super.key,
    required this.hotelName,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participants: $eventTitle'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getEventParticipants(hotelName, eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred.'));
          }

          final participants = snapshot.data ?? [];

          if (participants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.people_outline, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey),
                   SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                   Text('No registered participants yet.', style: TextStyle(color: Colors.grey, fontSize: ResponsiveUtils.sp(context, 16))),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            itemCount: participants.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final participant = participants[index];
              final name = participant['userName'] ?? 'Unnamed Guest';
              final room = participant['roomNumber'] ?? '-'; // '101' etc.
              final timestamp = participant['timestamp'] as Timestamp?;
              final timeStr = timestamp != null 
                  ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate()) 
                  : '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade800,
                  child: Text(name.substring(0, 1).toUpperCase()),
                ),
                title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Registration Date: $timeStr'),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 6)),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Room: $room',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.sp(context, 14),
                  ),
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }
}









