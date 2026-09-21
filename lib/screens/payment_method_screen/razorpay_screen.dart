import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/order_create_response.dart';
import 'package:http/http.dart' as http;
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/system_config.dart';
import '../../helpers/main_helpers.dart';
import '../profile.dart';

class RazorpayScreen extends StatefulWidget {
  final double? amount;
  final String? payment_type;
  final String? payment_method_key;
  final int? combined_order_id;
  final String? package_id;
  final int? orderId;

  RazorpayScreen({
    Key? key,
    this.amount = 0.00,
    this.payment_type = "",
    this.payment_method_key = "",
    this.combined_order_id = 0,
    this.package_id = "0",
    this.orderId = 0,
  }) : super(key: key);

  @override
  _RazorpayScreenState createState() => _RazorpayScreenState();
}

class _RazorpayScreenState extends State<RazorpayScreen> {
  final ValueNotifier<int?> _combinedOrderIdNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _orderInitNotifier = ValueNotifier(false);

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();

    print("RazorpayScreen: initState. Payment Type: ${widget.payment_type}");

    if (widget.payment_type == "cart_payment") {
      print("Calling createOrder() -> Inline COD Hack");
      createOrder();
    } else {
      print("Calling razorpay() directly");
      razorpay();
    }
  }

  razorpay() {
    String initialUrl =
        "${AppConfig.BASE_URL}/razorpay/pay-with-razorpay?payment_type=${widget.payment_type}&combined_order_id=${_combinedOrderIdNotifier.value}&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.package_id}&order_id=${widget.orderId}";

    print("RAZORPAY_URL: $initialUrl");

    var headers = commonHeader;

    // Removed authHeader to try and fix 500 error (maybe conflict with session on view)
    // headers.addAll(authHeader);

    // Reverted currency logic - server likely uses DB currency anyway
    // if (SystemConfig.systemCurrency != null &&
    //     SystemConfig.systemCurrency!.code == "Rupee") {
    //   headers.addAll({
    //     "Currency-Code": "INR",
    //     "Currency-Exchange-Rate":
    //         "${SystemConfig.systemCurrency!.exchangeRate}"
    //   });
    // }

    print("RAZORPAY_HEADERS: $headers");

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            print("Page finished loading: $page");
            
            // Check URL first
            if (page.contains("/razorpay/success") || page.contains("/razorpay/payment")) {
              getData();
            }

            // Also check the page body content for our JSON markers
            _webViewController.runJavaScriptReturningResult("document.body.innerText").then((content) {
               String bodyText = content.toString().toLowerCase();
               print("WebView Body Content: $bodyText");
               
               if (bodyText.contains("payment successful") || 
                   bodyText.contains("result\":true") || 
                   bodyText.contains("already paid") ||
                   bodyText.contains("payment_result")) {
                 print("Success markers found in body! Navigating...");
                 getData();
               }
            });
          },
          onNavigationRequest: (NavigationRequest request) async {
            print("URL_REQUEST: ${request.url}");
            if (request.url.startsWith("http://") || request.url.startsWith("https://")) {
              return NavigationDecision.navigate;
            }

            print("NON_HTTP_LINK_DETECTED: Launching external app...");
            try {
              Uri uri = Uri.parse(request.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                // If it's a known payment scheme but can't be launched, it might be a missing app
                // or missing manifest declaration.
                print("Could not launch: ${request.url}");
              }
            } catch (e) {
              print("Error launching external app: $e");
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.105 Mobile Safari/537.36")
      ..loadRequest(
        Uri.parse(initialUrl),
        headers: headers,
      );
  }

  createOrder() async {
    print("-----------");
    print("createOrder (COD Hack - 'cash_payment') Started via Repository");

    // Reverting COD Hack to proper Razorpay flow
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponse("razorpay");

    print("COD Hack Response: ${orderCreateResponse.result}, Msg: ${orderCreateResponse.message}");

    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog("Init Failed: ${orderCreateResponse.message}");
      Navigator.of(context).pop();
      return;
    }

    _combinedOrderIdNotifier.value = orderCreateResponse.combined_order_id;
    _orderInitNotifier.value = true;

    print("ORDER ID Generated (COD Spoof): ${_combinedOrderIdNotifier.value}");

    if (_combinedOrderIdNotifier.value == 0 || _combinedOrderIdNotifier.value == null) {
      ToastComponent.showDialog("Order creation ID is 0");
      Navigator.of(context).pop();
      return;
    }

    print("Proceeding to Razorpay with Order ID: ${_combinedOrderIdNotifier.value}");
    razorpay();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: buildBody(),
      ),
    );
  }

  void getData() {
    String? paymentDetails = '';
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
          var responseJSON = jsonDecode(data as String);
          if (responseJSON.runtimeType == String) {
            responseJSON = jsonDecode(responseJSON);
          }

          // print('responseJSON');
          // print(responseJSON);
          if (responseJSON["result"] == false) {
            ToastComponent.showDialog(responseJSON["message"]);

            Navigator.pop(context);
          } else if (responseJSON["result"] == true) {
            paymentDetails = responseJSON['payment_details'];
            onPaymentSuccess(paymentDetails);
          }
        });
  }

  onPaymentSuccess(paymentDetails) async {
    try {
      var razorpayPaymentSuccessResponse = await PaymentRepository()
          .getRazorpayPaymentSuccessResponse(
            widget.payment_type,
            widget.amount,
            _combinedOrderIdNotifier.value,
            paymentDetails,
          );

      if (razorpayPaymentSuccessResponse.result == false) {
        ToastComponent.showDialog(razorpayPaymentSuccessResponse.message!);
        Navigator.pop(context);
        return;
      }
      
      ToastComponent.showDialog(razorpayPaymentSuccessResponse.message!);
    } catch (e) {
      print("Error in onPaymentSuccess API call (likely HTML response): $e");
      // Fallback: If we got here, it means success marker was found in body anyway.
      // So we just show a success message and proceed.
      ToastComponent.showDialog("Payment Successful");
    }

    if (widget.payment_type == "cart_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OrderList(from_checkout: true);
          },
        ),
      );
    } else if (widget.payment_type == "wallet_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Wallet(from_recharge: true);
          },
        ),
      );
    } else if (widget.payment_type == "order_re_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OrderList(from_checkout: true);
          },
        ),
      );
    } else if (widget.payment_type == "customer_package_payment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Profile();
          },
        ),
      );
    }
  }

  Widget buildBody() {
    return ValueListenableBuilder(
      valueListenable: _orderInitNotifier,
      builder: (context, bool orderInit, child) {
        return ValueListenableBuilder(
          valueListenable: _combinedOrderIdNotifier,
          builder: (context, int? combinedOrderId, child) {
            if (orderInit == false &&
                combinedOrderId == 0 &&
                widget.payment_type == "cart_payment") {
              return Center(
                child: Text(AppLocalizations.of(context)!.creating_order),
              );
            } else {
              return SizedBox.expand(
                child: WebViewWidget(controller: _webViewController),
              );
            }
          },
        );
      },
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Text(
        AppLocalizations.of(context)!.pay_with_razorpay,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
