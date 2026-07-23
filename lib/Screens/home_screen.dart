import 'package:divine_arc/Screens/chalisa_screen.dart';
import 'package:divine_arc/Screens/prayer_list_tile.dart';
import 'package:divine_arc/Screens/quote_of_the_day.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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

  List<dynamic> _sortPrayersByPriority(List<dynamic> rawList) {
    int getPriorityScore(String name) {
      final title = name.toLowerCase().trim();

      if (title.contains('hanuman chalisa')) return 1;
      if (title.contains('shiv') && title.contains('aarti')) return 2;
      if (title.contains('ganesh') && title.contains('aarti')) return 3;
      if (title.contains('durga chalisa')) return 4;

      return 5;
    }

    final sortedList = List<dynamic>.from(rawList);
    sortedList.sort((a, b) {
      final nameA = a['content_name'] ?? '';
      final nameB = b['content_name'] ?? '';

      final priorityA = getPriorityScore(nameA);
      final priorityB = getPriorityScore(nameB);

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      return nameA.compareTo(nameB);
    });

    return sortedList;
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
                          final rawData = state.successResponse['data'] ?? [];
                          allPrayers.addAll(_sortPrayersByPriority(rawData));
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
                        vertical: 10,
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
                          QuoteOfTheDayCard(
                            isLoading: isLoading,
                            quoteText: _extractQuoteOnly(quoteResponse),
                            searchController: searchController,
                            onSearchTap: () async {
                              await _analytics.logEvent(
                                name: 'AskAnythingTextFieldTappedOnHomeScreen',
                              );
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AskAnythingScreen(),
                                ),
                              );
                            },
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
                                        return PrayerListItemTile(
                                          item: item,
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
                                                    (context) => ChalisaScreen(
                                                      contentId: item['id'],
                                                    ),
                                              ),
                                            );
                                          },
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
