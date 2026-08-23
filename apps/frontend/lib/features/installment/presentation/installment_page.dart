import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/nexora_mascot.dart';

class InstallmentPage extends StatelessWidget {
  const InstallmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NexoraScaffold(
      appBar: const NexoraAppBar(
        title: 'Cicilan',
        subtitle: 'Belum tersedia di buku besar',
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: const [
          Center(child: NexoraMascot(size: 140, state: NexoraMascotState.warning)),
          SizedBox(height: AppSpacing.xl),
          NexoraEmpty(
            icon: LucideIcons.creditCard,
            title: 'Cicilan belum tersedia',
            reason:
                'Nexora belum mencatat cicilan di buku besar keuangan. Fitur ini tidak memengaruhi aset, kewajiban, atau kekayaan bersih.',
          ),
        ],
      ),
    );
  }
}
