import 'package:flutter/material.dart';

import '../services/app_info.dart';

/// Titulo del AppBar con la version instalada debajo, en letra pequena.
/// Si la version no esta disponible muestra solo el titulo.
class AppBarTitle extends StatelessWidget {
  final String title;
  final bool centered;

  const AppBarTitle(this.title, {super.key, this.centered = false});

  @override
  Widget build(BuildContext context) {
    final label = AppInfo.label;
    if (label.isEmpty) return Text(title);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title),
        Opacity(
          opacity: 0.8,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
