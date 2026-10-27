// lib/screens/focus/expedition_dialogs.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:focus_time/services/audio_service.dart';

class ActiveTimerDialogs {
  static void showPauseDialog({
    required BuildContext context,
    required VoidCallback onClosed,
    required Function(int minutes) onSelectPause,
  }) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    // onClosed ne doit être appelé qu'une fois, que le dialogue soit fermé par
    // la croix, un choix, ou autrement (ex. bouton retour Android, ou fermeture
    // par l'écran) : sinon _isDialogActive resterait bloqué à true.
    bool closedHandled = false;
    void closeOnce() {
      if (closedHandled) return;
      closedHandled = true;
      onClosed();
    }

    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barre d'en-tête compacte
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: focusOrange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fireplace_rounded, color: focusOrange, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Faire une pause ?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Choisis une durée puis reprends quand tu es prêt.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            closeOnce();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: AudioManager().isMutedNotifier,
                      builder: (context, isMuted, _) => SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        dense: true,
                        secondary: Icon(
                          isMuted ? Icons.music_off_rounded : Icons.music_note_rounded,
                          color: focusOrange,
                        ),
                        title: const Text(
                          'Musique d’ambiance',
                          style: TextStyle(
                            color: darkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(isMuted ? 'Désactivée' : 'Activée'),
                        value: !isMuted,
                        activeThumbColor: focusOrange,
                        onChanged: (enabled) =>
                            AudioManager().setMuted(!enabled),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Choix rapides
                    Row(
                      children: [
                        _buildChoiceChip(bottomSheetContext, '5 min', 5, onSelectPause, closeOnce),
                        const SizedBox(width: 8),
                        _buildChoiceChip(bottomSheetContext, '10 min', 10, onSelectPause, closeOnce),
                        const SizedBox(width: 8),
                        _buildChoiceChip(bottomSheetContext, '15 min', 15, onSelectPause, closeOnce),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(closeOnce);
  }

  static Widget _buildChoiceChip(
    BuildContext ctx,
    String label,
    int minutes,
    Function(int) onSelect,
    VoidCallback onClosed,
  ) {
    const focusOrange = Color(0xFFFF8C00);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(ctx);
            onClosed();
            onSelect(minutes);
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: focusOrange.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.coffee_rounded, size: 14, color: focusOrange),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF143063),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showLostDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🧭 Tu t\'es perdu !'),
        content: const Text('Tu as quitté l\'application hors d\'un moment de pause autorisé. Ton trajet a été annulé.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: onConfirm,
            child: const Text('Compris', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showAbandonDialog(BuildContext context, VoidCallback onAbandon) {
    const darkBlue = Color(0xFF143063);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Abandonner le voyage ?', style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue)),
        content: const Text('Si tu quittes maintenant, toute ta progression sur cette session sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              onAbandon();
            },
            child: const Text('Oui, abandonner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void showFinishDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Fin de session !'),
        content: const Text('Ton trajet et ton temps de focus ont bien été enregistrés.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: onConfirm,
            child: const Text('Continuer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
