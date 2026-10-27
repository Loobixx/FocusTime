import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_time/services/admin_access_service.dart';

class ShopScreen extends StatefulWidget {
  final String backgroundAsset;
  final String equippedTentAsset;
  final String equippedEnclosureBackAsset;

  const ShopScreen({
    super.key,
    required this.backgroundAsset,
    required this.equippedTentAsset,
    required this.equippedEnclosureBackAsset,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Toutes';
  final List<String> _categories = ['Toutes', 'Tente', 'Clôture'];

  String _selectedOwnershipFilter = 'Tous';
  final List<String> _ownershipFilters = ['Tous', 'À acheter', 'Possédés'];

  // 1. Modèle de base (les états 'owned' et 'equipped' seront calculés dynamiquement via Firebase)
  final List<Map<String, dynamic>> _shopItemsTemplate = [
    {
      'id': 'tente_montagne',
      'name': 'Tente de la montagne',
      'type': 'Tente',
      'categoryIcon': Icons.home,
      'variants': [
        {
          'id': 'tente_montagne_base',
          'colorName': 'Classique',
          'colorCode': Colors.brown,
          'price': 0,
          'imagePath': 'assets/homePageAssets/logement/base/montagne/tente.png',
        },
        {
          'id': 'tente_montagne_violette',
          'colorName': 'Violette',
          'colorCode': const Color(0xFF7960FF),
          'price': 150, // Modifie le prix si besoin
          'imagePath': 'assets/homePageAssets/logement/base/montagne/tenteViolette.png',
        },
        {
          'id': 'tente_montagne_bleue',
          'colorName': 'Bleue',
          'colorCode': const Color(0xFF0094FF),
          'price': 150,
          'imagePath': 'assets/homePageAssets/logement/base/montagne/tenteBleue.png',
        },
      ]
    },
    {
      'id': 'cloture_montagne',
      'name': 'Clôture de la montagne',
      'type': 'Clôture',
      'categoryIcon': Icons.fence,
      'variants': [
        {
          'id': 'cloture_montagne_bois',
          'colorName': 'Bois brut',
          'colorCode': Colors.brown,
          'price': 0,
          'imagePath': 'assets/homePageAssets/cloture/base/montagne/arriere.png',
          'imageBack': 'assets/homePageAssets/cloture/base/montagne/arriere.png',
          'imageFront': 'assets/homePageAssets/cloture/base/montagne/avant.png',
        },
      ]
    },
  ];

  final AdminAccessService _adminService = AdminAccessService();

  void _showAdminOptions(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Outils d\'administration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF143063),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1 : +999 999 pièces
              ListTile(
                leading: const Icon(Icons.monetization_on, color: Color(0xFFFF8C00)),
                title: const Text('Définir 999 999 pièces'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'points': 999999,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solde mis à jour : 999 999 🪙')),
                    );
                  }
                },
              ),

              // Option 2 : Tout débloquer
              ListTile(
                leading: const Icon(Icons.lock_open_rounded, color: Colors.green),
                title: const Text('Débloquer tous les cosmétiques'),
                onTap: () async {
                  Navigator.pop(context);
                  final List<String> allIds = [];
                  for (final item in _shopItemsTemplate) {
                    final variants = item['variants'] as List;
                    for (final v in variants) {
                      allIds.add(v['id'] as String);
                    }
                  }

                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'unlockedItems': allIds,
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tous les articles ont été débloqués.')),
                    );
                  }
                },
              ),

              // Option 3 : Réinitialiser l'inventaire
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
                title: const Text(
                  'Réinitialiser l\'inventaire & les pièces',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'points': 0,
                    'unlockedItems': <String>[],
                    'equippedTent': 'assets/homePageAssets/logement/base/montagne/tente.png',
                    'equippedEnclosureBack': 'assets/homePageAssets/cloture/base/montagne/arriere.png',
                    'equippedEnclosureFront': 'assets/homePageAssets/cloture/base/montagne/avant.png',
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inventaire remis à zéro !')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // 2. TRANSACTION D'ACHAT (Débit des pièces + Ajout à l'inventaire)
  Future<void> _buyVariant(Map<String, dynamic> activeVariant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final price = activeVariant['price'] as int;
    final variantId = activeVariant['id'] as String;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        int currentPoints = snapshot.data()?['points'] ?? 0;

        if (currentPoints >= price) {
          transaction.update(userRef, {
            'points': currentPoints - price,
            'unlockedItems': FieldValue.arrayUnion([variantId]) // Ajoute l'objet sans écraser le reste
          });
        } else {
          throw Exception("Fonds insuffisants");
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat réussi ! 🎉'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'acheter : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. ÉQUIPER L'OBJET
  Future<void> _equipVariantInFirestore(Map<String, dynamic> item, Map<String, dynamic> activeVariant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (item['type'] == 'Tente') {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'equippedTent': activeVariant['imagePath'],
      });
    } else if (item['type'] == 'Clôture') {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'equippedEnclosureBack': activeVariant['imageBack'],
        'equippedEnclosureFront': activeVariant['imageFront'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Erreur d'authentification")));

    // 4. LECTURE EN DIRECT DE LA BASE DE DONNÉES
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator(color: focusOrange)));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final currentPoints = userData?['points'] ?? 0;
        final unlockedItems = List<String>.from(userData?['unlockedItems'] ?? []);
        
        final equippedTent = userData?['equippedTent'] ?? widget.equippedTentAsset;
        final equippedEnclosureBack = userData?['equippedEnclosureBack'] ?? widget.equippedEnclosureBackAsset;

        // 5. INJECTION DES STATUTS (Possédé / Équipé) DANS LES OBJETS
        final processedItems = _shopItemsTemplate.map((templateItem) {
          final variants = (templateItem['variants'] as List).map((v) {
            final variant = Map<String, dynamic>.from(v);
            
            // Possédé si le prix est 0 ou s'il est dans la liste "unlockedItems" de Firebase
            variant['owned'] = (variant['price'] == 0) || unlockedItems.contains(variant['id']);
            
            // Équipé si le chemin correspond à celui sauvegardé dans Firebase
            if (templateItem['type'] == 'Tente') {
              variant['equipped'] = (variant['imagePath'] == equippedTent);
            } else if (templateItem['type'] == 'Clôture') {
              variant['equipped'] = (variant['imageBack'] == equippedEnclosureBack);
            } else {
              variant['equipped'] = false;
            }
            return variant;
          }).toList();

          return {
            ...templateItem,
            'variants': variants,
          };
        }).toList();

        // Application des filtres de l'interface
        final filteredItems = processedItems.where((item) {
          final matchesCategory = _selectedCategory == 'Toutes' || item['type'] == _selectedCategory;
          final variants = item['variants'] as List<Map<String, dynamic>>;
          bool ownsAtLeastOne = variants.any((v) => v['owned'] == true);

          final matchesOwnership = _selectedOwnershipFilter == 'Tous' ||
              (_selectedOwnershipFilter == 'Possédés' && ownsAtLeastOne) ||
              (_selectedOwnershipFilter == 'À acheter' && !ownsAtLeastOne);

          return matchesCategory && matchesOwnership;
        }).toList();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: darkBlue),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Boutique', style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              // Bouton Admin visible uniquement pour les administrateurs
              StreamBuilder<bool>(
                stream: _adminService.watchAdminStatus(user.email),
                builder: (context, adminSnapshot) {
                  final bool isAdmin = adminSnapshot.data ?? false;
                  if (!isAdmin) return const SizedBox.shrink();

                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade700, width: 1.5),
                      ),
                      child: Icon(Icons.admin_panel_settings, color: Colors.amber.shade900, size: 20),
                    ),
                    tooltip: 'Panneau Admin',
                    onPressed: () => _showAdminOptions(context, user.uid),
                  );
                },
              ),

              // Solde de pièces
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: focusOrange, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: focusOrange, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$currentPoints',
                      style: const TextStyle(
                        color: darkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.backgroundAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: const Color(0xFF2C3E50)),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.white.withValues(alpha: 0.2)),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                          child: SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected = category == _selectedCategory;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCategory = category),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: isSelected ? focusOrange : Colors.white.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isSelected ? focusOrange : Colors.white, width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        category,
                                        style: TextStyle(color: isSelected ? Colors.white : darkBlue, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.filter_list, size: 16, color: darkBlue),
                              const SizedBox(width: 6),
                              Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedOwnershipFilter,
                                    icon: const Icon(Icons.arrow_drop_down, color: darkBlue, size: 20),
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 13),
                                    items: _ownershipFilters.map((String value) {
                                      return DropdownMenuItem<String>(value: value, child: Text(value));
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) setState(() => _selectedOwnershipFilter = newValue);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: filteredItems.isEmpty
                                      ? const Center(child: Text("Aucun objet trouvé", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)))
                                      : GridView.builder(
                                          padding: const EdgeInsets.all(16),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
                                          ),
                                          itemCount: filteredItems.length,
                                          itemBuilder: (context, index) {
                                            return _buildShopCard(filteredItems[index], currentPoints, darkBlue, focusOrange);
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopCard(Map<String, dynamic> item, int currentPoints, Color darkBlue, Color focusOrange) {
    final List<Map<String, dynamic>> variants = List<Map<String, dynamic>>.from(item['variants']);

    final displayVariant = variants.firstWhere(
      (v) => v['equipped'] == true,
      orElse: () => variants.first,
    );

    bool canAfford = currentPoints >= (displayVariant['price'] as int);
    bool isOwned = displayVariant['owned'] as bool;

    return GestureDetector(
      onTap: () => _showVariantBottomSheet(item, currentPoints, darkBlue, focusOrange),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOwned ? Colors.green : (canAfford ? darkBlue : Colors.grey), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0, right: 8.0),
                      child: Image.asset(
                        displayVariant['imagePath'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isOwned ? Colors.green.shade100 : (canAfford ? focusOrange : Colors.grey.shade300),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isOwned) ...[
                        Icon(Icons.monetization_on, size: 14, color: canAfford ? Colors.white : Colors.grey.shade600),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isOwned ? 'POSSÉDÉ' : '${displayVariant['price']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOwned ? Colors.green.shade800 : (canAfford ? Colors.white : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Icon(item['categoryIcon'], size: 16, color: darkBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVariantBottomSheet(Map<String, dynamic> item, int currentPoints, Color darkBlue, Color focusOrange) {
    final List<Map<String, dynamic>> variants = List<Map<String, dynamic>>.from(item['variants']);

    int selectedVariantIndex = variants.indexWhere((v) => v['equipped'] == true);
    if (selectedVariantIndex == -1) selectedVariantIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final activeVariant = variants[selectedVariantIndex];
            bool canAfford = currentPoints >= (activeVariant['price'] as int);
            bool isOwned = activeVariant['owned'] as bool;
            bool isEquipped = activeVariant['equipped'] == true;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Text(item['name'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue)),
                  Text("Style : ${activeVariant['colorName']}", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Image.asset(
                        activeVariant['imagePath'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    children: List.generate(variants.length, (index) {
                      final variant = variants[index];
                      final isSelected = index == selectedVariantIndex;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedVariantIndex = index),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: variant['colorCode'],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? focusOrange : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected ? [BoxShadow(color: focusOrange.withValues(alpha: 0.4), blurRadius: 8)] : [],
                          ),
                          child: variant['owned'] ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEquipped ? Colors.grey.shade400 : (isOwned ? Colors.green : (canAfford ? focusOrange : Colors.grey.shade400)),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(isEquipped ? Icons.check_circle : (isOwned ? Icons.check : (canAfford ? Icons.shopping_cart : Icons.lock))),
                      label: Text(
                        isEquipped ? "Déjà équipé" : (isOwned ? "Équiper cette variante" : (canAfford ? "Acheter pour ${activeVariant['price']} 🪙" : "Fonds insuffisants")),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: isEquipped
                          ? null
                          : () async {
                              if (isOwned) {
                                // Sauvegarde de l'équipement dans Firebase
                                await _equipVariantInFirestore(item, activeVariant);
                                if (context.mounted) Navigator.pop(context);
                              } else if (canAfford) {
                                // Achat via la transaction Firebase
                                await _buyVariant(activeVariant);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}