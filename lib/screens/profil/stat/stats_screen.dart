import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
                        'Statistiques',
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
                        .snapshots(),
                    builder: (context, historySnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('visited_cities')
                            .snapshots(),
                        builder: (context, visitedSnap) {
                          if (historySnap.connectionState == ConnectionState.waiting ||
                              visitedSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: focusOrange));
                          }

                          final historyDocs = historySnap.data?.docs ?? [];
                          final visitedDocs = visitedSnap.data?.docs ?? [];

                          int totalTrips = historyDocs.length;
                          int successTrips = 0;
                          int totalCitiesCrossed = 0;
                          Map<String, int> cityVisitCounts = {};

                          for (var doc in historyDocs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final bool isFailed = data['isFailed'] ?? false;
                            final int citiesCount = data['visitedDuringTripCount'] ?? 0;

                            if (!isFailed) {
                              successTrips++;
                              totalCitiesCrossed += citiesCount;
                              final endCity = data['endCity'] as String?;
                              if (endCity != null) {
                                cityVisitCounts[endCity] = (cityVisitCounts[endCity] ?? 0) + 1;
                              }
                            }
                          }

                          double successRate = totalTrips > 0 ? (successTrips / totalTrips) * 100 : 0.0;
                          double failRate = totalTrips > 0 ? 100.0 - successRate : 0.0;
                          double avgCitiesPerTrip = successTrips > 0 ? (totalCitiesCrossed / successTrips) : 0.0;

                          int totalDistinctVisited = visitedDocs.length;
                          double avgVisitsPerCity = totalDistinctVisited > 0
                              ? (cityVisitCounts.values.fold(0, (a, b) => a + b) / totalDistinctVisited)
                              : 0.0;

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            children: [
                              _buildStatCard(
                                title: 'Taux de réussite',
                                value: '${successRate.toStringAsFixed(1)} %',
                                subtitle: 'Échecs : ${failRate.toStringAsFixed(1)} % ($totalTrips sessions)',
                                icon: Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              _buildStatCard(
                                title: 'Villes uniques visitées',
                                value: '$totalDistinctVisited',
                                subtitle: 'Découvertes sur la carte',
                                icon: Icons.location_city,
                                color: focusOrange,
                              ),
                              _buildStatCard(
                                title: 'Moyenne de villes par voyage',
                                value: avgCitiesPerTrip.toStringAsFixed(1),
                                subtitle: 'Étapes validées par session réussie',
                                icon: Icons.alt_route,
                                color: Colors.blueAccent,
                              ),
                              _buildStatCard(
                                title: 'Passages moyens par ville',
                                value: avgVisitsPerCity.toStringAsFixed(1),
                                subtitle: 'Fréquence de passage sur les villes connues',
                                icon: Icons.repeat,
                                color: Colors.purpleAccent,
                              ),
                            ],
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    const darkBlue = Color(0xFF143063);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 14, color: darkBlue.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: darkBlue.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}