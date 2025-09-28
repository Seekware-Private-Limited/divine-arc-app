import 'package:flutter/material.dart';
import 'package:divine_arc/Utils/flutter_color_themes.dart';
import 'package:divine_arc/Utils/flutter_font_style.dart';

class FontSizeDropdown extends StatefulWidget {
  final double currentScale;
  final ValueChanged<double> onFontSizeChanged;

  const FontSizeDropdown({
    super.key,
    required this.currentScale,
    required this.onFontSizeChanged,
  });

  @override
  State<FontSizeDropdown> createState() => _FontSizeDropdownState();
}

class _FontSizeDropdownState extends State<FontSizeDropdown> {
  final List<String> _fontSizes = ['Small', 'Medium', 'Large'];
  final Map<String, double> _sizeMap = {
    'Small': 0.85,
    'Medium': 1.0,
    'Large': 1.25,
  };

  final GlobalKey _dropdownKey = GlobalKey();

  String _getSelectedSizeLabel(double scale) {
    return _sizeMap.entries
        .firstWhere(
          (entry) => entry.value == scale,
          orElse: () => const MapEntry('Medium', 1.0),
        )
        .key;
  }

  void _showFontSizeMenu(BuildContext context) async {
    final RenderBox renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 3,
        offset.dx + size.width,
        offset.dy + size.height + 300,
      ),
      items: [
        const PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Font Size", style: FTextStyle.socialloginbuttonText),
              Divider(),
            ],
          ),
        ),
        ..._fontSizes.map(
          (size) => PopupMenuItem<String>(
            value: size,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  size,
                  style:
                      _getSelectedSizeLabel(widget.currentScale) == size
                          ? FTextStyle.selectedRadioColorText
                          : FTextStyle.socialloginbuttonText,
                ),
                Icon(
                  _getSelectedSizeLabel(widget.currentScale) == size
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      _getSelectedSizeLabel(widget.currentScale) == size
                          ? AppColors.gradientStart
                          : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
      elevation: 8,
      color: Colors.white,
    );

    if (selected != null) {
      final scale = _sizeMap[selected]!;
      widget.onFontSizeChanged(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _dropdownKey,
      onTap: () => _showFontSizeMenu(context),
      child: Container(
        height: 35,
        width: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              _getSelectedSizeLabel(widget.currentScale),
              style: FTextStyle.socialloginbuttonText,
            ),
            const Icon(Icons.keyboard_arrow_down_sharp),
          ],
        ),
      ),
    );
  }
}
