import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class ToolbarCustomPopupBtn extends StatelessWidget {
  final Function(Color) onColorSelected;

  const ToolbarCustomPopupBtn({super.key, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: CustomPopup(
        content: PointerInterceptor(
          child: ElevatedButton(
            onPressed: () => onColorSelected(Colors.red),
            child: Text('Red'),
          ),
        ),
        child: Icon(Icons.format_color_text_outlined),
      ),
    );
  }
}
