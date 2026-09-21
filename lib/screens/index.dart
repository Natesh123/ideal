import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/addons_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/business_setting_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/currency_presenter.dart';
import 'package:active_ecommerce_cms_demo_app/providers/locale_provider.dart';
import 'package:active_ecommerce_cms_demo_app/screens/main.dart';
import 'package:active_ecommerce_cms_demo_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Index extends StatefulWidget {
  Index({super.key, this.goBack = true});
  bool? goBack;

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final ValueNotifier<bool> _isShownSplashScreenNotifier = ValueNotifier(false);

  Future<String?> getSharedValueHelperData() async {
    try {
      await access_token.load();
      await is_wholesale_user.load();
      print("Index: Sequential load finished. Token: ${access_token.$?.isNotEmpty}, Wholesale: ${is_wholesale_user.$}");
      
      AuthHelper().fetch_and_set();
      AddonsHelper().setAddonsData();
      BusinessSettingHelper().setBusinessSettingData();
      await app_language.load();
      await app_mobile_language.load();
      await app_language_rtl.load();
      await system_currency.load();
      if (mounted) {
        Provider.of<CurrencyPresenter>(context, listen: false).fetchListData();
      }
    } catch (e, stack) {
      print("Error in getSharedValueHelperData: $e\n$stack");
    }

    return app_mobile_language.$;
  }

  @override
  void initState() {
    super.initState();
    print("Index screen initState. Wholesale user: ${is_wholesale_user.$}");
    _isShownSplashScreenNotifier.value = SystemConfig.isShownSplashScreed;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await getSharedValueHelperData().timeout(const Duration(seconds: 3));
    } catch (e) {
      print("Splash screen background data fetch timeout or error: $e");
    }

    if (!mounted) return;

    try {
      String langCode = app_mobile_language.$ ?? AppConfig.mobile_app_code;
      if (langCode.isEmpty) langCode = "en";
      Provider.of<LocaleProvider>(context, listen: false).setLocale(langCode);
    } catch (e) {
      print("LocaleProvider setLocale error: $e");
    }

    SystemConfig.isShownSplashScreed = true;
    _isShownSplashScreenNotifier.value = true;
  }

  @override
  void dispose() {
    _isShownSplashScreenNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemConfig.context ??= context;
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: _isShownSplashScreenNotifier,
        builder: (context, isShown, _) {
          return isShown
              ? Main(
                  go_back: widget.goBack,
                )
              : SplashScreen();
        },
      ),
    );
  }
}
