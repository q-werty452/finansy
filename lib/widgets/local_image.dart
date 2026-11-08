import 'package:flutter/material.dart';

import '../state/app_state.dart';

/// Картинка из папки приложения (относительный путь) или из сети
Widget appImage(String path, {BoxFit fit = BoxFit.cover, Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}) {
  if (path.startsWith('http')) return Image.network(path, fit: fit, errorBuilder: errorBuilder);
  return Image.file(AppState.fileOf(path), fit: fit, errorBuilder: errorBuilder);
}
