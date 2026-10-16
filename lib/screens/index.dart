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
    Provider.of<CurrencyPresenter>(context, listen: false).fetchListData();

    return app_mobile_language.$;
  }

  @override
  void initState() {
    print("Index screen initState. Wholesale user: ${is_wholesale_user.$}");
    _isShownSplashScreenNotifier.value = SystemConfig.isShownSplashScreed;
    // TODO: implement initState
    getSharedValueHelperData().then((value) {
      Future.delayed(Duration(seconds: 3)).then((value) {
        SystemConfig.isShownSplashScreed = true;
        Provider.of<LocaleProvider>(context, listen: false)
            .setLocale(app_mobile_language.$!);
        _isShownSplashScreenNotifier.value = true;
      });
    });
    super.initState();
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
