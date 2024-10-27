import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class PopupButton extends StatefulWidget {
  final BoxConstraints constraints;
  final Color? iconColor;
  final Color? hoverColor;
  final Color? fillColor;

  final Widget content;
  final IconData childIcon;

  const PopupButton({
    super.key,
    required this.constraints,
    required this.content,
    required this.childIcon,
    this.hoverColor,
    this.fillColor,
    this.iconColor,
  });

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  bool isHover = false;

  late Color hoverColor = widget.hoverColor ?? Colors.white.withOpacity(0.04);
  late Color fillColor = widget.fillColor ?? Colors.white.withOpacity(0.16);
  late Color iconColor = widget.iconColor ?? Colors.white;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.constraints,
      color: (isHover) ? (hoverColor) : (null),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (PointerHoverEvent pe) => setState(() {
          isHover = !isHover;
          print(isHover);
        }),
        child: CustomPopup(
          content: PointerInterceptor(child: widget.content),
          child: Icon(widget.childIcon),
        ),
      ),
    );
  }
}
