import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../controllers/host_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/team.dart';
import '../../widgets/team_editor_card.dart';

class HostSettingsDialog extends StatefulWidget {
  const HostSettingsDialog({required this.controller, super.key});

  final HostController controller;

  @override
  State<HostSettingsDialog> createState() => _HostSettingsDialogState();
}

class _HostSettingsDialogState extends State<HostSettingsDialog> {
  late final TextEditingController _teamAController;
  late final TextEditingController _teamBController;
  late final TextEditingController _portController;
  late Color _teamAColor;
  late Color _teamBColor;
  late bool _autoResetEnabled;
  late int _autoResetSeconds;
  bool _saving = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _teamAController = TextEditingController(text: settings.match.teamAName);
    _teamBController = TextEditingController(text: settings.match.teamBName);
    _portController = TextEditingController(text: settings.port.toString());
    _teamAColor = Color(settings.match.teamAColor);
    _teamBColor = Color(settings.match.teamBColor);
    _autoResetEnabled = settings.match.autoResetEnabled;
    _autoResetSeconds = settings.match.autoResetSeconds;
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.spaceLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spaceLg,
                AppSizes.spaceLg,
                AppSizes.spaceMd,
                AppSizes.spaceMd,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Host settings',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSizes.spaceXs),
                        const Text(
                          'Match changes are synchronized to the buzzer.',
                          style: TextStyle(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _SectionTitle(
                      title: 'Teams',
                      subtitle: 'Choose readable names and distinct colors.',
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    TeamEditorCard(
                      label: 'Team A name',
                      nameController: _teamAController,
                      color: _teamAColor,
                      onColorChanged: (value) {
                        setState(() => _teamAColor = value);
                      },
                    ),
                    const SizedBox(height: AppSizes.spaceSm),
                    TeamEditorCard(
                      label: 'Team B name',
                      nameController: _teamBController,
                      color: _teamBColor,
                      onColorChanged: (value) {
                        setState(() => _teamBColor = value);
                      },
                    ),
                    const SizedBox(height: AppSizes.spaceXl),
                    const _SectionTitle(
                      title: 'Round reset',
                      subtitle:
                          'The host controls reset timing for both screens.',
                    ),
                    const SizedBox(height: AppSizes.spaceSm),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Automatic reset'),
                      subtitle: Text(
                        _autoResetEnabled
                            ? 'Reset after $_autoResetSeconds seconds'
                            : 'Rounds wait for a manual reset',
                      ),
                      value: _autoResetEnabled,
                      onChanged: (value) {
                        setState(() => _autoResetEnabled = value);
                      },
                    ),
                    Slider(
                      min: AppConstants.minimumResetSeconds.toDouble(),
                      max: AppConstants.maximumResetSeconds.toDouble(),
                      divisions:
                          AppConstants.maximumResetSeconds -
                          AppConstants.minimumResetSeconds,
                      label: '$_autoResetSeconds seconds',
                      value: _autoResetSeconds.toDouble(),
                      onChanged: _autoResetEnabled
                          ? (value) {
                              setState(() => _autoResetSeconds = value.round());
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSizes.spaceXl),
                    const _SectionTitle(
                      title: 'Buzzer sounds',
                      subtitle: 'WAV, MP3, OGG, or M4A up to 10 MB.',
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    _SoundRow(
                      teamLabel: _teamAController.text.trim().isEmpty
                          ? 'Team A'
                          : _teamAController.text.trim(),
                      filePath: widget.controller.settings.teamASoundPath,
                      onChoose: () => _chooseSound(Team.a),
                      onTest: () => widget.controller.testSound(Team.a),
                    ),
                    const SizedBox(height: AppSizes.spaceSm),
                    _SoundRow(
                      teamLabel: _teamBController.text.trim().isEmpty
                          ? 'Team B'
                          : _teamBController.text.trim(),
                      filePath: widget.controller.settings.teamBSoundPath,
                      onChoose: () => _chooseSound(Team.b),
                      onTest: () => widget.controller.testSound(Team.b),
                    ),
                    const SizedBox(height: AppSizes.spaceXl),
                    const _SectionTitle(
                      title: 'Network',
                      subtitle:
                          'Changing the port disconnects the current buzzer.',
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    TextField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Host port',
                        prefixIcon: Icon(Icons.lan_outlined),
                      ),
                    ),
                    if (_validationMessage != null) ...<Widget>[
                      const SizedBox(height: AppSizes.spaceSm),
                      Text(
                        _validationMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSizes.spaceLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Save settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseSound(Team team) async {
    await widget.controller.selectSound(team);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    final port = int.tryParse(_portController.text.trim());
    if (port == null ||
        port < AppConstants.minimumPort ||
        port > AppConstants.maximumPort) {
      setState(() {
        _validationMessage = 'Use a port from 1024 to 65535.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _validationMessage = null;
    });
    final match = widget.controller.match.copyWith(
      teamAName: _teamAController.text,
      teamBName: _teamBController.text,
      teamAColor: _teamAColor.toARGB32(),
      teamBColor: _teamBColor.toARGB32(),
      autoResetEnabled: _autoResetEnabled,
      autoResetSeconds: _autoResetSeconds,
    );
    await widget.controller.updateMatch(match);
    await widget.controller.updatePort(port);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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

class _SoundRow extends StatelessWidget {
  const _SoundRow({
    required this.teamLabel,
    required this.filePath,
    required this.onChoose,
    required this.onTest,
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
