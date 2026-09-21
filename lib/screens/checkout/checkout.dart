
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/enum_classes.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/cart_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/coupon_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/amarpay_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/bkash_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/flutterwave_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/iyzico_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/khalti_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/my_fatoora_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/nagad_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/offline_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/online_pay.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/payfast_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/paypal_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/paystack_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/paytm_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/razorpay_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/sslcommerz_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/stripe_screen.dart';
import 'package:active_ecommerce_cms_demo_app/other_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:one_context/one_context.dart';

import '../../custom/loading.dart';
import '../../helpers/auth_helper.dart';
import '../../repositories/guest_checkout_repository.dart';
import '../guest_checkout_pages/guest_checkout_address.dart';

import '../payment_method_screen/cybersource_screen.dart';
import '../payment_method_screen/phonepay_screen.dart';
import '../../services/push_notification_service.dart';

class Checkout extends StatefulWidget {
  int? order_id;
  String list;
  final PaymentFor? paymentFor;
  final double rechargeAmount;
  final String? title;
  var packageId;
  final String? guestCheckOutShippingAddress;

  Checkout({
    super.key,
    this.guestCheckOutShippingAddress,
    this.order_id = 0,
    this.paymentFor,
    this.list = "both",
    this.rechargeAmount = 0.0,
    this.title,
    this.packageId = 0,
  });

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ValueNotifier<int> _selectedPaymentMethodIndexNotifier = ValueNotifier(0);
  final ValueNotifier<String?> _selectedPaymentMethodNotifier = ValueNotifier("");
  final ValueNotifier<String?> _selectedPaymentMethodKeyNotifier = ValueNotifier("");
  final ValueNotifier<double> _codChargeValueNotifier = ValueNotifier(0.0);
  final ValueNotifier<String> _codChargeStringNotifier = ValueNotifier(". . .");

  final ScrollController _mainScrollController = ScrollController();
  final TextEditingController _couponController = TextEditingController();
  final _paymentTypeList = [];

  final ValueNotifier<bool> _isInitialNotifier = ValueNotifier(true);
  final ValueNotifier<String?> _totalStringNotifier = ValueNotifier(". . .");
  final ValueNotifier<double?> _grandTotalValueNotifier = ValueNotifier(0.00);
  final ValueNotifier<String?> _subTotalStringNotifier = ValueNotifier(". . .");
  final ValueNotifier<String?> _taxStringNotifier = ValueNotifier(". . .");
  final ValueNotifier<String> _shippingCostStringNotifier = ValueNotifier(". . .");
  final ValueNotifier<String?> _discountStringNotifier = ValueNotifier(". . .");
  final ValueNotifier<String> _usedCouponCodeNotifier = ValueNotifier("");
  final ValueNotifier<bool?> _couponAppliedNotifier = ValueNotifier(false);

  late BuildContext loadingcontext;
  String payment_type = "cart_payment";
  String? _title;

  @override
  void initState() {
    super.initState();
    fetchAll();
    print('recharge amount: ${widget.rechargeAmount}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_title == null) {
      if (widget.paymentFor == PaymentFor.WalletRecharge) {
        _title = AppLocalizations.of(context)!.recharge_wallet_ucf;
      } else if (widget.paymentFor == PaymentFor.PackagePay) {
        _title = AppLocalizations.of(context)!.buy_package_ucf;
      } else if (widget.paymentFor == PaymentFor.OrderRePayment) {
        _title = AppLocalizations.of(context)!.re_order_ucf;
      } else if (widget.paymentFor == PaymentFor.ManualPayment) {
        _title = AppLocalizations.of(context)!.make_offline_payment_ucf;
      } else {
        _title = AppLocalizations.of(context)!.checkout_ucf;
      }
    }
  }

