import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/host_controller.dart';
import '../../core/theme.dart';
import '../../widgets/error_banner.dart';
import '../settings/host_settings_dialog.dart';
import 'widgets/game_stage.dart';
import 'widgets/host_header.dart';
import 'widgets/pairing_card.dart';

class HostView extends StatelessWidget {
  const HostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<HostController>(
          builder: (context, controller, _) {
            if (!controller.initialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.desktopMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spaceLg),
                  child: Column(
                    children: <Widget>[
                      HostHeader(
                        controller: controller,
                        onSettings: () => _showSettings(context, controller),
                        onToggleSound: () =>
                            controller.setMobileSoundEnabled(
                              !controller.settings.mobileSoundEnabled,
                            ),
                      ),
                      if (controller.errorMessage != null) ...<Widget>[
                        const SizedBox(height: AppSizes.spaceMd),
                        ErrorBanner(
                          message: controller.errorMessage!,
                          onDismiss: controller.clearError,
                        ),
                      ],
                      const SizedBox(height: AppSizes.spaceLg),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 920) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  SizedBox(
                                    width: 370,
                                    child: PairingCard(controller: controller),
                                  ),
                                  const SizedBox(width: AppSizes.spaceLg),
                                  Expanded(
                                    child: GameStage(controller: controller),
                                  ),
                                ],
                              );
                            }
                            return SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 690,
                                    child: PairingCard(controller: controller),
                                  ),
                                  const SizedBox(height: AppSizes.spaceLg),
                                  SizedBox(
                                    height: 540,
                                    child: GameStage(controller: controller),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showSettings(BuildContext context, HostController controller) {
    return showDialog<void>(
      context: context,
      builder: (_) => HostSettingsDialog(controller: controller),
    );
  }
}
