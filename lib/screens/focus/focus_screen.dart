import 'dart:ui';
import 'package:focus_time/screens/map/map_screen.dart';
import 'package:focus_time/screens/focus/expedition_screen.dart'; // Pour envoyer directement en expé si transit
import 'package:flutter/material.dart';
import 'package:focus_time/utils/app_haptics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/time_formatter.dart';
import '../../services/admin_access_service.dart';
import '../../theme/app_theme.dart';

class FocusScreen extends StatefulWidget {
  // ✨ FIX : Paramètres pour gérer la reprise de route et le temps exact
  final List<String>? transitRoute;
  final int? transitRemainingMinutes;
  final int? exactDestinationMinutes;

  /// Vrai quand l'itinéraire vient d'être choisi sur la carte (sans durée) :
  /// on ne renvoie alors jamais vers la carte, on lance directement l'expédition.
  final bool routeAlreadyChosen;

  const FocusScreen({
    super.key,
    this.transitRoute,
    this.transitRemainingMinutes,
    this.exactDestinationMinutes,
    this.routeAlreadyChosen = false,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _focusMinutes = 60;
  bool _isExactTargetSelected = false; // ✨ Suivi du mode "Temps exact"

  final AdminAccessService _adminAccessService = AdminAccessService();
  late final Stream<bool> _adminStatusStream;

  @override
  void initState() {
    super.initState();
    _adminStatusStream = _adminAccessService.watchAdminStatus(
      FirebaseAuth.instance.currentUser?.email,
    );

    // Si on arrive avec un temps exact prédéfini (ex: depuis la reprise de route ou la carte)
    if (widget.transitRemainingMinutes != null) {
      _focusMinutes = widget.transitRemainingMinutes!;
      _isExactTargetSelected = true;
    } else if (widget.exactDestinationMinutes != null) {
      _focusMinutes = widget.exactDestinationMinutes!;
      _isExactTargetSelected = true;
    }
  }

  void _adjustTime(int minutesToAddOrRemove) {
    AppHaptics.lightImpact();
    setState(() {
      _isExactTargetSelected =
          false; // Dès qu'on touche aux boutons + ou -, on sort du mode exact
      _focusMinutes += minutesToAddOrRemove;
      // Plafond min à 10 min et max à 480 min (8h)
      if (_focusMinutes < 10) _focusMinutes = 10;
      if (_focusMinutes > 480) _focusMinutes = 480;
    });
  }

  // ✨ Fonction pour activer le temps exact de la destination en rouge
  void _selectExactTarget() {
    final int? exactTime =
        widget.transitRemainingMinutes ?? widget.exactDestinationMinutes;
    if (exactTime == null) return;
    AppHaptics.mediumImpact();
    setState(() {
      _focusMinutes = exactTime;
      _isExactTargetSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color darkBlue = Theme.of(context).colorScheme.primary;
    const focusOrange = AppColors.focusOrange;
    final Color panelColor = Theme.of(context)
        .colorScheme
        .surface
        .withValues(alpha: isDark ? 0.96 : 0.94);
    final Color borderColor = Theme.of(context).colorScheme.outline;

    double progress = (_focusMinutes / 480).clamp(0.0, 1.0);

    // ✨ FIX : Détection du statut de transit
    bool isResuming =
        widget.transitRoute != null && widget.transitRoute!.isNotEmpty;
    String targetCity = isResuming ? widget.transitRoute!.last : "";
    int timeToDestination = widget.transitRemainingMinutes ?? 0;

    final Color exactTargetColor = isDark
        ? AppColors.transitGreenDarkTheme
        : AppColors.transitGreen;
    final Color confirmForeground = _isExactTargetSelected
        ? Theme.of(context).colorScheme.onTertiary
        : Theme.of(context).colorScheme.onSecondary;
    return Scaffold(
      body: Stack(
        children: [
          // 1. Image de fond floutée
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
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

          // Voile d'ambiance
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
            ),
          ),

          // 2. Contenu centré
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // En-tête : Bouton retour & Titre
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                AppHaptics.lightImpact();
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: borderColor,
                                  ),
                                ),
                                child: Tooltip(
                                  message: 'Retour',
                                  child: Semantics(
                                    label: 'Bouton retour',
                                    excludeSemantics: true,
                                    child: Icon(
                                      Icons.arrow_back_ios_new,
                                      color: darkBlue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'FocusTime',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                                shadows: isDark
                                    ? const [Shadow(color: Colors.black54, blurRadius: 10)]
                                    : const [Shadow(color: Colors.white70, blurRadius: 10)],
                              ),
                            ),
                            const SizedBox(width: 42),
                          ],
                        ),
                      ),

                      // ✨ FIX : Bandeau d'information si on est en transit
                      if (isResuming) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_walk,
                                color: isDark
                                    ? AppColors.transitGreenDarkTheme
                                    : AppColors.transitGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Arrivée à $targetCity dans ${formatMinutesToHours(timeToDestination)}',
                                style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.25 : 0.08,
                                      ),
                                      blurRadius: 1.5,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(flex: 1),

                      // Cadran moderne avec jauge circulaire
                      Center(
                        child: Semantics(
                          label: _isExactTargetSelected
                              ? 'Jauge de progression, temps exact jusqu’à la destination'
                              : 'Durée de concentration sélectionnée',
                          value: formatMinutesToHours(_focusMinutes),
                          liveRegion: true,
                          excludeSemantics: true,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 270,
                                height: 270,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.72)
                                      : Colors.white.withValues(alpha: 0.25),
                                  border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.65 : 0.5), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 246,
                                height: 246,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 6,
                                  backgroundColor: isDark
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Colors.white.withValues(alpha: 0.2),
                                  // ✨ Le cercle devient rouge si on est en mode exact, sinon orange
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _isExactTargetSelected
                                        ? exactTargetColor
                                        : focusOrange,
                                  ),
                                ),
                              ),
                              Container(
                                width: 215,
                                height: 215,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Theme.of(context).colorScheme.surface
                                      : AppColors.surfaceDark,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Text(
                                        formatMinutesToHours(_focusMinutes),
                                        key: ValueKey<int>(_focusMinutes),
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.bold,
                                          // ✨ LE TEXTE PASSE EN ROUGE ICI SI SÉLECTIONNÉ !
                                          color: _isExactTargetSelected
                                              ? exactTargetColor
                                              : AppColors.textOnDark,
                                          letterSpacing: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.55,
                                              ),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isExactTargetSelected
                                          ? '🎯 TEMPS EXACT'
                                          : (isResuming
                                                ? 'Temps Focus'
                                                : 'Expédition'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                        color: _isExactTargetSelected
                                            ? exactTargetColor
                                            : (isDark
                                                ? AppColors.textSecondaryDarkTheme
                                                : AppColors.textOnDark.withValues(alpha: 0.85)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // ✨ BOUTON RAPIDE : "Aller jusqu'à la destination" en mode reprise
                      if (isResuming) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: _selectExactTarget,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _isExactTargetSelected
                                    ? exactTargetColor
                                    : (isDark
                                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                                        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: exactTargetColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    color: _isExactTargetSelected
                                        ? Theme.of(context).colorScheme.onTertiary
                                        : exactTargetColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Aller exactement jusqu\'à la destination (${formatMinutesToHours(timeToDestination)})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _isExactTargetSelected
                                          ? Theme.of(context).colorScheme.onTertiary
                                          : exactTargetColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Panneau de boutons de réglage précis (+ / - fins)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeButton(
                                        '+5m',
                                        () => _adjustTime(5),
                                        isDark ? AppColors.primaryDarkTheme : AppColors.darkBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTimeButton(
                                        '+15m',
                                        () => _adjustTime(15),
                                        isDark ? AppColors.primaryDarkTheme : AppColors.darkBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTimeButton(
                                        '+30m',
                                        () => _adjustTime(30),
                                        isDark ? AppColors.primaryDarkTheme : AppColors.darkBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTimeButton(
                                        '+1h',
                                        () => _adjustTime(60),
                                        isDark ? AppColors.primaryDarkTheme : AppColors.darkBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeButton(
                                        '-5m',
                                        () => _adjustTime(-5),
                                        isDark ? AppColors.errorOnDark : AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTimeButton(
                                        '-15m',
                                        () => _adjustTime(-15),
                                        isDark ? AppColors.errorOnDark : AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTimeButton(
                                        '-30m',
                                        () => _adjustTime(-30),
                                        isDark ? AppColors.errorOnDark : AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTimeButton(
                                        '-1h',
                                        () => _adjustTime(-60),
                                        isDark ? AppColors.errorOnDark : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Bouton Confirmer (Soit vers la carte, soit vers la reprise)
                      StreamBuilder<bool>(
                        stream: _adminStatusStream,
                        builder: (context, snapshot) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: snapshot.data == true ? 12.0 : 24.0,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isExactTargetSelected
                                      ? exactTargetColor
                                      : (isResuming
                                            ? focusOrange
                                            : focusOrange),
                                  foregroundColor: confirmForeground,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () {
                                  AppHaptics.heavyImpact();

                                  // ✨ FIX : Orientation selon le statut et le temps choisi
                                  if (isResuming) {
                                    // S'il reprend et choisit un temps PLUS LONG que le reste de la route :
                                    if (_focusMinutes > timeToDestination &&
                                        !widget.routeAlreadyChosen) {
                                      // On ouvre la carte pour qu'il choisisse les prochaines villes au-delà
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MapScreen(
                                            selectedDurationMinutes:
                                                _focusMinutes,
                                          ),
                                        ),
                                      );
                                    } else {
                                      // S'il choisit un temps plus court ou égal (ou le temps exact), on lance direct le focus
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ActiveTimerScreen(
                                            durationMinutes:
                                                _focusMinutes, // Le temps choisi
                                            plannedTravelMinutes:
                                                timeToDestination, // Le temps total qu'il reste pour cette portion
                                            plannedRoute: widget
                                                .transitRoute!, // L'itinéraire
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    // Trajet classique : direction la carte globale
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MapScreen(
                                          selectedDurationMinutes:
                                              _focusMinutes,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  isResuming
                                      ? ((_focusMinutes > timeToDestination &&
                                                !widget.routeAlreadyChosen)
                                            ? 'Définir la suite du voyage'
                                            : (widget.routeAlreadyChosen
                                                  ? 'Partir en expédition'
                                                  : 'Reprendre la marche'))
                                      : 'Confirmer la durée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: confirmForeground,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Bouton ADMIN 1 SECONDE (Invisible en transit)
                      if (!isResuming)
                        StreamBuilder<bool>(
                          stream: _adminStatusStream,
                          builder: (context, snapshot) {
                            if (snapshot.data != true) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Theme.of(context).colorScheme.onError,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(
                                    Icons.flash_on,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    '🚀 MODE ADMIN : 1 SECONDE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    AppHaptics.heavyImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MapScreen(
                                          selectedDurationMinutes: -1,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
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

  Widget _buildTimeButton(
    String label,
    VoidCallback onPressed,
    Color textColor,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAdding = label.startsWith('+');
    final String amount = label.substring(1);
    final String semanticLabel = isAdding
        ? 'Ajouter $amount au temps de focus'
        : 'Retirer $amount au temps de focus';
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: 'Durée actuelle : ${formatMinutesToHours(_focusMinutes)}',
      child: Tooltip(
        message: semanticLabel,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
