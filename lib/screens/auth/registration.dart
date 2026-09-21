
import 'dart:developer';
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/intl_phone_input.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/other_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/common_webview_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/home.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/auth_ui.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../custom/loading.dart';
import '../../helpers/auth_helper.dart';
import '../../helpers/store_value.dart';
import '../../repositories/address_repository.dart';
import 'otp.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final ValueNotifier<String> _register_by = ValueNotifier("phone");
  String initialCountry = 'IN';
  var countries_code = <String?>[];

  // reCAPTCHA v3 setup
  late WebViewController _controller;
  final ValueNotifier<bool> _isWebViewReady = ValueNotifier(false);
  final ValueNotifier<bool> _isWebViewLoading = ValueNotifier(false);
  final String _recaptchaUrl = "${AppConfig.BASE_URL}/google-recaptcha";
  final ValueNotifier<String> googleRecaptchaKey = ValueNotifier("");

  final ValueNotifier<String?> _phone = ValueNotifier("");
  final ValueNotifier<bool?> _isAgree = ValueNotifier(false);
  final ValueNotifier<String?> _selectedSource = ValueNotifier(null);
  final ValueNotifier<bool> _showPassword = ValueNotifier(false);
  final ValueNotifier<bool> _showConfirmPassword = ValueNotifier(false);
  final List<String> _sourceOptions = [
    "Google",
    "Instagram",
    "YouTube",
    "Facebook",
    "Other"
  ];

  //controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
  TextEditingController();
  final TextEditingController _sourceOtherController = TextEditingController();

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    super.initState();
    fetch_country();
    if (recaptcha_customer_register.$) {
      _setupWebViewController();
    }
  }

  void _setupWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            log('WebView loading: $progress%');
          },
          onPageStarted: (String url) {
            log('WebView page started: $url');
            if (mounted) {
              _isWebViewLoading.value = true;
              _isWebViewReady.value = false;
            }
          },
          onPageFinished: (String url) async {
            log('WebView page finished loading: $url');

            // Inject JavaScript to handle reCAPTCHA
            await _controller.runJavaScript('''
              // Listen for reCAPTCHA token
              function onRecaptchaSuccess(token) {
                Captcha.postMessage(token);
              }
              
              // Check if reCAPTCHA is loaded and trigger if needed
              if (typeof grecaptcha !== 'undefined') {
                console.log('reCAPTCHA is available');
              } else {
                console.log('reCAPTCHA not available');
              }
              
              // Listen for messages from the app
              window.addEventListener('message', function(event) {
                if (event.data.type === 'GET_RECAPTCHA_TOKEN') {
                  if (typeof grecaptcha !== 'undefined' && typeof grecaptcha.execute !== 'undefined') {
                    grecaptcha.execute();
                  }
                }
              });
            ''');

            if (mounted) {
              _isWebViewReady.value = true;
              _isWebViewLoading.value = false;
            }
          },
          onWebResourceError: (WebResourceError error) {
            log('''
WebView Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
''');
            if (mounted) {
              _isWebViewReady.value = false;
              _isWebViewLoading.value = false;
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url == _recaptchaUrl || request.url.contains('google.com/recaptcha')) {
              return NavigationDecision.navigate;
            } else if (request.url.startsWith('http')) {
              _launchUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (JavaScriptMessage message) {
          log("reCAPTCHA v3 Token Received: '${message.message}'");

          if (mounted && message.message.isNotEmpty && message.message != "error") {
            googleRecaptchaKey.value = message.message;
            log("reCAPTCHA key has been SET successfully: ${googleRecaptchaKey.value.substring(0, 20)}...");
          } else {
            log("reCAPTCHA key was EMPTY or an ERROR.");
            // Retry getting reCAPTCHA token
            _getRecaptchaToken();
          }
        },
      );

    _loadWebView();
  }

  void _loadWebView() async {
    try {
      _isWebViewLoading.value = true;
      await _controller.loadRequest(Uri.parse(_recaptchaUrl));
    } catch (e) {
      log('Error loading WebView: $e');
      if (mounted) {
        _isWebViewLoading.value = false;
        _isWebViewReady.value = false;
      }
    }
  }

  void _getRecaptchaToken() async {
    if (!_isWebViewReady.value) {
      log('WebView not ready yet');
      return;
    }

    try {
      await _controller.runJavaScript('''
        if (typeof grecaptcha !== 'undefined' && typeof grecaptcha.execute !== 'undefined') {
          grecaptcha.execute();
        } else {
          Captcha.postMessage('error');
        }
      ''');
    } catch (e) {
      log('Error executing reCAPTCHA: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      log('Could not launch $url');
    }
  }

  fetch_country() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countries_code.add(c.code));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    _register_by.dispose();
    _isWebViewReady.dispose();
    _isWebViewLoading.dispose();
    googleRecaptchaKey.dispose();
    _phone.dispose();
    _isAgree.dispose();
    _selectedSource.dispose();
    _showPassword.dispose();
    _showConfirmPassword.dispose();
    super.dispose();
  }

  onPressSignUp() async {
    print("DEBUG: onPressSignUp called");
    if (recaptcha_customer_register.$ && (!_isWebViewReady.value || googleRecaptchaKey.value.isEmpty)) {
      ToastComponent.showDialog("Please wait for reCAPTCHA to load");
      _getRecaptchaToken();
      return;
    }

    // Loading.show(context); // Moved after validation

    var name = _nameController.text.trim();
    var email = _emailController.text.trim();
    var password = _passwordController.text.trim();
    var passwordConfirm = _passwordConfirmController.text.trim();

    print("DEBUG: Values - Name: $name, Email: $email, Phone: ${_phone.value}, RegisterBy: ${_register_by.value}");
    print("DEBUG: Password length: ${password.length}");

    if (name == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_your_name);
      return;
    } else if (_register_by.value == 'email' && (email == "" || !isEmail(email))) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email);
      return;
    } else if (_register_by.value == 'phone' && _phone.value == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      return;
    } else if (_register_by.value == 'phone' &&
        RegExp(r'^0+$').hasMatch(_phoneNumberController.text.trim().replaceAll(RegExp(r'\D'), ''))) {
      ToastComponent.showDialog(
        "Please enter a valid phone number",
      );
      return;
    } else if (password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      return;
    } else if (passwordConfirm == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.confirm_your_password,
      );
      return;
    } else if (password.length < 6) {
      ToastComponent.showDialog(
        AppLocalizations.of(
          context,
        )!.password_must_contain_at_least_6_characters,
      );
      return;
    } else if (password != passwordConfirm) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.passwords_do_not_match,
      );
      return;
    } else if (_selectedSource.value == null) {
      ToastComponent.showDialog("Please select how you knew about us");
      return;
    } else if (_selectedSource.value == 'Other' && _sourceOtherController.text.trim().isEmpty) {
      ToastComponent.showDialog("Please specify how you knew about us");
      return;
    }

    Loading.show(context); // Show loading ONLY after validation passes

    print("DEBUG: Calling getSignupResponse...");
    dynamic signupResponse;
    try {
      signupResponse = await AuthRepository().getSignupResponse(
        name,
        _register_by.value == 'email' ? email : _phone.value,
        password,
        passwordConfirm,
        _register_by.value,
        googleRecaptchaKey.value,
        _selectedSource.value ?? 'Other',
        _sourceOtherController.text.trim(),
      );
      print("DEBUG: Signup Response obtained successfully.");
      await Future.delayed(const Duration(milliseconds: 500)); // Added for dialog stability
      Loading.close();
    } catch (e, stack) {
      print("DEBUG: SIGNUP ERROR: $e");
      print("DEBUG: STACK: $stack");
      Loading.close();
      ToastComponent.showDialog("Signup failed: $e");
      return;
    }

    print("DEBUG: Signup Response Result: ${signupResponse.result}");
    print("DEBUG: Signup Response Message: ${signupResponse.message}");

    if (signupResponse.result == false) {
      var message = "";
      signupResponse.message.forEach((value) {
        message += value + "\n";
      });

      ToastComponent.showDialog(message);

      // Reset reCAPTCHA token for retry
      if (recaptcha_customer_register.$) {
        googleRecaptchaKey.value = "";
        _getRecaptchaToken();
      }
    } else {
      ToastComponent.showDialog(signupResponse.message);

      if (signupResponse.access_token != null &&
          signupResponse.access_token!.isNotEmpty) {
        AuthHelper().setUserData(signupResponse);

        if (OtherConfig.USE_PUSH_NOTIFICATION) {
          final FirebaseMessaging fcm = FirebaseMessaging.instance;
          await fcm.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

          String? fcmToken = await fcm.getToken();

          print("--fcm token--");
          print(fcmToken);
          if (is_logged_in.$ == true) {
            // update device token
            var deviceTokenUpdateResponse = await ProfileRepository()
                .getDeviceTokenUpdateResponse(fcmToken!);
          }
        }
      }

      // If token is null OR user is not verified, then we must go to OTP
      final isVerified = signupResponse.user?.emailVerified ?? false;
      final hasToken = signupResponse.access_token != null && signupResponse.access_token!.isNotEmpty;
      
      print("DEBUG: emailVerified: $isVerified");
      print("DEBUG: hasToken: $hasToken");
      print("DEBUG: Current access_token: ${access_token.$}");

      if (!hasToken || (!isVerified && _register_by != 'email')) {
        final userId = signupResponse.user?.id ?? signupResponse.user_id;
        print("DEBUG: Navigating to OTP with UserID: $userId");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Otp(
                userId: userId,
                phoneOrEmail: _register_by.value == 'email' ? email : _phone.value,
                registerBy: _register_by.value,
              );
            },
          ),
        );
      } else {
        // Already verified or verification not required by server
        context.go("/");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      Stack(
        children:[ AuthScreen.buildScreen(
        context,
        "${AppLocalizations.of(context)!.join_ucf} ${AppConfig.app_name}",
            buildBody(context),
            ),
          if (recaptcha_customer_register.$)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: SizedBox(
                width: 250,
                height: 80,
                child: WebViewWidget(controller: _controller),
              ),
            ),
      ]);
  }

  Widget buildBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.name_ucf,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _nameController,
                      autofocus: false,
                      decoration: InputDecorations.buildInputDecoration_1(
                        hint_text: "John Doe",
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: ValueListenableBuilder<String>(
                    valueListenable: _register_by,
                    builder: (context, registerBy, _) => Text(
                      registerBy == "email"
                          ? AppLocalizations.of(context)!.email_ucf
                          : AppLocalizations.of(context)!.phone_ucf,
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: _register_by,
                  builder: (context, registerBy, _) {
                    return registerBy == "email"
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _emailController,
                                    autofocus: false,
                                    decoration:
                                    InputDecorations.buildInputDecoration_1(
                                      hint_text: "johndoe@example.com",
                                    ),
                                  ),
                                ),
                                if (otp_addon_installed.$)
                                  GestureDetector(
                                    onTap: () {
                                      _register_by.value = "phone";
                                    },
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .or_register_with_a_phone,
                                      style: TextStyle(
                                        color: MyTheme.accent_color,
                                        fontStyle: FontStyle.italic,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 36,
                                  child: CustomInternationalPhoneNumberInput(
                                    initialValue: PhoneNumber(isoCode: 'IN'),
                                    countries: countries_code,
                                    onInputChanged: (PhoneNumber number) {
                                      _phone.value = number.phoneNumber;
                                    },
                                    onInputValidated: (bool value) {},
                                    selectorConfig: SelectorConfig(
                                      selectorType: PhoneInputSelectorType.DIALOG,
                                    ),
                                    ignoreBlank: false,
                                    autoValidateMode: AutovalidateMode.disabled,
                                    selectorTextStyle: TextStyle(
                                      color: MyTheme.font_grey,
                                    ),
                                    textFieldController: _phoneNumberController,
                                    formatInput: true,
                                    keyboardType: TextInputType.numberWithOptions(
                                      signed: true,
                                      decimal: true,
                                    ),
                                    inputDecoration:
                                    InputDecorations.buildInputDecoration_phone(
                                      hint_text: "01XXX XXX XXX",
                                    ),
                                    onSaved: (PhoneNumber number) {},
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _register_by.value = "email";
                                  },
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!
                                        .or_register_with_an_email,
                                    style: TextStyle(
                                      color: MyTheme.accent_color,
                                      fontStyle: FontStyle.italic,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                  }
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    "How did you know about us?",
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: MyTheme.white,
                      border: Border.all(
                        color: MyTheme.textfield_grey,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _selectedSource,
                        builder: (context, selectedSource, _) => DropdownButton<String>(
                          isExpanded: true,
                          value: selectedSource,
                          hint: Text(
                            "Select an option",
                            style: TextStyle(color: MyTheme.textfield_grey),
                          ),
                          items: _sourceOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: MyTheme.font_grey)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            _selectedSource.value = newValue;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: _selectedSource,
                  builder: (context, selectedSource, _) {
                    if (selectedSource == 'Other') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _sourceOtherController,
                            autofocus: false,
                            decoration: InputDecorations.buildInputDecoration_1(
                              hint_text: "Please specify",
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.password_ucf,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 36,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _showPassword,
                          builder: (context, showPwd, _) => TextField(
                            controller: _passwordController,
                            autofocus: false,
                            obscureText: !showPwd,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration:
                            InputDecorations.buildInputDecoration_1(
                              hint_text: "• • • • • • • •",
                            ).copyWith(
                              suffixIcon: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  showPwd ? Icons.visibility : Icons.visibility_off,
                                  color: MyTheme.accent_color,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _showPassword.value = !showPwd;
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!
                            .password_must_contain_at_least_6_characters,
                        style: TextStyle(
                          color: MyTheme.textfield_grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.retype_password_ucf,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    height: 36,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _showConfirmPassword,
                      builder: (context, showConfirmPwd, _) => TextField(
                        controller: _passwordConfirmController,
                        autofocus: false,
                        obscureText: !showConfirmPwd,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecorations.buildInputDecoration_1(
                          hint_text: "• • • • • • • •",
                        ).copyWith(
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              showConfirmPwd ? Icons.visibility : Icons.visibility_off,
                              color: MyTheme.accent_color,
                              size: 18,
                            ),
                            onPressed: () {
                              _showConfirmPassword.value = !showConfirmPwd;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 15,
                        width: 15,
                        child: ValueListenableBuilder<bool?>(
                          valueListenable: _isAgree,
                          builder: (context, isAgree, _) => Checkbox(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            value: isAgree,
                            onChanged: (newValue) {
                              _isAgree.value = newValue;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          maxLines: 2,
                          text: TextSpan(
                            style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(text: "I agree to the"),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CommonWebviewScreen(
                                              page_name: "Terms Conditions",
                                              url:
                                              "${AppConfig.RAW_BASE_URL}/mobile-page/terms",
                                            ),
                                      ),
                                    );
                                  },
                                style:
                                TextStyle(color: MyTheme.accent_color),
                                text: " Terms Conditions",
                              ),
                              TextSpan(text: " &"),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CommonWebviewScreen(
                                              page_name: "Privacy Policy",
                                              url:
                                              "${AppConfig.RAW_BASE_URL}/mobile-page/privacy-policy",
                                            ),
                                      ),
                                    );
                                  },
                                text: " Privacy Policy",
                                style:
                                TextStyle(color: MyTheme.accent_color),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: SizedBox(
                    height: 45,
                    child: ValueListenableBuilder<bool?>(
                      valueListenable: _isAgree,
                      builder: (context, isAgree, _) => Btn.minWidthFixHeight(
                        minWidth: double.infinity,
                        height: 50,
                        color: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(6.0),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.sign_up_ucf,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: isAgree == true
                            ? () {
                          onPressSignUp();
                        }
                            : null,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!
                              .already_have_an_account,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      InkWell(
                        child: Text(
                          AppLocalizations.of(context)!.log_in,
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          context.push('/users/login');
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}