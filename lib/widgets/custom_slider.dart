import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

// Widget reutilizable como StatelessWidget
class CustomSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String? title;
  final bool showPreview;
  final bool showQuickButtons;

  const CustomSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = 'Tamaño de Fuente',
    this.showPreview = true,
    this.showQuickButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Slider principal
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.blue[400],
                  inactiveTrackColor: Colors.grey[300],
                  trackHeight: 6.0,
                  thumbColor: Colors.blue[600],
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  overlayColor: Colors.blue.withValues(alpha: 0.2),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
                ),
                child: Slider(
                  value: value,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  onChanged: onChanged,
                ),
              ),

              // Indicadores de nivel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  int level = index + 1;
                  bool isSelected = value.round() == level;
                  return Column(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue[600]
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$level',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.blue[600]
                              : Colors.grey[500],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),

        // Botones rápidos opcionales
        if (showQuickButtons) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Selección Rápida',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    int level = index + 1;
                    bool isSelected = value.round() == level;
                    return GestureDetector(
                      onTap: () => onChanged(level.toDouble()),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue[600]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$level',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                _getSizeLabel(level),
                                style: TextStyle(
                                  fontSize: 7,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getSizeLabel(int level) {
    switch (level) {
      case 1:
        return 'XS';
      case 2:
        return 'S';
      case 3:
        return 'M';
      case 4:
        return 'L';
      case 5:
        return 'XL';
      default:
        return '';
    }
  }
}

// Versión compacta solo con slider
class CompactCustomSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String? label;
  final IconData icon;
  final double min;
  final double max;
  final int? divisions;

  const CompactCustomSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Label',
    this.icon = Icons.inventory_2,
    this.min = 1.0,
    this.max = 10.0,
    this.divisions = 9,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),

      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(width: 12),
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 0),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.blue[400],
                inactiveTrackColor: Colors.grey[300],
                trackHeight: 4.0,
                thumbColor: AppColors.primary,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 25,
            child: Text(
              '${value.round()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Demo de cómo usar los widgets
class CustomSliderDemo extends StatefulWidget {
  const CustomSliderDemo({super.key});
  @override
  State<CustomSliderDemo> createState() => _CustomSliderDemoState();
}

class _CustomSliderDemoState extends State<CustomSliderDemo> {
  double fontSize = 1.0;
  double compactFontSize = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('FontSize Slider Demo'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Widget completo
            CustomSlider(
              value: fontSize,
              onChanged: (value) {
                setState(() {
                  fontSize = value;
                });
                // Aquí puedes actualizar tu provider
                log('FontSize cambiado a: ${value.round()}');
              },
              title: 'Tamaño Principal',
              showPreview: true,
              showQuickButtons: true,
            ),

            SizedBox(height: 24),

            // Widget compacto
            CompactCustomSlider(
              value: compactFontSize,
              onChanged: (value) {
                setState(() {
                  compactFontSize = value;
                });
              },
              label: 'Compacto',
            ),

            SizedBox(height: 24),

            // Solo slider sin extras
            CustomSlider(
              value: fontSize,
              onChanged: (value) {
                setState(() {
                  fontSize = value;
                });
              },
              title: 'Solo Slider',
              showPreview: false,
              showQuickButtons: false,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: CustomSliderDemo()));
}
