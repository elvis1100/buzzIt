import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../core/theme.dart';

class TeamEditorCard extends StatelessWidget {
  const TeamEditorCard({
    required this.label,
    required this.nameController,
    required this.color,
    required this.onColorChanged,
    super.key,
  });

  final String label;
  final TextEditingController nameController;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        child: Row(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              onTap: () async {
                final selected = await showAppColorPicker(context, color);
                if (selected != null) {
                  onColorChanged(selected);
                }
              },
              child: Tooltip(
                message: 'Change $label color',
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.24),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color:
                        ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: TextField(
                controller: nameController,
                maxLength: 24,
                decoration: InputDecoration(labelText: label, counterText: ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Color?> showAppColorPicker(BuildContext context, Color initialColor) {
  var selected = initialColor;
  return showDialog<Color>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Choose team color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (color) => selected = color,
            enableAlpha: false,
            displayThumbColor: true,
            hexInputBar: true,
            labelTypes: const <ColorLabelType>[ColorLabelType.hex],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Use color'),
          ),
        ],
      );
    },
  );
}
