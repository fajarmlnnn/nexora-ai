import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/nexora_mascot.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NexoraScaffold(
      appBar: const NexoraAppBar(
        title: 'Notifikasi',
        subtitle: 'Pemberitahuan perangkat',
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const Center(child: NexoraMascot(size: 140, state: NexoraMascotState.idle)),
          const SizedBox(height: AppSpacing.xl),
          NexoraEmpty(
            icon: LucideIcons.bellOff,
            title: 'Belum ada notifikasi',
            reason:
                'Nexora belum mengirim pemberitahuan ke perangkat ini. Tidak ada antrian notifikasi palsu atau badge belum dibaca.',
          ),
        ],
      ),
    );
  }
}
