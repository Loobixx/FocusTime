import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:focus_time/services/admin_access_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final AdminAccessService _adminAccessService = AdminAccessService();
  final TextEditingController _emailController = TextEditingController();
  late final Stream<bool> _adminStatusStream;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _adminStatusStream = _adminAccessService.watchAdminStatus(
      FirebaseAuth.instance.currentUser?.email,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<bool> _setAdminStatus(String email, bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null || user?.uid == null) {
      _showMessage('Votre session a expiré. Reconnectez-vous.');
      return false;
    }

    setState(() => _saving = true);
    try {
      await _adminAccessService.setAdminStatus(
        email,
        enabled: enabled,
        currentAdminEmail: user!.email!,
        actorUid: user.uid,
      );
      _showMessage(
        enabled
            ? 'Accès administrateur activé pour ${email.trim()}.'
            : 'Accès administrateur désactivé pour ${email.trim()}.',
      );
      return true;
    } on FormatException catch (error) {
      _showMessage(error.message);
      return false;
    } on StateError catch (error) {
      _showMessage(error.message);
      return false;
    } on FirebaseException catch (error) {
      _showMessage('Action refusée ou impossible (${error.code}).');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addAdmin() async {
    final email = _emailController.text.trim();
    final added = await _setAdminStatus(email, true);
    if (added && mounted) _emailController.clear();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des administrateurs'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<bool>(
        stream: _adminStatusStream,
        builder: (context, statusSnapshot) {
          if (statusSnapshot.hasError) {
            return const Center(
              child: Text('Impossible de vérifier vos droits administrateur.'),
            );
          }
          if (!statusSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (statusSnapshot.data != true) {
            return const Center(
              child: Text(
                'Cette page est réservée aux administrateurs actifs.',
              ),
            );
          }

          final currentEmail = FirebaseAuth.instance.currentUser?.email
              ?.trim()
              .toLowerCase();

          return StreamBuilder<List<AdminAccount>>(
            stream: _adminAccessService.watchAdmins(),
            builder: (context, adminsSnapshot) {
              if (adminsSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Impossible de charger la liste. Vérifiez votre connexion et vos droits.',
                  ),
                );
              }
              if (!adminsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final admins = adminsSnapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Ajoutez une adresse ou désactivez un autre compte. '
                    'Votre propre accès ne peut pas être modifié depuis cette page.',
                    style: TextStyle(color: darkBlue),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail',
                      hintText: 'nom@exemple.com',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _saving ? null : _addAdmin(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _addAdmin,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Ajouter un administrateur'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Comptes autorisés (${admins.where((admin) => admin.enabled).length} actifs)',
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (admins.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Aucun compte administrateur enregistré.'),
                    ),
                  ...admins.map((admin) {
                    final isCurrentAdmin =
                        admin.email.toLowerCase() == currentEmail;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        admin.enabled
                            ? Icons.admin_panel_settings
                            : Icons.person_outline,
                        color: admin.enabled ? Colors.green : Colors.grey,
                      ),
                      title: Text(admin.email),
                      subtitle: Text(
                        isCurrentAdmin
                            ? 'Votre compte'
                            : admin.enabled
                            ? 'Actif'
                            : 'Désactivé',
                      ),
                      trailing: Switch(
                        value: admin.enabled,
                        onChanged: _saving || isCurrentAdmin
                            ? null
                            : (enabled) =>
                                  _setAdminStatus(admin.email, enabled),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
