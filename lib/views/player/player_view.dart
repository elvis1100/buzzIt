import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/player_controller.dart';
import '../../core/theme.dart';
import '../../models/team.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_pill.dart';
import '../settings/player_settings_dialog.dart';
import 'widgets/buzzer_panel.dart';
import 'widgets/player_connection_view.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlayerController>(
        builder: (context, controller, _) {
          if (!controller.initialized) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!controller.isConnected) {
            return PlayerConnectionView(controller: controller);
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: BuzzerPanel(
                      team: Team.a,
                      name: controller.match.teamAName,
                      color: Color(controller.match.teamAColor),
                      displayedWinner: controller.displayedWinner,
                      enabled: controller.canBuzz,
                      onPressed: () => controller.buzz(Team.a),
                    ),
                  ),
                  Container(width: 3, color: Colors.white),
                  Expanded(
                    child: BuzzerPanel(
                      team: Team.b,
                      name: controller.match.teamBName,
                      color: Color(controller.match.teamBColor),
                      displayedWinner: controller.displayedWinner,
                      enabled: controller.canBuzz,
                      onPressed: () => controller.buzz(Team.b),
                    ),
                  ),
                ],
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spaceSm),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusPill,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSizes.spaceSm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const StatusPill(
                              label: 'Connected',
                              color: AppColors.success,
                              icon: Icons.lan_rounded,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.spaceSm,
                              ),
                              child: Text(
                                'Round ${controller.gameState.roundId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Buzzer settings',
                              onPressed: () =>
                                  _showSettings(context, controller),
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (controller.errorMessage != null)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.spaceMd),
                        child: ErrorBanner(
                          message: controller.errorMessage!,
                          onDismiss: controller.clearError,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSettings(
    BuildContext context,
    PlayerController controller,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => PlayerSettingsDialog(controller: controller),
    );
  }
}
