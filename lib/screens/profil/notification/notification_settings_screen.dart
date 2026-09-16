import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _arrivalNotif = true;
  bool _pauseReminderNotif = true;
  bool _soundEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (mounted) {
      setState(() {
        _arrivalNotif = data?['notifArrival'] ?? true;
        _pauseReminderNotif = data?['notifPauseReminder'] ?? true;
        _soundEnabled = data?['notifSound'] ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      if (key == 'notifArrival') _arrivalNotif = value;
      if (key == 'notifPauseReminder') _pauseReminderNotif = value;
      if (key == 'notifSound') _soundEnabled = value;
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      key: value,
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

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
                        'Paramètres des notifications',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: focusOrange))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          children: [
                            _buildSwitchCard(
                              title: 'Notifications d\'arrivée',
                              subtitle: 'Être prévenu lorsque tu arrives à une étape.',
                              value: _arrivalNotif,
                              onChanged: (val) => _updatePreference('notifArrival', val),
                            ),
                            _buildSwitchCard(
                              title: 'Rappel de fin de pause',
                              subtitle: 'Recevoir une alerte 2 minutes avant la fin de la pause.',
                              value: _pauseReminderNotif,
                              onChanged: (val) => _updatePreference('notifPauseReminder', val),
                            ),
                            _buildSwitchCard(
                              title: 'Son des notifications',
                              subtitle: 'Activer le son lors de l\'envoi des alertes.',
                              value: _soundEnabled,
                              onChanged: (val) => _updatePreference('notifSound', val),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: darkBlue.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  activeColor: focusOrange,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}