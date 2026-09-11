import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/city_network.dart';
import '../utils/time_formatter.dart';
import 'active_timer_screen.dart';

class SelectDestinationScreen extends StatefulWidget {
  final int selectedDurationMinutes;

  const SelectDestinationScreen({
    super.key,
    required this.selectedDurationMinutes,
  });

  @override
  State<SelectDestinationScreen> createState() => _SelectDestinationScreenState();
}

class _SelectDestinationScreenState extends State<SelectDestinationScreen> {
  String _currentCity = 'Valenciennes';
  Set<String> _visitedCities = {};
  Map<String, ShortestPathResult> _routes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataAndCalculateRoutes();
  }

  Future<void> _loadDataAndCalculateRoutes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    final visitedDoc = await userRef.collection('visited_cities').get();

    _currentCity = userDoc.data()?['currentCity'] ?? 'Valenciennes';
    _visitedCities = visitedDoc.docs.map((d) => d.id).toSet();

    _routes = CityNetwork.calculateAllShortestPaths(
      startCity: _currentCity,
      visitedCities: _visitedCities,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    // Trier les destinations par temps de trajet croissant
    final sortedDestinations = _routes.entries.toList()
      ..sort((a, b) => a.value.totalTravelMinutes.compareTo(b.value.totalTravelMinutes));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/fond2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: darkBlue, size: 20),
                              ),
                            ),
                            const Text(
                              'Destinations',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                                shadows: [Shadow(color: Colors.white70, blurRadius: 10)],
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: focusOrange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Départ : $_currentCity  •  Carburant : ${formatMinutesToHours(widget.selectedDurationMinutes)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlue, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: focusOrange))
                            : ListView.builder(
                                itemCount: sortedDestinations.length,
                                itemBuilder: (context, index) {
                                  final entry = sortedDestinations[index];
                                  final cityName = entry.key;
                                  final routeResult = entry.value;
                                  final travelMinutes = routeResult.totalTravelMinutes;
                                  final isReachable = travelMinutes <= widget.selectedDurationMinutes;
                                  final isVisited = _visitedCities.contains(cityName);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isReachable
                                                ? Colors.white.withValues(alpha: 0.85)
                                                : Colors.white.withValues(alpha: 0.45),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isReachable ? Colors.white : Colors.white24,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                            leading: CircleAvatar(
                                              backgroundColor: isReachable
                                                  ? focusOrange.withValues(alpha: 0.15)
                                                  : Colors.grey.withValues(alpha: 0.2),
                                              child: Icon(
                                                isVisited ? Icons.verified : Icons.place,
                                                color: isReachable ? focusOrange : Colors.grey,
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Text(
                                                  cityName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isReachable ? darkBlue : Colors.grey.shade700,
                                                  ),
                                                ),
                                                if (isVisited) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text(
                                                      '×5 rapide',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Trajet : ${_currentCity} ➔ ${routeResult.path.join(" ➔ ")}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isReachable ? Colors.black87 : Colors.black45,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Temps de route : ${formatMinutesToHours(travelMinutes)} (${routeResult.path.length} étape${routeResult.path.length > 1 ? "s" : ""})',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isReachable ? const Color(0xFF1B5E20) : Colors.red.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: isReachable
                                                ? const Icon(Icons.arrow_forward_ios, color: focusOrange, size: 18)
                                                : const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                                            onTap: isReachable
                                                ? () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ActiveTimerScreen(
                                                          plannedRoute: routeResult.path,
                                                          durationMinutes: widget.selectedDurationMinutes,
                                                          plannedTravelMinutes: travelMinutes,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}