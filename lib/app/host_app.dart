import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/host_controller.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../views/host/host_view.dart';

class HostApp extends StatelessWidget {
  const HostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HostController>(
      create: (_) => HostController()..initialize(),
      child: MaterialApp(
        title: '${AppConstants.appName} Host',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HostView(),
      ),
    );
  }
}
