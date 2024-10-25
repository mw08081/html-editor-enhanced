import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class PopupButton extends StatelessWidget {
  final IconData childIcon;
  final Widget content;

  const PopupButton({
    super.key,
    required this.childIcon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: CustomPopup(
        content: PointerInterceptor(child: content),
        child: Icon(childIcon),
      ),
    );
  }
}
