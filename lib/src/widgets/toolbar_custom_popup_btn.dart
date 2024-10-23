import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class ToolbarCustomPopupBtn extends StatelessWidget {
  final IconData btnIcon;

  final Widget body;
  // final Function(Color) onBodyBtnClicked;

  const ToolbarCustomPopupBtn({
    super.key,
    required this.btnIcon,
    required this.body,
    // required this.onBodyBtnClicked,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: CustomPopup(
        content: PointerInterceptor(child: body),
        child: Icon(btnIcon),
      ),
    );
  }
}
