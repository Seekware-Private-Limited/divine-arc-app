import 'package:divine_arc/Utils/app_imports.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController issueController = TextEditingController();
  final TextEditingController stepsController = TextEditingController();

  final GlobalKey _dropdownKey = GlobalKey();

  String? selectedIssueType;
  bool isSubmitted = false;

  final List<Map<String, dynamic>> issueTypes = [
    {"key": "issue_type_bug", "icon": Icons.bug_report_outlined},
    {"key": "issue_type_crash", "icon": Icons.warning_amber_rounded},
    {"key": "issue_type_ui", "icon": Icons.design_services_outlined},
    {"key": "issue_type_performance", "icon": Icons.speed_rounded},
    {"key": "issue_type_other", "icon": Icons.more_horiz},
  ];

  bool isValid() {
    return selectedIssueType != null &&
        issueController.text.trim().length >= 10;
  }

  void _showCustomDropdown() async {
    final RenderBox renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 5,
        MediaQuery.of(context).size.width * 0.2,
        0,
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 8,
      items: [
        ...issueTypes.map((item) {
          return PopupMenuItem<String>(
            value: item["key"],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(item["icon"], size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.translate(item["key"]),
                      style:
                          selectedIssueType == item["key"]
                              ? FTextStyle.selectedRadioColorText
                              : FTextStyle.defaultText,
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Icon(
                  selectedIssueType == item["key"]
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      selectedIssueType == item["key"]
                          ? AppColors.gradientStart
                          : Colors.grey,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );

    if (selected != null) {
      setState(() {
        selectedIssueType = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.GlobalBG,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgGitaGPT.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            const LanguageDropdown(),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('report_issue_title'),
                          style: FTextStyle.boldText,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('report_issue_subtitle'),
                          style: FTextStyle.defaultText,
                        ),
                        const SizedBox(height: 30),

                        GestureDetector(
                          key: _dropdownKey,
                          onTap: _showCustomDropdown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.report_problem_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedIssueType == null
                                        ? AppLocalizations.of(
                                          context,
                                        )!.translate('issue_type')
                                        : AppLocalizations.of(
                                          context,
                                        )!.translate(selectedIssueType!),
                                    style: FTextStyle.defaultText,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded),
                              ],
                            ),
                          ),
                        ),

                        if (isSubmitted && selectedIssueType == null) ...[
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('issue_type_required_error'),
                            style: FTextStyle.errorTextStyle,
                          ),
                        ],

                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: issueController,
                            maxLines: 5,
                            style: FTextStyle.defaultText,
                            onChanged: (value) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.translate('issue_hint'),
                              hintStyle: FTextStyle.defaultText,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(15),
                            ),
                          ),
                        ),

                        if (isSubmitted &&
                            issueController.text.trim().length < 10) ...[
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('issue_min_length_error'),
                            style: FTextStyle.errorTextStyle,
                          ),
                        ],

                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: stepsController,
                            maxLines: 4,
                            style: FTextStyle.defaultText,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.translate('steps_hint'),
                              hintStyle: FTextStyle.defaultText,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(15),
                            ),
                          ),
                        ),

                        const Spacer(),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSubmitted = true;
                            });

                            if (isValid()) {
                              print("Issue Type: $selectedIssueType");
                              print("Description: ${issueController.text}");
                              print("Steps: ${stepsController.text}");

                              setState(() {
                                issueController.clear();
                                stepsController.clear();
                                selectedIssueType = null;
                                isSubmitted = false;
                              });
                              CommonUtils.showSuccessToast(
                                'Issue submitted successfully',
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            height: 45,
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('submit_issue'),
                                style: FTextStyle.buttonText,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
