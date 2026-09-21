import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WholesaleOtp extends StatefulWidget {
  final int userId;
  const WholesaleOtp({super.key, required this.userId});

  @override
  State<WholesaleOtp> createState() => _WholesaleOtpState();
}

class _WholesaleOtpState extends State<WholesaleOtp> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  final ValueNotifier<int> _rebuildNotifier = ValueNotifier(0);

  Future<void> _onPressConfirm() async {
    var code = _codeController.text.trim();
    if (code.isEmpty) {
      ToastComponent.showDialog("Please enter the verification code");
      return;
    }

    _loading = true;
    _rebuildNotifier.value++;

    var response = await AuthRepository()
        .getWholesaleVerifyOtpResponse(widget.userId, code);

    _loading = false;
    _rebuildNotifier.value++;

    if (response.result == false) {
      ToastComponent.showDialog(
          response.message?.toString() ?? "Verification failed");
    } else {
      ToastComponent.showDialog("Verified successfully!");
      AuthHelper().setUserData(response);
      context.go("/");
    }
  }

  Future<void> _onResend() async {
    var response =
        await AuthRepository().getWholesaleResendOtpResponse(widget.userId);
    ToastComponent.showDialog(
        response.message?.toString() ?? "OTP resent");
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _rebuildNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

              // Icon
              // Logo
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 12),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: MyTheme.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                ),
                child: Image.asset(
                    'assets/app_logo.png'),
              ),

              const SizedBox(height: 20),

              Text(
                "OTP VERIFICATION",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MyTheme.accent_color,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Enter the verification code sent to your phone",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: MyTheme.font_grey,
                ),
              ),

              const SizedBox(height: 32),

              // OTP Input
              SizedBox(
                height: 50,
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: MyTheme.dark_grey,
                  ),
                  decoration: InputDecorations.buildInputDecoration_1(
                    hint_text: "• • • • • •",
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Confirm Button
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
                  child: _loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Confirm",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  onPressed: _loading ? null : _onPressConfirm,
                ),
              ),

              const SizedBox(height: 24),

              // Resend
              GestureDetector(
                onTap: _onResend,
                child: Text(
                  "Resend Code",
                  style: TextStyle(
                    color: MyTheme.accent_color,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      }
    );
  }
}
