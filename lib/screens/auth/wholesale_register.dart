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
import 'package:active_ecommerce_cms_demo_app/ui_elements/auth_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:validators/validators.dart';
import 'otp.dart';
import 'wholesale_otp.dart';

class WholesaleRegister extends StatefulWidget {
  const WholesaleRegister({super.key});

  @override
  State<WholesaleRegister> createState() => _WholesaleRegisterState();
}

class _WholesaleRegisterState extends State<WholesaleRegister> {
  final ValueNotifier<String> _register_by = ValueNotifier("phone");
  final ValueNotifier<String?> _phone = ValueNotifier("");
  var countries_code = <String?>[];
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final ValueNotifier<bool> _obscureConfirm = ValueNotifier(true);
  final ValueNotifier<bool> _isAgree = ValueNotifier(false);
  final ValueNotifier<String?> _selectedSource = ValueNotifier(null);
  final List<String> _sourceOptions = [
    "Google",
    "Instagram",
    "YouTube",
    "Facebook",
    "Other"
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final TextEditingController _sourceOtherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  void _fetchCountries() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countries_code.add(c.code));
  }

  Future<void> _onPressRegister() async {
    FocusScope.of(context).unfocus();

    var name = _nameController.text.trim();
    var email = _emailController.text.trim();
    var password = _passwordController.text.trim();
    var passwordConfirm = _passwordConfirmController.text.trim();

    if (name.isEmpty) {
      ToastComponent.showDialog("Please enter your name");
      return;
    } else if (_register_by.value == 'email' && (email.isEmpty || !isEmail(email))) {
      ToastComponent.showDialog("Please enter a valid email");
      return;
    } else if (_register_by.value == 'phone' &&
        (_phone.value == null || _phone.value!.isEmpty)) {
      ToastComponent.showDialog("Please enter your phone number");
      return;
    } else if (password.isEmpty) {
      ToastComponent.showDialog("Please enter a password");
      return;
    } else if (password.length < 6) {
      ToastComponent.showDialog("Password must contain at least 6 digits");
      return;
    } else if (password != passwordConfirm) {
      ToastComponent.showDialog("Passwords do not match");
      return;
    } else if (_selectedSource.value == null) {
      ToastComponent.showDialog("Please select how you knew about us");
      return;
    } else if (_selectedSource.value == 'Other' && _sourceOtherController.text.trim().isEmpty) {
      ToastComponent.showDialog("Please specify how you knew about us");
      return;
    } else if (!_isAgree.value) {
      ToastComponent.showDialog("Please agree to terms and conditions");
      return;
    }

    Loading.show(context);

    var signupResponse = await AuthRepository().getWholesaleSignupResponse(
      name,
      _register_by.value == 'email' ? email : _phone.value,
      password,
      passwordConfirm,
      _register_by.value,
      _selectedSource.value ?? 'Other',
      _sourceOtherController.text.trim(),
    );

    Loading.close();

    if (signupResponse.result == false) {
      if (signupResponse.message is List) {
        ToastComponent.showDialog(signupResponse.message.join("\n"));
      } else {
        ToastComponent.showDialog(signupResponse.message.toString());
      }
    } else {
      debugPrint("Wholesale Signup Success: ${signupResponse.message}");
      debugPrint("Access Token: ${signupResponse.access_token}");
      debugPrint("User ID from user object: ${signupResponse.user?.id}");
      debugPrint("User ID from root: ${signupResponse.user_id}");

      ToastComponent.showDialog(signupResponse.message.toString());

      if ((signupResponse.access_token == null ||
          signupResponse.access_token!.isEmpty) && _register_by.value != 'email') {
        // No token received → OTP verification needed
        final userId = signupResponse.user?.id ?? signupResponse.user_id;
        debugPrint("Navigating to OTP with UserID: $userId");

        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WholesaleOtp(userId: userId),
            ),
          );
        } else {
          debugPrint("Error: userId is null, cannot navigate to OTP");
          AuthHelper().setUserData(signupResponse);
          context.go("/");
        }
      } else {
        // Access token received → direct login (already verified)
        debugPrint("Token received, navigating to home");
        AuthHelper().setUserData(signupResponse);
        context.go("/");
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _sourceOtherController.dispose();
    _register_by.dispose();
    _phone.dispose();
    _obscurePassword.dispose();
    _obscureConfirm.dispose();
    _isAgree.dispose();
    _selectedSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen.buildScreen(
      context,
      "Wholesale Registration",
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
            "Personal Info",
            style: TextStyle(
              fontSize: 13,
              color: MyTheme.font_grey,
            ),
          ),
          const SizedBox(height: 20),

          // Name
          _buildLabel("Your name"),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: TextField(
              controller: _nameController,
              decoration: InputDecorations.buildInputDecoration_1(
                hint_text: "Full Name",
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Email / Phone label
          ValueListenableBuilder<String>(
            valueListenable: _register_by,
            builder: (context, registerBy, _) => _buildLabel(registerBy == "email" ? "Your Phone / Email" : "Your Phone"),
          ),
          const SizedBox(height: 6),

          ValueListenableBuilder<String>(
            valueListenable: _register_by,
            builder: (context, registerBy, _) {
              if (registerBy == "email") {
                return Column(
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
                        onTap: () => _register_by.value = "phone",
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
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 44,
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
                      onTap: () => _register_by.value = "email",
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
                );
              }
            },
          ),

          const SizedBox(height: 14),

          // Reference
          _buildLabel("How did you know about us?"),
          const SizedBox(height: 6),
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: MyTheme.shimmer_base,
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
                  dropdownColor: Colors.white,
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
          
          ValueListenableBuilder<String?>(
            valueListenable: _selectedSource,
            builder: (context, selectedSource, _) {
              if (selectedSource == 'Other') {
                return Column(
                  children: [
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _sourceOtherController,
                        decoration: InputDecoration(
                          hintText: "Please specify",
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
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }
          ),

          const SizedBox(height: 14),

          // Password
          _buildLabel("Password"),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: ValueListenableBuilder<bool>(
              valueListenable: _obscurePassword,
              builder: (context, obscurePwd, _) => TextField(
                controller: _passwordController,
                obscureText: obscurePwd,
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
                      obscurePwd
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: MyTheme.font_grey,
                      size: 20,
                    ),
                    onPressed: () => _obscurePassword.value = !obscurePwd,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                "Password must contain at least 6 digits",
                style: TextStyle(
                  color: MyTheme.font_grey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Confirm Password
          _buildLabel("Confirm Password"),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: ValueListenableBuilder<bool>(
              valueListenable: _obscureConfirm,
              builder: (context, obscureConf, _) => TextField(
                controller: _passwordConfirmController,
                obscureText: obscureConf,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: "Confirm Password",
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
                      obscureConf
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: MyTheme.font_grey,
                      size: 20,
                    ),
                    onPressed: () => _obscureConfirm.value = !obscureConf,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isAgree,
                  builder: (context, isAgree, _) => Checkbox(
                    value: isAgree,
                    activeColor: MyTheme.accent_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) => _isAgree.value = val ?? false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style:
                        TextStyle(color: MyTheme.font_grey, fontSize: 12),
                    children: [
                      const TextSpan(text: "By signing up you agree to our "),
                      TextSpan(
                        text: "terms and conditions",
                        style:
                            TextStyle(color: MyTheme.accent_color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isAgree,
              builder: (context, isAgree, _) => Btn.minWidthFixHeight(
                minWidth: double.infinity,
                height: 48,
                color: isAgree ? MyTheme.accent_color : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Register",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: isAgree ? _onPressRegister : null,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style:
                    TextStyle(color: MyTheme.font_grey, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  "Log In",
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

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: MyTheme.accent_color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
