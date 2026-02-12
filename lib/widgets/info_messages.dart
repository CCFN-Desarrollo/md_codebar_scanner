import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

/// Tipos de mensaje que soporta el box
enum InfoMessageType { success, warning, error }

class InfoMessageBox extends StatelessWidget {
  final String message;
  final InfoMessageType type;
  final bool showIcon;

  const InfoMessageBox({
    super.key,
    required this.message,
    this.type = InfoMessageType.success,
    this.showIcon = true,
  });

  Color _getColor() {
    switch (type) {
      case InfoMessageType.success:
        return AppColors.success;
      case InfoMessageType.warning:
        return AppColors.warning;
      case InfoMessageType.error:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case InfoMessageType.success:
        return Icons.check_circle_outline;
      case InfoMessageType.warning:
        return Icons.warning_amber_rounded;
      case InfoMessageType.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showIcon) Icon(_getIcon(), color: color, size: 20),
              if (showIcon) const SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
