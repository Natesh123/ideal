
import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/common_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/confirm_code_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/login_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/logout_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/password_confirm_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/password_forget_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/resend_code_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

class AuthRepository {
  Future<LoginResponse> getLoginResponse(
      String? email, String password, String loginBy,String capchaKey,) async {
    var postBody = jsonEncode({
      "email": "$email",
      "password": password,
      "identity_matrix": AppConfig.purchase_code,
      "login_by": loginBy,
      "temp_user_id": temp_user_id.$,
      "g-recaptcha-response": capchaKey,
      "recaptcha_action":"recaptcha_customer_login"

    });

    String url = ("${AppConfig.BASE_URL}/auth/login");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Accept": "*/*",
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);
    print('login response ${response.body}');
    return loginResponseFromJson(response.body);
  }

  Future<LoginResponse> getSocialLoginResponse(
      String socialProvider,
      String? name,
      String? email,
      String? provider, {
        access_token = "",
        secret_token = "",
      }) async {
    email = email == ("null") ? "" : email;

    var postBody = jsonEncode({
      "name": name,
      "email": email,
      "provider": "$provider",
      "social_provider": socialProvider,
      "access_token": "$access_token",
      "secret_token": "$secret_token"
    });

    String url = ("${AppConfig.BASE_URL}/auth/social-login");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);
    return loginResponseFromJson(response.body);
  }

  Future<LogoutResponse> getLogoutResponse() async {
    String url = ("${AppConfig.BASE_URL}/auth/logout");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );

    return logoutResponseFromJson(response.body);
  }

  Future<CommonResponse> getAccountDeleteResponse() async {
    String url = ("${AppConfig.BASE_URL}/auth/account-deletion");

    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );
    return commonResponseFromJson(response.body);
  }

  Future<LoginResponse> getSignupResponse(
      String name,
      String? emailOrPhone,
      String password,
      String passwordConfirmation,
      String registerBy,
      String capchaKey,
      String sourceReference,
      [String? referenceSourceOther]
      ) async {
    print("DEBUG: Original emailOrPhone passed to API: $emailOrPhone");

    var postBody = jsonEncode({
      "name": name,
      "email_or_phone": emailOrPhone,
      "password": password,
      "password_confirmation": passwordConfirmation,
      "register_by": registerBy,
      "g-recaptcha-response": capchaKey,
      "temp_user_id": temp_user_id.$,
      "reference_source": sourceReference,
      "reference_source_other": referenceSourceOther,
    });

    String url = ("${AppConfig.BASE_URL}/auth/signup");
    print("------------------ Regular Signup API Request (POST) ------------------");
    print("URL: $url");
    print("Body: $postBody");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);

    print("Regular Signup Status Code: ${response.statusCode}");
    print("Regular Signup Response Body: ${response.body}");

    return loginResponseFromJson(response.body);
  }

  Future<ResendCodeResponse> getResendCodeResponse() async {
    String url = ("${AppConfig.BASE_URL}/auth/resend_code");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
      },
    );
    return resendCodeResponseFromJson(response.body);
  }

  Future<ResendCodeResponse> getResendCodeResponseByUserId(
      int userId, String registerBy, {String? emailOrPhone}) async {
    String url = ("${AppConfig.BASE_URL}/auth/resend_code?user_id=$userId&register_by=$registerBy&email_or_phone=${Uri.encodeComponent(emailOrPhone ?? '')}");
    
    print("------------------ Regular Resend API Request (GET) ------------------");
    print("URL: $url");

    final response = await ApiRequest.get(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Authorization": "Bearer ${access_token.$}",
        });

    print("Regular Resend Status Code: ${response.statusCode}");
    print("Regular Resend Body: ${response.body}");

    return resendCodeResponseFromJson(response.body);
  }

  Future<ConfirmCodeResponse> getConfirmCodeResponse(
      String verificationCode) async {
    var postBody = jsonEncode({"verification_code": verificationCode});

    String url = ("${AppConfig.BASE_URL}/auth/confirm_code");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Authorization": "Bearer ${access_token.$}",
        },
        body: postBody);

    return confirmCodeResponseFromJson(response.body);
  }

  Future<PasswordForgetResponse> getPasswordForgetResponse(
      String? emailOrPhone,
      String sendCodeBy,
      String capchaKey
      ) async {
    var postBody = jsonEncode(
        {"email_or_phone": "$emailOrPhone",
          "send_code_by": sendCodeBy,
          "g-recaptcha-response": capchaKey,
          "recaptcha_action":"recaptcha_forgot_password"
        });

    String url = ("${AppConfig.BASE_URL}/auth/password/forget_request");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);

    return passwordForgetResponseFromJson(response.body);
  }

  Future<PasswordConfirmResponse> getPasswordConfirmResponse(
      String verificationCode, String password) async {
    var postBody = jsonEncode(
        {"verification_code": verificationCode, "password": password});

    String url = ("${AppConfig.BASE_URL}/auth/password/confirm_reset");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);

    return passwordConfirmResponseFromJson(response.body);
  }

  Future<ResendCodeResponse> getPasswordResendCodeResponse(
      String? emailOrCode, String verifyBy) async {
    var postBody = jsonEncode(
        {"email_or_code": "$emailOrCode", "verify_by": verifyBy});

    String url = ("${AppConfig.BASE_URL}/auth/password/resend_code");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);

    return resendCodeResponseFromJson(response.body);
  }

  Future<LoginResponse> getWholesaleLoginResponse(
      String? emailOrPhone, String password, String loginBy) async {
    var postBody = jsonEncode({
      "email_or_phone": "$emailOrPhone",
      "password": password,
      "login_by": loginBy,
    });

    String url = ("${AppConfig.BASE_URL}/auth/wholesale/app-login");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Accept": "*/*",
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);
    print('wholesale login response ${response.body}');
    return loginResponseFromJson(response.body);
  }

  Future<LoginResponse> getWholesaleSignupResponse(
    String name,
    String? emailOrPhone,
    String password,
    String passwordConfirmation,
    String registerBy,
    String referenceSource,
    [String? referenceSourceOther]
  ) async {
    var postBody = jsonEncode({
      "name": name,
      "email_or_phone": "$emailOrPhone",
      "password": password,
      "password_confirmation": passwordConfirmation,
      "register_by": registerBy,
      "reference_source": referenceSource,
      "reference_source_other": referenceSourceOther,
    });

    String url = ("${AppConfig.BASE_URL}/auth/wholesale/app-register");
    print("------------------ Wholesale Signup API Request ------------------");
    print("URL: $url");
    print("Headers: {Content-Type: application/json, App-Language: ${app_language.$!}}");
    print("Body: $postBody");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);

    print("Wholesale Signup Status Code: ${response.statusCode}");
    print("Wholesale Signup Response Body: ${response.body}");

    return loginResponseFromJson(response.body);
  }

  Future<LoginResponse> getWholesaleVerifyOtpResponse(
      int userId, String code) async {
    var postBody = jsonEncode({
      "user_id": userId,
      "verification_code": code,
    });

    String url = ("${AppConfig.BASE_URL}/auth/wholesale/verify-otp");
    print("------------------ Wholesale Verify OTP API Request ------------------");
    print("URL: $url");
    print("Body: $postBody");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);

    print("Wholesale Verify Status Code: ${response.statusCode}");
    print("Wholesale Verify Response Body: ${response.body}");

    return loginResponseFromJson(response.body);
  }

  Future<LoginResponse> getWholesaleResendOtpResponse(int userId) async {
    var postBody = jsonEncode({"user_id": userId});

    String url = ("${AppConfig.BASE_URL}/auth/wholesale/resend-otp");
    print("------------------ Wholesale Resend OTP API Request ------------------");
    print("URL: $url");
    print("Body: $postBody");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody);

    print("Wholesale Resend Status Code: ${response.statusCode}");
    print("Wholesale Resend Response Body: ${response.body}");

    return loginResponseFromJson(response.body);
  }

  Future<LoginResponse> getUserByTokenResponse() async {
    var postBody = jsonEncode({"access_token": "${access_token.$}"});

    String url = ("${AppConfig.BASE_URL}/auth/info");
    if (access_token.$!.isNotEmpty) {
      final response = await ApiRequest.post(
          url: url,
          headers: {
            "Content-Type": "application/json",
            "App-Language": app_language.$!,
          },
          body: postBody);

      return loginResponseFromJson(response.body);
    }
    return LoginResponse();
  }
}
