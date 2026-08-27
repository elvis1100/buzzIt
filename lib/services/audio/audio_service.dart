import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/team.dart';

class AudioService {
  static const _supportedExtensions = <String>['wav', 'mp3', 'ogg', 'm4a'];
  static const _maximumSoundBytes = 10 * 1024 * 1024;

  final AudioPlayer _teamAPlayer = AudioPlayer();
  final AudioPlayer _teamBPlayer = AudioPlayer();



  Future<void> play(Team team, {String? customPath}) async {
    final requested = customPath == null ? null : File(customPath);
    final useCustom = requested != null && await requested.exists();

    final player = team == Team.a ? _teamAPlayer : _teamBPlayer;
    await player.setReleaseMode(ReleaseMode.stop);

    if (useCustom) {
      await player.play(DeviceFileSource(requested.path));
    } else {
      final assetPath = team == Team.a ? 'sound/ding.mp3' : 'sound/buzz.wav';
      await player.play(AssetSource(assetPath));
    }
  }
  Future<String?> importSound(Team team) async {
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
    final supportDirectory = await getApplicationSupportDirectory();
    final soundsDirectory = Directory(
      path.join(supportDirectory.path, 'sounds'),
    );
    await soundsDirectory.create(recursive: true);
    final destination = File(
      path.join(
        soundsDirectory.path,
        team == Team.a ? 'custom_team_a$extension' : 'custom_team_b$extension',
      ),
    );
    await destination.writeAsBytes(await picked.readAsBytes(), flush: true);
    return destination.path;
  }



  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _teamAPlayer.dispose(),
      _teamBPlayer.dispose(),
    ]);
  }
}
