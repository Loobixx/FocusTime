import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_time/models/companion.dart';
import 'package:focus_time/widgets/camp_widgets.dart';

class CompanionPenScreen extends StatefulWidget {
  final List<String> selectedIds; 
  final List<String> unlockedIds;
  final String background;

  const CompanionPenScreen({
    super.key,
    required this.selectedIds,
    required this.unlockedIds,
    required this.background,
  });

  @override
  State<CompanionPenScreen> createState() => _CompanionPenScreenState();
}

class _CompanionPenScreenState extends State<CompanionPenScreen> {
  static const Color _panelBg = Color(0xFF6E4C33);
  static const Color _textBrown = Color(0xFF4A301E);
  static const Color _btnGreen = Color(0xFF6CC164);
  static const Color _btnBeige = Color(0xFFD3AE86);
  static const Color _btnOrange = Color(0xFFF79E4A);
  static const Color _headerYellow = Color(0xFFF5C564);

  late final List<String> _selectedCompanions = List.from(widget.selectedIds);

  void _toggleCompanion(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCompanions.contains(id)) {
        _selectedCompanions.remove(id); 
      } else {
        if (_selectedCompanions.length < 4) {
          _selectedCompanions.add(id); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu ne peux sélectionner que 4 familiers maximum !', style: TextStyle(color: Colors.white)),
              backgroundColor: _textBrown,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.background,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF1B2A41)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
          
          SafeArea(
            child: Center(
              // 👈 NOUVEAU : On bloque la largeur au format téléphone (480px max)
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _panelBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF4A301E), width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: _buildHeader(),
                            ),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.55,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: CompanionData.allCompanions.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.7,
                                ),
                                itemBuilder: (context, index) => _buildPenCard(CompanionData.allCompanions[index]),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildConfirmButton(),
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

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: _headerYellow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC78C46), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'COMPAGNONS (${_selectedCompanions.length}/4)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.pets, color: _textBrown, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _btnBeige,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC78C46), width: 2),
            ),
            child: const Icon(Icons.close_rounded, color: _textBrown, size: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildPenCard(Companion companion) {
    final bool unlocked = widget.unlockedIds.contains(companion.id) || widget.selectedIds.contains(companion.id);
    final int selectionIndex = _selectedCompanions.indexOf(companion.id); 
    final bool isSelected = selectionIndex != -1;

    return GestureDetector(
      onTap: unlocked ? () => _toggleCompanion(companion.id) : null,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: isSelected ? Border.all(color: _headerYellow, width: 2) : Border.all(color: Colors.transparent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/homePageAssets/cloture/base/montagne/arriere.png', fit: BoxFit.contain),
                  
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: FractionallySizedBox(
                      widthFactor: 0.45,
                      heightFactor: 0.45,
                      child: unlocked
                          ? Image.asset(
                              campCompanionAsset(companion.id),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(Icons.pets, color: _headerYellow),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                ColorFiltered(
                                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                  child: Image.asset(campCompanionAsset(companion.id), fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.pets, color: Colors.black)),
                                ),
                                const Text('?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                  Image.asset('assets/homePageAssets/cloture/base/montagne/avant.png', fit: BoxFit.contain),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          _buildPixelPill(companion.name.toUpperCase(), _btnBeige),
          
          const SizedBox(height: 6),
          if (!unlocked)
            _buildPixelPill('À TROUVER', _btnBeige, icon: Icons.lock)
          else if (isSelected)
            _buildPixelPill('SÉLECTIONNÉ (${selectionIndex + 1})', _btnBeige)
          else
            _buildPixelPill('CHOISIR', _btnGreen, textColor: Colors.white),
        ],
      ),
    );
  }

  Widget _buildPixelPill(String text, Color bgColor, {Color textColor = _textBrown, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4A301E), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4A301E).withValues(alpha: 0.5), offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context, _selectedCompanions),
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _btnOrange,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC78C46), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, color: _textBrown, size: 28),
            SizedBox(width: 12),
            Text(
              'CONFIRMER',
              style: TextStyle(
                color: _textBrown,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}