  @override
  void dispose() {
    _selectedPaymentMethodIndexNotifier.dispose();
    _selectedPaymentMethodNotifier.dispose();
    _selectedPaymentMethodKeyNotifier.dispose();
    _isInitialNotifier.dispose();
    _totalStringNotifier.dispose();
    _grandTotalValueNotifier.dispose();
    _subTotalStringNotifier.dispose();
    _taxStringNotifier.dispose();
    _shippingCostStringNotifier.dispose();
    _discountStringNotifier.dispose();
    _codChargeValueNotifier.dispose();
    _codChargeStringNotifier.dispose();
    _usedCouponCodeNotifier.dispose();
    _couponAppliedNotifier.dispose();
    _mainScrollController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  String balance() {
    String? displayValue;
    double codCharge = _codChargeValueNotifier.value;

    if (widget.paymentFor == PaymentFor.ManualPayment ||
        widget.paymentFor == PaymentFor.WalletRecharge ||
        widget.paymentFor == PaymentFor.PackagePay ||
        widget.paymentFor == PaymentFor.OrderRePayment) {
      String amountString =
      widget.rechargeAmount.isNaN
          ? "0.00"
          : widget.rechargeAmount.toStringAsFixed(2);
      displayValue =
      SystemConfig.systemCurrency != null
          ? "${SystemConfig.systemCurrency!.symbol!}$amountString"
          : amountString;
    } else {
      double totalValue = _grandTotalValueNotifier.value ?? 0.0;
      String amountString = totalValue.toStringAsFixed(2);

      displayValue = SystemConfig.systemCurrency != null
          ? "${SystemConfig.systemCurrency!.symbol!}$amountString"
          : amountString;
    }

    return displayValue ?? '';
  }

  fetchAll() async {
    String mode = widget.paymentFor != PaymentFor.Order &&
        widget.paymentFor != PaymentFor.ManualPayment
        ? "wallet"
        : "order";

    // Fetch payment list first
    var paymentTypeResponseList = await PaymentRepository()
        .getPaymentResponseList(list: widget.list, mode: mode);

    _paymentTypeList.clear();
    _paymentTypeList.addAll(paymentTypeResponseList);
    if (_paymentTypeList.isNotEmpty) {
      _selectedPaymentMethodNotifier.value = _paymentTypeList[0].payment_type;
      _selectedPaymentMethodKeyNotifier.value = _paymentTypeList[0].payment_type_key;
    }
    _isInitialNotifier.value = false;

    // Then fetch summary
    await fetchSummary();

    // After fetching summary, set _grandTotalValue based on paymentFor
    if (widget.paymentFor == PaymentFor.WalletRecharge ||
        widget.paymentFor == PaymentFor.PackagePay ||
        widget.paymentFor == PaymentFor.OrderRePayment ||
        widget.paymentFor == PaymentFor.ManualPayment) {
      _grandTotalValueNotifier.value = widget.rechargeAmount;
      if (widget.paymentFor == PaymentFor.OrderRePayment) {
        payment_type = 'order_re_payment';
      } else if (widget.paymentFor == PaymentFor.WalletRecharge) {
        payment_type = "wallet_payment";
      } else if (widget.paymentFor == PaymentFor.PackagePay) {
        payment_type = "customer_package_payment";
      } else if (widget.paymentFor == PaymentFor.ManualPayment) {

      }
    } else {

      payment_type = 'cart_payment';
    }
  }

  fetchSummary() async {
    var cartSummaryResponse = await CartRepository().getCartSummaryResponse(
        payment_type: _selectedPaymentMethodKeyNotifier.value);

    if (cartSummaryResponse != null) {
      _subTotalStringNotifier.value = cartSummaryResponse.sub_total;
      _taxStringNotifier.value = cartSummaryResponse.tax;
      _shippingCostStringNotifier.value =
          cartSummaryResponse.shipping_cost ?? ". . .";
      _discountStringNotifier.value = cartSummaryResponse.discount;
      _totalStringNotifier.value = cartSummaryResponse.grand_total;
      _grandTotalValueNotifier.value = cartSummaryResponse.grand_total_value;
      _usedCouponCodeNotifier.value =
          cartSummaryResponse.coupon_code ?? _usedCouponCodeNotifier.value;
      _couponController.text = _usedCouponCodeNotifier.value;
      _couponAppliedNotifier.value = cartSummaryResponse.coupon_applied;

      _codChargeValueNotifier.value =
          cartSummaryResponse.cash_on_delivery_charge_value ?? 0.0;
      _codChargeStringNotifier.value =
          cartSummaryResponse.cash_on_delivery_charge ?? "0.00";
    }
  }

  calculateCodCharge() {
    _codChargeValueNotifier.value = 0.0;
    _codChargeStringNotifier.value = "0.00";
  }

  reset() {
    _paymentTypeList.clear();
    _isInitialNotifier.value = true;
    _selectedPaymentMethodIndexNotifier.value = 0;
    _selectedPaymentMethodNotifier.value = "";
    _selectedPaymentMethodKeyNotifier.value = "";

    reset_summary();
  }

  reset_summary() {
    _totalStringNotifier.value = ". . .";
    _grandTotalValueNotifier.value = 0.00;
    _subTotalStringNotifier.value = ". . .";
    _taxStringNotifier.value = ". . .";
    _shippingCostStringNotifier.value = ". . .";
    _discountStringNotifier.value = ". . .";
    _usedCouponCodeNotifier.value = "";
    _couponController.text = _usedCouponCodeNotifier.value;
    _couponAppliedNotifier.value = false;
  }

  Future<void> _onRefresh() async {
    reset();
    await fetchAll();
  }

  onPopped(value) {

    fetchAll();
  }

  onCouponApply() async {
    var couponCode = _couponController.text.toString();
    if (couponCode == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_coupon_code,
      );
      return;
    }

    var couponApplyResponse =
    await CouponRepository().getCouponApplyResponse(couponCode);
    if (couponApplyResponse.result == false) {
      ToastComponent.showDialog(
        couponApplyResponse.message,
      );
      return;
    }

    reset_summary();
    await fetchSummary();
  }

