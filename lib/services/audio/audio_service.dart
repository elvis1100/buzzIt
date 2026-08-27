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

  final AudioPlayer _teamAPlayer = AudioPlayer();
  final AudioPlayer _teamBPlayer = AudioPlayer();

  Future<void> play(Team team, {String? customPath}) async {
    final requested = customPath == null ? null : File(customPath);
    final useCustom = requested != null && await requested.exists();

    if (useCustom) {
      await _playFile(team, requested);
      return;
    }

    final player = _playerFor(team);
    await player.setReleaseMode(ReleaseMode.stop);
    final assetPath = team == Team.a ? 'sound/ding.mp3' : 'sound/buzz.wav';
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

  Future<String> persistSound(Team team, SoundSelection selection) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final soundsDirectory = Directory(
      path.join(supportDirectory.path, 'sounds'),
    );
    await soundsDirectory.create(recursive: true);
    final destination = File(
      path.join(
        soundsDirectory.path,
        team == Team.a
            ? 'custom_team_a${selection.extension}'
            : 'custom_team_b${selection.extension}',
      ),
    );
    await _playerFor(team).stop();
    await destination.writeAsBytes(selection.bytes, flush: true);
    await _deleteSupersededSounds(team, destination.path, soundsDirectory);
    return destination.path;
  }

  AudioPlayer _playerFor(Team team) {
    return team == Team.a ? _teamAPlayer : _teamBPlayer;
  }

  Future<void> _playFile(Team team, File file) async {
    final player = _playerFor(team);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.play(DeviceFileSource(file.path));
  }

  Future<void> _deleteSupersededSounds(
    Team team,
    String destinationPath,
    Directory soundsDirectory,
  ) async {
    final baseName = team == Team.a ? 'custom_team_a' : 'custom_team_b';
    for (final extension in _supportedExtensions) {
      final candidate = File(
        path.join(soundsDirectory.path, '$baseName.$extension'),
      );
      if (candidate.path != destinationPath && await candidate.exists()) {
        await candidate.delete();
      }
    }
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _teamAPlayer.dispose(),
      _teamBPlayer.dispose(),
    ]);
  }
}
