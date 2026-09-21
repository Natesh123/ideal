import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/main_helpers.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/bkash_begin_response.dart';
import 'package:http/http.dart' as http;
import 'package:active_ecommerce_cms_demo_app/data_model/bkash_payment_process_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/flutterwave_url_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/iyzico_payment_success_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/nagad_begin_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/nagad_payment_process_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/order_create_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/payment_type_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/paypal_url_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/paystack_payment_success_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/razorpay_payment_success_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/sslcommerz_begin_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/middlewares/banned_user.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

class PaymentRepository {
  Future<dynamic> getPaymentResponseList({mode = "", list = "both"}) async {
    String url =
        ("${AppConfig.BASE_URL}/payment-types?mode=$mode&list=$list");

    final response = await ApiRequest.get(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        middleware: BannedUser());

    return paymentTypeResponseFromJson(response.body);
  }

  Future<dynamic> getOrderCreateResponse(paymentMethod) async {
    // Determine currency details
    String currencyCode = SystemConfig.systemCurrency?.code ?? "USD";
    double exchangeRate = SystemConfig.systemCurrency?.exchangeRate ?? 1.0;

    if (paymentMethod.toString().toLowerCase().contains("razorpay")) {
      // Force INR for Razorpay
      currencyCode = "INR";
      // If base is Rupee, we need exchange rate? Or maybe just 1?
      // Let's assume server handles conversion if we say INR.
      // But logging suggests 87.5. Let's try passing what we have.
    }

    var postBody = jsonEncode({
      "user_id": "${user_id.$}", // Added user_id
      "payment_type": "$paymentMethod",
      "currency_code": currencyCode,
      "currency_exchange_rate": exchangeRate
    });

    String url = ("${AppConfig.BASE_URL}/order/store");

    print("Payment Method Key: $paymentMethod");

    // Start with a COPY of common headers to avoid reference issues
    Map<String, String> headerMap = Map.from(commonHeader);
    headerMap.addAll(currencyHeader);

    headerMap.addAll({
      "Content-Type": "application/json",
      "Authorization": "Bearer ${access_token.$}",
      "App-Language": app_language.$!,
    });

    if (paymentMethod.toString().toLowerCase().contains("razorpay")) {
      print("FORCING INR for Razorpay Body/Header");
      headerMap["Currency-Code"] = "INR";
      // headerMap["Currency-Exchange-Rate"] = "$exchangeRate"; // Try sending rate too
    }

    print("DEBUG HEADERS: $headerMap");
    print("DEBUG BODY: $postBody");

    try {
      var response = await http.post(
          Uri.parse(url),
          headers: headerMap,
          body: postBody
      );

      print("DEBUG STATUS: ${response.statusCode}");
      print("DEBUG BODY: ${response.body}");

      return orderCreateResponseFromJson(response.body);

    } catch (e) {
      print("DEBUG ERROR: $e");
      return orderCreateResponseFromJson('{"result": false, "message": "Client Error: $e", "combined_order_id": 0}');
    }
  }

  Future<PaypalUrlResponse> getPaypalUrlResponse(
      String paymentType,
      int? combinedOrderId,
      var packageId,
      double? amount,
      int? orderId) async {
    String url =
        ("${AppConfig.BASE_URL}/paypal/payment/url?payment_type=$paymentType&combined_order_id=$combinedOrderId&amount=$amount&user_id=${user_id.$}&package_id=$packageId&order_id=$orderId");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return paypalUrlResponseFromJson(response.body);
  }

  Future<FlutterwaveUrlResponse> getFlutterwaveUrlResponse(
      String paymentType,
      int? combinedOrderId,
      var packageId,
      double? amount,
      int orderId) async {
    String url =
        ("${AppConfig.BASE_URL}/flutterwave/payment/url?payment_type=$paymentType&combined_order_id=$combinedOrderId&amount=$amount&user_id=${user_id.$}&package_id=$packageId&order_id=$orderId");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return flutterwaveUrlResponseFromJson(response.body);
  }

