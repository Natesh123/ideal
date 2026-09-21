import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../helpers/main_helpers.dart';
import '../profile.dart';

class NagadScreen extends StatefulWidget {
  double? amount;
  String payment_type;
  String? payment_method_key;
  var package_id;
  int? orderId;
  NagadScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.payment_type = "",
    this.package_id = "0",
    this.payment_method_key = "",
  });

  @override
  _NagadScreenState createState() => _NagadScreenState();
}

class _NagadScreenState extends State<NagadScreen> {
  final ValueNotifier<int?> _combinedOrderIdNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _orderInitNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _initialUrlNotifier = ValueNotifier("");
  final ValueNotifier<bool> _initialUrlFetchedNotifier = ValueNotifier(false);

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.payment_type == "cart_payment") {
      createOrder();
    }

    if (widget.payment_type != "cart_payment") {
      // on cart payment need proper order id
      getSetInitialUrl();
    }
  }

  createOrder() async {
    var orderCreateResponse = await PaymentRepository().getOrderCreateResponse(
      widget.payment_method_key,
    );

    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(orderCreateResponse.message);
      Navigator.of(context).pop();
      return;
    }

    _combinedOrderIdNotifier.value = orderCreateResponse.combined_order_id;
    _orderInitNotifier.value = true;

    getSetInitialUrl();
  }

  getSetInitialUrl() async {
    var nagadUrlResponse = await PaymentRepository().getNagadBeginResponse(
      widget.payment_type,
      _combinedOrderIdNotifier.value,
      widget.package_id,
      widget.amount,
      widget.orderId!,
    );

    if (nagadUrlResponse.result == false) {
      ToastComponent.showDialog(nagadUrlResponse.message!);
      Navigator.of(context).pop();
      return;
    }

    _initialUrlNotifier.value = nagadUrlResponse.url;
    _initialUrlFetchedNotifier.value = true;

    nagad();
    //print(_initial_url);
    //print(_initial_url_fetched);
  }

  nagad() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/nagad/verify/") ||
                page.contains('/check-out/confirm-payment/')) {
              getData();
            } else {
              if (page.contains('confirm-payment')) {
                print('yessssssss');
              } else {
                print('nooooooooo');
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrlNotifier.value!), headers: commonHeader);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: buildBody(),
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
          if (responseJSON["result"] == false) {
            ToastComponent.showDialog(responseJSON["message"]);
            Navigator.pop(context);
          } else if (widget.payment_type == "order_re_payment") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return OrderList(from_checkout: true);
                },
              ),
            );
          } else if (responseJSON["result"] == true) {
            paymentDetails = responseJSON['payment_details'];
            onPaymentSuccess(paymentDetails);
          }
        });
  }

  onPaymentSuccess(paymentDetails) async {
    var nagadPaymentProcessResponse = await PaymentRepository()
        .getNagadPaymentProcessResponse(
          widget.payment_type,
          widget.amount,
          _combinedOrderIdNotifier.value,
          paymentDetails,
        );

    if (nagadPaymentProcessResponse.result == false) {
      ToastComponent.showDialog(nagadPaymentProcessResponse.message!);
      Navigator.pop(context);
      return;
    }

    ToastComponent.showDialog(nagadPaymentProcessResponse.message!);
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
            return ValueListenableBuilder(
              valueListenable: _initialUrlFetchedNotifier,
              builder: (context, bool initialUrlFetched, child) {
                if (orderInit == false &&
                    combinedOrderId == 0 &&
                    widget.payment_type == "cart_payment") {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.creating_order),
                  );
                } else if (initialUrlFetched == false) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.fetching_nagad_url),
                  );
                } else {
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: WebViewWidget(controller: _webViewController),
                    ),
                  );
                }
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
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Text(
        AppLocalizations.of(context)!.pay_with_nagad,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
