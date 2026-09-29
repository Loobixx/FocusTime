import 'package:flutter/material.dart';

class ActiveTimerDialogs {
  static void showArrivalDialog({
    required BuildContext context,
    required String cityName,
    required VoidCallback onClosed,
    required Function(int minutes) onSelectPause,
  }) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('🔥 Étape atteinte à $cityName !', style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlue, fontSize: 18)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                Navigator.pop(dialogContext);
                onClosed();
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu as planté ta tente pour souffler un peu au coin du feu. Veux-tu faire une pause pour recharger ton énergie avant de repartir à pied ?',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(dialogContext, '5 min', 5, focusOrange, onSelectPause, onClosed),
                _buildButton(dialogContext, '10 min', 10, focusOrange, onSelectPause, onClosed),
                _buildButton(dialogContext, '15 min', 15, focusOrange, onSelectPause, onClosed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildButton(
    BuildContext dialogCtx, 
    String label, 
    int minutes, 
    Color color, 
    Function(int) onSelectPause,
    VoidCallback onClosed,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(dialogCtx);
        onClosed();
        onSelectPause(minutes);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
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