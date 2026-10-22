import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_time/models/companion.dart';
import 'package:focus_time/widgets/camp_widgets.dart';

/// Page "Enclos" : chaque compagnon a son petit enclos.
/// Se ferme avec `Navigator.pop(context, idChoisi)` quand on confirme,
/// ou avec `null` si on ferme sans valider.
class CompanionPenScreen extends StatefulWidget {
  final String selectedId;
  final List<String> unlockedIds;
  final String background;

  const CompanionPenScreen({
    super.key,
    required this.selectedId,
    required this.unlockedIds,
    required this.background,
  });

  @override
  State<CompanionPenScreen> createState() => _CompanionPenScreenState();
}

class _CompanionPenScreenState extends State<CompanionPenScreen> {
  static const Color _orange = Color(0xFFFF8C00);
  static const Color _brown = Color(0xFF6B4423);

  late String _selected = widget.selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.background,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF1B2A41)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  Expanded(
                    child: GridView.builder(
                      itemCount: CompanionData.allCompanions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                      itemBuilder: (context, index) =>
                          _buildPen(CompanionData.allCompanions[index]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, _selected),
                      icon: const Icon(Icons.pets),
                      label: const Text(
                        'CONFIRMER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'CHOISIR UN COMPAGNON',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.pets, color: _brown, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: _orange,
          shape: const CircleBorder(
            side: BorderSide(color: Color(0xFFFFD54F), width: 2),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPen(Companion companion) {
    final bool unlocked =
        widget.unlockedIds.contains(companion.id) ||
        widget.selectedId == companion.id;
    final bool selected = _selected == companion.id;

    final Widget image = Image.asset(
      campCompanionAsset(companion.id),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.pets, color: _orange, size: 40),
    );

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: unlocked
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = companion.id);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE9C87B), Color(0xFFC99A4B)],
                ),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFFD54F)
                      : Colors.white.withValues(alpha: 0.25),
                  width: selected ? 3 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: 0.55,
                        heightFactor: 0.5,
                        alignment: Alignment.bottomCenter,
                        child: unlocked
                            ? image
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                    child: image,
                                  ),
                                  const Text(
                                    '?',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const CustomPaint(painter: CampFencePainter()),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _pill(companion.name, const Color(0xFFD7AE75), textColor: _brown),
        const SizedBox(height: 6),
        if (!unlocked)
          _pill('À trouver', _brown, icon: Icons.lock_outline)
        else if (selected)
          _pill('SÉLECTIONNÉ', _brown)
        else
          _pill('CHOISIR', const Color(0xFF3FA34D)),
      ],
    );
  }

  Widget _pill(
    String text,
    Color background, {
    Color textColor = Colors.white,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
