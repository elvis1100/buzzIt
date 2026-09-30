import 'package:flutter/material.dart';

import '../../controllers/host_controller.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/sound_selection.dart';
import '../../models/team.dart';
import '../../widgets/team_editor_card.dart';
import 'widgets/host_settings_widgets.dart';

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
  late bool _soundEnabled;
  SoundSelection? _teamASound;
  SoundSelection? _teamBSound;
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
    _soundEnabled = settings.soundEnabled;
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
                    const SettingsSectionTitle(
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
                    const SettingsSectionTitle(
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
                    const SettingsSectionTitle(
                      title: 'Buzzer sounds',
                      subtitle: 'WAV, MP3, OGG, or M4A up to 10 MB.',
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Play sound on this computer'),
                      subtitle: const Text(
                        'Mute only this computer; phone sound is unchanged.',
                      ),
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() => _soundEnabled = value);
                      },
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    SoundSelectionRow(
                      teamLabel: _teamAController.text.trim().isEmpty
                          ? 'Team A'
                          : _teamAController.text.trim(),
                      filePath:
                          _teamASound?.fileName ??
                          widget.controller.settings.teamASoundPath,
                      onChoose: () => _chooseSound(Team.a),
                      onTest: () => _testSound(Team.a),
                    ),
                    const SizedBox(height: AppSizes.spaceSm),
                    SoundSelectionRow(
                      teamLabel: _teamBController.text.trim().isEmpty
                          ? 'Team B'
                          : _teamBController.text.trim(),
                      filePath:
                          _teamBSound?.fileName ??
                          widget.controller.settings.teamBSoundPath,
                      onChoose: () => _chooseSound(Team.b),
                      onTest: () => _testSound(Team.b),
                    ),
                    const SizedBox(height: AppSizes.spaceXl),
                    const SettingsSectionTitle(
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
    try {
      final selection = await widget.controller.chooseSound();
      if (selection == null) {
        return;
      }
      await widget.controller.previewSound(team, selection);
      if (!mounted) {
        return;
      }
      setState(() {
        if (team == Team.a) {
          _teamASound = selection;
        } else {
          _teamBSound = selection;
        }
        _validationMessage = null;
      });
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _validationMessage = error.message);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _validationMessage =
              'Could not use that sound. Choose another file.',
        );
      }
    }
  }

  Future<void> _testSound(Team team) async {
    try {
      final selection = team == Team.a ? _teamASound : _teamBSound;
      if (selection == null) {
        await widget.controller.testSound(team);
      } else {
        await widget.controller.previewSound(team, selection);
      }
      if (mounted) {
        setState(() => _validationMessage = null);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _validationMessage =
              'Could not play that sound. Choose another file.',
        );
      }
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
    try {
      await widget.controller.saveSettings(
        match: match,
        soundEnabled: _soundEnabled,
        port: port,
        teamASound: _teamASound,
        teamBSound: _teamBSound,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on HostSettingsSaveException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _validationMessage = error.message;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _validationMessage =
              'Could not save settings. Check the sound files and try again.';
        });
      }
    }
  }
}
