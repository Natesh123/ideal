import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/intl_phone_input.dart';
import 'package:active_ecommerce_cms_demo_app/custom/loading.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/wholesale_register.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/auth_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class WholesaleLogin extends StatefulWidget {
  const WholesaleLogin({super.key});

  @override
  State<WholesaleLogin> createState() => _WholesaleLoginState();
}

class _WholesaleLoginState extends State<WholesaleLogin> {
  final ValueNotifier<String> _loginByNotifier = ValueNotifier("phone");
  final ValueNotifier<String?> _phoneNotifier = ValueNotifier("");
  var countries_code = <String?>[];

  final ValueNotifier<bool> _obscurePasswordNotifier = ValueNotifier(true);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  void _fetchCountries() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countries_code.add(c.code));
  }

  Future<void> _onPressedLogin() async {
    FocusScope.of(context).unfocus();

    var email = _emailController.text.trim();
    var password = _passwordController.text.trim();

    if (_loginByNotifier.value == 'email' && email.isEmpty) {
      ToastComponent.showDialog("Please enter your email");
      return;
    } else if (_loginByNotifier.value == 'phone' && (_phoneNotifier.value == null || _phoneNotifier.value!.isEmpty)) {
      ToastComponent.showDialog("Please enter your phone number");
      return;
    } else if (password.isEmpty) {
      ToastComponent.showDialog("Please enter your password");
      return;
    }

    Loading.show(context);

    var loginResponse = await AuthRepository().getWholesaleLoginResponse(
      _loginByNotifier.value == 'email' ? email : _phoneNotifier.value,
      password,
      _loginByNotifier.value,
    );

    Loading.close();

    if (loginResponse.result == false) {
      if (loginResponse.message is List) {
        ToastComponent.showDialog(loginResponse.message!.join("\n"));
      } else {
        ToastComponent.showDialog(loginResponse.message!.toString());
      }
    } else {
      ToastComponent.showDialog(loginResponse.message!.toString());
      AuthHelper().setUserData(loginResponse);
      context.go("/");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _loginByNotifier.dispose();
    _phoneNotifier.dispose();
    _obscurePasswordNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen.buildScreen(
      context,
      "Login to Wholesale Account",
      buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            "WELCOME BACK !",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MyTheme.accent_color,
            ),
          ),
          const SizedBox(height: 32),

          // Email / Phone label
          ValueListenableBuilder<String>(
            valueListenable: _loginByNotifier,
            builder: (context, loginBy, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loginBy == "email" ? "Email" : "Phone",
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  if (loginBy == "email")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 44,
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecorations.buildInputDecoration_1(
                              hint_text: "johndoe@example.com",
                            ),
                          ),
                        ),
                        if (otp_addon_installed.$)
                          GestureDetector(
                            onTap: () => _loginByNotifier.value = "phone",
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "*Use Phone Instead",
                                style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 44,
                          child: CustomInternationalPhoneNumberInput(
                            initialValue: PhoneNumber(isoCode: 'IN'),
                            countries: countries_code,
                            onInputChanged: (PhoneNumber number) {
                              _phoneNotifier.value = number.phoneNumber;
                            },
                            onInputValidated: (bool value) {},
                            selectorConfig: SelectorConfig(
                              selectorType: PhoneInputSelectorType.DIALOG,
                            ),
                            ignoreBlank: false,
                            autoValidateMode: AutovalidateMode.disabled,
                            selectorTextStyle: TextStyle(color: MyTheme.font_grey),
                            textStyle: TextStyle(color: MyTheme.font_grey),
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
                          onTap: () => _loginByNotifier.value = "email",
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "*Use Email Instead",
                              style: TextStyle(
                                color: MyTheme.accent_color,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Password Label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Password",
              style: TextStyle(
                color: MyTheme.accent_color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Password Input
          ValueListenableBuilder<bool>(
            valueListenable: _obscurePasswordNotifier,
            builder: (context, obscurePassword, _) {
              return SizedBox(
                height: 44,
                child: TextField(
                  controller: _passwordController,
                  obscureText: obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: "• • • • • • • •",
                    hintStyle: TextStyle(color: MyTheme.textfield_grey),
                    filled: true,
                    fillColor: MyTheme.shimmer_base,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: MyTheme.font_grey,
                        size: 20,
                      ),
                      onPressed: () => _obscurePasswordNotifier.value = !obscurePassword,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Btn.minWidthFixHeight(
              minWidth: double.infinity,
              height: 48,
              color: MyTheme.accent_color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _onPressedLogin,
            ),
          ),

          const SizedBox(height: 20),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: MyTheme.font_grey, fontSize: 13),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WholesaleRegister(),
                    ),
                  );
                },
                child: Text(
                  "Register Now",
                  style: TextStyle(
                    color: MyTheme.accent_color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
