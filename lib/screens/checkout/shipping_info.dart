
import 'dart:convert';
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/enum_classes.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/delivery_info_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/shipping_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/checkout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShippingInfo extends StatefulWidget {
  final String? guestCheckOutShippingAddress;

  ShippingInfo({
    Key? key,
    this.guestCheckOutShippingAddress,
  }) : super(key: key);

  @override
  _ShippingInfoState createState() => _ShippingInfoState();
}

class _ShippingInfoState extends State<ShippingInfo> {
  final ScrollController _mainScrollController = ScrollController();
  final ValueNotifier<List<SellerWithShipping>> _sellerWiseShippingOptionNotifier = ValueNotifier([]);
  final ValueNotifier<List<DeliveryInfoResponse>> _deliveryInfoListNotifier = ValueNotifier([]);
  final ValueNotifier<String?> _shippingCostStringNotifier = ValueNotifier(". . .");
  final ValueNotifier<bool> _isFetchDeliveryInfoNotifier = ValueNotifier(false);

  double mWidth = 0;
  double mHeight = 0;

  fetchAll() {
    getDeliveryInfo();
  }

  getDeliveryInfo() async {
    var deliveryInfoList = await (ShippingRepository()
        .getDeliveryInfo(guestAddress: widget.guestCheckOutShippingAddress));
    _isFetchDeliveryInfoNotifier.value = true;
    _deliveryInfoListNotifier.value = deliveryInfoList;

    List<SellerWithShipping> sellerWiseShippingOption = [];
    for (var element in _deliveryInfoListNotifier.value) {
      ShippingOption shippingOption;
      int? shippingId;
      bool isAllDigital =
          element.cartItems?.every((item) => item.isDigital ?? false) ?? false;
      bool hasCarriers = element.carriers?.data?.isNotEmpty ?? false;
      if (hasCarriers && !isAllDigital) {
        shippingOption = ShippingOption.Carrier;
        shippingId = element.carriers!.data!.first.id;
      } else {
        shippingOption = ShippingOption.HomeDelivery;
        shippingId = null;
      }

      sellerWiseShippingOption.add(SellerWithShipping(
        element.ownerId,
        shippingOption,
        shippingId,
        isAllDigital: isAllDigital,
      ));
    }
    _sellerWiseShippingOptionNotifier.value = sellerWiseShippingOption;

    getSetShippingCost();
  }

  getSetShippingCost() async {
    var shippingCostResponse = await AddressRepository()
        .getShippingCostResponse(shipping_type: _sellerWiseShippingOptionNotifier.value);

    if (shippingCostResponse.result == true &&
        shippingCostResponse.value_string != null) {
      _shippingCostStringNotifier.value = shippingCostResponse.value_string;
    } else {
      _shippingCostStringNotifier.value = "0.0";
    }
  }

  resetData() {
    clearData();
    fetchAll();
  }

  clearData() {
    _deliveryInfoListNotifier.value = [];
    _sellerWiseShippingOptionNotifier.value = [];
    _shippingCostStringNotifier.value = ". . .";
    _isFetchDeliveryInfoNotifier.value = false;
  }

  Future<void> _onRefresh() async {
    clearData();
    fetchAll();
  }

  onPopped(value) async {
    resetData();
  }

