import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/sound_selection.dart';
import '../../models/team.dart';

class AudioService {
  static const _supportedExtensions = <String>['wav', 'mp3', 'ogg', 'm4a'];
  static const _maximumSoundBytes = 10 * 1024 * 1024;

  AudioPlayer? _teamAPlayer;
  AudioPlayer? _teamBPlayer;

  Future<void> play(Team team, {String? customPath}) async {
    final requested = customPath == null ? null : File(customPath);
    final useCustom = requested != null && await requested.exists();

    if (useCustom) {
      await _playFile(team, requested);
      return;
    }

    final player = _playerFor(team);
    await player.setReleaseMode(ReleaseMode.stop);
    final assetPath = team == Team.a ? 'sound/ding.wav' : 'sound/buzz.wav';
    await player.play(AssetSource(assetPath));
  }

  Future<SoundSelection?> chooseSound() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Choose a buzzer sound',
      type: FileType.custom,
      allowedExtensions: _supportedExtensions,
    );
    if (picked == null) {
      return null;
    }
    if (await picked.length() > _maximumSoundBytes) {
      throw const FormatException('Sound files must be 10 MB or smaller.');
    }
    final extension = path.extension(picked.name).toLowerCase();
    if (!_supportedExtensions.contains(extension.replaceFirst('.', ''))) {
      throw const FormatException('Choose a WAV, MP3, OGG, or M4A file.');
    }

    return SoundSelection(
      fileName: picked.name,
      extension: extension,
      bytes: await picked.readAsBytes(),
    );
  }

  Future<void> previewSelection(Team team, SoundSelection selection) async {
    final temporaryDirectory = await getTemporaryDirectory();
    final preview = File(
      path.join(
        temporaryDirectory.path,
        team == Team.a
            ? 'buzzit_team_a_preview${selection.extension}'
            : 'buzzit_team_b_preview${selection.extension}',
      ),
    );
    await preview.writeAsBytes(selection.bytes, flush: true);
    await _playFile(team, preview);
  }

  /// Copies a selected sound to a new managed file without replacing the
  /// current one. The caller must discard it after a failed settings save or
  /// prune older copies after a successful save.
  Future<String> persistSound(Team team, SoundSelection selection) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final soundsDirectory = Directory(
      path.join(supportDirectory.path, 'sounds'),
    );
    await soundsDirectory.create(recursive: true);
    // A new path keeps the currently selected file intact until host settings
    // are saved. Failed saves can discard this file without changing playback.
    final baseName = team == Team.a ? 'custom_team_a' : 'custom_team_b';
    final destination = File(
      path.join(
        soundsDirectory.path,
        '${baseName}_${DateTime.now().microsecondsSinceEpoch}${selection.extension}',
      ),
    );
    await _teamPlayerIfCreated(team)?.stop();
    await destination.writeAsBytes(selection.bytes, flush: true);
    return destination.path;
  }

  AudioPlayer _playerFor(Team team) {
    return team == Team.a
        ? (_teamAPlayer ??= AudioPlayer())
        : (_teamBPlayer ??= AudioPlayer());
  }

  Future<void> _playFile(Team team, File file) async {
    final player = _playerFor(team);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.play(DeviceFileSource(file.path));
  }

  AudioPlayer? _teamPlayerIfCreated(Team team) {
    return team == Team.a ? _teamAPlayer : _teamBPlayer;
  }

  /// Removes a newly persisted managed file when the host settings save fails.
  Future<void> discardSound(String filePath) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final soundsDirectory = path.join(supportDirectory.path, 'sounds');
    if (!path.isWithin(soundsDirectory, filePath)) {
      return;
    }
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Removes older managed copies after the new settings have been saved.
  Future<void> pruneSounds(Team team, String keepPath) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final soundsDirectory = Directory(
      path.join(supportDirectory.path, 'sounds'),
    );
    if (!await soundsDirectory.exists()) {
      return;
    }
    final baseName = team == Team.a ? 'custom_team_a' : 'custom_team_b';
    await for (final entity in soundsDirectory.list()) {
      if (entity is! File || entity.path == keepPath) {
        continue;
      }
      final name = path.basename(entity.path);
      if ((name.startsWith('${baseName}_') || name.startsWith('$baseName.')) &&
          _supportedExtensions.contains(
            path.extension(name).replaceFirst('.', ''),
          )) {
        await entity.delete();
      }
    }
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      if (_teamAPlayer case final player?) player.dispose(),
      if (_teamBPlayer case final player?) player.dispose(),
    ]);
  }
}
