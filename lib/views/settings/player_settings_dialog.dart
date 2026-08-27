import 'package:flutter/material.dart';

import '../../controllers/player_controller.dart';
import '../../core/theme.dart';
import '../../widgets/team_editor_card.dart';

class PlayerSettingsDialog extends StatefulWidget {
  const PlayerSettingsDialog({required this.controller, super.key});

  final PlayerController controller;

  @override
  State<PlayerSettingsDialog> createState() => _PlayerSettingsDialogState();
}

class _PlayerSettingsDialogState extends State<PlayerSettingsDialog> {
  late final TextEditingController _teamAController;
  late final TextEditingController _teamBController;
  late Color _teamAColor;
  late Color _teamBColor;
  late bool _hapticsEnabled;
  late bool _soundEnabled;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _teamAController = TextEditingController(
      text: widget.controller.match.teamAName,
    );
    _teamBController = TextEditingController(
      text: widget.controller.match.teamBName,
    );
    _teamAColor = Color(widget.controller.match.teamAColor);
    _teamBColor = Color(widget.controller.match.teamBColor);
    _hapticsEnabled = widget.controller.preferences.hapticsEnabled;
    _soundEnabled = widget.controller.mobileSoundEnabled;
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.spaceMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
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
                          'Buzzer settings',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSizes.spaceXs),
                        Text(
                          'Connected to ${widget.controller.preferences.host}:${widget.controller.preferences.port}',
                          style: const TextStyle(color: AppColors.inkMuted),
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
                    Text(
                      'Team appearance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    const Text(
                      'Changes are saved by the host and synchronized here.',
                      style: TextStyle(color: AppColors.inkMuted),
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
                    const SizedBox(height: AppSizes.spaceLg),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tap haptics'),
                      subtitle: const Text(
                        'Vibrate briefly when a team presses its buzzer.',
                      ),
                      value: _hapticsEnabled,
                      onChanged: (value) {
                        setState(() => _hapticsEnabled = value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Play sound on this phone'),
                      subtitle: const Text(
                        'Shared with the host control; host computer sound is unchanged.',
                      ),
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() => _soundEnabled = value);
                      },
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: AppSizes.spaceSm),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.spaceMd),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: _disconnect,
                      icon: const Icon(Icons.link_off_rounded),
                      label: const Text('Disconnect from host'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSizes.spaceMd),
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
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.controller.updateTeams(
        teamAName: _teamAController.text,
        teamBName: _teamBController.text,
        teamAColor: _teamAColor.toARGB32(),
        teamBColor: _teamBColor.toARGB32(),
        mobileSoundEnabled: _soundEnabled,
      );
      await widget.controller.setHapticsEnabled(_hapticsEnabled);
      if (mounted) {
        Navigator.pop(context);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'Could not save buzzer settings: $error';
        });
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await widget.controller.disconnect();
      if (mounted) {
        Navigator.pop(context);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not disconnect cleanly: $error';
        });
      }
    }
  }
}
