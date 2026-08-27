import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/team.dart';

class BuzzerPanel extends StatelessWidget {
  const BuzzerPanel({
    required this.team,
    required this.name,
    required this.color,
    required this.displayedWinner,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final Team team;
  final String name;
  final Color color;
  final Team? displayedWinner;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isWinner = displayedWinner == team;
    final isOpponent = displayedWinner != null && !isWinner;
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : AppColors.ink;

    return Semantics(
      button: true,
      enabled: enabled,
      label: '$name buzzer',
      value: isWinner ? 'Winner' : (isOpponent ? 'Locked' : 'Ready'),
      child: AnimatedOpacity(
        opacity: isOpponent ? 0.28 : 1,
        duration: AppDurations.quick,
        child: AnimatedContainer(
          duration: AppDurations.standard,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: color,
            boxShadow: isWinner
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.45),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              splashColor: foreground.withValues(alpha: 0.18),
              highlightColor: foreground.withValues(alpha: 0.1),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    top: -100,
                    right: -70,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: foreground.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -120,
                    left: -80,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: foreground.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.spaceXl),
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: foreground.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.spaceMd,
                                vertical: AppSizes.spaceSm,
                              ),
                              child: Text(
                                team == Team.a ? 'TEAM A' : 'TEAM B',
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedScale(
                            scale: isWinner ? 1.06 : 1,
                            duration: AppDurations.celebratory,
                            curve: Curves.easeOutBack,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                AnimatedSwitcher(
                                  duration: AppDurations.standard,
                                  child: Icon(
                                    isWinner
                                        ? Icons.emoji_events_rounded
                                        : isOpponent
                                        ? Icons.lock_rounded
                                        : Icons.touch_app_rounded,
                                    key: ValueKey<String>(
                                      '$isWinner-$isOpponent',
                                    ),
                                    size: isWinner ? 72 : 58,
                                    color: foreground,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.spaceMd),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: foreground,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.5,
                                      ),
                                ),
                                const SizedBox(height: AppSizes.spaceSm),
                                Text(
                                  isWinner
                                      ? 'YOU HIT FIRST!'
                                      : isOpponent
                                      ? 'ROUND LOCKED'
                                      : 'TAP ANYWHERE',
                                  style: TextStyle(
                                    color: foreground.withValues(alpha: 0.84),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          displayedWinner == null
                              ? 'Ready'
                              : isWinner
                              ? ''
                              : 'Waiting for reset',
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}
