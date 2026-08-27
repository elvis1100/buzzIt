import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../controllers/host_controller.dart';
import '../../../core/theme.dart';
import '../../../widgets/status_pill.dart';

class PairingCard extends StatelessWidget {
  const PairingCard({required this.controller, super.key});

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    final pairingPayload = controller.pairingPayload;
    final hasAddress = pairingPayload != null;
    return Card(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              left: AppSizes.spaceLg,
              top: AppSizes.spaceLg,
              right: AppSizes.spaceLg,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Wrap(
                    spacing: AppSizes.spaceMd,
                    runSpacing: AppSizes.spaceSm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        'Connect the buzzer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      StatusPill(
                        label: controller.clientConnected
                            ? 'Buzzer connected'
                            : 'Waiting',
                        color: controller.clientConnected
                            ? AppColors.success
                            : AppColors.warning,
                        icon: controller.clientConnected
                            ? Icons.phone_android_rounded
                            : Icons.hourglass_top_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceSm),
                  Text(
                    'Scan this code from the Android app or enter the details manually.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  if (pairingPayload != null)
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                          border: Border.all(color: AppColors.surfaceMuted),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.spaceMd),
                          child: QrImageView(
                            data: pairingPayload,
                            version: QrVersions.auto,
                            size: 188,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primaryDark,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.primaryDark,
                            ),
                            semanticsLabel: 'BuzzIt pairing QR code',
                          ),
                        ),
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSizes.spaceLg),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 52,
                              color: AppColors.warning,
                            ),
                            SizedBox(height: AppSizes.spaceSm),
                            Text(
                              'QR pairing is unavailable until a private LAN address is detected.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSizes.spaceLg),
                  Text(
                    'PAIRING CODE',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceSm),
                  SelectableText(
                    controller.pairingCode,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  if (hasAddress)
                    DropdownButtonFormField<String>(
                      initialValue: controller.selectedAddress,
                      decoration: const InputDecoration(
                        labelText: 'Host IP address',
                        prefixIcon: Icon(Icons.router_outlined),
                      ),
                      items: controller.localAddresses
                          .map(
                            (address) => DropdownMenuItem<String>(
                              value: address,
                              child: Text(
                                '$address:${controller.settings.port}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectAddress(value);
                        }
                      },
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSizes.spaceMd),
                        child: Text(
                          'No private LAN address was found. Connect this computer to the same Wi-Fi as the phone.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceLg),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.clientConnected
                        ? null
                        : controller.refreshPairingCode,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Generate new code'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
