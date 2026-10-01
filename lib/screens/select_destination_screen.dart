import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/city_network.dart';
import '../utils/time_formatter.dart';
import 'focus_moment/expedition_screen.dart';

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
  Set<String> _stoppedCities = {}; // Stocke les villes d'arrêt
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
  final stoppedDoc = await userRef.collection('stopped_cities').get();

  _currentCity = userDoc.data()?['currentCity'] ?? 'Valenciennes';
  _visitedCities = visitedDoc.docs.map((d) => d.id).toSet();
  _stoppedCities = stoppedDoc.docs.map((d) => d.id).toSet(); 

  // 🔍 AJOUTE CETTE LIGNE POUR VÉRIFIER DANS LA CONSOLE :
  print("🛑 Villes d'arrêt trouvées dans Firestore : $_stoppedCities");

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
          // Fond flouté avec ambiance
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/biome/fond2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: darkBlue.withValues(alpha: 0.25)),
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
                      // En-tête stylé
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              ),
                            ),
                            const Text(
                              'Choix de l\'expédition',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),

                      // Widget de départ et énergie moderne
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: focusOrange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.my_location, color: focusOrange, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Position actuelle : $_currentCity',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlue, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Énergie dispo : ${widget.selectedDurationMinutes == -1 ? "Illimitée (Admin 🚀)" : formatMinutesToHours(widget.selectedDurationMinutes)}',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Légende des couleurs / statuts mise à jour
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLegendBadge(Colors.purple.shade400, 'Étape arrêtée'),
                            _buildLegendBadge(Colors.amber.shade700, 'Traversée'),
                            _buildLegendBadge(focusOrange, 'Accessible'),
                            _buildLegendBadge(Colors.grey, 'Trop loin'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Liste des destinations
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
                                  
                                  final isReachable = widget.selectedDurationMinutes == -1 || travelMinutes <= widget.selectedDurationMinutes;
                                  final isVisited = _visitedCities.contains(cityName);
                                  final isStopped = _stoppedCities.contains(cityName); // Ville où l'on s'est arrêté

                                  Color cardBorderColor = Colors.white24;
                                  Color accentColor = Colors.grey;
                                  IconData statusIcon = Icons.place;

                                  // Priorité d'affichage : Arrêt > Visité/Traversé > Accessible > Verrouillé
                                  if (isStopped) {
                                    cardBorderColor = Colors.purple.shade400; // Violet pour les arrêts
                                    accentColor = Colors.purple.shade700;Future<void> _loadDataAndCalculateRoutes() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final userDoc = await userRef.get();
  
  final visitedDoc = await userRef.collection('visited_cities').get();
  final stoppedDoc = await userRef.collection('stopped_cities').get();

  _currentCity = userDoc.data()?['currentCity'] ?? 'Valenciennes';
  _visitedCities = visitedDoc.docs.map((d) => d.id).toSet();
  _stoppedCities = stoppedDoc.docs.map((d) => d.id).toSet(); 

  // 🔍 AJOUTE CETTE LIGNE POUR VÉRIFIER DANS LA CONSOLE :
  print("🛑 Villes d'arrêt trouvées dans Firestore : $_stoppedCities");

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
                                    statusIcon = Icons.home_outlined;
                                  } else if (isVisited) {
                                    cardBorderColor = Colors.amber.shade400; // Doré pour les traversées
                                    accentColor = Colors.amber.shade700;
                                    statusIcon = Icons.verified;
                                  } else if (isReachable) {
                                    cardBorderColor = focusOrange;
                                    accentColor = focusOrange;
                                    statusIcon = Icons.navigation;
                                  } else {
                                    statusIcon = Icons.lock_outline;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isReachable
                                                ? Colors.white.withValues(alpha: 0.88)
                                                : Colors.white.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: cardBorderColor,
                                              width: isStopped || isVisited || isReachable ? 2.0 : 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: CircleAvatar(
                                              backgroundColor: accentColor.withValues(alpha: 0.15),
                                              child: Icon(statusIcon, color: accentColor),
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    cityName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: isReachable ? darkBlue : Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                                // Badge distinctif selon l'état
                                                if (isStopped)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: Colors.purple.shade700, width: 1),
                                                    ),
                                                    child: Text(
                                                      '🏕️ Étape arrêtée',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                                    ),
                                                  )
                                                else if (isVisited)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: Colors.amber.shade700, width: 1),
                                                    ),
                                                    child: Text(
                                                      '✨ Traversée',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Chemin : $_currentCity ➔ ${routeResult.path.join(" ➔ ")}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isReachable ? Colors.black87 : Colors.black45,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Icon(Icons.timer, size: 13, color: isReachable ? const Color(0xFF1B5E20) : Colors.red.shade700),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Temps : ${formatMinutesToHours(travelMinutes)} (${routeResult.path.length} étape${routeResult.path.length > 1 ? "s" : ""})',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: isReachable ? const Color(0xFF1B5E20) : Colors.red.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: isReachable
                                                ? Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: focusOrange.withValues(alpha: 0.15),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.arrow_forward_ios, color: focusOrange, size: 16),
                                                  )
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

  // Petit widget helper pour la légende en haut
  Widget _buildLegendBadge(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}