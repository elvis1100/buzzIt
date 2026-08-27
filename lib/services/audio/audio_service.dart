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

  late String _defaultTeamAPath;
  late String _defaultTeamBPath;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final supportDirectory = await getApplicationSupportDirectory();
    final soundsDirectory = Directory(
      path.join(supportDirectory.path, 'sounds'),
    );
    await soundsDirectory.create(recursive: true);
    _defaultTeamAPath = path.join(soundsDirectory.path, 'default_team_a.wav');
    _defaultTeamBPath = path.join(soundsDirectory.path, 'default_team_b.wav');
    await _ensureTone(_defaultTeamAPath, frequency: 659.25);
    await _ensureTone(_defaultTeamBPath, frequency: 880);
    await _teamAPlayer.setReleaseMode(ReleaseMode.stop);
    await _teamBPlayer.setReleaseMode(ReleaseMode.stop);
    _initialized = true;
  }

  Future<void> play(Team team, {String? customPath}) async {
    await initialize();
    final player = team == Team.a ? _teamAPlayer : _teamBPlayer;
    final fallback = team == Team.a ? _defaultTeamAPath : _defaultTeamBPath;
    final requested = customPath == null ? null : File(customPath);
    final selectedPath = requested != null && await requested.exists()
        ? requested.path
        : fallback;
    await player.stop();
    await player.play(DeviceFileSource(selectedPath));
  }

  Future<String?> importSound(Team team) async {
    await initialize();
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

  Future<void> _ensureTone(String filePath, {required double frequency}) async {
    final file = File(filePath);
    if (await file.exists()) {
      return;
    }
    await file.writeAsBytes(_createTone(frequency), flush: true);
  }

  Uint8List _createTone(double frequency) {
    const sampleRate = 44100;
    const durationSeconds = 0.42;
    const channels = 1;
    const bitsPerSample = 16;
    final sampleCount = (sampleRate * durationSeconds).round();
    final dataLength = sampleCount * channels * (bitsPerSample ~/ 8);
    final bytes = ByteData(44 + dataLength);

    void writeAscii(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        bytes.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    writeAscii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, channels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * channels * 2, Endian.little);
    bytes.setUint16(32, channels * 2, Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);

    for (var index = 0; index < sampleCount; index++) {
      final progress = index / sampleCount;
      final attack = min(1.0, progress / 0.025);
      final decay = pow(1 - progress, 2.4).toDouble();
      final fundamental = sin(2 * pi * frequency * index / sampleRate);
      final overtone = 0.22 * sin(4 * pi * frequency * index / sampleRate);
      final sample = ((fundamental + overtone) * attack * decay * 22000)
          .clamp(-32768, 32767)
          .round();
      bytes.setInt16(44 + index * 2, sample, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _teamAPlayer.dispose(),
      _teamBPlayer.dispose(),
    ]);
  }
}
