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
              Column(
                children: <Widget>[
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 2,
                      child: BuzzerPanel(
                        team: Team.a,
                        name: controller.match.teamAName,
                        color: Color(controller.match.teamAColor),
                        displayedWinner: controller.displayedWinner,
                        enabled: controller.canBuzz,
                        onPressed: () => controller.buzz(Team.a),
                      ),
                    ),
                  ),
                  Container(height: 3, color: Colors.white),
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
              _SettingsBar(controller: controller),
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

}

class _SettingsBar extends StatefulWidget {
  final PlayerController controller;
  const _SettingsBar({required this.controller});

  @override
  State<_SettingsBar> createState() => _SettingsBarState();
}

class _SettingsBarState extends State<_SettingsBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: _expanded
                ? const EdgeInsets.only(left: AppSizes.spaceSm)
                : const EdgeInsets.all(4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_expanded) ...[
                  const StatusPill(
                    label: 'Connected',
                    color: AppColors.success,
                    icon: Icons.lan_rounded,
                  ),

                  IconButton(
                    tooltip: 'Buzzer settings',
                    onPressed: () => _showSettings(context, widget.controller),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ] else
                  IconButton(
                    tooltip: 'Expand',
                    onPressed: () => setState(() => _expanded = true),
                    icon: const Icon(Icons.menu_rounded),
                  ),
              ],
            ),
          ),
        ),
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
