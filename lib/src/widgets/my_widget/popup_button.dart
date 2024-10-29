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

  late Color? hoverColor;
  late Color? fillColor;
  late Color? iconColor;

  @override
  void initState() {
    super.initState();

    hoverColor = widget.hoverColor ?? Colors.white.withOpacity(0.04);
    fillColor = (widget.fillColor != null) ? (widget.fillColor!) : (null);
    iconColor = widget.iconColor ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.constraints,
      color: (isHover) ? (hoverColor) : (fillColor),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (PointerEnterEvent pe) => setState(() {
          isHover = true;
        }),
        onExit: (PointerExitEvent pe) => setState(() {
          isHover = false;
        }),
        child: CustomPopup(
          content: PointerInterceptor(child: widget.content),
          child: Icon(widget.childIcon),
        ),
      ),
    );
  }
}
