import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class AppBarBackground extends StatelessWidget {
  const AppBarBackground({
    super.key,
    required this.state,
  });

  final TypeCastState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            state.forumParams[state.currentForum]?.color ?? Colors.blue,
            state.forumParams[state.currentForum]?.darkColor.darken() ??
                Colors.blue,
          ],
        ),
      ),
    );
  }
}