  Future<dynamic> getOrderCreateResponseFromWallet(
      paymentMethod, double? amount) async {
    String url = ("${AppConfig.BASE_URL}/payments/pay/wallet");

    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "payment_type": "$paymentMethod",
      "amount": "$amount"
    });

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!
        },
        body: postBody,
        middleware: BannedUser());

    return orderCreateResponseFromJson(response.body);
  }

  Future<dynamic> getOrderCreateResponseFromCod(paymentMethod) async {
    var postBody = jsonEncode(
        {"user_id": "${user_id.$}", "payment_type": "$paymentMethod"});

    String url = ("${AppConfig.BASE_URL}/payments/pay/cod");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}"
        },
        body: postBody,
        middleware: BannedUser());

    return orderCreateResponseFromJson(response.body);
  }

  Future<dynamic> getOrderCreateResponseFromManualPayment(
      paymentMethod) async {
    var postBody = jsonEncode(
        {"user_id": "${user_id.$}", "payment_type": "$paymentMethod"});

    String url = ("${AppConfig.BASE_URL}/payments/pay/manual");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!
        },
        body: postBody,
        middleware: BannedUser());

    return orderCreateResponseFromJson(response.body);
  }

  Future<RazorpayPaymentSuccessResponse> getRazorpayPaymentSuccessResponse(
      paymentType,
      double? amount,
      int? combinedOrderId,
      String? paymentDetails) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "payment_type": "$paymentType",
      "combined_order_id": "$combinedOrderId",
      "amount": "$amount",
      "payment_details": "$paymentDetails"
    });

    String url = ("${AppConfig.BASE_URL}/razorpay/success");
    print("RAZORPAY_SUCCESS_URL: $url");
    print("RAZORPAY_SUCCESS_BODY: $postBody");

    final response = await ApiRequest.post(
        url: url,
        headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$!
        },
        body: postBody);

    print("RAZORPAY_SUCCESS_RESPONSE_STATUS: ${response.statusCode}");
    print("RAZORPAY_SUCCESS_RESPONSE_BODY: ${response.body}");

    return razorpayPaymentSuccessResponseFromJson(response.body);
  }

  Future<PaystackPaymentSuccessResponse> getPaystackPaymentSuccessResponse(
      paymentType,
      double? amount,
      int? combinedOrderId,
      Map<String, dynamic> paymentDetails) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "payment_type": "$paymentType",
      "combined_order_id": "$combinedOrderId",
      "amount": "$amount",
      "payment_details": "$paymentDetails"
    });

    String url = ("${AppConfig.BASE_URL}/paystack/success");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}"
        },
        body: postBody);

    return paystackPaymentSuccessResponseFromJson(response.body);
  }

  Future<IyzicoPaymentSuccessResponse> getIyzicoPaymentSuccessResponse(
      paymentType,
      double? amount,
      int? combinedOrderId,
      String? paymentDetails) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "payment_type": "$paymentType",
      "combined_order_id": "$combinedOrderId",
      "amount": "$amount",
      "payment_details": "$paymentDetails"
    });

    String url = ("${AppConfig.BASE_URL}/paystack/success");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}"
        },
        body: postBody);

    return iyzicoPaymentSuccessResponseFromJson(response.body);
  }

  Future<BkashBeginResponse> getBkashBeginResponse(
      String paymentType,
      int? combinedOrderId,
      var packageId,
      double? amount,
      int orderId) async {
    String url =
        ("${AppConfig.BASE_URL}/bkash/begin?payment_type=$paymentType&combined_order_id=$combinedOrderId&amount=$amount&user_id=${user_id.$}&package_id=$packageId&order_id=$orderId}");
    final response = await ApiRequest.get(
      url: url,
      headers: {"Authorization": "Bearer ${access_token.$}"},
    );

    return bkashBeginResponseFromJson(response.body);
  }

  Future<BkashPaymentProcessResponse> getBkashPaymentProcessResponse({
    required payment_type,
    required double? amount,
    required int? combined_order_id,
    required String? payment_id,
    required String? token,
    required String package_id,
  }) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "payment_type": "$payment_type",
      "combined_order_id": "$combined_order_id",
      "package_id": package_id,
      "amount": "$amount",
      "payment_id": "$payment_id",
      "token": "$token"
    });

    String url = ("${AppConfig.BASE_URL}/bkash/api/success");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: postBody);

    return bkashPaymentProcessResponseFromJson(response.body);
  }

  Future<SslcommerzBeginResponse> getSslcommerzBeginResponse(
      String paymentType,
      int? combinedOrderId,
      var packageId,
      double? amount,
      int orderId) async {
    String url =
        ("${AppConfig.BASE_URL}/sslcommerz/begin?payment_type=$paymentType&combined_order_id=$combinedOrderId&amount=$amount&user_id=${user_id.$}&package_id=$packageId&order_id=$orderId");

    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!
      },
    );

    return sslcommerzBeginResponseFromJson(response.body);
  }

  Future<NagadBeginResponse> getNagadBeginResponse(
      String paymentType,
      int? combinedOrderId,
      var packageId,
      double? amount,
      int orderId) async {
    String url =
        ("${AppConfig.BASE_URL}/nagad/begin?payment_type=$paymentType&combined_order_id=$combinedOrderId&amount=$amount&user_id=${user_id.$}&package_id=$packageId&order_id=$orderId");

    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!
      },
    );

    return nagadBeginResponseFromJson(response.body);
  }

  Future<NagadPaymentProcessResponse> getNagadPaymentProcessResponse(
      paymentType,
      double? amount,
      int? combinedOrderId,
      String? paymentDetails) async {
    var postBody = jsonEncode({
      "user_id": "${user_id.$}",
      "payment_type": "$paymentType",
      "combined_order_id": "$combinedOrderId",
      "amount": "$amount",
      "payment_details": "$paymentDetails"
    });

    String url = ("${AppConfig.BASE_URL}/nagad/process");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: postBody);

    return nagadPaymentProcessResponseFromJson(response.body);
  }
}
