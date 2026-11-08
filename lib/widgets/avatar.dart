import 'package:flutter/material.dart';

import '../theme.dart';
import 'local_image.dart';

class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const Avatar({super.key, this.url, required this.name, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final initials = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();
    final fallback = Container(
      color: const Color(0xFF0E120A),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: p.accent, fontSize: size * 0.36, fontWeight: FontWeight.w500),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent),
      child: ClipOval(child: url == null || url!.isEmpty ? fallback : appImage(url!, errorBuilder: (_, _, _) => fallback)),
    );
  }
}
