import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

/// Selector compacto [-] valor [+] con etiqueta, para frente / impresiones.
class QuantityStepper extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.inventory_2,
    this.min = 1,
    this.max = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _button(
                Icons.remove,
                value > min ? () => onChanged(value - 1) : null,
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _button(
                Icons.add,
                value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _button(IconData icon, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      color: AppColors.primary,
      disabledColor: AppColors.textTertiary,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }
}
