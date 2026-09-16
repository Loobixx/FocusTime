import 'dart:ui';
import 'package:focus_time/utils/time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/fond1.png'), fit: BoxFit.cover),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: darkBlue),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Historique des voyages',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('travel_history')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: focusOrange));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucun voyage enregistré pour le moment.',
                            style: TextStyle(color: darkBlue, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        );
                      }

                      final trips = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: trips.length,
                        itemBuilder: (context, index) {
                          final data = trips[index].data() as Map<String, dynamic>;
                          final dateText = _formatDate(data['date'] as Timestamp?);
                          final start = data['startCity'] ?? '?';
                          final end = data['endCity'] ?? '?';
                          final duration = data['durationMinutes'] ?? 0;
                          final bool isCompleted = data['isCompleted'] ?? true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            dateText,
                                            style: TextStyle(fontSize: 13, color: darkBlue.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isCompleted ? Colors.green.withValues(alpha: 0.8) : Colors.purple.withValues(alpha: 0.8),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isCompleted ? 'Terminé' : 'En pause',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.route, color: focusOrange, size: 24),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '$start ➔ $end',
                                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: darkBlue),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 18, color: darkBlue.withValues(alpha: 0.8)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Temps de concentration : ${formatMinutesToHours(duration)}',
                                            style: TextStyle(fontSize: 14, color: darkBlue.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}