  onCouponRemove() async {
    var couponRemoveResponse =
    await CouponRepository().getCouponRemoveResponse();

    if (couponRemoveResponse.result == false) {
      ToastComponent.showDialog(
        couponRemoveResponse.message,
      );
      return;
    }

    reset_summary();
    await fetchSummary();
  }

  onPressPlaceOrderOrProceed() async {
    if (guest_checkout_status.$ && !is_logged_in.$) {
      Loading.show(context);
      // guest checkout user create response
      var guestUserAccountCreateResponse = await GuestCheckoutRepository()
          .guestUserAccountCreate(widget.guestCheckOutShippingAddress);
      Loading.close();

      AuthHelper().setUserData(guestUserAccountCreateResponse);

      if (!guestUserAccountCreateResponse.result!) {
        ToastComponent.showDialog(
          LangText(context).local.already_have_account,
        );

        Navigator.pushAndRemoveUntil(OneContext().context!,
            MaterialPageRoute(builder: (context) {
              return GuestCheckoutAddress();
            }), (Route<dynamic> route) => true);
        return;
      }
    }

    if (_selectedPaymentMethodNotifier.value == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.please_choose_one_option_to_pay,
      );
      return;
    }
    print("Grand total value before check: ${_grandTotalValueNotifier.value}");
    if (_grandTotalValueNotifier.value == null || _grandTotalValueNotifier.value! <= 0.00) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.nothing_to_pay,
      );
      return;
    }

    if (_selectedPaymentMethodNotifier.value == "bkash") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return BkashScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    if (_selectedPaymentMethodNotifier.value == "stripe") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return StripeScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    if (_selectedPaymentMethodNotifier.value == "aamarpay") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return AmarpayScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "paypal") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PaypalScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "razorpay") {
      print("--- RAZORPAY DEBUG: Place Order Button Clicked ---");
      int? combinedOrderId = 0;
      if (payment_type == "cart_payment") {
        print("--- RAZORPAY DEBUG: Creating order on server first... ---");
        Loading.show(context);
        var orderCreateResponse = await PaymentRepository().getOrderCreateResponse("razorpay");
        Loading.close();
        if (orderCreateResponse.result == false) {
          ToastComponent.showDialog(orderCreateResponse.message);
          return;
        }
        combinedOrderId = orderCreateResponse.combined_order_id;
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return RazorpayScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
          combined_order_id: combinedOrderId,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "paystack") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PaystackScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "iyzico") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return IyzicoScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "iyzico") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return MyFatooraScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    if (_selectedPaymentMethodNotifier.value == "cybersource") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return CybersourceScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "bkash") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return BkashScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "nagad") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return NagadScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "sslcommerz") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return SslCommerzScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "flutterwave") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return FlutterwaveScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }

    else if (_selectedPaymentMethodNotifier.value == "paytm") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PaytmScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "khalti") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return KhaltiScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "instamojo") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return OnlinePay(
          title: LangText(context).local.pay_with_instamojo,
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethodNotifier.value == "payfast") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PayfastScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    else if (_selectedPaymentMethodNotifier.value == "phonepe") {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return PhonePeScreen(
          amount: _grandTotalValueNotifier.value,
          payment_type: payment_type,
          payment_method_key: _selectedPaymentMethodKeyNotifier.value,
          package_id: widget.packageId.toString(),
          orderId: widget.order_id,
        );
      })).then((value) {
        onPopped(value);
      });
    }
    else if (_selectedPaymentMethodNotifier.value == "wallet_system") {
      pay_by_wallet();
    } else if (_selectedPaymentMethodNotifier.value == "cash_payment") {
      pay_by_cod();
    } else if (_selectedPaymentMethodNotifier.value == "manual_payment" &&
        widget.paymentFor == PaymentFor.Order) {
      pay_by_manual_payment();
    } else if (_selectedPaymentMethodNotifier.value == "manual_payment" &&
        (widget.paymentFor == PaymentFor.ManualPayment ||
            widget.paymentFor == PaymentFor.WalletRecharge ||
            widget.paymentFor == PaymentFor.PackagePay)) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return OfflineScreen(
          order_id: widget.order_id,
          paymentInstruction:
          _paymentTypeList[_selectedPaymentMethodIndexNotifier.value].details,
          offline_payment_id: _paymentTypeList[_selectedPaymentMethodIndexNotifier.value]
              .offline_payment_id,
          rechargeAmount: widget.rechargeAmount,
          offLinePaymentFor: widget.paymentFor,
          paymentMethod: _paymentTypeList[_selectedPaymentMethodIndexNotifier.value].name,
          packageId: widget.packageId,
        );
      })).then((value) {
        onPopped(value);
      });
    }
  }

  pay_by_wallet() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromWallet(
        _selectedPaymentMethodKeyNotifier.value, _grandTotalValueNotifier.value);
    Navigator.of(loadingcontext).pop();

    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(
        orderCreateResponse.message,
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderList(from_checkout: true);
    }));
  }

  pay_by_cod() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromCod(_selectedPaymentMethodKeyNotifier.value);
    Navigator.of(loadingcontext).pop();
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(
        orderCreateResponse.message,
      );
      Navigator.of(context).pop();
      return;
    }

    if (OtherConfig.USE_PUSH_NOTIFICATION) {
      PushNotificationService.showNotification(
        title: "Order Placed",
        body: "Your Order Has been placed successfully.",
        data: {
          "item_type": "order",
          "item_type_id": orderCreateResponse.combined_order_id.toString(),
        },
      );
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderList(from_checkout: true);
    }));
  }

  pay_by_manual_payment() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromManualPayment(_selectedPaymentMethodKeyNotifier.value);
    Navigator.pop(loadingcontext);
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(
        orderCreateResponse.message,
      );
      Navigator.of(context).pop();
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderList(from_checkout: true);
    }));
  }

  onPaymentMethodItemTap(index) {
    if (_selectedPaymentMethodKeyNotifier.value !=
        _paymentTypeList[index].payment_type_key) {
      _selectedPaymentMethodIndexNotifier.value = index;
      _selectedPaymentMethodNotifier.value =
          _paymentTypeList[index].payment_type;
      _selectedPaymentMethodKeyNotifier.value =
          _paymentTypeList[index].payment_type_key;
      fetchSummary();
    }
  }

  onPressDetails() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding:
        EdgeInsets.only(top: 16.0, left: 2.0, right: 2.0, bottom: 2.0),
        content: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          AppLocalizations.of(context)!.subtotal_all_capital,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Spacer(),
                      Text(
                        SystemConfig.systemCurrency != null
                            ? _subTotalStringNotifier.value!.replaceAll(
                            SystemConfig.systemCurrency!.code!,
                            SystemConfig.systemCurrency!.symbol!)
                            : _subTotalStringNotifier.value!,
                        style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          AppLocalizations.of(context)!.tax_all_capital,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Spacer(),
                      Text(
                        SystemConfig.systemCurrency != null
                            ? _taxStringNotifier.value!.replaceAll(
                            SystemConfig.systemCurrency!.code!,
                            SystemConfig.systemCurrency!.symbol!)
                            : _taxStringNotifier.value!,
                        style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          AppLocalizations.of(context)!
                              .shipping_cost_all_capital,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Spacer(),
                      Text(
                        SystemConfig.systemCurrency != null
                            ? _shippingCostStringNotifier.value.replaceAll(
                            SystemConfig.systemCurrency!.code!,
                            SystemConfig.systemCurrency!.symbol!)
                            : _shippingCostStringNotifier.value,
                        style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          AppLocalizations.of(context)!.discount_all_capital,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Spacer(),
                      Text(
                        SystemConfig.systemCurrency != null
                            ? _discountStringNotifier.value!.replaceAll(
                            SystemConfig.systemCurrency!.code!,
                            SystemConfig.systemCurrency!.symbol!)
                            : _discountStringNotifier.value!,
                        style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
              if (_codChargeValueNotifier.value > 0 || (_codChargeStringNotifier.value != ". . ." && _codChargeStringNotifier.value != "0.00" && _codChargeStringNotifier.value != ""))
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            AppLocalizations.of(context)!
                                .cash_on_delivery_charge_all_capital,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Spacer(),
                        Text(
                          SystemConfig.systemCurrency != null
                              ? _codChargeStringNotifier.value.replaceAll(
                                  SystemConfig.systemCurrency!.code!,
                                  SystemConfig.systemCurrency!.symbol!)
                              : _codChargeStringNotifier.value,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
              Divider(),
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          AppLocalizations.of(context)!
                              .grand_total_all_capital,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Spacer(),
                      Text(
                        SystemConfig.systemCurrency != null
                            ? _totalStringNotifier.value!.replaceAll(
                                SystemConfig.systemCurrency!.code!,
                                SystemConfig.systemCurrency!.symbol!)
                            : _totalStringNotifier.value!,
                        style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
            ],
          ),
        ),
        actions: [
          Btn.basic(
            child: Text(
              AppLocalizations.of(context)!.close_all_lower,
              style: TextStyle(color: MyTheme.medium_grey),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        bottomNavigationBar: buildBottomAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: buildPaymentMethodList(),
                        ),
                        Container(
                          height: 140,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            //Apply Coupon and order details container
            Align(
              alignment: Alignment.bottomCenter,
              child: widget.paymentFor == PaymentFor.WalletRecharge ||
                  widget.paymentFor == PaymentFor.PackagePay
                  ? const SizedBox.shrink()
                  : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                height: (widget.paymentFor == PaymentFor.ManualPayment) ||
                    (widget.paymentFor == PaymentFor.OrderRePayment)
                    ? 80
                    : 140,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (widget.paymentFor == PaymentFor.Order)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: buildApplyCouponRow(context),
                        ),
                      grandTotalSection(),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildApplyCouponRow(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _couponAppliedNotifier,
      builder: (context, bool? couponApplied, child) {
        return Row(
          children: [
            Form(
              key: _formKey,
              child: SizedBox(
                height: 42,
                width: (MediaQuery.of(context).size.width - 32) * (2 / 3),
                child: TextFormField(
                  controller: _couponController,
                  readOnly: couponApplied!,
                  autofocus: false,
                  decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enter_coupon_code,
                      hintStyle:
                      TextStyle(fontSize: 14.0, color: MyTheme.textfield_grey),
                      enabledBorder: app_language_rtl.$!
                          ? const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: MyTheme.textfield_grey, width: 0.5),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      )
                          : const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: MyTheme.textfield_grey, width: 0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                        BorderSide(color: MyTheme.medium_grey, width: 0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ),
                      ),
                      contentPadding: const EdgeInsets.only(left: 16.0)),
                ),
              ),
            ),
            !couponApplied
                ? SizedBox(
              width: (MediaQuery.of(context).size.width - 32) * (1 / 3),
              height: 42,
              child: Btn.basic(
                minWidth: MediaQuery.of(context).size.width,
                color: MyTheme.accent_color,
                shape: app_language_rtl.$!
                    ? const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      bottomLeft: Radius.circular(8.0),
                    ))
                    : const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    )),
                child: Text(
                  AppLocalizations.of(context)!.apply_coupon_all_capital,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  onCouponApply();
                },
              ),
            )
                : SizedBox(
              width: (MediaQuery.of(context).size.width - 32) * (1 / 3),
              height: 42,
              child: Btn.basic(
                minWidth: MediaQuery.of(context).size.width,
                color: MyTheme.accent_color,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    )),
                child: Text(
                  AppLocalizations.of(context)!.remove_ucf,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  onCouponRemove();
                },
              ),
            )
          ],
        );
      },
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        widget.title!, // Use widget.title as it's passed in the constructor
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildPaymentMethodList() {
    return ValueListenableBuilder(
      valueListenable: _isInitialNotifier,
      builder: (context, bool isInitial, child) {
        if (isInitial && _paymentTypeList.isEmpty) {
          return SingleChildScrollView(
              child: ShimmerHelper()
                  .buildListShimmer(item_count: 5, item_height: 100.0));
        } else if (_paymentTypeList.isNotEmpty) {
          return SingleChildScrollView(
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: 16,
                );
              },
              itemCount: _paymentTypeList.length,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 0.0),
                  child: buildPaymentMethodItemCard(index),
                );
              },
            ),
          );
        } else {
          return SizedBox(
              height: 100,
              child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.no_payment_method_is_added,
                    style: TextStyle(color: MyTheme.font_grey),
                  )));
        }
      },
    );
  }
  GestureDetector buildPaymentMethodItemCard(index) {
    return GestureDetector(
      onTap: () {
        onPaymentMethodItemTap(index);
      },
      child: ValueListenableBuilder(
        valueListenable: _selectedPaymentMethodKeyNotifier,
        builder: (context, String? selectedKey, child) {
          bool isSelected = selectedKey == _paymentTypeList[index].payment_type_key;
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(6))
                    .copyWith(
                    border: Border.all(
                        color: isSelected
                            ? MyTheme.accent_color
                            : MyTheme.light_grey,
                        width: isSelected ? 2.0 : 0.0)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                          width: 100,
                          height: 70,
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FadeInImage.assetNetwork(
                                placeholder: 'assets/placeholder.png',
                                image: AppConfig.getSanitizedUrl(_paymentTypeList[index].image),
                                fit: BoxFit.fitWidth,
                              ))),
                      SizedBox(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                _paymentTypeList[index].title,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                    color: MyTheme.font_grey,
                                    fontSize: 14,
                                    height: 1.6,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: buildPaymentMethodCheckContainer(isSelected),
              )
            ],
          );
        },
      ),
    );
  }

  Widget buildPaymentMethodCheckContainer(bool check) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 400),
      opacity: check ? 1 : 0,
      child: Container(
        height: 16,
        width: 16,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0), color: Colors.green),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(Icons.check, color: Colors.white, size: 10),
        ),
      ),
    );
  }

  BottomAppBar buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      child: Container(
        color: Colors.transparent,
        height: 50,
        child: Btn.minWidthFixHeight(
          minWidth: MediaQuery.of(context).size.width,
          height: 50,
          color: MyTheme.accent_color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            widget.paymentFor == PaymentFor.WalletRecharge
                ? AppLocalizations.of(context)!.recharge_wallet_ucf
                : widget.paymentFor == PaymentFor.ManualPayment
                ? AppLocalizations.of(context)!.proceed_all_caps
                : widget.paymentFor == PaymentFor.PackagePay
                ? AppLocalizations.of(context)!.buy_package_ucf
                : AppLocalizations.of(context)!
                .place_my_order_all_capital,
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            onPressPlaceOrderOrProceed();
          },
        ),
      ),
    );
  }

  Widget grandTotalSection() {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: MyTheme.soft_accent_color,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                AppLocalizations.of(context)!.total_amount_ucf,
                style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
              ),
            ),
            Visibility(
              visible:
                  widget.paymentFor != PaymentFor.ManualPayment &&
                  widget.paymentFor != PaymentFor.OrderRePayment,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: () {
                    onPressDetails();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.see_details_all_lower,
                    style: TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ValueListenableBuilder(
                valueListenable: _totalStringNotifier,
                builder: (context, String? totalString, child) {
                  return ValueListenableBuilder(
                    valueListenable: _grandTotalValueNotifier,
                    builder: (context, double? grandTotalValue, child) {
                      return ValueListenableBuilder(
                          valueListenable: _codChargeValueNotifier,
                          builder: (context, double codCharge, child) {
                            return Text(
                              balance(),
                              style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            );
                          });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  loading() {
    showDialog(
      context: context,
      builder: (context) {
        loadingcontext = context;
        return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(
                  width: 10,
                ),
                Text(AppLocalizations.of(context)!.please_wait_ucf),
              ],
            ));
      },
    );
  }
}
