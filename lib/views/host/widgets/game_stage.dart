import 'package:flutter/material.dart';

import '../../../controllers/host_controller.dart';
import '../../../core/theme.dart';
import '../../../models/team.dart';

class GameStage extends StatelessWidget {
  const GameStage({required this.controller, super.key});

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    final winner = controller.gameState.winner;
    final winnerColor = winner == Team.a
        ? Color(controller.match.teamAColor)
        : Color(controller.match.teamBColor);
    final background = winner == null ? AppColors.surface : winnerColor;
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : AppColors.ink;
    final winnerName = winner == Team.a
        ? controller.match.teamAName
        : controller.match.teamBName;

    return AnimatedContainer(
      duration: AppDurations.standard,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: winner == null
              ? AppColors.surfaceMuted
              : foreground.withValues(alpha: 0.18),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: winner == null
                ? AppColors.ink.withValues(alpha: 0.05)
                : winnerColor.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceXl),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Spacer(),
                Text(
                  controller.match.autoResetEnabled
                      ? 'Auto-reset: ${controller.match.autoResetSeconds}s'
                      : 'Manual reset',
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppDurations.standard,
                child: winner == null
                    ? _ReadyState(
                        key: const ValueKey<String>('ready'),
                        foreground: foreground,
                        clientConnected: controller.clientConnected,
                      )
                    : _WinnerState(
                        key: ValueKey<Team>(winner),
                        name: winnerName,
                        foreground: foreground,
                        remainingSeconds: controller.remainingResetSeconds,
                      ),
              ),
            ),
            Wrap(
              spacing: AppSizes.spaceMd,
              runSpacing: AppSizes.spaceMd,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 140,
                  child: _TeamKey(
                    name: controller.match.teamAName,
                    color: Color(controller.match.teamAColor),
                    selected: winner == Team.a,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _TeamKey(
                    name: controller.match.teamBName,
                    color: Color(controller.match.teamBColor),
                    selected: winner == Team.b,
                  ),
                ),
                FilledButton.icon(
                  onPressed: winner == null ? null : controller.resetRound,
                  style: FilledButton.styleFrom(
                    backgroundColor: foreground,
                    foregroundColor: background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spaceLg,
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reset buzzers'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyState extends StatelessWidget {
  const _ReadyState({
    required this.foreground,
    required this.clientConnected,
    super.key,
  });

  final Color foreground;
  final bool clientConnected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(AppSizes.spaceLg),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 62,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceLg),
        Text(
          clientConnected
              ? 'Waiting for a buzz…'
              : 'Connect the buzzer to begin',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Text(
          clientConnected
              ? 'Both teams are active. First tap wins the round.'
              : 'The host is ready and listening on your local network.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foreground.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _WinnerState extends StatelessWidget {
  const _WinnerState({
    required this.name,
    required this.foreground,
    required this.remainingSeconds,
    super.key,
  });

  final String name;
  final Color foreground;
  final int? remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.emoji_events_rounded, size: 72, color: foreground),
        const SizedBox(height: AppSizes.spaceMd),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Text(
          'BUZZED FIRST',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: foreground.withValues(alpha: 0.82),
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        if (remainingSeconds != null) ...<Widget>[
          const SizedBox(height: AppSizes.spaceLg),
          Text(
            'Resetting in $remainingSeconds',
            style: TextStyle(
              color: foreground.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamKey extends StatelessWidget {
  const _TeamKey({
    required this.name,
    required this.color,
    required this.selected,
  });

  final String name;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.quick,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceMd,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.22) : color,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white
              : AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
