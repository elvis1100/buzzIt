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
    required this.onToggleSound,
    super.key,
  });

  final HostController controller;
  final VoidCallback onSettings;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    final listening = controller.serverStatus == HostServerStatus.listening;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSizes.spaceMd,
      runSpacing: AppSizes.spaceSm,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppLogo(size: 58),
            const SizedBox(width: AppSizes.spaceMd),
            Text(
              'BuzzIt Host',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StatusPill(
              label: listening ? 'Server running' : 'Server down',
              color: listening ? AppColors.success : AppColors.error,
              icon: listening ? Icons.lan_rounded : Icons.lan_outlined,
            ),
            const SizedBox(width: AppSizes.spaceMd),
            IconButton.filledTonal(
              tooltip: controller.settings.mobileSoundEnabled
                  ? 'Mute phone sound'
                  : 'Unmute phone sound',
              onPressed: onToggleSound,
              icon: Icon(
                controller.settings.mobileSoundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            IconButton.filledTonal(
              tooltip: 'Host settings',
              onPressed: onSettings,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
