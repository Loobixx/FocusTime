import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/models/companion.dart';
import 'package:focus_time/screens/camp/companion_pen_screen.dart';
import 'package:focus_time/screens/focus/expedition_dialogs.dart';
import 'package:focus_time/screens/map/fog_of_war.dart';
import 'package:focus_time/widgets/biome_backdrop.dart';
import 'package:focus_time/widgets/camp_widgets.dart';

void main() {
  group('Widgets graphiques (BiomeBackdrop, Campfire, CampFencePainter, FogOfWar)', () {
    testWidgets('BiomeBackdrop peint chacun des 5 biomes sans erreur', (tester) async {
      for (final zone in ['desert', 'lac', 'nuages', 'nuit', 'montagnes']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: BiomeBackdrop(zoneId: zone),
              ),
            ),
          ),
        );
        expect(find.byType(BiomeBackdrop), findsOneWidget);
      }
    });

    testWidgets('Campfire et CampFencePainter s\'affichent et campCompanionAsset résout les chemins', (tester) async {
      expect(
        campCompanionAsset('chien'),
        CompanionData.getById('chien')!.campImagePath,
      );
      expect(
        campCompanionAsset('inconnu'),
        CompanionData.allCompanions.first.campImagePath,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(width: 80, height: 80, child: Campfire()),
                SizedBox(
                  width: 120,
                  height: 100,
                  child: CustomPaint(painter: CampFencePainter()),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Campfire), findsOneWidget);
    });

    testWidgets('FogOfWarPainter et WorldCloudsPainter peignent les zones de révélation', (tester) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawCircle(const Offset(10, 10), 8, Paint()..color = Colors.white);
      final sprite = await recorder.endRecording().toImage(20, 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: FogOfWarPainter(
                      revealAreas: const [
                        FogRevealArea(center: Offset(100, 100), radius: 50),
                      ],
                      titleReveals: const [
                        RegionTitleReveal(position: Offset(150, 80)),
                      ],
                      animationValue: 0.25,
                      sprites: [sprite],
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: WorldCloudsPainter(
                      zone: const Rect.fromLTWH(0, 0, 300, 300),
                      animationValue: 0.5,
                      sprites: [sprite],
                      revealPaths: [
                        Path()..addRect(const Rect.fromLTWH(50, 50, 100, 100)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('ActiveTimerDialogs', () {
    testWidgets('showPauseDialog affiche les durées 5/10/15 min et appelle onSelectPause + onClosed une seule fois', (tester) async {
      int? selectedMinutes;
      int closedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  ActiveTimerDialogs.showPauseDialog(
                    context: context,
                    onClosed: () => closedCount++,
                    onSelectPause: (minutes) => selectedMinutes = minutes,
                  );
                },
                child: const Text('Ouvrir pause'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir pause'));
      await tester.pumpAndSettle();

      expect(find.text('Faire une pause ?'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);

      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();

      expect(selectedMinutes, 10);
      expect(closedCount, 1);
    });

    testWidgets('showAbandonDialog, showLostDialog et showFinishDialog déclenchent leurs callbacks', (tester) async {
      bool abandoned = false;
      bool lostConfirmed = false;
      bool finishConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => ActiveTimerDialogs.showAbandonDialog(
                      context,
                      () => abandoned = true,
                    ),
                    child: const Text('Abandon'),
                  ),
                  ElevatedButton(
                    onPressed: () => ActiveTimerDialogs.showLostDialog(
                      context,
                      () {
                        lostConfirmed = true;
                        Navigator.pop(context);
                      },
                    ),
                    child: const Text('Perdu'),
                  ),
                  ElevatedButton(
                    onPressed: () => ActiveTimerDialogs.showFinishDialog(
                      context,
                      () {
                        finishConfirmed = true;
                        Navigator.pop(context);
                      },
                    ),
                    child: const Text('Fini'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abandon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oui, abandonner'));
      await tester.pumpAndSettle();
      expect(abandoned, isTrue);

      await tester.tap(find.text('Perdu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compris'));
      await tester.pumpAndSettle();
      expect(lostConfirmed, isTrue);

      await tester.tap(find.text('Fini'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(finishConfirmed, isTrue);
    });
  });

  group('CompanionPenScreen', () {
    testWidgets('affiche l\'état débloqué/verrouillé, bascule la sélection et renvoie la liste à la confirmation', (tester) async {
      List<String>? returnedCompanions;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedCompanions = await Navigator.push<List<String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompanionPenScreen(
                        selectedIds: ['chien'],
                        unlockedIds: ['chien', 'husky'],
                        background: 'assets/biome/fond2.png',
                      ),
                    ),
                  );
                },
                child: const Text('Ouvrir enclos'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir enclos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('COMPAGNONS (1/4)'), findsOneWidget);
      expect(find.text('SÉLECTIONNÉ (1)'), findsOneWidget);
      expect(find.text('CHOISIR'), findsOneWidget);
      expect(find.text('À TROUVER'), findsNWidgets(2));

      // Sélectionne le 2e compagnon débloqué ('husky' -> 'AZUR')
      await tester.tap(find.text('CHOISIR'));
      await tester.pump();

      expect(find.text('COMPAGNONS (2/4)'), findsOneWidget);

      // Confirme la sélection
      await tester.tap(find.text('CONFIRMER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(returnedCompanions, equals(['chien', 'husky']));
    });
  });
}
