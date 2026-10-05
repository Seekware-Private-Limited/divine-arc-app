import 'package:flutter/material.dart';
import 'package:divine_arc/Utils/flutter_color_themes.dart';
import 'package:divine_arc/Utils/flutter_font_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    'Small': 1.0,
    'Medium': 1.15,
    'Large': 1.35,
  };

  final GlobalKey _dropdownKey = GlobalKey();

  String _getSelectedSizeLabel(double scale) {
    return _sizeMap.entries
        .firstWhere(
          (entry) => (entry.value - scale).abs() < 0.01,
          orElse: () => const MapEntry('Small', 1.0),
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
        offset.dy + size.height + 6,
        offset.dx + size.width,
        offset.dy + size.height + 300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.gradientStart.withValues(alpha: 0.15),
        ),
      ),
      constraints: const BoxConstraints(minWidth: 170),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              'Font Size',
              style: FTextStyle.socialloginbuttonText.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.grey[500],
              ),
            ),
          ),
        ),
        ..._fontSizes.map((size) {
          final bool isSelected =
              _getSelectedSizeLabel(widget.currentScale) == size;

          return PopupMenuItem<String>(
            value: size,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.gradientStart.withValues(alpha: 0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    size,
                    style:
                        isSelected
                            ? FTextStyle.selectedRadioColorText
                            : FTextStyle.socialloginbuttonText,
                  ),
                  if (isSelected)
                    Icon(
                      LucideIcons.check500,
                      size: 18,
                      color: AppColors.gradientStart,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
      elevation: 6,
      color: Colors.white,
    );

    if (selected != null) {
      final scale = _sizeMap[selected]!;
      widget.onFontSizeChanged(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: _dropdownKey,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFontSizeMenu(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gradientStart.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.aLargeSmall500,
                size: 16,
                color: AppColors.gradientStart,
              ),
              const SizedBox(width: 8),
              Text(
                _getSelectedSizeLabel(widget.currentScale),
                style: FTextStyle.socialloginbuttonText,
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevronDown500,
                size: 16,
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
