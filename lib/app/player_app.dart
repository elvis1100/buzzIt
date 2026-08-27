import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/player_controller.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../views/player/player_view.dart';

class PlayerApp extends StatelessWidget {
  const PlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlayerController>(
      create: (_) => PlayerController()..initialize(),
      child: MaterialApp(
        title: '${AppConstants.appName} Buzzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const PlayerView(),
      ),
    );
  }
}
