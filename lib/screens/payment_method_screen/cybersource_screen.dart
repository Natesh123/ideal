
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../custom/lang_text.dart';
import '../../helpers/main_helpers.dart';
import '../profile.dart';

class CybersourceScreen extends StatefulWidget {
  final double? amount;
  final String payment_type;
  final String? payment_method_key;
  final dynamic package_id;
  final int? orderId;

  const CybersourceScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    required this.payment_type,
    this.package_id = "0",
    this.payment_method_key = "",
  });

  @override
  State<CybersourceScreen> createState() => _CybersourceScreenState();
}

class _CybersourceScreenState extends State<CybersourceScreen> {
  final ValueNotifier<int?> _combinedOrderIdNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _orderInitNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _paymentCompletedNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _errorMessageNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _currentUrlNotifier = ValueNotifier(null);

  late WebViewController _webViewController;
  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();

    if (widget.payment_type == "cart_payment") {
      createOrder();
    } else {
      _orderInitNotifier.value = true;
      initiateCybersourcePayment();
    }
  }

  void _initializeWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (kDebugMode) {
              print('WebView loading: $progress%');
            }
          },
          onPageStarted: (String url) {
            _isLoadingNotifier.value = true;
            _currentUrlNotifier.value = url;
          },
          onPageFinished: (String url) {
            _isLoadingNotifier.value = false;
            _currentUrlNotifier.value = url;

            if (url.contains('${AppConfig.BASE_URL}/payment/success') ||
                url.contains(
                    '${AppConfig.BASE_URL}/cyber-source/payment/callback')) {
              _handlePaymentSuccess();
            } else if (url.contains('/payment/failure') ||
                url.contains('/payment/error')) {
              _handlePaymentFailure();
            }
          },
          onWebResourceError: (WebResourceError error) {
            _errorMessageNotifier.value = 'Payment failed: ${error.description}';
            _isLoadingNotifier.value = false;
            if (kDebugMode) {
              print('WebView error: ${error.description}');
            }
          },
          onUrlChange: (UrlChange change) {
            if (kDebugMode) {
              print('URL changed to: ${change.url}');
            }
            _currentUrlNotifier.value = change.url;
          },
        ),
      )
      ..addJavaScriptChannel('PaymentHandler',
          onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'payment_success') {
          _handlePaymentSuccess();
        } else if (message.message == 'payment_failure') {
          _handlePaymentFailure();
        }
      });

    _controllerCompleter.complete(_webViewController);
  }

  void createOrder() async {
    try {
      final orderCreateResponse = await PaymentRepository()
          .getOrderCreateResponse(widget.payment_method_key);

      if (orderCreateResponse.result == false) {
        _showErrorAndClose(orderCreateResponse.message);
        return;
      }

      _combinedOrderIdNotifier.value = orderCreateResponse.combined_order_id;
      _orderInitNotifier.value = true;

      initiateCybersourcePayment();
    } catch (e) {
      _showErrorAndClose('Failed to create order: $e');
    }
  }

  Future<void> initiateCybersourcePayment() async {
    try {
      final postData = _buildPaymentPostData();
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/cyber-source/payment/pay"),
        headers: commonHeader,
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        await _webViewController.loadHtmlString(response.body);
      } else {
        _showErrorAndClose(
            'Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorAndClose('Payment initialization error: $e');
    }
  }

  Map<String, dynamic> _buildPaymentPostData() {
    final postData = {
      "payment_type": widget.payment_type,
      "user_id": user_id.$,
      "amount": widget.amount,
    };

    if (widget.payment_type == 'cart_payment') {
      postData['combined_order_id'] = _combinedOrderIdNotifier.value;
    } else if (widget.payment_type == 'wallet_payment') {
      postData['payment_method'] = "cybersource";
    } else if (widget.payment_type == 'order_re_payment') {
      postData['order_id'] = widget.orderId;
    } else if (widget.payment_type == 'customer_package_payment') {
      postData['package_id'] = widget.package_id;
    }

    return postData;
  }

  void _handlePaymentSuccess() {
    if (_paymentCompletedNotifier.value) return;
    _paymentCompletedNotifier.value = true;
    _isLoadingNotifier.value = false;
    ToastComponent.showDialog("Payment completed successfully!");
    _navigateAfterPayment();
  }

  void _handlePaymentFailure() {
    _errorMessageNotifier.value = "Payment failed. Please try again.";
    _isLoadingNotifier.value = false;
  }

  void _navigateAfterPayment() {
    Widget targetScreen;

    if (widget.payment_type == "cart_payment" ||
        widget.payment_type == "order_re_payment") {
      targetScreen = OrderList(from_checkout: true);
    } else if (widget.payment_type == "wallet_payment") {
      targetScreen = Wallet(from_recharge: true);
    } else if (widget.payment_type == "customer_package_payment") {
      targetScreen = Profile();
    } else {
      targetScreen = Profile();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
      (Route<dynamic> route) => false,
    );
  }

  void _showErrorAndClose(String message) {
    ToastComponent.showDialog(message);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: _buildPaymentView(),
      ),
    );
  }

  Widget _buildPaymentView() {
    return ValueListenableBuilder<String?>(
      valueListenable: _errorMessageNotifier,
      builder: (context, errorMessage, child) {
        if (errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'),
                ),
              ],
            ),
          );
        }
        return ValueListenableBuilder<bool>(
          valueListenable: _orderInitNotifier,
          builder: (context, orderInit, child) {
            if (!orderInit && widget.payment_type == "cart_payment") {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(LangText(context).local.creating_order),
                  ],
                ),
              );
            }
            return ValueListenableBuilder<bool>(
              valueListenable: _isLoadingNotifier,
              builder: (context, isLoading, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _paymentCompletedNotifier,
                  builder: (context, paymentCompleted, child) {
                    return Stack(
                      children: [
                        WebViewWidget(controller: _webViewController),
                        if (isLoading)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  paymentCompleted
                                      ? "Processing payment..."
                                      : "Loading payment gateway...",
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
        onPressed: () {
          if (!_paymentCompletedNotifier.value) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Cancel Payment?"),
                content: Text("Are you sure you want to cancel this payment?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("No"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text("Yes"),
                  ),
                ],
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        "Pay with CyberSource",
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
