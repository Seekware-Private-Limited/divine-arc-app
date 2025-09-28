import 'package:divine_arc/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:divine_arc/Screens/chalisa_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/common_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String quoteResponse = '';
  bool isPrayersLoading = false;
  List<dynamic> allPrayers = [];
  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(context).add(GetRandomQuoteEvent());
    BlocProvider.of<HomeFlowBloc>(context).add(GetAllPrayersEvent());
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
            body: SafeArea(
              child: BlocListener<HomeFlowBloc, HomeFlowState>(
                listener: (context, state) {
                  if (state is GetRandomQuoteLoading) {
                    setState(() {
                      isLoading = true;
                    });
                  } else if (state is GetRandomQuoteSuccess) {
                    setState(() {
                      isLoading = false;
                    });
                    quoteResponse = state.successResponse;
                  } else if (state is GetRandomQuoteFailure) {
                    setState(() {
                      isLoading = false;
                    });
                    CommonUtils.showErrorToast(
                      state.failureResponse['message'],
                    );
                  } else if (state is GetAllPrayersLoading) {
                    setState(() {
                      isPrayersLoading = true;
                    });
                  } else if (state is GetAllPrayersLoaded) {
                    setState(() {
                      isPrayersLoading = false;
                    });
                    final response = state.successResponse;
                    allPrayers.addAll(response);
                  } else if (state is GetAllPrayersFailure) {
                    setState(() {
                      isPrayersLoading = false;
                    });
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/bgGitaGPT.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          // Sticky Header
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

                          // Sticky Card with search
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
                              height: 180,
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
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Text(
                                        //   AppLocalizations.of(
                                        //     context,
                                        //   )!.translate('loremipsumShort'),
                                        //   style: FTextStyle.defaultTextBold,
                                        //   textAlign: TextAlign.center,
                                        // ),
                                        // const SizedBox(height: 8),
                                        if (isLoading)
                                          Center(
                                            child:
                                                LoadingAnimationWidget.staggeredDotsWave(
                                                  color:
                                                      AppColors.gradientStart,
                                                  size: 50,
                                                ),
                                          ),
                                        Text(
                                          quoteResponse,
                                          style:
                                              FTextStyle.socialloginbuttonText,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
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

                          // Scrollable list
                          Expanded(
                            child: ListView.builder(
                              itemCount: allPrayers.length,
                              itemBuilder: (context, index) {
                                final item = allPrayers[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ChalisaScreen(
                                                image: item['image_url'],
                                                title:
                                                    item['title'] ?? 'No Title',
                                                prayer:
                                                    item['prayer'] ??
                                                    'No Prayer Found',
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height: 100,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.GlobalBG,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          // Show network image from `image_url`
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              item['image_url'] ??
                                                  '', // Use image_url from API
                                              height: 80,
                                              width: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Title and Prayer (subtitle)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item['title'] ?? 'No Title',
                                                  style: FTextStyle.defaultText
                                                      .copyWith(fontSize: 12),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  item['description'] ??
                                                      'No Description',
                                                  style: FTextStyle.defaultText
                                                      .copyWith(fontSize: 10),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Right Arrow Icon
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => ChalisaScreen(
                                                        image:
                                                            item['image_url'],
                                                        title:
                                                            item['title'] ??
                                                            'No Title',
                                                        prayer:
                                                            item['prayer'] ??
                                                            'No Prayer Found',
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 30,
                                              width: 30,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.gradientStart,
                                                borderRadius:
                                                    BorderRadius.circular(5),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
