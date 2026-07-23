import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/flutter_color_themes.dart';
import 'package:flutter/material.dart';

class QuoteOfTheDayCard extends StatelessWidget {
  final bool isLoading;
  final String quoteText;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;

  const QuoteOfTheDayCard({
    super.key,
    required this.isLoading,
    required this.quoteText,
    required this.searchController,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gradientStart.withValues(alpha: 0.4),
          width: 1,
        ),
        color: const Color(0xFFFFFDF9),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.GlobalBG,
              AppColors.gradientStart.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.gradientStart,
                      size: 50,
                    ),
                  ),
                )
              else
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -8,
                      right: -4,
                      child: Text(
                        '”',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: AppColors.gradientStart.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('quoteOfTheDay').toUpperCase(),
                            style: FTextStyle.defaultText.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            quoteText.isNotEmpty
                                ? quoteText
                                : AppLocalizations.of(
                                  context,
                                )!.translate('dummyText'),
                            style: FTextStyle.defaultText.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSearchTap,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gradientStart.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradientStart.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/searchIcon.png',
                          height: 16,
                          width: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: IgnorePointer(
                            child: TextField(
                              controller: searchController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!.translate('askAnything'),
                                hintStyle: FTextStyle.defaultText,
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.gradientStart.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
