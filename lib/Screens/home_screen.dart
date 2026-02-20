import 'package:divine_arc/Screens/chalisa_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String quoteResponse = '';
  bool isContentLoading = false;
  List<dynamic> allPrayers = [];

  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(context).add(GetRandomQuoteEvent());

    String language = PrefUtils.getLanguage();
    if (language.isEmpty) {
      language = 'en';
    }

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
                        setState(() {
                          isLoading = true;
                        });
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
                        setState(() {
                          isContentLoading = true;
                        });
                      } else if (state is ViewAllContentLoaded) {
                        setState(() {
                          isContentLoading = false;
                          allPrayers.clear();
                          allPrayers.addAll(state.successResponse['data']);
                        });
                      } else if (state is ViewAllContentError) {
                        setState(() {
                          isContentLoading = false;
                        });
                        CommonUtils.showErrorToast('Failed to load prayers');
                      } else if (state is CommonServerFailureHome) {
                        setState(() {
                          isLoading = false;
                          isContentLoading = false;
                        });
                      } else if (state is SessionExpiredStateHome) {
                        setState(() {
                          isLoading = false;
                        });

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
                              LanguageDropdown(),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.gradientStart,
                                width: 1.5,
                              ),
                              color: Colors.white,
                            ),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.GlobalBG,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Opacity(
                                      opacity: 0.2,
                                      child: Image.asset(
                                        'assets/images/homeImage.png',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isLoading)
                                          Center(
                                            child:
                                                LoadingAnimationWidget.staggeredDotsWave(
                                                  color:
                                                      AppColors.gradientStart,
                                                  size: 50,
                                                ),
                                          )
                                        else
                                          Text(
                                            quoteResponse.isNotEmpty
                                                ? quoteResponse
                                                : AppLocalizations.of(
                                                  context,
                                                )!.translate('dummyText'),
                                            style: FTextStyle.defaultText,
                                            textAlign: TextAlign.center,
                                          ),
                                        const SizedBox(height: 10),
                                        Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                child: TextField(
                                                  controller: searchController,
                                                  textInputAction:
                                                      TextInputAction.search,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                AskAnythingScreen(),
                                                      ),
                                                    );
                                                  },
                                                  readOnly: true,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.translate(
                                                          'askAnything',
                                                        ),
                                                    hintStyle:
                                                        FTextStyle.defaultText,
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

                                        final contentImage =
                                            item['content_image'] ??
                                            'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png';
                                        final contentName =
                                            item['content_name'] ?? 'No Title';
                                        final contentDescription =
                                            item['content_description'] ??
                                            'No Description';
                                        final contentAudio =
                                            item['audio'] ?? '';

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 15,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => ChalisaScreen(
                                                        contentName:
                                                            contentName,
                                                        contentImage:
                                                            contentImage,
                                                        contentDescription:
                                                            contentDescription,
                                                        contentAudio:
                                                            contentAudio,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 100,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.GlobalBG,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      contentImage,
                                                      height: 80,
                                                      width: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Image.asset(
                                                            'assets/images/errorImage.png',
                                                            height: 80,
                                                            width: 80,
                                                            fit: BoxFit.cover,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          contentName,
                                                          style: FTextStyle
                                                              .defaultText
                                                              .copyWith(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          contentDescription,
                                                          style: FTextStyle
                                                              .defaultText
                                                              .copyWith(
                                                                fontSize: 12,
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
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => ChalisaScreen(
                                                                contentName:
                                                                    contentName,
                                                                contentImage:
                                                                    contentImage,
                                                                contentDescription:
                                                                    contentDescription,
                                                                contentAudio:
                                                                    contentAudio,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      height: 30,
                                                      width: 30,
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors
                                                                .gradientStart,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                      ),
                                                      child: Image.asset(
                                                        'assets/images/whiteArrow.png',
                                                        height: 8,
                                                        width: 8,
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
