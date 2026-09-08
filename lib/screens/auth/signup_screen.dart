import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../repositories/profil_repository.dart';
import '../../models/profil.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const SignupScreen({super.key, required this.onSwitchToLogin});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _authService = AuthService();
  final _profilRepository = ProfilRepository();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final credential = await _authService.signUp(email: email, password: _passwordController.text);
      final uid = credential.user!.uid;
      await _profilRepository.creerProfil(Profil(
        uid: uid,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: email,
        emailCv: email,
        typeRecherche: TypeRecherche.alternance,
      ));
    } catch (e) {
      setState(() => _error = "Inscription impossible. Vérifie les champs (mot de passe : 6 caractères minimum).");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Jalon', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('recherche ingénieur', style: monoStyle(size: 12)),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Créer un compte', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 18),
                        Row(children: [
                          Expanded(child: TextField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom'))),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom'))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                        const SizedBox(height: 12),
                        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe')),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.brick, fontSize: 12.5)),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Créer mon compte'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(onPressed: widget.onSwitchToLogin, child: const Text('Déjà un compte ? Se connecter')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
