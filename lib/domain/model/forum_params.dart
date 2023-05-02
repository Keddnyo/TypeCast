import 'package:flutter/material.dart';

class ForumParams {
  int id;
  String digestTopicId;
  MaterialColor color;
  MaterialColor darkColor;
  int recursive;

  ForumParams({
    required this.id,
    required this.digestTopicId,
    required this.color,
    required this.darkColor,
    required this.recursive,
  });
}
