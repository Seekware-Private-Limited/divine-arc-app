import 'package:divine_arc/Utils/app_imports.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController messageController = TextEditingController();
  bool _showDeleteSuccess = false;

  @override
  void initState() {
    super.initState();
    _prefillMessage();
  }

  void _prefillMessage() {
    final String name = PrefUtils.getName();
    final String email = PrefUtils.getEmail();

    messageController.text =
        'Hello Divine ARC Support Team,\n\nI would like to request the permanent deletion of my Divine ARC account along with all associated personal information and data linked to my account.\n\nName: $name\nEmail: $email\n\nI understand that this action is permanent and cannot be undone. Please process my account deletion request at your earliest convenience.\n\nThank you for your assistance.';
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: BlocListener<HomeFlowBloc, HomeFlowState>(
        listener: (context, state) {
          if (state is ReportIssueLoaded) {
            setState(() => _showDeleteSuccess = true);
          } else if (state is ReportIssueFailure) {
            CommonUtils.showErrorToast(state.failureResponse['message']);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.GlobalBG,
          body: Stack(
            children: [
              SizedBox.expand(
                child: Image.asset(
                  'assets/images/bgGitaGPT.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: _showDeleteSuccess ? _buildSuccessUI() : _buildFormUI(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 54,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.translate('request_submitted'),
                style: FTextStyle.boldText.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Divider(
                color: Colors.grey.withValues(alpha: 0.2),
                thickness: 1,
                indent: 40,
                endIndent: 40,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(
                  context,
                )!.translate('delete_account_success_description'),
                style: FTextStyle.defaultText.copyWith(
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.translate('go_back'),
                      style: FTextStyle.buttonText,
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

  Widget _buildFormUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const CustomBackButton(), const LanguageDropdown()],
          ),
          const SizedBox(height: 40),
          Text(
            AppLocalizations.of(context)!.translate('delete_account'),
            style: FTextStyle.boldText,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.translate('delete_account_subtitle'),
            style: FTextStyle.defaultText,
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.grey.shade500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.translate('delete_account'),
                    style: FTextStyle.defaultText.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pre-filled read-only message field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: messageController,
              maxLines: 12,
              readOnly: true,
              style: FTextStyle.defaultText.copyWith(
                color: Colors.grey.shade600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(15),
              ),
            ),
          ),

          const SizedBox(height: 40),

          BlocBuilder<HomeFlowBloc, HomeFlowState>(
            builder: (context, state) {
              final isLoading = state is ReportIssueLoading;

              return GestureDetector(
                onTap:
                    isLoading
                        ? null
                        : () {
                          BlocProvider.of<HomeFlowBloc>(context).add(
                            ReportIssue(
                              title: AppLocalizations.of(
                                context,
                              )!.translate('delete_account'),
                              description: messageController.text.trim(),
                            ),
                          );
                        },
                child: Container(
                  height: 45,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child:
                        isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('submit_request'),
                              style: FTextStyle.buttonText,
                            ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
