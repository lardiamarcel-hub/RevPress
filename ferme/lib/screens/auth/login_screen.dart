import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();

  bool _modeInscription = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final auth = context.read<AuthService>();
    try {
      if (_modeInscription) {
        await auth.inscription(_emailCtrl.text, _motDePasseCtrl.text);
      } else {
        await auth.connexion(_emailCtrl.text, _motDePasseCtrl.text);
      }
      // La navigation suit automatiquement via SessionProvider (AppGate).
    } catch (e) {
      setState(() => _erreur = _messageErreur(e));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  String _messageErreur(Object e) {
    final texte = e.toString();
    if (texte.contains('user-not-found') || texte.contains('wrong-password') || texte.contains('invalid-credential')) {
      return 'Adresse e-mail ou mot de passe incorrect.';
    }
    if (texte.contains('email-already-in-use')) {
      return 'Un compte existe déjà avec cet e-mail. Connectez-vous.';
    }
    if (texte.contains('weak-password')) {
      return 'Mot de passe trop court (6 caractères minimum).';
    }
    if (texte.contains('invalid-email')) {
      return 'Adresse e-mail invalide.';
    }
    return "Une erreur est survenue. Vérifiez votre connexion et réessayez.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset('assets/icon/icon.png', width: 88, height: 88),
                          ),
                          const SizedBox(height: 12),
                          Text('Suivi Ferme', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Suivi financier à distance de la ferme',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motDePasseCtrl,
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                      onFieldSubmitted: (_) => _valider(),
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 12),
                      Text(_erreur!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _enCours ? null : _valider,
                      child: _enCours
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_modeInscription ? "S'inscrire" : 'Se connecter'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _enCours
                          ? null
                          : () => setState(() {
                                _modeInscription = !_modeInscription;
                                _erreur = null;
                              }),
                      child: Text(
                        _modeInscription
                            ? 'Vous avez déjà un compte ? Se connecter'
                            : "Première connexion ou invité(e) ? Créer un compte",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
