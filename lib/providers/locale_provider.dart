import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  Locale get locale {
    String langCode = (app_mobile_language.$ == null || app_mobile_language.$.toString().isEmpty) 
        ? "en" 
        : app_mobile_language.$!;
    return _locale ??= Locale(langCode, '');
  }

  void setLocale(String code) {
    String langCode = code.isEmpty ? "en" : code;
    _locale = Locale(langCode, '');
    notifyListeners();
  }
}
