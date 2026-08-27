import 'package:flutter/material.dart';

import '../../../controllers/host_controller.dart';
import '../../../core/theme.dart';
import '../../../models/connection_status.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/status_pill.dart';

class HostHeader extends StatelessWidget {
  const HostHeader({
    required this.controller,
    required this.onSettings,
    super.key,
  });

  final HostController controller;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final listening = controller.serverStatus == HostServerStatus.listening;
    return Row(
      children: <Widget>[
        const AppLogo(size: 58),
        const SizedBox(width: AppSizes.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'BuzzIt Host',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSizes.spaceXs),
              Text(
                'Fast, fair buzzing on your local network',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        StatusPill(
          label: listening ? 'Host online' : 'Host unavailable',
          color: listening ? AppColors.success : AppColors.error,
          icon: listening ? Icons.lan_rounded : Icons.lan_outlined,
        ),
        const SizedBox(width: AppSizes.spaceMd),
        IconButton.filledTonal(
          tooltip: 'Host settings',
          onPressed: onSettings,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}