  changeShippingOption(ShippingOption option, int sellerIndex) {
    List<SellerWithShipping> options = List.from(_sellerWiseShippingOptionNotifier.value);
    options[sellerIndex].shippingOption = option;
    options[sellerIndex].shippingId = null;

    if (option == ShippingOption.PickUpPoint) {
      if (_deliveryInfoListNotifier.value[sellerIndex].pickupPoints!.isNotEmpty) {
        options[sellerIndex].shippingId =
            _deliveryInfoListNotifier.value[sellerIndex].pickupPoints!.first.id;
      }
    } else if (option == ShippingOption.Carrier) {
      if (_deliveryInfoListNotifier.value[sellerIndex].carriers!.data!.isNotEmpty) {
        options[sellerIndex].shippingId =
            _deliveryInfoListNotifier.value[sellerIndex].carriers!.data!.first.id;
      }
    }
    _sellerWiseShippingOptionNotifier.value = options;
    getSetShippingCost();
  }
  //
  // onPressProceed(context) async {
  //   bool hasError = _sellerWiseShippingOption.any((seller) =>
  //   !seller.isAllDigital && seller.shippingId == null);
  //
  //   if (hasError) {
  //     ToastComponent.showDialog(
  //       LangText(context).local.please_choose_valid_info,
  //     );
  //     return;
  //   }
  //
  //   var shippingCostResponse = await AddressRepository()
  //       .getShippingCostResponse(shipping_type: _sellerWiseShippingOption);
  //
  //   if (shippingCostResponse.result == false) {
  //     ToastComponent.showDialog(
  //       LangText(context).local.network_error,
  //     );
  //     return;
  //   }
  //
  //   Navigator.push(context, MaterialPageRoute(builder: (context) {
  //     return Checkout(
  //       title: AppLocalizations.of(context)!.checkout_ucf,
  //       paymentFor: PaymentFor.Order,
  //       guestCheckOutShippingAddress: widget.guestCheckOutShippingAddress,
  //     );
  //   })).then((value) {
  //     onPopped(value);
  //   });
  // }
  onPressProceed(context) async {
    // FIX: Update the validation logic here
    bool hasError = _sellerWiseShippingOptionNotifier.value.any((seller) =>
    !seller.isAllDigital &&
        seller.shippingOption != ShippingOption.HomeDelivery &&
        seller.shippingId == null);

    if (hasError) {
      ToastComponent.showDialog(
        LangText(context).local.please_choose_valid_info,
      );
      return;
    }

    // The rest of your code remains the same...
    var shippingCostResponse = await AddressRepository()
        .getShippingCostResponse(shipping_type: _sellerWiseShippingOptionNotifier.value);

    if (shippingCostResponse.result == false) {
      ToastComponent.showDialog(
        LangText(context).local.network_error,
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Checkout(
        title: AppLocalizations.of(context)!.checkout_ucf,
        paymentFor: PaymentFor.Order,
        guestCheckOutShippingAddress: widget.guestCheckOutShippingAddress,
      );
    })).then((value) {
      onPopped(value);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  @override
  void dispose() {
    _sellerWiseShippingOptionNotifier.dispose();
    _deliveryInfoListNotifier.dispose();
    _shippingCostStringNotifier.dispose();
    _isFetchDeliveryInfoNotifier.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidth = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection:
      app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(

          appBar: customAppBar(context) as PreferredSizeWidget?,
          bottomNavigationBar: buildBottomAppBar(context),
          body: buildBody(context)),
    );
  }

  RefreshIndicator buildBody(BuildContext context) {
    return RefreshIndicator(
      color: MyTheme.accent_color,
      backgroundColor: Colors.white,
      onRefresh: _onRefresh,
      displacement: 0,
      child: buildBodyChildren(context),
    );
  }

  Widget buildBodyChildren(BuildContext context) {
    return buildCartSellerList();
  }

  Widget buildShippingListBody(sellerIndex) {
    switch (_sellerWiseShippingOptionNotifier.value[sellerIndex].shippingOption) {
      case ShippingOption.PickUpPoint:
        return buildPickupPoint(sellerIndex);
      case ShippingOption.Carrier:
        return buildCarrierSection(sellerIndex);
      default:
        return Container();
    }
  }

  Widget buildPickupPoint(sellerArrayIndex) {
    return ValueListenableBuilder(
      valueListenable: _isFetchDeliveryInfoNotifier,
      builder: (context, bool isFetchDeliveryInfo, child) {
        if (!isFetchDeliveryInfo) {
          return buildCarrierShimmer();
        } else if (_deliveryInfoListNotifier.value[sellerArrayIndex].pickupPoints!.isNotEmpty) {
          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemCount: _deliveryInfoListNotifier.value[sellerArrayIndex].pickupPoints!.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return buildPickupPointItemCard(index, sellerArrayIndex);
            },
          );
        } else {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.pickup_point_is_unavailable_ucf,
                style: TextStyle(color: MyTheme.font_grey),
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildPickupPointItemCard(pickupPointIndex, sellerArrayIndex) {
    return GestureDetector(
      onTap: () {
        List<SellerWithShipping> options = List.from(_sellerWiseShippingOptionNotifier.value);
        options[sellerArrayIndex].shippingId =
            _deliveryInfoListNotifier.value[sellerArrayIndex]
                .pickupPoints![pickupPointIndex]
                .id;
        _sellerWiseShippingOptionNotifier.value = options;
        getSetShippingCost();
      },
      child: ValueListenableBuilder(
        valueListenable: _sellerWiseShippingOptionNotifier,
        builder: (context, List<SellerWithShipping> shippingOptions, child) {
          bool isSelected = shippingOptions[sellerArrayIndex].shippingId ==
              _deliveryInfoListNotifier.value[sellerArrayIndex]
                  .pickupPoints![pickupPointIndex]
                  .id;
          return Container(
            decoration: BoxDecorations.buildBoxDecoration_1(radius: 8).copyWith(
                border: isSelected
                    ? Border.all(color: MyTheme.accent_color, width: 1.0)
                    : Border.all(color: MyTheme.light_grey, width: 1.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: buildPickUpPointInfoItemChildren(
                  pickupPointIndex, sellerArrayIndex, isSelected),
            ),
          );
        },
      ),
    );
  }

  Column buildPickUpPointInfoItemChildren(pickupPointIndex, sellerArrayIndex, bool isSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 75,
                child: Text(
                  AppLocalizations.of(context)!.address_ucf,
                  style: TextStyle(
                    fontSize: 13,
                    color: MyTheme.dark_font_grey,
                  ),
                ),
              ),
              SizedBox(
                width: 175,
                child: Text(
                  _deliveryInfoListNotifier.value[sellerArrayIndex]
                      .pickupPoints![pickupPointIndex]
                      .name!,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 13,
                      color: MyTheme.dark_grey,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              buildShippingSelectMarkContainer(isSelected)
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 75,
                child: Text(
                  AppLocalizations.of(context)!.phone_ucf,
                  style: TextStyle(
                    fontSize: 13,
                    color: MyTheme.dark_font_grey,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: Text(
                  _deliveryInfoListNotifier.value[sellerArrayIndex]
                      .pickupPoints![pickupPointIndex]
                      .phone!,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 13,
                      color: MyTheme.dark_grey,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCarrierSection(sellerArrayIndex) {
    return ValueListenableBuilder(
      valueListenable: _isFetchDeliveryInfoNotifier,
      builder: (context, bool isFetchDeliveryInfo, child) {
        if (!isFetchDeliveryInfo) {
          return buildCarrierShimmer();
        } else if (_deliveryInfoListNotifier.value[sellerArrayIndex]
            .carriers!
            .data!
            .isNotEmpty) {
          return buildCarrierListView(sellerArrayIndex);
        } else {
          return buildCarrierNoData();
        }
      },
    );
  }

  SizedBox buildCarrierNoData() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.carrier_points_is_unavailable_ucf,
          style: TextStyle(color: MyTheme.font_grey),
        ),
      ),
    );
  }

  Widget buildCarrierListView(sellerArrayIndex) {
    return ListView.separated(
      itemCount: _deliveryInfoListNotifier.value[sellerArrayIndex].carriers!.data!.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 14);
      },
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return buildCarrierItemCard(index, sellerArrayIndex);
      },
    );
  }

  Widget buildCarrierShimmer() {
    return ShimmerHelper().buildListShimmer(item_count: 2, item_height: 50.0);
  }

  Widget buildCarrierItemCard(carrierIndex, sellerArrayIndex) {
    return GestureDetector(
      onTap: () {
        List<SellerWithShipping> options = List.from(_sellerWiseShippingOptionNotifier.value);
        options[sellerArrayIndex].shippingId =
            _deliveryInfoListNotifier.value[sellerArrayIndex]
                .carriers!
                .data![carrierIndex]
                .id;
        _sellerWiseShippingOptionNotifier.value = options;
        getSetShippingCost();
      },
      child: ValueListenableBuilder(
        valueListenable: _sellerWiseShippingOptionNotifier,
        builder: (context, List<SellerWithShipping> shippingOptions, child) {
          bool isSelected = shippingOptions[sellerArrayIndex].shippingId ==
              _deliveryInfoListNotifier.value[sellerArrayIndex]
                  .carriers!
                  .data![carrierIndex]
                  .id;
          return Container(
            decoration: BoxDecorations.buildBoxDecoration_1(radius: 8).copyWith(
                border: isSelected
                    ? Border.all(color: MyTheme.accent_color, width: 1.0)
                    : Border.all(color: MyTheme.light_grey, width: 1.0)),
            child: buildCarrierInfoItemChildren(carrierIndex, sellerArrayIndex, isSelected),
          );
        },
      ),
    );
  }

  Widget buildCarrierInfoItemChildren(carrierIndex, sellerArrayIndex, bool isSelected) {
    return Stack(
      children: [
        SizedBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 10,),
              SizedBox(
                height: 75.0,
                width: 75.0,
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder.png',
                  image: AppConfig.getSanitizedUrl(_deliveryInfoListNotifier.value[sellerArrayIndex]
                      .carriers!
                      .data![carrierIndex]
                      .logo!),
                  fit: BoxFit.fitWidth,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: DeviceInfo(context).width! / 3,
                      child: Text(
                        _deliveryInfoListNotifier.value[sellerArrayIndex]
                            .carriers!
                            .data![carrierIndex]
                            .name!,
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 13,
                            color: MyTheme.dark_font_grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "${_deliveryInfoListNotifier.value[sellerArrayIndex].carriers!.data![carrierIndex].transitTime} ${LangText(context).local.day_ucf}",
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 13,
                            color: MyTheme.dark_font_grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _deliveryInfoListNotifier.value[sellerArrayIndex]
                    .carriers!
                    .data![carrierIndex]
                    .transitPrice!
                    .replaceAll(RegExp(r'[a-zA-Z]+'), ''),
                maxLines: 2,
                style: TextStyle(
                    fontSize: 13,
                    color: MyTheme.dark_font_grey,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(
                width: 16,
              )
            ],
          ),
        ),
        Positioned(
          right: 16,
          top: 10,
          child: buildShippingSelectMarkContainer(isSelected),
        )
      ],
    );
  }

  Container buildShippingSelectMarkContainer(bool check) {
    return check
        ? Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0), color: Colors.green),
      child: const Padding(
        padding: EdgeInsets.all(3),
        child: Icon(Icons.check, color: Colors.white, size: 10),
      ),
    )
        : Container();
  }

  BottomAppBar buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        height: 50,
        child: Btn.minWidthFixHeight(
          minWidth: MediaQuery.of(context).size.width,
          height: 50,
          color: MyTheme.accent_color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
          child: Text(
            AppLocalizations.of(context)!.proceed_to_checkout,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            onPressProceed(context);
          },
        ),
      ),
    );
  }

  Widget customAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: MyTheme.white,
      automaticallyImplyLeading: false,
      title: buildAppbarTitle(context),
      leading: UsefulElements.backButton(context),
    );
  }

  SizedBox buildAppbarTitle(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 40,
      child: ValueListenableBuilder(
        valueListenable: _shippingCostStringNotifier,
        builder: (context, String? shippingCostString, child) {
          String formattedCost = shippingCostString ?? "";
          if (SystemConfig.systemCurrency != null && shippingCostString != null) {
            formattedCost = shippingCostString.replaceAll(
                SystemConfig.systemCurrency!.code!,
                SystemConfig.systemCurrency!.symbol!);
          }
          final regExp = RegExp(r'^([^0-9\s]+)([0-9])');
          if (regExp.hasMatch(formattedCost)) {
            formattedCost = formattedCost.replaceFirstMapped(
                regExp, (match) => "${match.group(1)} ${match.group(2)}");
          }
          return Text(
            "${AppLocalizations.of(context)!.shipping_cost_ucf} $formattedCost",
            style: TextStyle(
                fontSize: 16,
                color: MyTheme.dark_font_grey,
                fontWeight: FontWeight.bold),
          );
        },
      ),
    );
  }

  Widget buildChooseShippingOptions(BuildContext context, int sellerIndex) {
    bool hasCarriers =
        _deliveryInfoListNotifier.value[sellerIndex].carriers?.data?.isNotEmpty ?? false;

    return Container(
      color: MyTheme.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          hasCarriers
              ? buildCarrierOption(context, sellerIndex)
              : buildAddressOption(context, sellerIndex),
          const SizedBox(width: 14),
          if (pick_up_status.$) buildPickUpPointOption(context, sellerIndex),
        ],
      ),
    );
  }

  Widget buildPickUpPointOption(BuildContext context, sellerIndex) {
    return ValueListenableBuilder(
      valueListenable: _sellerWiseShippingOptionNotifier,
      builder: (context, List<SellerWithShipping> shippingOptions, child) {
        bool isSelected = shippingOptions[sellerIndex].shippingOption == ShippingOption.PickUpPoint;
        return Btn.basic(
          color: isSelected
              ? MyTheme.accent_color
              : MyTheme.accent_color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: MyTheme.accent_color)),
          padding: const EdgeInsets.only(right: 14),
          onPressed: () {
            changeShippingOption(ShippingOption.PickUpPoint, sellerIndex);
          },
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                Radio(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? MyTheme.white
                          : MyTheme.accent_color;
                    }),
                    value: ShippingOption.PickUpPoint,
                    groupValue: shippingOptions[sellerIndex].shippingOption,
                    onChanged: (dynamic newOption) {
                      changeShippingOption(newOption, sellerIndex);
                    }),
                Text(
                  AppLocalizations.of(context)!.pickup_point_ucf,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? MyTheme.white
                          : MyTheme.accent_color,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildAddressOption(BuildContext context, sellerIndex) {
    return ValueListenableBuilder(
      valueListenable: _sellerWiseShippingOptionNotifier,
      builder: (context, List<SellerWithShipping> shippingOptions, child) {
        bool isSelected = shippingOptions[sellerIndex].shippingOption == ShippingOption.HomeDelivery;
        return Btn.basic(
          color: isSelected
              ? MyTheme.accent_color
              : MyTheme.accent_color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: MyTheme.accent_color)),
          padding: const EdgeInsets.only(right: 14),
          onPressed: () {
            changeShippingOption(ShippingOption.HomeDelivery, sellerIndex);
          },
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                Radio(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? MyTheme.white
                          : MyTheme.accent_color;
                    }),
                    value: ShippingOption.HomeDelivery,
                    groupValue: shippingOptions[sellerIndex].shippingOption,
                    onChanged: (dynamic newOption) {
                      changeShippingOption(newOption, sellerIndex);
                    }),
                Text(
                  AppLocalizations.of(context)!.home_delivery_ucf,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? MyTheme.white
                          : MyTheme.accent_color,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildCarrierOption(BuildContext context, sellerIndex) {
    return ValueListenableBuilder(
      valueListenable: _sellerWiseShippingOptionNotifier,
      builder: (context, List<SellerWithShipping> shippingOptions, child) {
        bool isSelected = shippingOptions[sellerIndex].shippingOption == ShippingOption.Carrier;
        return Btn.basic(
          color: isSelected
              ? MyTheme.accent_color
              : MyTheme.accent_color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: MyTheme.accent_color)),
          padding: const EdgeInsets.only(right: 14),
          onPressed: () {
            changeShippingOption(ShippingOption.Carrier, sellerIndex);
          },
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                Radio(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? MyTheme.white
                          : MyTheme.accent_color;
                    }),
                    value: ShippingOption.Carrier,
                    groupValue: shippingOptions[sellerIndex].shippingOption,
                    onChanged: (dynamic newOption) {
                      changeShippingOption(newOption, sellerIndex);
                    }),
                Text(
                  AppLocalizations.of(context)!.carrier_ucf,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? MyTheme.white
                          : MyTheme.accent_color,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildCartSellerList() {
    return ValueListenableBuilder(
      valueListenable: _isFetchDeliveryInfoNotifier,
      builder: (context, bool isFetchDeliveryInfo, child) {
        if (!isFetchDeliveryInfo) {
          return ShimmerHelper()
              .buildListShimmer(item_count: 1, item_height: 200.0);
        } else if (_deliveryInfoListNotifier.value.isNotEmpty) {
          return buildCartSellerListBody();
        } else {
          return SizedBox(
              height: 100,
              child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.cart_is_empty,
                    style: TextStyle(color: MyTheme.font_grey),
                  )));
        }
      },
    );
  }

  SingleChildScrollView buildCartSellerListBody() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: ValueListenableBuilder(
          valueListenable: _deliveryInfoListNotifier,
          builder: (context, List<DeliveryInfoResponse> deliveryInfoList, child) {
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              separatorBuilder: (context, index) => const SizedBox(height: 26),
              itemCount: deliveryInfoList.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return buildCartSellerListItem(index, context);
              },
            );
          },
        ),
      ),
    );
  }

  Column buildCartSellerListItem(int index, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            _deliveryInfoListNotifier.value[index].name!,
            style: const TextStyle(
                color: MyTheme.accent_color,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
        ),
        buildCartSellerItemList(index),
        if (!_sellerWiseShippingOptionNotifier.value[index].isAllDigital)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Text(
                  LangText(context).local.choose_delivery_ucf,
                  style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              const SizedBox(height: 5),
              buildChooseShippingOptions(context, index),
              const SizedBox(height: 10),
              buildShippingListBody(index),
            ],
          ),
      ],
    );
  }

  SingleChildScrollView buildCartSellerItemList(seller_index) {
    return SingleChildScrollView(
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemCount: _deliveryInfoListNotifier.value[seller_index].cartItems!.length,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return buildCartSellerItemCard(index, seller_index);
        },
      ),
    );
  }

  buildCartSellerItemCard(itemIndex, sellerIndex) {
    return Container(
      height: 80,
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child:
      Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        SizedBox(
          width: DeviceInfo(context).width! / 4,
          height: 120,
          child: ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(6), right: Radius.zero),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/placeholder.png',
              image: AppConfig.getSanitizedUrl(_deliveryInfoListNotifier.value[sellerIndex]
                  .cartItems![itemIndex]
                  .productThumbnailImage!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: DeviceInfo(context).width! / 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _deliveryInfoListNotifier.value[sellerIndex]
                      .cartItems![itemIndex]
                      .productName!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// Enum and Class definitions remain the same
enum ShippingOption { HomeDelivery, PickUpPoint, Carrier }

class SellerWithShipping {
  int? sellerId;
  ShippingOption shippingOption;
  int? shippingId;
  bool isAllDigital;

  SellerWithShipping(this.sellerId, this.shippingOption, this.shippingId,
      {this.isAllDigital = false});

  Map toJson() => {
    'seller_id': sellerId,
    'shipping_type': shippingOption == ShippingOption.HomeDelivery
        ? "home_delivery"
        : shippingOption == ShippingOption.Carrier
        ? "carrier"
        : "pickup_point",
    'shipping_id': shippingId,
  };
}