import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/widgets/my_widget/popup_button.dart';
import 'package:html_editor_enhanced/utils/utils.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'my_widget/custom_widget_wrapper.dart';

/// Toolbar widget class
class ToolbarWidget extends StatefulWidget {
  /// The [HtmlEditorController] is mainly used to call the [execCommand] method
  final HtmlEditorController controller;
  final HtmlToolbarOptions htmlToolbarOptions;
  final Callbacks? callbacks;

  const ToolbarWidget({
    Key? key,
    required this.controller,
    required this.htmlToolbarOptions,
    required this.callbacks,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ToolbarWidgetState();
  }
}

/// Toolbar widget state
class ToolbarWidgetState extends State<ToolbarWidget> {
  /// List that controls which [ToggleButtons] are selected for
  /// bold/italic/underline/clear styles / strikthrough
  List<bool> _fontSelected = List<bool>.filled(5, false);

  /// List that controls which [ToggleButtons] are selected for
  ///   /superscript/subscript
  List<bool> _miscFontSelected = List<bool>.filled(2, false);

  /// List that controls which [ToggleButtons] are selected for
  /// forecolor/backcolor
  List<bool> _colorSelected = List<bool>.filled(2, false);

  /// List that controls which [ToggleButtons] are selected for
  /// ordered/unordered list
  List<bool> _listSelected = List<bool>.filled(2, false);

  /// List that controls which [ToggleButtons] are selected for
  /// fullscreen, codeview, undo, redo, and help. Fullscreen and codeview
  /// are the only buttons that will ever be selected.
  List<bool> _miscSelected = List<bool>.filled(5, false);

  /// List that controls which [ToggleButtons] are selected for
  /// justify left/right/center/full.
  List<bool> _alignSelected = List<bool>.filled(4, false);

  List<bool> _textDirectionSelected = List<bool>.filled(2, false);

  /// Sets the selected item for the font style dropdown
  String _fontSelectedItem = 'p';

  String _fontNameSelectedItem = 'sans-serif';

  /// Sets the selected item for the font size dropdown
  double _fontSizeSelectedItem = 3;

  /// Keeps track of the current font size in px
  double _actualFontSizeSelectedItem = 12;

  /// Sets the selected item for the font units dropdown
  String _fontSizeUnitSelectedItem = 'pt';

  /// Sets the selected item for the foreground color dialog
  Color _foreColorSelected = Colors.black;

  /// colors that can be chosen
  List<Color> colors = [
    Color(0xFFFFFFFF), // #FFFFFF -> 서식취소로 변경
    Color(0xFF000000), // #000000
    Color(0xFF333333), // #333333
    Color(0xFF666666), // #666666
    Color(0xFF9D9D9D), // #9D9D9D
    Color(0xFFDDDDDD), // #DDDDDD
    Color(0xFFFFFFFF), // #FFFFFF
    Color(0xFFEE2323), // #EE2323
    Color(0xFFF89009), // #F89009
    Color(0xFFF3C000), // #F3C000
    Color(0xFF0DB4A0), // #0DB4A0
    Color(0xFF006DD7), // #006DD7
    Color(0xFF8A3DB6), // #8A3DB6
    Color(0xFF72889C), // #72889C
    Color(0xFFFFC1C8), // #ffc1c8
    Color(0xFFFFC9AF), // #ffc9af
    Color(0xFFF6E199), // #f6e199
    Color(0xFF9FEEC3), // #9feec3
    Color(0xFF99CEFA), // #99cefa
    Color(0xFFC1BEF9), // #c1bef9
    Color(0xFFC0D1E7), // #c0d1e7
    Color(0xFFEF5369), // #ef5369
    Color(0xFFEF6F53), // #ef6f53
    Color(0xFFA6BC00), // #a6bc00
    Color(0xFF409D00), // #409d00
    Color(0xFF0493D3), // #0493d3
    Color(0xFF6164C6), // #6164c6
    Color(0xFF8CB3BE), // #8cb3be
    Color(0xFF781B34), // #781b34
    Color(0xFF953B35), // #953b35
    Color(0xFF5F6D2C), // #5f6d2c
    Color(0xFF1B711C), // #1b711c
    Color(0xFF1A5490), // #1a5490
    Color(0xFF5733B1), // #5733b1
    Color(0xFF456771) // #456771
  ];

  /// Sets the selected item for the background color dialog
  Color _backColorSelected = Colors.black;

  /// Sets the selected item for the list style dropdown
  String? _listStyleSelectedItem;

  /// Sets the selected item for the line height dropdown
  double _lineHeightSelectedItem = 1;

  /// Masks the toolbar with a grey color if false
  bool _enabled = true;

  /// Tracks the expanded status of the toolbar
  bool _isExpanded = false;

  @override
  void initState() {
    widget.controller.toolbar = this;
    _isExpanded = widget.htmlToolbarOptions.initiallyExpanded;
    for (var t in widget.htmlToolbarOptions.defaultToolbarButtons) {
      if (t is FontButtons) {
        _fontSelected = List<bool>.filled(t.getIcons1().length, false);
        _miscFontSelected = List<bool>.filled(t.getIcons2().length, false);
      }
      if (t is ColorButtons) {
        _colorSelected = List<bool>.filled(t.getIcons().length, false);
      }
      if (t is ListButtons) {
        _listSelected = List<bool>.filled(t.getIcons().length, false);
      }
      if (t is OtherButtons) {
        _miscSelected = List<bool>.filled(t.getIcons1().length, false);
      }
      if (t is ParagraphButtons) {
        _alignSelected = List<bool>.filled(t.getIcons1().length, false);
      }
    }
    super.initState();
  }

  void disable() {
    setState(mounted, this.setState, () {
      _enabled = false;
    });
  }

  void enable() {
    setState(mounted, this.setState, () {
      _enabled = true;
    });
  }

