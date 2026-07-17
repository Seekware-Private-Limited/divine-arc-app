import 'package:divine_arc/Screens/chalisa_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rate_my_app/rate_my_app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String quoteResponse = '';
  bool isContentLoading = false;
  List<dynamic> allPrayers = [];
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  final RateMyApp _rateMyApp = RateMyApp(
    minDays: 3,
    minLaunches: 5,
    remindDays: 3,
    remindLaunches: 5,
    googlePlayIdentifier: 'com.divinearc.app',
    appStoreIdentifier: '6758439307',
  );

  @override
  void initState() {
    super.initState();
    _initialize();
    _initRateMyApp();
  }

  String _extractQuoteOnly(String rawResponse) {
    if (rawResponse.trim().isEmpty) return rawResponse;
    final withoutCitation = rawResponse.split('—').first;
    final withoutNewlines = withoutCitation.split('\n').first;
    return withoutNewlines.trim();
  }

  Future<void> _initRateMyApp() async {
    await _rateMyApp.init();

    if (_rateMyApp.shouldOpenDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCustomRateDialog();
      });
    }
  }

  void _showCustomRateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.containerBG,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/images/DivineArcLogo.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('enjoyingdivinearc'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.gradientStart,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(
                    context,
                  )!.translate('enjoyingdivinearc_description'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        onPressed: () {
                          _rateMyApp.callEvent(
                            RateMyAppEventType.laterButtonPressed,
                          );
                          Navigator.of(dialogContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.gradientStart),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('later'),
                          style: FTextStyle.rateNowBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gradientStart,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          await _rateMyApp.callEvent(
                            RateMyAppEventType.rateButtonPressed,
                          );
                          await _rateMyApp.launchStore();
                          if (mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('ratenow'),
                          style: FTextStyle.rateNowWhite,
                        ),
                      ),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    _rateMyApp.callEvent(RateMyAppEventType.noButtonPressed);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.translate('nothanks'),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnHomeScreen');

    BlocProvider.of<HomeFlowBloc>(context).add(GetRandomQuoteEvent());

    String language = PrefUtils.getLanguage();
    if (language.isEmpty) {
      language = 'en';
    }
    if (!mounted) return;
    BlocProvider.of<HomeFlowBloc>(
      context,
    ).add(ViewAllContent(language: language));
  }

  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1)),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bgGitaGPT.png',
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: BlocListener<HomeFlowBloc, HomeFlowState>(
                    listener: (context, state) {
                      if (state is GetRandomQuoteLoading) {
                        setState(() => isLoading = true);
                      } else if (state is GetRandomQuoteSuccess) {
                        setState(() {
                          isLoading = false;
                          quoteResponse = state.successResponse;
                        });
                      } else if (state is GetRandomQuoteFailure) {
                        setState(() {
                          isLoading = false;
                          quoteResponse = '';
                        });
                        CommonUtils.showErrorToast(
                          'Something went wrong, Please try again later',
                        );
                      } else if (state is ViewAllContentLoading) {
                        setState(() => isContentLoading = true);
                      } else if (state is ViewAllContentLoaded) {
                        setState(() {
                          isContentLoading = false;
                          allPrayers.clear();
                          allPrayers.addAll(state.successResponse['data']);
                        });
                      } else if (state is ViewAllContentError) {
                        setState(() => isContentLoading = false);
                        CommonUtils.showErrorToast('Failed to load prayers');
                      } else if (state is CommonServerFailureHome) {
                        setState(() {
                          isLoading = false;
                          isContentLoading = false;
                        });
                      } else if (state is SessionExpiredStateHome) {
                        setState(() => isLoading = false);
                        SessionExpiredSnackBar.show(
                          context: context,
                          message: state.message,
                        );
                      } else if (state is CheckNetworkConnectionHomeFlow) {
                        setState(() {
                          isLoading = false;
                          isContentLoading = false;
                        });
                        CommonUtils.showErrorToast(
                          AppLocalizations.of(
                            context,
                          )!.translate('nointernetConnection'),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('home'),
                                  style: FTextStyle.homeText,
                                ),
                              ),
                              LanguageDropdown(
                                onLanguageChanged: (updatedLanguageCode) {
                                  BlocProvider.of<HomeFlowBloc>(context).add(
                                    ViewAllContent(
                                      language: updatedLanguageCode,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.gradientStart.withValues(
                                  alpha: 0.4,
                                ),
                                width: 1,
                              ),
                              color: const Color(0xFFFFFDF9),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gradientStart.withValues(
                                    alpha: 0.14,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    AppColors.GlobalBG,
                                    AppColors.gradientStart.withValues(
                                      alpha: 0.3,
                                    ),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading)
                                      Center(
                                        child:
                                            LoadingAnimationWidget.staggeredDotsWave(
                                              color: AppColors.gradientStart,
                                              size: 50,
                                            ),
                                      )
                                    else
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: SizedBox(
                                              height: 30,
                                              child: OverflowBox(
                                                maxHeight: 56,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '”',
                                                  style: TextStyle(
                                                    fontSize: 46,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors
                                                        .gradientStart
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .translate(
                                                        'quoteOfTheDay',
                                                      )
                                                      .toUpperCase(),
                                                  style: FTextStyle.defaultText
                                                      .copyWith(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 1.2,
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  quoteResponse.isNotEmpty
                                                      ? _extractQuoteOnly(
                                                        quoteResponse,
                                                      )
                                                      : AppLocalizations.of(
                                                        context,
                                                      )!.translate('dummyText'),
                                                  style: FTextStyle.defaultText
                                                      .copyWith(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                                        onTap: () async {
                                          await _analytics.logEvent(
                                            name:
                                                'AskAnythingTextFieldTappedOnHomeScreen',
                                          );
                                          if (!mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      AskAnythingScreen(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 48,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: AppColors.gradientStart
                                                  .withValues(alpha: 0.3),
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.gradientStart
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
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
                                                    controller:
                                                        searchController,
                                                    readOnly: true,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.translate(
                                                            'askAnything',
                                                          ),
                                                      hintStyle:
                                                          FTextStyle
                                                              .defaultText,
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                                color: AppColors.gradientStart
                                                    .withValues(alpha: 0.6),
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
                          ),

                          const SizedBox(height: 20),

                          Expanded(
                            child:
                                isContentLoading
                                    ? Center(
                                      child:
                                          LoadingAnimationWidget.staggeredDotsWave(
                                            color: AppColors.gradientStart,
                                            size: 50,
                                          ),
                                    )
                                    : ListView.builder(
                                      itemCount: allPrayers.length,
                                      itemBuilder: (context, index) {
                                        final item = allPrayers[index];
                                        final contentId = item['id'];
                                        final contentImage =
                                            item['content_image'] ??
                                            'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png';
                                        final contentName =
                                            item['content_name'] ?? 'No Title';
                                        final contentDescription =
                                            item['content_description'] ??
                                            'No Description';

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: Material(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              onTap: () async {
                                                await _analytics.logEvent(
                                                  name:
                                                      'ChalisaViewTappedOnHomeScreen',
                                                );
                                                if (!mounted) return;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            ChalisaScreen(
                                                              contentId:
                                                                  contentId,
                                                            ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: AppColors
                                                        .gradientStart
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .gradientStart
                                                          .withValues(
                                                            alpha: 0.08,
                                                          ),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: Image.network(
                                                        contentImage,
                                                        height: 72,
                                                        width: 72,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Image.asset(
                                                              'assets/images/errorImage.png',
                                                              height: 72,
                                                              width: 72,
                                                              fit: BoxFit.cover,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            contentName,
                                                            style: FTextStyle
                                                                .defaultText
                                                                .copyWith(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Text(
                                                            contentDescription,
                                                            style: FTextStyle
                                                                .defaultText
                                                                .copyWith(
                                                                  fontSize:
                                                                      12.5,
                                                                  color:
                                                                      Colors
                                                                          .grey[600],
                                                                  height: 1.3,
                                                                ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      height: 34,
                                                      width: 34,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            AppColors
                                                                .gradientStart,
                                                            AppColors
                                                                .gradientEnd,
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              9,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        LucideIcons
                                                            .arrowUpRight,
                                                        size: 18,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
