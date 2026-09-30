import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../core/theme.dart';

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSizes.spaceXs),
        Text(subtitle, style: const TextStyle(color: AppColors.inkMuted)),
      ],
    );
  }
}

class SoundSelectionRow extends StatelessWidget {
  const SoundSelectionRow({
    required this.teamLabel,
    required this.filePath,
    required this.onChoose,
    required this.onTest,
    super.key,
  });

  final String teamLabel;
  final String? filePath;
  final VoidCallback onChoose;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        child: Row(
          children: <Widget>[
            const Icon(Icons.music_note_rounded, color: AppColors.primary),
            const SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    teamLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    filePath == null
                        ? 'Built-in chime'
                        : path.basename(filePath!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Preview sound',
              onPressed: onTest,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            OutlinedButton(onPressed: onChoose, child: const Text('Choose')),
          ],
        ),
      ),
    );
  }
}