  /// Updates the toolbar from the JS handler on mobile and the onMessage
  /// listener on web
  void updateToolbar(Map<String, dynamic> json) {
    //get parent element
    String parentElem = json['style'] ?? '';
    //get font name
    var fontName = (json['fontName'] ?? '').toString().replaceAll('"', '');
    //get font size
    var fontSize = double.tryParse(json['fontSize']) ?? 3;
    //get bold/underline/italic status
    var fontList = (json['font'] as List<dynamic>).cast<bool?>();
    //get superscript/subscript/strikethrough status
    var miscFontList = (json['miscFont'] as List<dynamic>).cast<bool?>();
    //get forecolor/backcolor
    var colorList = (json['color'] as List<dynamic>).cast<String?>();
    //get ordered/unordered list status
    var paragraphList = (json['paragraph'] as List<dynamic>).cast<bool?>();
    //get justify status
    var alignList = (json['align'] as List<dynamic>).cast<bool?>();
    //get line height
    String lineHeight = json['lineHeight'] ?? '';
    //get list icon type
    String listType = json['listStyle'] ?? '';
    //get text direction
    String textDir = json['direction'] ?? 'ltr';
    //check the parent element if it matches one of the predetermined styles and update the toolbar
    if (['pre', 'blockquote', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']
        .contains(parentElem)) {
      setState(mounted, this.setState, () {
        _fontSelectedItem = parentElem;
      });
    } else {
      setState(mounted, this.setState, () {
        _fontSelectedItem = 'p';
      });
    }
    //check the font name if it matches one of the predetermined fonts and update the toolbar
    if (['Courier New', 'sans-serif', 'Times New Roman'].contains(fontName)) {
      setState(mounted, this.setState, () {
        _fontNameSelectedItem = fontName;
      });
    } else {
      setState(mounted, this.setState, () {
        _fontNameSelectedItem = 'sans-serif';
      });
    }
    //update the fore/back selected color if necessary
    if (colorList[0] != null && colorList[0]!.isNotEmpty) {
      setState(mounted, this.setState, () {
        var rgb = colorList[0]!.replaceAll('rgb(', '').replaceAll(')', '');
        var rgbList = rgb.split(', ');
        _foreColorSelected = Color.fromRGBO(int.parse(rgbList[0]),
            int.parse(rgbList[1]), int.parse(rgbList[2]), 1);
      });
    } else {
      setState(mounted, this.setState, () {
        _foreColorSelected = Colors.black;
      });
    }
    if (colorList[1] != null && colorList[1]!.isNotEmpty) {
      setState(mounted, this.setState, () {
        print(1);
        _backColorSelected =
            Color(int.parse(colorList[1]!, radix: 16) + 0xFF000000);
      });
    } else {
      setState(mounted, this.setState, () {
        // print(2);
        // _backColorSelected = Colors.black;
      });
    }
    //check the list style if it matches one of the predetermined styles and update the toolbar
    if ([
      'decimal',
      'lower-alpha',
      'upper-alpha',
      'lower-roman',
      'upper-roman',
      'disc',
      'circle',
      'square'
    ].contains(listType)) {
      setState(mounted, this.setState, () {
        _listStyleSelectedItem = listType;
      });
    } else {
      _listStyleSelectedItem = null;
    }
    //update the lineheight selected item if necessary
    if (lineHeight.isNotEmpty && lineHeight.endsWith('px')) {
      var lineHeightDouble =
          double.tryParse(lineHeight.replaceAll('px', '')) ?? 16;
      var lineHeights = <double>[1, 1.2, 1.4, 1.5, 1.6, 1.8, 2, 3];
      lineHeights =
          lineHeights.map((e) => e * _actualFontSizeSelectedItem).toList();
      if (lineHeights.contains(lineHeightDouble)) {
        setState(mounted, this.setState, () {
          _lineHeightSelectedItem =
              lineHeightDouble / _actualFontSizeSelectedItem;
        });
      }
    } else if (lineHeight == 'normal') {
      setState(mounted, this.setState, () {
        _lineHeightSelectedItem = 1.0;
      });
    }
    //check if the font size matches one of the predetermined sizes and update the toolbar
    if ([1, 2, 3, 4, 5, 6, 7].contains(fontSize)) {
      setState(mounted, this.setState, () {
        _fontSizeSelectedItem = fontSize;
      });
    }
    if (textDir == 'ltr') {
      setState(mounted, this.setState, () {
        _textDirectionSelected = [true, false];
      });
    } else if (textDir == 'rtl') {
      setState(mounted, this.setState, () {
        _textDirectionSelected = [false, true];
      });
    }
    //use the remaining bool lists to update the selected items accordingly
    setState(mounted, this.setState, () {
      for (var t in widget.htmlToolbarOptions.defaultToolbarButtons) {
        if (t is FontButtons) {
          for (var i = 0; i < _fontSelected.length; i++) {
            if (t.getIcons1()[i].icon == Icons.format_bold) {
              _fontSelected[i] = fontList[0] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_italic) {
              _fontSelected[i] = fontList[1] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_underline) {
              _fontSelected[i] = fontList[2] ?? false;
            }
          }
          for (var i = 0; i < _miscFontSelected.length; i++) {
            if (t.getIcons2()[i].icon == Icons.format_strikethrough) {
              _miscFontSelected[i] = miscFontList[0] ?? false;
            }
            if (t.getIcons2()[i].icon == Icons.superscript) {
              _miscFontSelected[i] = miscFontList[1] ?? false;
            }
            if (t.getIcons2()[i].icon == Icons.subscript) {
              _miscFontSelected[i] = miscFontList[2] ?? false;
            }
          }
        }
        if (t is ListButtons) {
          for (var i = 0; i < _listSelected.length; i++) {
            if (t.getIcons()[i].icon == Icons.format_list_bulleted) {
              _listSelected[i] = paragraphList[0] ?? false;
            }
            if (t.getIcons()[i].icon == Icons.format_list_numbered) {
              _listSelected[i] = paragraphList[1] ?? false;
            }
          }
        }
        if (t is ParagraphButtons) {
          for (var i = 0; i < _alignSelected.length; i++) {
            if (t.getIcons1()[i].icon == Icons.format_align_left) {
              _alignSelected[i] = alignList[0] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_align_center) {
              _alignSelected[i] = alignList[1] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_align_right) {
              _alignSelected[i] = alignList[2] ?? false;
            }
            if (t.getIcons1()[i].icon == Icons.format_align_justify) {
              _alignSelected[i] = alignList[3] ?? false;
            }
          }
        }
      }
    });
    if (widget.callbacks?.onChangeSelection != null) {
      widget.callbacks!.onChangeSelection!.call(EditorSettings(
          parentElement: parentElem,
          fontName: fontName,
          fontSize: fontSize,
          isBold: fontList[0] ?? false,
          isItalic: fontList[1] ?? false,
          isUnderline: fontList[2] ?? false,
          isStrikethrough: miscFontList[0] ?? false,
          isSuperscript: miscFontList[1] ?? false,
          isSubscript: miscFontList[2] ?? false,
          foregroundColor: _foreColorSelected,
          backgroundColor: _backColorSelected,
          isUl: paragraphList[0] ?? false,
          isOl: paragraphList[1] ?? false,
          isAlignLeft: alignList[0] ?? false,
          isAlignCenter: alignList[1] ?? false,
          isAlignRight: alignList[2] ?? false,
          isAlignJustify: alignList[3] ?? false,
          lineHeight: _lineHeightSelectedItem,
          textDirection:
              textDir == 'rtl' ? TextDirection.rtl : TextDirection.ltr));
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.setFocus();
    print('controller set focus');
    if (widget.htmlToolbarOptions.toolbarType == ToolbarType.nativeGrid) {
      return PointerInterceptor(
        child: AbsorbPointer(
          absorbing: !_enabled,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Wrap(
                runSpacing: widget.htmlToolbarOptions.gridViewVerticalSpacing,
                spacing: widget.htmlToolbarOptions.gridViewHorizontalSpacing,
                children: _buildChildren(),
              ),
            ),
          ),
        ),
      );
    } else if (widget.htmlToolbarOptions.toolbarType ==
        ToolbarType.nativeScrollable) {
      return PointerInterceptor(
        child: AbsorbPointer(
          absorbing: !_enabled,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: Container(
              color: Colors.grey.shade100,
              height: widget.htmlToolbarOptions.toolbarItemHeight + 15,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: CustomScrollView(
                  scrollDirection: Axis.horizontal,
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Row(
                        children: _buildChildren(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else if (widget.htmlToolbarOptions.toolbarType ==
        ToolbarType.nativeExpandable) {
      return PointerInterceptor(
        child: AbsorbPointer(
          absorbing: !_enabled,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: _isExpanded
                    ? MediaQuery.of(context).size.height
                    : widget.htmlToolbarOptions.toolbarItemHeight + 15,
              ),
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Wrap(
                        runSpacing:
                            widget.htmlToolbarOptions.gridViewVerticalSpacing,
                        spacing:
                            widget.htmlToolbarOptions.gridViewHorizontalSpacing,
                        children: _buildChildren()
                          ..insert(
                              0,
                              Container(
                                height:
                                    widget.htmlToolbarOptions.toolbarItemHeight,
                                child: IconButton(
                                  icon: Icon(
                                    _isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () async {
                                    setState(mounted, this.setState, () {
                                      _isExpanded = !_isExpanded;
                                    });
                                    await Future.delayed(
                                        Duration(milliseconds: 100));
                                    if (kIsWeb) {
                                      widget.controller.recalculateHeight();
                                    } else {
                                      await widget.controller.editorController!
                                          .evaluateJavascript(
                                              source:
                                                  "var height = \$('div.note-editable').outerHeight(true); window.flutter_inappwebview.callHandler('setHeight', height);");
                                    }
                                  },
                                ),
                              )),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: ExpandIconDelegate(
                                widget.htmlToolbarOptions.toolbarItemHeight,
                                _isExpanded, () async {
                              setState(mounted, this.setState, () {
                                _isExpanded = !_isExpanded;
                              });
                              await Future.delayed(Duration(milliseconds: 100));
                              if (kIsWeb) {
                                widget.controller.recalculateHeight();
                              } else {
                                await widget.controller.editorController!
                                    .evaluateJavascript(
                                        source:
                                            "var height = \$('div.note-editable').outerHeight(true); window.flutter_inappwebview.callHandler('setHeight', height);");
                              }
                            }),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _buildChildren(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );
    }
    return Container(height: 0, width: 0);
  }

  // 앞에 0 3개는 사용 안함 (index 정리) +++ font size is only int!!!!!
  final TextStyle trailingTextStyle =
      TextStyle(fontSize: 15, color: Colors.black);
  List<int> _actualFontSizeList = [0, 0, 0, 12, 14, 18, 24, 36];
  void _setFontSize(int fontSize) {
    setState(mounted, this.setState, () {
      // js
      widget.controller.execCommand('fontSize', argument: fontSize.toString());

      // editor
      _actualFontSizeSelectedItem = _actualFontSizeList[fontSize] as double;

      // pop
      Navigator.pop(context);
    });
  }

  void _setColor(String command, Color newColor) {
    widget.controller.execCommand(command,
        argument: (newColor.value & 0xFFFFFF)
            .toRadixString(16)
            .padLeft(6, '0')
            .toUpperCase());
  }

  List<Widget> _buildChildren() {
    TextEditingController foreColorHexController =
        TextEditingController(text: '#${_foreColorSelected.hex}');
    TextEditingController backColorHexController =
        TextEditingController(text: '#${_backColorSelected.hex}');

    var toolbarChildren = <Widget>[];
    for (var t in widget.htmlToolbarOptions.defaultToolbarButtons) {
      if (t is StyleButtons && t.style) {
        toolbarChildren.add(Container(
          padding: const EdgeInsets.only(left: 8.0),
          height: widget.htmlToolbarOptions.toolbarItemHeight,
          decoration: !widget.htmlToolbarOptions.renderBorder
              ? null
              : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                  BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.12))),
          child: CustomDropdownButtonHideUnderline(
            child: CustomDropdownButton<String>(
              elevation: widget.htmlToolbarOptions.dropdownElevation,
              icon: widget.htmlToolbarOptions.dropdownIcon,
              iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
              iconSize: widget.htmlToolbarOptions.dropdownIconSize,
              itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
              focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
              dropdownColor: widget.htmlToolbarOptions.dropdownBackgroundColor,
              menuDirection: widget.htmlToolbarOptions.dropdownMenuDirection ??
                  (widget.htmlToolbarOptions.toolbarPosition ==
                          ToolbarPosition.belowEditor
                      ? DropdownMenuDirection.up
                      : DropdownMenuDirection.down),
              menuMaxHeight: widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                  MediaQuery.of(context).size.height / 3,
              style: widget.htmlToolbarOptions.textStyle,
              items: [
                CustomDropdownMenuItem(
                    value: 'p',
                    child: PointerInterceptor(child: Text('Normal'))),
                CustomDropdownMenuItem(
                    value: 'blockquote',
                    child: PointerInterceptor(
                      child: Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  left: BorderSide(
                                      color: Colors.grey, width: 3.0))),
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('Quote',
                              style: TextStyle(
                                  fontFamily: 'times', color: Colors.grey))),
                    )),
                CustomDropdownMenuItem(
                    value: 'pre',
                    child: PointerInterceptor(
                      child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.grey),
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('Code',
                              style: TextStyle(
                                  fontFamily: 'courier', color: Colors.white))),
                    )),
                CustomDropdownMenuItem(
                  value: 'h1',
                  child: PointerInterceptor(
                      child: Text('Header 1',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 32))),
                ),
                CustomDropdownMenuItem(
                  value: 'h2',
                  child: PointerInterceptor(
                      child: Text('Header 2',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24))),
                ),
                CustomDropdownMenuItem(
                  value: 'h3',
                  child: PointerInterceptor(
                      child: Text('Header 3',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18))),
                ),
                CustomDropdownMenuItem(
                  value: 'h4',
                  child: PointerInterceptor(
                      child: Text('Header 4',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16))),
                ),
                CustomDropdownMenuItem(
                  value: 'h5',
                  child: PointerInterceptor(
                      child: Text('Header 5',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13))),
                ),
                CustomDropdownMenuItem(
                  value: 'h6',
                  child: PointerInterceptor(
                      child: Text('Header 6',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11))),
                ),
              ],
              value: _fontSelectedItem,
              onChanged: (String? changed) async {
                void updateSelectedItem(dynamic changed) {
                  if (changed is String) {
                    setState(mounted, this.setState, () {
                      _fontSelectedItem = changed;
                    });
                  }
                }

                if (changed != null) {
                  var proceed =
                      await widget.htmlToolbarOptions.onDropdownChanged?.call(
                              DropdownType.style,
                              changed,
                              updateSelectedItem) ??
                          true;
                  if (proceed) {
                    widget.controller
                        .execCommand('formatBlock', argument: changed);
                    updateSelectedItem(changed);
                  }
                }
              },
            ),
          ),
        ));
      }
      if (t is FontSettingButtons) {
        toolbarChildren.add(CustomWidgetWrapper(widgets: [
          const SizedBox(width: 30),
          if (t.fontName == true) Text('fontName ▼'),
          if (t.fontSize == true)
            PopupButton(
              contentPadding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Text(
                        '$_actualFontSizeSelectedItem $_fontSizeUnitSelectedItem    '),
                    Text('▼', style: TextStyle(fontSize: 12))
                  ],
                ),
              ),
              content: Container(
                width: 200,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                        titleAlignment: ListTileTitleAlignment.center,
                        title: Text('가나다',
                            style:
                                TextStyle(fontSize: 36, color: Colors.black)),
                        trailing: Text('36 pt', style: trailingTextStyle),
                        onTap: () => _setFontSize(7)),
                    ListTile(
                      title: Text('가나다',
                          style: TextStyle(fontSize: 24, color: Colors.black)),
                      trailing: Text('24 pt', style: trailingTextStyle),
                      onTap: () => _setFontSize(6),
                    ),
                    ListTile(
                      title: Text('가나다',
                          style: TextStyle(fontSize: 18, color: Colors.black)),
                      trailing: Text('18 pt', style: trailingTextStyle),
                      onTap: () => _setFontSize(5),
                    ),
                    ListTile(
                      title: Text('가나다',
                          style: TextStyle(fontSize: 14, color: Colors.black)),
                      trailing: Text('14 pt', style: trailingTextStyle),
                      onTap: () => _setFontSize(4),
                    ),
                    ListTile(
                      title: Text('가나다',
                          style: TextStyle(fontSize: 12, color: Colors.black)),
                      trailing: Text('12 pt', style: trailingTextStyle),
                      onTap: () => _setFontSize(3),
                    ),
                  ],
                ),
              ),
              constraints: BoxConstraints.tightFor(
                width: 70,
                height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              ),
            ),
        ]));
        if (t.fontSizeUnit) {
          toolbarChildren.add(Container(
            padding: const EdgeInsets.only(left: 8.0),
            height: widget.htmlToolbarOptions.toolbarItemHeight,
            decoration: !widget.htmlToolbarOptions.renderBorder
                ? null
                : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                    BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12))),
            child: CustomDropdownButtonHideUnderline(
              child: CustomDropdownButton<String>(
                elevation: widget.htmlToolbarOptions.dropdownElevation,
                icon: widget.htmlToolbarOptions.dropdownIcon,
                iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
                iconSize: widget.htmlToolbarOptions.dropdownIconSize,
                itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
                focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
                dropdownColor:
                    widget.htmlToolbarOptions.dropdownBackgroundColor,
                menuDirection:
                    widget.htmlToolbarOptions.dropdownMenuDirection ??
                        (widget.htmlToolbarOptions.toolbarPosition ==
                                ToolbarPosition.belowEditor
                            ? DropdownMenuDirection.up
                            : DropdownMenuDirection.down),
                menuMaxHeight:
                    widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                        MediaQuery.of(context).size.height / 3,
                style: widget.htmlToolbarOptions.textStyle,
                items: [
                  CustomDropdownMenuItem(
                    value: 'pt',
                    child: PointerInterceptor(child: Text('pt')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'px',
                    child: PointerInterceptor(child: Text('px')),
                  ),
                ],
                value: _fontSizeUnitSelectedItem,
                onChanged: (String? changed) async {
                  void updateSelectedItem(dynamic changed) {
                    if (changed is String) {
                      setState(mounted, this.setState, () {
                        _fontSizeUnitSelectedItem = changed;
                      });
                    }
                  }

                  if (changed != null) {
                    var proceed =
                        await widget.htmlToolbarOptions.onDropdownChanged?.call(
                                DropdownType.fontSizeUnit,
                                changed,
                                updateSelectedItem) ??
                            true;
                    if (proceed) {
                      updateSelectedItem(changed);
                    }
                  }
                },
              ),
            ),
          ));
        }
      }
      if (t is FontButtons) {
        if (t.bold ||
            t.italic ||
            t.underline ||
            t.clearAll ||
            t.strikethrough) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                setState(mounted, this.setState, () {
                  _fontSelected[index] = !_fontSelected[index];
                });
              }

              if (t.getIcons1()[index].icon == Icons.format_bold) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.bold, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('bold');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_italic) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.italic, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('italic');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_underline) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.underline, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('underline');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_clear) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.clearFormatting, null, null) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('removeFormat');
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_strikethrough) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.strikethrough, _fontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('strikeThrough');
                  updateStatus();
                }
              }

              print(index);
            },
            isSelected: _fontSelected,
            children: t.getIcons1(),
          ));
        }
        if (t.superscript || t.subscript) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                setState(mounted, this.setState, () {
                  _miscFontSelected[index] = !_miscFontSelected[index];
                });
              }

              if (t.getIcons2()[index].icon == Icons.superscript) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.superscript, _miscFontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('superscript');
                  updateStatus();
                }
              }
              if (t.getIcons2()[index].icon == Icons.subscript) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.subscript, _miscFontSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('subscript');
                  updateStatus();
                }
              }
            },
            isSelected: _miscFontSelected,
            children: t.getIcons2(),
          ));
        }
      }
      if (t is ColorButtons && (t.foregroundColor || t.highlightColor)) {
        // 팝업 버튼에 스타일을 적용하고,
        // 두 버튼을 custom wrap로 감싸서 List[widget, widet] -> Widget
        // 리턴하여 추가해보쟈..

        toolbarChildren.add(
          CustomWidgetWrapper(
            widgets: [
              PopupButton(
                child: Icon(Icons.format_color_text, color: _foreColorSelected),
                content: Container(
                  width: 200,
                  height: 220,
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, // 한 줄에 표시할 색상 수
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: colors.length,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              child: Container(
                                child: Icon(Icons.dnd_forwardslash_sharp,
                                    color: Colors.black),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: (colors[index] == Colors.white)
                                          ? Colors.black
                                          : colors[index], // Border color
                                      width: 0.001 // Border width
                                      ),
                                  shape: BoxShape.circle,
                                  color: colors[index],
                                ),
                                clipBehavior: Clip.hardEdge,
                              ),
                              onTap: () {
                                setState(mounted, this.setState, () {
                                  _foreColorSelected = Colors.black;
                                });

                                _setColor('foreColor', Colors.black);
                                Navigator.of(context).pop();
                              },
                            );
                          } else {
                            return GestureDetector(
                              onTap: () {
                                late Color newColor = colors[index];

                                _setColor('foreColor', newColor);

                                setState(mounted, this.setState, () {
                                  _foreColorSelected = newColor;
                                  // print(_foreColorSelected.toString());
                                  Navigator.pop(context);
                                });
                              },
                              child: Container(
                                child: (_foreColorSelected == colors[index])
                                    ? (Icon(
                                        Icons.check,
                                        size: 17.5,
                                        color: (colors[index] == Colors.white)
                                            ? Colors.black
                                            : Colors.white,
                                      ))
                                    : (null),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: (colors[index] == Colors.white)
                                          ? Colors.black
                                          : colors[index], // Border color
                                      width: 0.5 // Border width
                                      ),
                                  shape: BoxShape.circle,
                                  color: colors[index],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 5.0),
                      Divider(),
                      SizedBox(height: 5.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: foreColorHexController,
                              decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.colorize_sharp),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none),
                            ),
                          ),
                          TextButton(
                              onPressed: () {
                                try {
                                  if (foreColorHexController.text.length != 7)
                                    throw ('should input format like #ffeeff');

                                  Color newColor =
                                      foreColorHexController.text.toColor;

                                  if (foreColorHexController.text !=
                                          "#000000" &&
                                      newColor == Colors.black) {
                                    throw ('should input HEX Range rValue like #ffeeff');
                                  }

                                  _setColor('foreColor', newColor);

                                  setState(mounted, this.setState, () {
                                    _foreColorSelected = newColor;
                                    Navigator.pop(context);
                                  });
                                } catch (err) {
                                  debugPrint(err.toString());
                                }
                              },
                              child: Text('입력')),
                        ],
                      ),
                    ],
                  ),
                ),
                constraints: BoxConstraints.tightFor(
                  width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
                  height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
                ),
              ),
              PopupButton(
                child: Icon(Icons.format_color_fill, color: _backColorSelected),
                content: Container(
                  color: Colors.white,
                  width: 200,
                  height: 220,
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, // 한 줄에 표시할 색상 수
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: colors.length,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              child: Container(
                                child: Icon(Icons.dnd_forwardslash_sharp,
                                    color: Colors.black),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: (colors[index] == Colors.white)
                                          ? Colors.black
                                          : colors[index], // Border color
                                      width: 0.001 // Border width
                                      ),
                                  shape: BoxShape.circle,
                                  color: colors[index],
                                ),
                                clipBehavior: Clip.hardEdge,
                              ),
                              onTap: () {
                                setState(mounted, this.setState, () {
                                  _backColorSelected = Colors.black;
                                });

                                widget.controller.execCommand('hiliteColor',
                                    argument: 'initial');
                                Navigator.of(context).pop();
                              },
                            );
                          } else {
                            return GestureDetector(
                              child: Container(
                                child: (_backColorSelected == colors[index])
                                    ? (Icon(
                                        Icons.check,
                                        size: 17.5,
                                        color: (colors[index] == Colors.white)
                                            ? Colors.black
                                            : Colors.white,
                                      ))
                                    : (null),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: (colors[index] == Colors.white)
                                          ? Colors.black
                                          : colors[index], // Border color
                                      width: 0.5 // Border width
                                      ),
                                  shape: BoxShape.circle,
                                  color: colors[index],
                                ),
                              ),
                              onTap: () {
                                late Color newColor = colors[index];

                                _setColor('hiliteColor', newColor);
                                setState(mounted, this.setState, () {
                                  _backColorSelected = newColor;
                                  Navigator.pop(context);
                                });
                              },
                            );
                          }
                        },
                      ),
                      SizedBox(height: 5.0),
                      Divider(),
                      SizedBox(height: 5.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: backColorHexController,
                              decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.color_lens),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none),
                            ),
                          ),
                          TextButton(
                              onPressed: () {
                                try {
                                  if (backColorHexController.text.length != 7)
                                    throw ('should input format like #ffeeff');

                                  Color newColor =
                                      backColorHexController.text.toColor;

                                  if (backColorHexController.text !=
                                          "#000000" &&
                                      newColor == Colors.black) {
                                    throw ('should input HEX Range Value like #ffeeff');
                                  }

                                  _setColor('hiliteColor', newColor);
                                  setState(mounted, this.setState, () {
                                    _backColorSelected = newColor;
                                    Navigator.pop(context);
                                  });
                                } catch (err) {
                                  debugPrint(err.toString());
                                }
                              },
                              child: Text('입력')),
                        ],
                      ),
                    ],
                  ),
                ),
                constraints: BoxConstraints.tightFor(
                  width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
                  height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
                ),
              ),
            ],
          ),
        );
        //
        // toolbarChildren.add(ToggleButtons(
        //   constraints: BoxConstraints.tightFor(
        //     width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
        //     height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
        //   ),
        //   color: widget.htmlToolbarOptions.buttonColor,
        //   selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
        //   fillColor: widget.htmlToolbarOptions.buttonFillColor,
        //   focusColor: widget.htmlToolbarOptions.buttonFocusColor,
        //   highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
        //   hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
        //   splashColor: widget.htmlToolbarOptions.buttonSplashColor,
        //   selectedBorderColor:
        //       widget.htmlToolbarOptions.buttonSelectedBorderColor,
        //   borderColor: widget.htmlToolbarOptions.buttonBorderColor,
        //   borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
        //   borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
        //   renderBorder: widget.htmlToolbarOptions.renderBorder,
        //   textStyle: widget.htmlToolbarOptions.textStyle,
        //   onPressed: (int index) async {
        //     void updateStatus(Color? color) {
        //       setState(mounted, this.setState, () {
        //         _colorSelected[index] = !_colorSelected[index];
        //         if (color != null &&
        //             t.getIcons()[index].icon == Icons.format_color_text) {
        //           _foreColorSelected = color;
        //         }
        //         if (color != null &&
        //             t.getIcons()[index].icon == Icons.format_color_fill) {
        //           _backColorSelected = color;
        //         }
        //       });
        //     }
        //
        //     if (_colorSelected[index]) {
        //       if (t.getIcons()[index].icon == Icons.format_color_text) {
        //         var proceed = await widget.htmlToolbarOptions.onButtonPressed
        //                 ?.call(ButtonType.foregroundColor,
        //                     _colorSelected[index], updateStatus) ??
        //             true;
        //         if (proceed) {
        //           widget.controller.execCommand('foreColor',
        //               argument: (Colors.black.value & 0xFFFFFF)
        //                   .toRadixString(16)
        //                   .padLeft(6, '0')
        //                   .toUpperCase());
        //           updateStatus(null);
        //         }
        //       }
        //       if (t.getIcons()[index].icon == Icons.format_color_fill) {
        //         var proceed = await widget.htmlToolbarOptions.onButtonPressed
        //                 ?.call(ButtonType.highlightColor, _colorSelected[index],
        //                     updateStatus) ??
        //             true;
        //         if (proceed) {
        //           widget.controller.execCommand('hiliteColor',
        //               argument: (Colors.yellow.value & 0xFFFFFF)
        //                   .toRadixString(16)
        //                   .padLeft(6, '0')
        //                   .toUpperCase());
        //           updateStatus(null);
        //         }
        //       }
        //     } else {
        //       var proceed = true;
        //       if (t.getIcons()[index].icon == Icons.format_color_text) {
        //         proceed = await widget.htmlToolbarOptions.onButtonPressed?.call(
        //                 ButtonType.foregroundColor,
        //                 _colorSelected[index],
        //                 updateStatus) ??
        //             true;
        //       } else if (t.getIcons()[index].icon == Icons.format_color_fill) {
        //         proceed = await widget.htmlToolbarOptions.onButtonPressed?.call(
        //                 ButtonType.highlightColor,
        //                 _colorSelected[index],
        //                 updateStatus) ??
        //             true;
        //       }
        //       if (proceed) {
        //         late Color newColor;
        //         if (t.getIcons()[index].icon == Icons.format_color_text) {
        //           newColor = _foreColorSelected;
        //         } else {
        //           newColor = _backColorSelected;
        //         }
        //         await showDialog(
        //             context: context,
        //             builder: (BuildContext context) {
        //               return PointerInterceptor(
        //                 child: AlertDialog(
        //                   scrollable: true,
        //                   content: ColorPicker(
        //                     color: newColor,
        //                     onColorChanged: (color) {
        //                       newColor = color;
        //                     },
        //                     title: Text('Choose a Color',
        //                         style:
        //                             Theme.of(context).textTheme.headlineSmall),
        //                     width: 40,
        //                     height: 40,
        //                     spacing: 0,
        //                     runSpacing: 0,
        //                     borderRadius: 0,
        //                     wheelDiameter: 165,
        //                     enableOpacity: false,
        //                     showColorCode: true,
        //                     colorCodeHasColor: true,
        //                     pickersEnabled: <ColorPickerType, bool>{
        //                       ColorPickerType.wheel: true,
        //                     },
        //                     copyPasteBehavior:
        //                         const ColorPickerCopyPasteBehavior(
        //                       parseShortHexCode: true,
        //                     ),
        //                     actionButtons: const ColorPickerActionButtons(
        //                       dialogActionButtons: true,
        //                     ),
        //                   ),
        //                   actions: <Widget>[
        //                     TextButton(
        //                       onPressed: () {
        //                         Navigator.of(context).pop();
        //                       },
        //                       child: Text('Cancel'),
        //                     ),
        //                     TextButton(
        //                         onPressed: () {
        //                           if (t.getIcons()[index].icon ==
        //                               Icons.format_color_text) {
        //                             setState(mounted, this.setState, () {
        //                               _foreColorSelected = Colors.black;
        //                             });
        //                             widget.controller.execCommand(
        //                                 'removeFormat',
        //                                 argument: 'foreColor');
        //                             widget.controller.execCommand('foreColor',
        //                                 argument: 'initial');
        //                           }
        //                           if (t.getIcons()[index].icon ==
        //                               Icons.format_color_fill) {
        //                             setState(mounted, this.setState, () {
        //                               _backColorSelected = Colors.yellow;
        //                             });
        //                             widget.controller.execCommand(
        //                                 'removeFormat',
        //                                 argument: 'hiliteColor');
        //                             widget.controller.execCommand('hiliteColor',
        //                                 argument: 'initial');
        //                           }
        //                           Navigator.of(context).pop();
        //                         },
        //                         child: Text('Reset to default color')),
        //                     TextButton(
        //                       onPressed: () {
        //                         if (t.getIcons()[index].icon ==
        //                             Icons.format_color_text) {
        //                           widget.controller.execCommand('foreColor',
        //                               argument: (newColor.value & 0xFFFFFF)
        //                                   .toRadixString(16)
        //                                   .padLeft(6, '0')
        //                                   .toUpperCase());
        //                           setState(mounted, this.setState, () {
        //                             _foreColorSelected = newColor;
        //                           });
        //                         }
        //                         if (t.getIcons()[index].icon ==
        //                             Icons.format_color_fill) {
        //                           widget.controller.execCommand('hiliteColor',
        //                               argument: (newColor.value & 0xFFFFFF)
        //                                   .toRadixString(16)
        //                                   .padLeft(6, '0')
        //                                   .toUpperCase());
        //                           setState(mounted, this.setState, () {
        //                             _backColorSelected = newColor;
        //                           });
        //                         }
        //                         setState(mounted, this.setState, () {
        //                           _colorSelected[index] =
        //                               !_colorSelected[index];
        //                         });
        //                         Navigator.of(context).pop();
        //                       },
        //                       child: Text('Set color'),
        //                     )
        //                   ],
        //                 ),
        //               );
        //             });
        //       }
        //     }
        //   },
        //   isSelected: _colorSelected,
        //   children: t.getIcons(),
        // ));
      }
      if (t is ListButtons) {
        if (t.ul || t.ol) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                setState(mounted, this.setState, () {
                  _listSelected[index] = !_listSelected[index];
                });
              }

              if (t.getIcons()[index].icon == Icons.format_list_bulleted) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.ul, _listSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('insertUnorderedList');
                  updateStatus();
                }
              }
              if (t.getIcons()[index].icon == Icons.format_list_numbered) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.ol, _listSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('insertOrderedList');
                  updateStatus();
                }
              }
            },
            isSelected: _listSelected,
            children: t.getIcons(),
          ));
        }
        if (t.listStyles) {
          toolbarChildren.add(Container(
            padding: const EdgeInsets.only(left: 8.0),
            height: widget.htmlToolbarOptions.toolbarItemHeight,
            decoration: !widget.htmlToolbarOptions.renderBorder
                ? null
                : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                    BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12))),
            child: CustomDropdownButtonHideUnderline(
              child: CustomDropdownButton<String>(
                elevation: widget.htmlToolbarOptions.dropdownElevation,
                icon: widget.htmlToolbarOptions.dropdownIcon,
                iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
                iconSize: widget.htmlToolbarOptions.dropdownIconSize,
                itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
                focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
                dropdownColor:
                    widget.htmlToolbarOptions.dropdownBackgroundColor,
                menuDirection:
                    widget.htmlToolbarOptions.dropdownMenuDirection ??
                        (widget.htmlToolbarOptions.toolbarPosition ==
                                ToolbarPosition.belowEditor
                            ? DropdownMenuDirection.up
                            : DropdownMenuDirection.down),
                menuMaxHeight:
                    widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                        MediaQuery.of(context).size.height / 3,
                style: widget.htmlToolbarOptions.textStyle,
                items: [
                  CustomDropdownMenuItem(
                    value: 'decimal',
                    child: PointerInterceptor(child: Text('1. Numbered')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'lower-alpha',
                    child: PointerInterceptor(child: Text('a. Lower Alpha')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'upper-alpha',
                    child: PointerInterceptor(child: Text('A. Upper Alpha')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'lower-roman',
                    child: PointerInterceptor(child: Text('i. Lower Roman')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'upper-roman',
                    child: PointerInterceptor(child: Text('I. Upper Roman')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'disc',
                    child: PointerInterceptor(child: Text('• Disc')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'circle',
                    child: PointerInterceptor(child: Text('○ Circle')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'square',
                    child: PointerInterceptor(child: Text('■ Square')),
                  ),
                ],
                hint: Text('Select list style'),
                value: _listStyleSelectedItem,
                onChanged: (String? changed) async {
                  void updateSelectedItem(dynamic changed) {
                    if (changed is String) {
                      setState(mounted, this.setState, () {
                        _listStyleSelectedItem = changed;
                      });
                    }
                  }

                  if (changed != null) {
                    var proceed =
                        await widget.htmlToolbarOptions.onDropdownChanged?.call(
                                DropdownType.listStyles,
                                changed,
                                updateSelectedItem) ??
                            true;
                    if (proceed) {
                      if (kIsWeb) {
                        widget.controller.changeListStyle(changed);
                      } else {
                        await widget.controller.editorController!
                            .evaluateJavascript(source: '''
                               var \$focusNode = \$(window.getSelection().focusNode);
                               var \$parentList = \$focusNode.closest("div.note-editable ol, div.note-editable ul");
                               \$parentList.css("list-style-type", "$changed");
                            ''');
                      }
                      updateSelectedItem(changed);
                    }
                  }
                },
              ),
            ),
          ));
        }
      }
      if (t is ParagraphButtons) {
        if (t.alignLeft || t.alignCenter || t.alignRight || t.alignJustify) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                _alignSelected = List<bool>.filled(t.getIcons1().length, false);
                setState(mounted, this.setState, () {
                  _alignSelected[index] = !_alignSelected[index];
                });
              }

              if (t.getIcons1()[index].icon == Icons.format_align_left) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignLeft, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyLeft');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_align_center) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignCenter, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyCenter');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_align_right) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignRight, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyRight');
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.format_align_justify) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.alignJustify, _alignSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('justifyFull');
                  updateStatus();
                }
              }
            },
            isSelected: _alignSelected,
            children: t.getIcons1(),
          ));
        }
        if (t.increaseIndent || t.decreaseIndent) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              if (t.getIcons2()[index].icon == Icons.format_indent_increase) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.increaseIndent, null, null) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('indent');
                }
              }
              if (t.getIcons2()[index].icon == Icons.format_indent_decrease) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.decreaseIndent, null, null) ??
                    true;
                if (proceed) {
                  widget.controller.execCommand('outdent');
                }
              }
            },
            isSelected: List<bool>.filled(t.getIcons2().length, false),
            children: t.getIcons2(),
          ));
        }
        if (t.lineHeight) {
          toolbarChildren.add(Container(
            padding: const EdgeInsets.only(left: 8.0),
            height: widget.htmlToolbarOptions.toolbarItemHeight,
            decoration: !widget.htmlToolbarOptions.renderBorder
                ? null
                : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                    BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12))),
            child: CustomDropdownButtonHideUnderline(
              child: CustomDropdownButton<double>(
                elevation: widget.htmlToolbarOptions.dropdownElevation,
                icon: widget.htmlToolbarOptions.dropdownIcon,
                iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
                iconSize: widget.htmlToolbarOptions.dropdownIconSize,
                itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
                focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
                dropdownColor:
                    widget.htmlToolbarOptions.dropdownBackgroundColor,
                menuDirection:
                    widget.htmlToolbarOptions.dropdownMenuDirection ??
                        (widget.htmlToolbarOptions.toolbarPosition ==
                                ToolbarPosition.belowEditor
                            ? DropdownMenuDirection.up
                            : DropdownMenuDirection.down),
                menuMaxHeight:
                    widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                        MediaQuery.of(context).size.height / 3,
                style: widget.htmlToolbarOptions.textStyle,
                items: [
                  CustomDropdownMenuItem(
                      value: 1, child: PointerInterceptor(child: Text('1.0'))),
                  CustomDropdownMenuItem(
                    value: 1.2,
                    child: PointerInterceptor(child: Text('1.2')),
                  ),
                  CustomDropdownMenuItem(
                    value: 1.4,
                    child: PointerInterceptor(child: Text('1.4')),
                  ),
                  CustomDropdownMenuItem(
                    value: 1.5,
                    child: PointerInterceptor(child: Text('1.5')),
                  ),
                  CustomDropdownMenuItem(
                    value: 1.6,
                    child: PointerInterceptor(child: Text('1.6')),
                  ),
                  CustomDropdownMenuItem(
                    value: 1.8,
                    child: PointerInterceptor(child: Text('1.8')),
                  ),
                  CustomDropdownMenuItem(
                    value: 2,
                    child: PointerInterceptor(child: Text('2.0')),
                  ),
                  CustomDropdownMenuItem(
                      value: 3, child: PointerInterceptor(child: Text('3.0'))),
                ],
                value: _lineHeightSelectedItem,
                onChanged: (double? changed) async {
                  void updateSelectedItem(dynamic changed) {
                    if (changed is double) {
                      setState(mounted, this.setState, () {
                        _lineHeightSelectedItem = changed;
                      });
                    }
                  }

                  if (changed != null) {
                    var proceed =
                        await widget.htmlToolbarOptions.onDropdownChanged?.call(
                                DropdownType.lineHeight,
                                changed,
                                updateSelectedItem) ??
                            true;
                    if (proceed) {
                      if (kIsWeb) {
                        widget.controller.changeLineHeight(changed.toString());
                      } else {
                        await widget.controller.editorController!
                            .evaluateJavascript(
                                source:
                                    "\$('#summernote-2').summernote('lineHeight', '$changed');");
                      }
                      updateSelectedItem(changed);
                    }
                  }
                },
              ),
            ),
          ));
        }
        if (t.textDirection) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                _textDirectionSelected = List<bool>.filled(2, false);
                setState(mounted, this.setState, () {
                  _textDirectionSelected[index] =
                      !_textDirectionSelected[index];
                });
              }

              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(index == 0 ? ButtonType.ltr : ButtonType.rtl,
                          _alignSelected[index], updateStatus) ??
                  true;
              if (proceed) {
                if (kIsWeb) {
                  widget.controller
                      .changeTextDirection(index == 0 ? 'ltr' : 'rtl');
                } else {
                  await widget.controller.editorController!
                      .evaluateJavascript(source: """
                  var s=document.getSelection();			
                  if(s==''){
                      document.execCommand("insertHTML", false, "<p dir='${index == 0 ? "ltr" : "rtl"}'></p>");
                  }else{
                      document.execCommand("insertHTML", false, "<div dir='${index == 0 ? "ltr" : "rtl"}'>"+ document.getSelection()+"</div>");
                  }
                """);
                }
                updateStatus();
              }
            },
            isSelected: _textDirectionSelected,
            children: [
              Icon(Icons.format_textdirection_l_to_r),
              Icon(Icons.format_textdirection_r_to_l),
            ],
          ));
        }
        if (t.caseConverter) {
          toolbarChildren.add(Container(
            padding: const EdgeInsets.only(left: 8.0),
            height: widget.htmlToolbarOptions.toolbarItemHeight,
            decoration: !widget.htmlToolbarOptions.renderBorder
                ? null
                : widget.htmlToolbarOptions.dropdownBoxDecoration ??
                    BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12))),
            child: CustomDropdownButtonHideUnderline(
              child: CustomDropdownButton<String>(
                elevation: widget.htmlToolbarOptions.dropdownElevation,
                icon: widget.htmlToolbarOptions.dropdownIcon,
                iconEnabledColor: widget.htmlToolbarOptions.dropdownIconColor,
                iconSize: widget.htmlToolbarOptions.dropdownIconSize,
                itemHeight: widget.htmlToolbarOptions.dropdownItemHeight,
                focusColor: widget.htmlToolbarOptions.dropdownFocusColor,
                dropdownColor:
                    widget.htmlToolbarOptions.dropdownBackgroundColor,
                menuDirection:
                    widget.htmlToolbarOptions.dropdownMenuDirection ??
                        (widget.htmlToolbarOptions.toolbarPosition ==
                                ToolbarPosition.belowEditor
                            ? DropdownMenuDirection.up
                            : DropdownMenuDirection.down),
                menuMaxHeight:
                    widget.htmlToolbarOptions.dropdownMenuMaxHeight ??
                        MediaQuery.of(context).size.height / 3,
                style: widget.htmlToolbarOptions.textStyle,
                items: [
                  CustomDropdownMenuItem(
                    value: 'lower',
                    child: PointerInterceptor(child: Text('lowercase')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'sentence',
                    child: PointerInterceptor(child: Text('Sentence case')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'title',
                    child: PointerInterceptor(child: Text('Title Case')),
                  ),
                  CustomDropdownMenuItem(
                    value: 'upper',
                    child: PointerInterceptor(child: Text('UPPERCASE')),
                  ),
                ],
                hint: Text('Change case'),
                value: null,
                onChanged: (String? changed) async {
                  if (changed != null) {
                    var proceed = await widget
                            .htmlToolbarOptions.onDropdownChanged
                            ?.call(DropdownType.caseConverter, changed, null) ??
                        true;
                    if (proceed) {
                      if (kIsWeb) {
                        widget.controller.changeCase(changed);
                      } else {
                        await widget.controller.editorController!
                            .evaluateJavascript(source: """
                          var selected = \$('#summernote-2').summernote('createRange');
                          if(selected.toString()){
                              var texto;
                              var count = 0;
                              var value = "$changed";
                              var nodes = selected.nodes();
                              for (var i=0; i< nodes.length; ++i) {
                                  if (nodes[i].nodeName == "#text") {
                                      count++;
                                      texto = nodes[i].nodeValue.toLowerCase();
                                      nodes[i].nodeValue = texto;
                                      if (value == 'upper') {
                                         nodes[i].nodeValue = texto.toUpperCase();
                                      }
                                      else if (value == 'sentence' && count==1) {
                                         nodes[i].nodeValue = texto.charAt(0).toUpperCase() + texto.slice(1).toLowerCase();
                                      } else if (value == 'title') {
                                        var sentence = texto.split(" ");
                                        for(var j = 0; j< sentence.length; j++){
                                           sentence[j] = sentence[j][0].toUpperCase() + sentence[j].slice(1);
                                        }
                                        nodes[i].nodeValue = sentence.join(" ");
                                      }
                                  }
                              }
                          }
                        """);
                      }
                    }
                  }
                },
              ),
            ),
          ));
        }
      }
      if (t is InsertButtons &&
          (t.audio ||
              t.video ||
              t.otherFile ||
              t.picture ||
              t.link ||
              t.hr ||
              t.table)) {
        toolbarChildren.add(ToggleButtons(
          constraints: BoxConstraints.tightFor(
            width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
          ),
          color: widget.htmlToolbarOptions.buttonColor,
          selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
          fillColor: widget.htmlToolbarOptions.buttonFillColor,
          focusColor: widget.htmlToolbarOptions.buttonFocusColor,
          highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
          hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
          splashColor: widget.htmlToolbarOptions.buttonSplashColor,
          selectedBorderColor:
              widget.htmlToolbarOptions.buttonSelectedBorderColor,
          borderColor: widget.htmlToolbarOptions.buttonBorderColor,
          borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
          borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
          renderBorder: widget.htmlToolbarOptions.renderBorder,
          textStyle: widget.htmlToolbarOptions.textStyle,
          onPressed: (int index) async {
            if (t.getIcons()[index].icon == Icons.link) {
              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(ButtonType.link, null, null) ??
                  true;
              if (proceed) {
                final text = TextEditingController();
                final url = TextEditingController();
                final textFocus = FocusNode();
                final urlFocus = FocusNode();
                final formKey = GlobalKey<FormState>();
                var openNewTab = false;
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PointerInterceptor(
                        child: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text('Insert Link'),
                            scrollable: true,
                            content: Form(
                              key: formKey,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Text to display',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    TextField(
                                      controller: text,
                                      focusNode: textFocus,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Text',
                                      ),
                                      onSubmitted: (_) {
                                        urlFocus.requestFocus();
                                      },
                                    ),
                                    SizedBox(height: 20),
                                    Text('URL',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: url,
                                      focusNode: urlFocus,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'URL',
                                      ),
                                      validator: (String? value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a URL!';
                                        }
                                        return null;
                                      },
                                    ),
                                    Row(
                                      children: <Widget>[
                                        SizedBox(
                                          height: 48.0,
                                          width: 24.0,
                                          child: Checkbox(
                                            value: openNewTab,
                                            activeColor: Color(0xFF827250),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                openNewTab = value!;
                                              });
                                            },
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .dialogBackgroundColor,
                                              padding: EdgeInsets.only(
                                                  left: 5, right: 5),
                                              elevation: 0.0),
                                          onPressed: () {
                                            setState(() {
                                              openNewTab = !openNewTab;
                                            });
                                          },
                                          child: Text('Open in new window',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color)),
                                        ),
                                      ],
                                    ),
                                  ]),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    var proceed = await widget
                                            .htmlToolbarOptions
                                            .linkInsertInterceptor
                                            ?.call(
                                                text.text.isEmpty
                                                    ? url.text
                                                    : text.text,
                                                url.text,
                                                openNewTab) ??
                                        true;
                                    if (proceed) {
                                      widget.controller.insertLink(
                                        text.text.isEmpty
                                            ? url.text
                                            : text.text,
                                        url.text,
                                        openNewTab,
                                      );
                                    }
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('OK'),
                              )
                            ],
                          );
                        }),
                      );
                    });
              }
            }
            if (t.getIcons()[index].icon == Icons.image_outlined) {
              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(ButtonType.picture, null, null) ??
                  true;
              if (proceed) {
                final filename = TextEditingController();
                final url = TextEditingController();
                final urlFocus = FocusNode();
                FilePickerResult? result;
                String? validateFailed;
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PointerInterceptor(
                        child: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text('Insert Image'),
                            scrollable: true,
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget
                                      .htmlToolbarOptions.allowImagePicking)
                                    Text('Select from files',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  if (widget
                                      .htmlToolbarOptions.allowImagePicking)
                                    SizedBox(height: 10),
                                  if (widget
                                      .htmlToolbarOptions.allowImagePicking)
                                    TextFormField(
                                        controller: filename,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          prefixIcon: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .dialogBackgroundColor,
                                                padding: EdgeInsets.only(
                                                    left: 5, right: 5),
                                                elevation: 0.0),
                                            onPressed: () async {
                                              result = await FilePicker.platform
                                                  .pickFiles(
                                                type: FileType.image,
                                                withData: true,
                                                allowedExtensions: widget
                                                    .htmlToolbarOptions
                                                    .imageExtensions,
                                              );
                                              if (result?.files.single.name !=
                                                  null) {
                                                setState(() {
                                                  filename.text =
                                                      result!.files.single.name;
                                                });
                                              }
                                            },
                                            child: Text('Choose image',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color)),
                                          ),
                                          suffixIcon: result != null
                                              ? IconButton(
                                                  icon: Icon(Icons.close),
                                                  onPressed: () {
                                                    setState(() {
                                                      result = null;
                                                      filename.text = '';
                                                    });
                                                  })
                                              : Container(height: 0, width: 0),
                                          errorText: validateFailed,
                                          errorMaxLines: 2,
                                          border: InputBorder.none,
                                        )),
                                  if (widget
                                      .htmlToolbarOptions.allowImagePicking)
                                    SizedBox(height: 20),
                                  if (widget
                                      .htmlToolbarOptions.allowImagePicking)
                                    Text('URL',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  if (widget
                                      .htmlToolbarOptions.allowImagePicking)
                                    SizedBox(height: 10),
                                  TextField(
                                    controller: url,
                                    focusNode: urlFocus,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'URL',
                                      errorText: validateFailed,
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ]),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (filename.text.isEmpty &&
                                      url.text.isEmpty) {
                                    setState(() {
                                      validateFailed = widget.htmlToolbarOptions
                                              .allowImagePicking
                                          ? 'Please either choose an image or enter an image URL!'
                                          : 'Please enter an image URL!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      url.text.isNotEmpty) {
                                    setState(() {
                                      validateFailed =
                                          'Please input either an image or an image URL, not both!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      result?.files.single.bytes != null) {
                                    var base64Data = base64
                                        .encode(result!.files.single.bytes!);
                                    var proceed = await widget
                                            .htmlToolbarOptions
                                            .mediaUploadInterceptor
                                            ?.call(result!.files.single,
                                                InsertFileType.image) ??
                                        true;
                                    if (proceed) {
                                      widget.controller.insertHtml(
                                          "<img src='data:image/${result!.files.single.extension};base64,$base64Data' data-filename='${result!.files.single.name}'/>");
                                    }
                                    Navigator.of(context).pop();
                                  } else {
                                    var proceed = await widget
                                            .htmlToolbarOptions
                                            .mediaLinkInsertInterceptor
                                            ?.call(url.text,
                                                InsertFileType.image) ??
                                        true;
                                    if (proceed) {
                                      widget.controller
                                          .insertNetworkImage(url.text);
                                    }
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('OK'),
                              )
                            ],
                          );
                        }),
                      );
                    });
              }
            }
            if (t.getIcons()[index].icon == Icons.audiotrack_outlined) {
              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(ButtonType.audio, null, null) ??
                  true;
              if (proceed) {
                final filename = TextEditingController();
                final url = TextEditingController();
                final urlFocus = FocusNode();
                FilePickerResult? result;
                String? validateFailed;
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PointerInterceptor(
                        child: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text('Insert Audio'),
                            scrollable: true,
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Select from files',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextFormField(
                                      controller: filename,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        prefixIcon: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .dialogBackgroundColor,
                                              padding: EdgeInsets.only(
                                                  left: 5, right: 5),
                                              elevation: 0.0),
                                          onPressed: () async {
                                            result = await FilePicker.platform
                                                .pickFiles(
                                              type: FileType.audio,
                                              withData: true,
                                              allowedExtensions: widget
                                                  .htmlToolbarOptions
                                                  .audioExtensions,
                                            );
                                            if (result?.files.single.name !=
                                                null) {
                                              setState(() {
                                                filename.text =
                                                    result!.files.single.name;
                                              });
                                            }
                                          },
                                          child: Text('Choose audio',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color)),
                                        ),
                                        suffixIcon: result != null
                                            ? IconButton(
                                                icon: Icon(Icons.close),
                                                onPressed: () {
                                                  setState(() {
                                                    result = null;
                                                    filename.text = '';
                                                  });
                                                })
                                            : Container(height: 0, width: 0),
                                        errorText: validateFailed,
                                        errorMaxLines: 2,
                                        border: InputBorder.none,
                                      )),
                                  SizedBox(height: 20),
                                  Text('URL',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: url,
                                    focusNode: urlFocus,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'URL',
                                      errorText: validateFailed,
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ]),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (filename.text.isEmpty &&
                                      url.text.isEmpty) {
                                    setState(() {
                                      validateFailed =
                                          'Please either choose an audio file or enter an audio file URL!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      url.text.isNotEmpty) {
                                    setState(() {
                                      validateFailed =
                                          'Please input either an audio file or an audio URL, not both!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      result?.files.single.bytes != null) {
                                    var base64Data = base64
                                        .encode(result!.files.single.bytes!);
                                    var proceed = await widget
                                            .htmlToolbarOptions
                                            .mediaUploadInterceptor
                                            ?.call(result!.files.single,
                                                InsertFileType.audio) ??
                                        true;
                                    if (proceed) {
                                      widget.controller.insertHtml(
                                          "<audio controls src='data:audio/${result!.files.single.extension};base64,$base64Data' data-filename='${result!.files.single.name}'></audio>");
                                    }
                                    Navigator.of(context).pop();
                                  } else {
                                    var proceed = await widget
                                            .htmlToolbarOptions
                                            .mediaLinkInsertInterceptor
                                            ?.call(url.text,
                                                InsertFileType.audio) ??
                                        true;
                                    if (proceed) {
                                      widget.controller.insertHtml(
                                          "<audio controls src='${url.text}'></audio>");
                                    }
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('OK'),
                              )
                            ],
                          );
                        }),
                      );
                    });
              }
            }
            if (t.getIcons()[index].icon == Icons.videocam_outlined) {
              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(ButtonType.video, null, null) ??
                  true;
              if (proceed) {
                final filename = TextEditingController();
                final url = TextEditingController();
                final urlFocus = FocusNode();
                FilePickerResult? result;
                String? validateFailed;
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PointerInterceptor(
                        child: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text('Insert Video'),
                            scrollable: true,
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Select from files',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextFormField(
                                      controller: filename,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        prefixIcon: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .dialogBackgroundColor,
                                              padding: EdgeInsets.only(
                                                  left: 5, right: 5),
                                              elevation: 0.0),
                                          onPressed: () async {
                                            result = await FilePicker.platform
                                                .pickFiles(
                                              type: FileType.video,
                                              withData: true,
                                              allowedExtensions: widget
                                                  .htmlToolbarOptions
                                                  .videoExtensions,
                                            );
                                            if (result?.files.single.name !=
                                                null) {
                                              setState(() {
                                                filename.text =
                                                    result!.files.single.name;
                                              });
                                            }
                                          },
                                          child: Text('Choose video',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color)),
                                        ),
                                        suffixIcon: result != null
                                            ? IconButton(
                                                icon: Icon(Icons.close),
                                                onPressed: () {
                                                  setState(() {
                                                    result = null;
                                                    filename.text = '';
                                                  });
                                                })
                                            : Container(height: 0, width: 0),
                                        errorText: validateFailed,
                                        errorMaxLines: 2,
                                        border: InputBorder.none,
                                      )),
                                  SizedBox(height: 20),
                                  Text('URL',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: url,
                                    focusNode: urlFocus,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'URL',
                                      errorText: validateFailed,
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ]),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (filename.text.isEmpty &&
                                      url.text.isEmpty) {
                                    setState(() {
                                      validateFailed =
                                          'Please either choose a video or enter a video URL!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      url.text.isNotEmpty) {
                                    setState(() {
                                      validateFailed =
                                          'Please input either a video or a video URL, not both!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      result?.files.single.bytes != null) {
                                    var base64Data = base64
                                        .encode(result!.files.single.bytes!);
                                    var proceed = await widget
                                            .htmlToolbarOptions
                                            .mediaUploadInterceptor
                                            ?.call(result!.files.single,
                                                InsertFileType.video) ??
                                        true;
                                    if (proceed) {
                                      widget.controller.insertHtml(
                                          "<video controls src='data:video/${result!.files.single.extension};base64,$base64Data' data-filename='${result!.files.single.name}'></video>");
                                    }
                                    Navigator.of(context).pop();
                                  } else {
                                    var proceed = await widget
                                            .htmlToolbarOptions
                                            .mediaLinkInsertInterceptor
                                            ?.call(url.text,
                                                InsertFileType.video) ??
                                        true;
                                    if (proceed) {
                                      widget.controller.insertHtml(
                                          "<video controls src='${url.text}'></video>");
                                    }
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('OK'),
                              )
                            ],
                          );
                        }),
                      );
                    });
              }
            }
            if (t.getIcons()[index].icon == Icons.attach_file) {
              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(ButtonType.otherFile, null, null) ??
                  true;
              if (proceed) {
                final filename = TextEditingController();
                final url = TextEditingController();
                final urlFocus = FocusNode();
                FilePickerResult? result;
                String? validateFailed;
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PointerInterceptor(
                        child: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text('Insert File'),
                            scrollable: true,
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Select from files',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextFormField(
                                      controller: filename,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        prefixIcon: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .dialogBackgroundColor,
                                              padding: EdgeInsets.only(
                                                  left: 5, right: 5),
                                              elevation: 0.0),
                                          onPressed: () async {
                                            result = await FilePicker.platform
                                                .pickFiles(
                                              type: FileType.any,
                                              withData: true,
                                              allowedExtensions: widget
                                                  .htmlToolbarOptions
                                                  .otherFileExtensions,
                                            );
                                            if (result?.files.single.name !=
                                                null) {
                                              setState(() {
                                                filename.text =
                                                    result!.files.single.name;
                                              });
                                            }
                                          },
                                          child: Text('Choose file',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color)),
                                        ),
                                        suffixIcon: result != null
                                            ? IconButton(
                                                icon: Icon(Icons.close),
                                                onPressed: () {
                                                  setState(() {
                                                    result = null;
                                                    filename.text = '';
                                                  });
                                                })
                                            : Container(height: 0, width: 0),
                                        errorText: validateFailed,
                                        errorMaxLines: 2,
                                        border: InputBorder.none,
                                      )),
                                  SizedBox(height: 20),
                                  Text('URL',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: url,
                                    focusNode: urlFocus,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'URL',
                                      errorText: validateFailed,
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ]),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (filename.text.isEmpty &&
                                      url.text.isEmpty) {
                                    setState(() {
                                      validateFailed =
                                          'Please either choose a file or enter a file URL!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      url.text.isNotEmpty) {
                                    setState(() {
                                      validateFailed =
                                          'Please input either a file or a file URL, not both!';
                                    });
                                  } else if (filename.text.isNotEmpty &&
                                      result?.files.single.bytes != null) {
                                    widget.htmlToolbarOptions.onOtherFileUpload
                                        ?.call(result!.files.single);
                                    Navigator.of(context).pop();
                                  } else {
                                    widget.htmlToolbarOptions
                                        .onOtherFileLinkInsert
                                        ?.call(url.text);
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('OK'),
                              )
                            ],
                          );
                        }),
                      );
                    });
              }
            }
            if (t.getIcons()[index].icon == Icons.table_chart_outlined) {
              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(ButtonType.table, null, null) ??
                  true;
              if (proceed) {
                var currentRows = 1;
                var currentCols = 1;
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PointerInterceptor(
                        child: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text('Insert Table'),
                            scrollable: true,
                            content: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  NumberPicker(
                                    value: currentRows,
                                    minValue: 1,
                                    maxValue: 10,
                                    onChanged: (value) =>
                                        setState(() => currentRows = value),
                                  ),
                                  Text('x'),
                                  NumberPicker(
                                    value: currentCols,
                                    minValue: 1,
                                    maxValue: 10,
                                    onChanged: (value) =>
                                        setState(() => currentCols = value),
                                  ),
                                ]),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (kIsWeb) {
                                    widget.controller.insertTable(
                                        '${currentRows}x$currentCols');
                                  } else {
                                    await widget.controller.editorController!
                                        .evaluateJavascript(
                                            source:
                                                "\$('#summernote-2').summernote('insertTable', '${currentRows}x$currentCols');");
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              )
                            ],
                          );
                        }),
                      );
                    });
              }
            }
            if (t.getIcons()[index].icon == Icons.horizontal_rule) {
              var proceed = await widget.htmlToolbarOptions.onButtonPressed
                      ?.call(ButtonType.hr, null, null) ??
                  true;
              if (proceed) {
                widget.controller.insertHtml('<hr/>');
              }
            }
          },
          isSelected: List<bool>.filled(t.getIcons().length, false),
          children: t.getIcons(),
        ));
      }
      if (t is OtherButtons) {
        if (t.fullscreen || t.codeview || t.undo || t.redo || t.help) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              void updateStatus() {
                setState(mounted, this.setState, () {
                  _miscSelected[index] = !_miscSelected[index];
                });
              }

              if (t.getIcons1()[index].icon == Icons.fullscreen) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.fullscreen, _miscSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.setFullScreen();
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.code) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.codeview, _miscSelected[index],
                            updateStatus) ??
                    true;
                if (proceed) {
                  widget.controller.toggleCodeView();
                  updateStatus();
                }
              }
              if (t.getIcons1()[index].icon == Icons.undo) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.undo, null, null) ??
                    true;
                if (proceed) {
                  widget.controller.undo();
                }
              }
              if (t.getIcons1()[index].icon == Icons.redo) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.redo, null, null) ??
                    true;
                if (proceed) {
                  widget.controller.redo();
                }
              }
              if (t.getIcons1()[index].icon == Icons.help_outline) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.help, null, null) ??
                    true;
                if (proceed) {
                  await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PointerInterceptor(
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return AlertDialog(
                              title: Text('Help'),
                              scrollable: true,
                              content: Container(
                                height: MediaQuery.of(context).size.height / 2,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columnSpacing: 5,
                                    dataRowMinHeight: 75,
                                    columns: const <DataColumn>[
                                      DataColumn(
                                        label: Text(
                                          'Key Combination',
                                          style: TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Action',
                                          style: TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                    rows: const <DataRow>[
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('ESC')),
                                          DataCell(Text('Escape')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('ENTER')),
                                          DataCell(Text('Insert Paragraph')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+Z')),
                                          DataCell(
                                              Text('Undo the last command')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+Z')),
                                          DataCell(
                                              Text('Undo the last command')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+Y')),
                                          DataCell(
                                              Text('Redo the last command')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('TAB')),
                                          DataCell(Text('Tab')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('SHIFT+TAB')),
                                          DataCell(Text('Untab')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+B')),
                                          DataCell(Text('Set a bold style')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+I')),
                                          DataCell(Text('Set an italic style')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+U')),
                                          DataCell(
                                              Text('Set an underline style')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+SHIFT+S')),
                                          DataCell(Text(
                                              'Set a strikethrough style')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+BACKSLASH')),
                                          DataCell(Text('Clean a style')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+SHIFT+L')),
                                          DataCell(Text('Set left align')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+SHIFT+E')),
                                          DataCell(Text('Set center align')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+SHIFT+R')),
                                          DataCell(Text('Set right align')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+SHIFT+J')),
                                          DataCell(Text('Set full align')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+SHIFT+NUM7')),
                                          DataCell(
                                              Text('Toggle unordered list')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+SHIFT+NUM8')),
                                          DataCell(Text('Toggle ordered list')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+LEFTBRACKET')),
                                          DataCell(Text(
                                              'Outdent on current paragraph')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+RIGHTBRACKET')),
                                          DataCell(Text(
                                              'Indent on current paragraph')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+NUM0')),
                                          DataCell(Text(
                                              'Change current block\'s format as a paragraph (<p> tag)')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+NUM1')),
                                          DataCell(Text(
                                              'Change current block\'s format as H1')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+NUM2')),
                                          DataCell(Text(
                                              'Change current block\'s format as H2')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+NUM3')),
                                          DataCell(Text(
                                              'Change current block\'s format as H3')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+NUM4')),
                                          DataCell(Text(
                                              'Change current block\'s format as H4')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+NUM5')),
                                          DataCell(Text(
                                              'Change current block\'s format as H5')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+NUM6')),
                                          DataCell(Text(
                                              'Change current block\'s format as H6')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+ENTER')),
                                          DataCell(
                                              Text('Insert horizontal rule')),
                                        ],
                                      ),
                                      DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text('CTRL+K')),
                                          DataCell(Text('Show link dialog')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Close'),
                                )
                              ],
                            );
                          }),
                        );
                      });
                }
              }
            },
            isSelected: _miscSelected,
            children: t.getIcons1(),
          ));
        }
        if (t.copy || t.paste) {
          toolbarChildren.add(ToggleButtons(
            constraints: BoxConstraints.tightFor(
              width: widget.htmlToolbarOptions.toolbarItemHeight - 2,
              height: widget.htmlToolbarOptions.toolbarItemHeight - 2,
            ),
            color: widget.htmlToolbarOptions.buttonColor,
            selectedColor: widget.htmlToolbarOptions.buttonSelectedColor,
            fillColor: widget.htmlToolbarOptions.buttonFillColor,
            focusColor: widget.htmlToolbarOptions.buttonFocusColor,
            highlightColor: widget.htmlToolbarOptions.buttonHighlightColor,
            hoverColor: widget.htmlToolbarOptions.buttonHoverColor,
            splashColor: widget.htmlToolbarOptions.buttonSplashColor,
            selectedBorderColor:
                widget.htmlToolbarOptions.buttonSelectedBorderColor,
            borderColor: widget.htmlToolbarOptions.buttonBorderColor,
            borderRadius: widget.htmlToolbarOptions.buttonBorderRadius,
            borderWidth: widget.htmlToolbarOptions.buttonBorderWidth,
            renderBorder: widget.htmlToolbarOptions.renderBorder,
            textStyle: widget.htmlToolbarOptions.textStyle,
            onPressed: (int index) async {
              if (t.getIcons2()[index].icon == Icons.copy) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.copy, null, null) ??
                    true;
                if (proceed) {
                  var data = await widget.controller.getText();
                  await Clipboard.setData(ClipboardData(text: data));
                }
              }
              if (t.getIcons2()[index].icon == Icons.paste) {
                var proceed = await widget.htmlToolbarOptions.onButtonPressed
                        ?.call(ButtonType.paste, null, null) ??
                    true;
                if (proceed) {
                  var data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null) {
                    var text = data.text!;
                    widget.controller.insertHtml(text);
                  }
                }
              }
            },
            isSelected: List<bool>.filled(t.getIcons2().length, false),
            children: t.getIcons2(),
          ));
        }
      }
    }
    if (widget.htmlToolbarOptions.customToolbarInsertionIndices.isNotEmpty &&
        widget.htmlToolbarOptions.customToolbarInsertionIndices.length ==
            widget.htmlToolbarOptions.customToolbarButtons.length) {
      for (var i = 0;
          i < widget.htmlToolbarOptions.customToolbarInsertionIndices.length;
          i++) {
        if (widget.htmlToolbarOptions.customToolbarInsertionIndices[i] >
            toolbarChildren.length) {
          toolbarChildren.insert(toolbarChildren.length,
              widget.htmlToolbarOptions.customToolbarButtons[i]);
        } else if (widget.htmlToolbarOptions.customToolbarInsertionIndices[i] <
            0) {
          toolbarChildren.insert(
              0, widget.htmlToolbarOptions.customToolbarButtons[i]);
        } else {
          toolbarChildren.insert(
              widget.htmlToolbarOptions.customToolbarInsertionIndices[i],
              widget.htmlToolbarOptions.customToolbarButtons[i]);
        }
      }
    } else {
      toolbarChildren.addAll(widget.htmlToolbarOptions.customToolbarButtons);
    }
    if (widget.htmlToolbarOptions.renderSeparatorWidget) {
      toolbarChildren = intersperse(
              widget.htmlToolbarOptions.separatorWidget, toolbarChildren)
          .toList();
    }
    return toolbarChildren;
  }
}
