import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../controllers/player_controller.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../models/connection_status.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/error_banner.dart';
import '../qr_scanner_view.dart';

class PlayerConnectionView extends StatefulWidget {
  const PlayerConnectionView({required this.controller, super.key});

  final PlayerController controller;

  @override
  State<PlayerConnectionView> createState() => _PlayerConnectionViewState();
}

class _PlayerConnectionViewState extends State<PlayerConnectionView> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _codeController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final preferences = widget.controller.preferences;
    _hostController = TextEditingController(text: preferences.host);
    _portController = TextEditingController(text: preferences.port.toString());
    _codeController = TextEditingController(text: preferences.pairingCode);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connecting =
        widget.controller.status != PlayerConnectionStatus.disconnected;
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.spaceLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const AppLogo(size: 128),
                        const SizedBox(height: AppSizes.spaceLg),
                        Text(
                          'Ready to buzz?',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                              ),
                        ),
                        const SizedBox(height: AppSizes.spaceSm),
                        Text(
                          'Connect to the host on the same Wi-Fi network. Once paired, both team buzzers fill this screen.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.inkMuted,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.spaceLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Connect to host',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSizes.spaceXs),
                          const Text(
                            'Scanning the host QR code is the fastest option.',
                            style: TextStyle(color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: AppSizes.spaceLg),
                          FilledButton.icon(
                            onPressed: connecting ? null : _scanQr,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Scan host QR code'),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.spaceMd,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSizes.spaceMd,
                                  ),
                                  child: Text(
                                    'OR ENTER MANUALLY',
                                    style: TextStyle(
                                      color: AppColors.inkMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                          ),
                          TextField(
                            controller: _hostController,
                            enabled: !connecting,
                            decoration: const InputDecoration(
                              labelText: 'Host IP address',
                              hintText: '192.168.1.25',
                              prefixIcon: Icon(Icons.router_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSizes.spaceSm),
                          TextField(
                            controller: _portController,
                            enabled: !connecting,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Port',
                            ),
                          ),
                          const SizedBox(height: AppSizes.spaceSm),
                          TextField(
                            controller: _codeController,
                            enabled: !connecting,
                            keyboardType: TextInputType.number,
                            maxLength: AppConstants.pairingCodeLength,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                AppConstants.pairingCodeLength,
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Six-digit pairing code',
                              counterText: '',
                              prefixIcon: Icon(Icons.pin_outlined),
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
                          if (widget.controller.errorMessage !=
                              null) ...<Widget>[
                            const SizedBox(height: AppSizes.spaceMd),
                            ErrorBanner(
                              message: widget.controller.errorMessage!,
                              onDismiss: widget.controller.clearError,
                            ),
                          ],
                          const SizedBox(height: AppSizes.spaceLg),
                          FilledButton.icon(
                            onPressed: connecting ? null : _connect,
                            icon: connecting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.link_rounded),
                            label: Text(
                              connecting
                                  ? _statusLabel(widget.controller.status)
                                  : 'Connect',
                            ),
                          ),
                          if (connecting) ...<Widget>[
                            const SizedBox(height: AppSizes.spaceSm),
                            TextButton(
                              onPressed: widget.controller.disconnect,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(PlayerConnectionStatus status) {
    return switch (status) {
      PlayerConnectionStatus.connecting => 'Connecting…',
      PlayerConnectionStatus.pairing => 'Pairing…',
      PlayerConnectionStatus.reconnecting => 'Reconnecting…',
      _ => 'Connecting…',
    };
  }

  Future<void> _scanQr() async {
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const QrScannerView()),
    );
    if (value != null) {
      await widget.controller.connectFromQr(value);
    }
  }

  Future<void> _connect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final code = _codeController.text.trim();
    if (host.isEmpty ||
        port == null ||
        port < AppConstants.minimumPort ||
        port > AppConstants.maximumPort ||
        !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _validationMessage =
            'Enter a host address, a valid port, and the six-digit code.';
      });
      return;
    }
    setState(() => _validationMessage = null);
    await widget.controller.connect(host: host, port: port, pairingCode: code);
  }
}
