import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:info_popup/info_popup.dart';
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
  late final InfoPopupController _controller;
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
  void dispose() {
    super.dispose();
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
        child: InfoPopupWidget(
          child: Icon(widget.childIcon),
          customContent: () => PointerInterceptor(child: widget.content),
          infoPopupDismissed: () {
            debugPrint('dismiss');
          },

          // areaBackgroundColor: Colors.white,
          // onControllerCreated: (controller) {
          //   _controller = controller;
          // },

          // child: PointerInterceptor(child: widget.content),
        ),
      ),
    );
    // child: CustomPopup(
    //   anchorKey: GlobalKey(),
    //   content: PointerInterceptor(child: widget.content),
    //   child: Icon(widget.childIcon),
  }
}
