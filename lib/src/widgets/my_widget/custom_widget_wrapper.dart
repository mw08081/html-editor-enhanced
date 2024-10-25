import 'package:flutter/material.dart';

class CustomWidgetWrapper extends StatelessWidget {
  const CustomWidgetWrapper({super.key, required this.widgets});

  final List<Widget> widgets;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [...widgets],
    );
  }
}
