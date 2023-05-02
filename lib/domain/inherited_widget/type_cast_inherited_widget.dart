import 'package:flutter/material.dart';
import 'package:typecast/main.dart';

class TypeCastInheritedWidget extends InheritedWidget {
  final TypeCastState state;

  const TypeCastInheritedWidget(
      {super.key, required super.child, required this.state});

  @override
  bool updateShouldNotify(covariant TypeCastInheritedWidget oldWidget) {
    return state.currentForum != oldWidget.state.currentForum;
  }

  static TypeCastInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TypeCastInheritedWidget>();
  }
}
