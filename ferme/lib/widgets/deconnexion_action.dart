import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';

/// Bouton de déconnexion à placer dans les `actions` d'un AppBar.
class DeconnexionAction extends StatelessWidget {
  const DeconnexionAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Se déconnecter',
      icon: const Icon(Icons.logout),
      onPressed: context.read<SessionProvider>().deconnexion,
    );
  }
}
