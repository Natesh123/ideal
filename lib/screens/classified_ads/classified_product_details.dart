import 'dart:async';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/text_styles.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/classified_ads_details_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/classified_ads_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/screens/brand_products.dart';
import 'package:active_ecommerce_cms_demo_app/screens/common_webview_screen.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/classified_product_mini_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../custom/lang_text.dart';
import '../../repositories/classified_product_repository.dart';

class ClassifiedAdsDetails extends StatefulWidget {
  String slug;

  ClassifiedAdsDetails({super.key, required this.slug});

  @override
  _ClassifiedAdsDetailsState createState() => _ClassifiedAdsDetailsState();
}

class _ClassifiedAdsDetailsState extends State<ClassifiedAdsDetails>
    with TickerProviderStateMixin {
  final ValueNotifier<bool> _showCopiedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showPhoneNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentImageNotifier = ValueNotifier<int>(0);
  final ScrollController _mainScrollController = ScrollController(
    initialScrollOffset: 0.0,
  );

  final ScrollController _variantScrollController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();

  final ValueNotifier<double> _scrollPositionNotifier = ValueNotifier<double>(0.0);

  Animation? _colorTween;
  late AnimationController _ColorAnimationController;

  final CarouselSliderController _carouselController = CarouselSliderController();

  //init values

  final bool _isInWishList = false;
  final ValueNotifier<bool> _productDetailsFetchedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<ClassifiedProductDetailsResponseDatum?> _productDetailsNotifier =
      ValueNotifier<ClassifiedProductDetailsResponseDatum?>(null);

  final _productImageList = [];

  final ValueNotifier<double> _opacityNotifier = ValueNotifier<double>(0.0);

  final List<ClassifiedAdsMiniData> _relatedProducts = [];
  final ValueNotifier<bool> _relatedProductInitNotifier = ValueNotifier<bool>(false);
  fetchAll() {
    fetchProductDetails();

    fetchRelatedProducts();
  }

  fetchProductDetails() async {
    var productDetailsResponse = await ClassifiedProductRepository()
        .getClassifiedProductsDetails(widget.slug);

    if (productDetailsResponse.data!.isNotEmpty) {
      _productDetailsNotifier.value = productDetailsResponse.data!.first;
      for (var element in _productDetailsNotifier.value!.photos!.data!) {
        _productImageList.add(element.url);
      }
      _productDetailsFetchedNotifier.value = true;
    }
  }

  fetchRelatedProducts() async {
    var relatedProductResponse = await ClassifiedProductRepository()
        .getClassifiedOtherAds(slug: widget.slug);

    _relatedProducts.addAll(relatedProductResponse.data!);
    _relatedProductInitNotifier.value = true;
  }

  reset() {
    _currentImageNotifier.value = 0;
    _productImageList.clear();
    _relatedProducts.clear();
    _productDetailsFetchedNotifier.value = false;
    _productDetailsNotifier.value = null;
    _relatedProductInitNotifier.value = false;
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  onCopyTap() {
    _showCopiedNotifier.value = true;
    Timer(const Duration(seconds: 3), () {
      _showCopiedNotifier.value = false;
    });
  }

  onPressShare(context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder<bool>(
          valueListenable: _showCopiedNotifier,
          builder: (context, showCopied, _) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                top: 36.0,
                left: 36.0,
                right: 36.0,
                bottom: 2.0,
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Btn.minWidthFixHeight(
                          minWidth: 75.0,
                          height: 26.0,
                          color: Color.fromRGBO(253, 253, 253, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.copy_product_link_ucf,
                            style: TextStyle(color: MyTheme.medium_grey),
                          ),
                          onPressed: () {
                            onCopyTap();

                          },
                        ),
                      ),
                      showCopied
                          ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              AppLocalizations.of(context)!.copied_ucf,
                              style: TextStyle(
                                color: MyTheme.medium_grey,
                                fontSize: 12,
                              ),
                            ),
                          )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Btn.minWidthFixHeight(
                          minWidth: 75.0,
                          height: 26.0,
                          color: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.share_options_ucf,
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            // print("share links ${_productDetailsNotifier.value!.link}");
                            Share.share(_productDetailsNotifier.value!.link!);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding:
                          app_language_rtl.$!
                              ? EdgeInsets.only(left: 8.0)
                              : EdgeInsets.only(right: 8.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 30,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: MyTheme.font_grey,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          LangText(context).local.close_all_capital,
                          style: TextStyle(color: MyTheme.font_grey),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    _ColorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 0),
    );

    _colorTween = ColorTween(
      begin: Colors.transparent,
      end: Colors.white,
    ).animate(_ColorAnimationController);

    _mainScrollController.addListener(() {
      _scrollPositionNotifier.value = _mainScrollController.position.pixels;

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (100 > _scrollPositionNotifier.value && _scrollPositionNotifier.value > 1) {
          _opacityNotifier.value = _scrollPositionNotifier.value / 100;
        }
      }

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (100 > _scrollPositionNotifier.value && _scrollPositionNotifier.value > 1) {
          _opacityNotifier.value = _scrollPositionNotifier.value / 100;

          if (100 > _scrollPositionNotifier.value) {
            _opacityNotifier.value = 1;
          }
        }
      }
    });
    fetchAll();
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _variantScrollController.dispose();
    _imageScrollController.dispose();
    _showCopiedNotifier.dispose();
    _showPhoneNotifier.dispose();
    _currentImageNotifier.dispose();
    _scrollPositionNotifier.dispose();
    _productDetailsFetchedNotifier.dispose();
    _productDetailsNotifier.dispose();
    _opacityNotifier.dispose();
    _relatedProductInitNotifier.dispose();
    _ColorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        body: RefreshIndicator(
          color: MyTheme.accent_color,
          backgroundColor: Colors.white,
          onRefresh: _onPageRefresh,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              ValueListenableBuilder(
                valueListenable: _opacityNotifier,
                builder: (context, double opacity, child) {
                  return SliverAppBar(
                    elevation: 0,
                    backgroundColor: Colors.white.withOpacity(opacity),
                    pinned: true,
                    automaticallyImplyLeading: false,
                    title: Row(
                      children: [
                        Builder(
                          builder: (context) => InkWell(
                            onTap: () {
                              return Navigator.of(context).pop();
                            },
                            child: Container(
                              decoration: BoxDecorations.buildCircularButtonDecoration_1(),
                              width: 36,
                              height: 36,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.arrow_left,
                                  color: MyTheme.dark_font_grey,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: _scrollPositionNotifier,
                          builder: (context, double scrollPosition, child) {
                            return ValueListenableBuilder(
                              valueListenable: _productDetailsNotifier,
                              builder: (context, ClassifiedProductDetailsResponseDatum? productDetails, child) {
                                return AnimatedOpacity(
                                  opacity: scrollPosition > 350 ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: SizedBox(
                                    width: DeviceInfo(context).width! / 1.8,
                                    child: Text(
                                      productDetails != null ? productDetails.name! : '',
                                      style: TextStyle(
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            onPressShare(context);
                          },
                          child: Container(
                            decoration: BoxDecorations.buildCircularButtonDecoration_1(),
                            width: 36,
                            height: 36,
                            child: Center(
                              child: Icon(
                                Icons.share_outlined,
                                color: MyTheme.dark_font_grey,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    expandedHeight: 375.0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: buildProductSliderImageSection(),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: ValueListenableBuilder(
                  valueListenable: _productDetailsNotifier,
                  builder: (context, ClassifiedProductDetailsResponseDatum? productDetails, child) {
                    return Container(
                      decoration: BoxDecorations.buildBoxDecoration_1(),
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 14, right: 14),
                            child: productDetails != null
                                ? Text(
                                    productDetails.name!,
                                    style: TextStyles.smallTitleTexStyle(),
                                    maxLines: 2,
                                  )
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 14, right: 14),
                            child: productDetails != null
                                ? buildMainPriceRow()
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 14, right: 14),
                            child: productDetails != null
                                ? buildBrandRow()
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 50.0,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: productDetails != null
                                ? buildSellerRow(context)
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 50.0,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 10, right: 14),
                            child: productDetails != null
                                ? buildLocationContainer(context)
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 14,
                              left: 10,
                              right: 14,
                              bottom: 20,
                            ),
                            child: productDetails != null
                                ? buildContractContainer(context)
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: MyTheme.white,
                      margin: EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              20.0,
                              16.0,
                              0.0,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.description_ucf,
                              style: TextStyle(
                                color: MyTheme.dark_font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              8.0,
                              0.0,
                              8.0,
                              8.0,
                            ),
                            child: ValueListenableBuilder(
                              valueListenable: _productDetailsNotifier,
                              builder: (context, ClassifiedProductDetailsResponseDatum? productDetails, child) {
                                if (productDetails == null) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 8.0,
                                    ),
                                    child: ShimmerHelper().buildBasicShimmer(
                                      height: 60.0,
                                    ),
                                  );
                                }
                                return buildExpandableDescription(productDetails.description!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    divider(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return CommonWebviewScreen(
                                url:
                                    "${AppConfig.RAW_BASE_URL}/mobile-page/seller-policy",
                                page_name:
                                    AppLocalizations.of(
                                      context,
                                    )!.seller_policy_ucf,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        color: MyTheme.white,
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18.0,
                            14.0,
                            18.0,
                            14.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.seller_policy_ucf,
                                style: TextStyle(
                                  color: MyTheme.dark_font_grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/arrow.png",
                                height: 11,
                                width: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    divider(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return CommonWebviewScreen(
                                url:
                                    "${AppConfig.RAW_BASE_URL}/mobile-page/return-policy",
                                page_name:
                                    AppLocalizations.of(
                                      context,
                                    )!.return_policy_ucf,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        color: MyTheme.white,
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18.0,
                            14.0,
                            18.0,
                            14.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.return_policy_ucf,
                                style: TextStyle(
                                  color: MyTheme.dark_font_grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/arrow.png",
                                height: 11,
                                width: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    divider(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return CommonWebviewScreen(
                                url:
                                    "${AppConfig.RAW_BASE_URL}/mobile-page/support-policy",
                                page_name:
                                    AppLocalizations.of(
                                      context,
                                    )!.support_policy_ucf,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        color: MyTheme.white,
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18.0,
                            14.0,
                            18.0,
                            14.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.support_policy_ucf,
                                style: TextStyle(
                                  color: MyTheme.dark_font_grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/arrow.png",
                                height: 11,
                                width: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    divider(),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0, 24.0, 18.0, 0.0),
                    child: ValueListenableBuilder(
                      valueListenable: _productDetailsNotifier,
                      builder: (context, ClassifiedProductDetailsResponseDatum? productDetails, child) {
                        return Text(
                          "${AppLocalizations.of(context)!.other_ads_of_ucf} ${productDetails != null ? productDetails.category! : ""}",
                          style: const TextStyle(
                            color: MyTheme.dark_font_grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    height: 240,
                    child: buildProductsMayLikeList(),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLocationContainer(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, ClassifiedProductDetailsResponseDatum? productDetails, child) {
        if (productDetails == null) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined, size: 24),
            const SizedBox(width: 10),
            SizedBox(
              width: DeviceInfo(context).width! / 1.4,
              child: Text(
                productDetails.location!,
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: MyTheme.dark_font_grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildContractContainer(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, ClassifiedProductDetailsResponseDatum? productDetails, child) {
        if (productDetails == null) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.phone, size: 24),
            const SizedBox(width: 10),
            ValueListenableBuilder(
              valueListenable: _showPhoneNotifier,
              builder: (context, bool showPhone, child) {
                return SizedBox(
                  width: DeviceInfo(context).width! / 2,
                  child: InkWell(
                    onTap: () {
                      _showPhoneNotifier.value = !showPhone;
                    },
                    child: Text(
                      showPhone ? productDetails.phone! : "01XXXXXXXXX",
                      style: TextStyle(fontSize: 12, color: MyTheme.dark_font_grey),
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            Material(
              elevation: 8,
              color: MyTheme.accent_color,
              borderRadius: BorderRadius.circular(50),
              child: IconButton(
                onPressed: () {
                  launchUrl(Uri.parse("tel://${productDetails.phone}"));
                },
                icon: Icon(Icons.phone_forwarded, color: MyTheme.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Row buildMainPriceRow() {
    return Row(
      children: [
        Text(
          _productDetailsNotifier.value!.unitPrice!,
          style: TextStyle(
            color: MyTheme.accent_color,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget buildSellerRow(BuildContext context) {
    return Container(
      color: MyTheme.light_grey,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * (.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.seller_ucf,
                  style: const TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
                ),
                Text(
                  _productDetailsNotifier.value!.addedBy!,
                  style: TextStyle(
                    color: MyTheme.font_grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTotalPriceRow() {
    return Container(
      height: 40,
      color: MyTheme.amber,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? const EdgeInsets.only(left: 8.0)
                : const EdgeInsets.only(right: 8.0),
            child: SizedBox(
              width: 75,
              child: Text(
                AppLocalizations.of(context)!.total_price_ucf,
                style: const TextStyle(
                  color: Color.fromRGBO(153, 153, 153, 1),
                  fontSize: 10,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              _productDetailsNotifier.value!.unitPrice!,
              style: TextStyle(
                color: MyTheme.accent_color,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildVariantShimmers() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildBrandRow() {
    var brand = _productDetailsNotifier.value!.brand!;
    return brand.id! > 0
        ? InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return BrandProducts(slug: brand.slug!);
                  },
                ),
              );
            },
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? const EdgeInsets.only(left: 8.0)
                      : const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 75,
                    child: Text(
                      AppLocalizations.of(context)!.brand_ucf,
                      style: const TextStyle(
                        color: Color.fromRGBO(153, 153, 153, 1),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    brand.name!,
                    style: TextStyle(
                      color: MyTheme.font_grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  ExpandableNotifier buildExpandableDescription(String description) {
    return ExpandableNotifier(
      child: ScrollOnExpand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expandable(
              collapsed: SizedBox(
                height: 50,
                child: Html(data: description),
              ),
              expanded: SizedBox(
                child: Html(data: description),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Builder(
                  builder: (context) {
                    var controller = ExpandableController.of(context)!;
                    return Btn.basic(
                      child: Text(
                        !controller.expanded
                            ? AppLocalizations.of(context)!.view_more
                            : AppLocalizations.of(context)!.show_less_ucf,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () {
                        controller.toggle();
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductsMayLikeList() {
    return ValueListenableBuilder(
      valueListenable: _relatedProductInitNotifier,
      builder: (context, bool relatedProductInit, child) {
        if (!relatedProductInit && _relatedProducts.isEmpty) {
          return Row(
            children: [
              Padding(
                padding: app_language_rtl.$!
                    ? const EdgeInsets.only(left: 8.0)
                    : const EdgeInsets.only(right: 8.0),
                child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3,
                ),
              ),
              Padding(
                padding: app_language_rtl.$!
                    ? const EdgeInsets.only(left: 8.0)
                    : const EdgeInsets.only(right: 8.0),
                child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 0.0),
                child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3,
                ),
              ),
            ],
          );
        } else if (relatedProductInit && _relatedProducts.isNotEmpty) {
          return SizedBox(
            height: 248,
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              padding: const EdgeInsets.all(16),
              itemCount: _relatedProducts.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return ClassifiedMiniProductCard(
                  id: _relatedProducts[index].id,
                  slug: widget.slug,
                  image: _relatedProducts[index].thumbnailImage,
                  name: _relatedProducts[index].name,
                  unit_price: _relatedProducts[index].unitPrice,
                  condition: _relatedProducts[index].condition,
                );
              },
            ),
          );
        } else {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_related_product,
                style: TextStyle(color: MyTheme.font_grey),
              ),
            ),
          );
        }
      },
    );
  }

  openPhotoDialog(BuildContext context, path) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          child: Stack(
            children: [
              PhotoView(
                enableRotation: true,
                heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
                imageProvider: NetworkImage(path),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: ShapeDecoration(
                    color: MyTheme.medium_grey_50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        topRight: Radius.circular(25),
                        topLeft: Radius.circular(25),
                      ),
                    ),
                  ),
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: Icon(Icons.clear, color: MyTheme.white),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  buildProductImageSection() {
    return ValueListenableBuilder(
      valueListenable: _currentImageNotifier,
      builder: (context, int currentImage, child) {
        if (_productImageList.isEmpty) {
          return Row(
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ShimmerHelper().buildBasicShimmer(
                        height: 40.0,
                        width: 40.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ShimmerHelper().buildBasicShimmer(
                        height: 40.0,
                        width: 40.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ShimmerHelper().buildBasicShimmer(
                        height: 40.0,
                        width: 40.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ShimmerHelper().buildBasicShimmer(
                        height: 40.0,
                        width: 40.0,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(height: 190.0),
                ),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 250,
                width: 64,
                child: Scrollbar(
                  controller: _imageScrollController,
                  thickness: 4.0,
                  child: Padding(
                    padding: app_language_rtl.$!
                        ? const EdgeInsets.only(left: 8.0)
                        : const EdgeInsets.only(right: 8.0),
                    child: ListView.builder(
                      itemCount: _productImageList.length,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        int itemIndex = index;
                        return GestureDetector(
                          onTap: () {
                            _currentImageNotifier.value = itemIndex;
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 2.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: currentImage == itemIndex
                                    ? MyTheme.accent_color
                                    : const Color.fromRGBO(112, 112, 112, .3),
                                width: currentImage == itemIndex ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FadeInImage.assetNetwork(
                                placeholder: 'assets/placeholder.png',
                                image: _productImageList[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  openPhotoDialog(context, _productImageList[currentImage]);
                },
                child: SizedBox(
                  height: 250,
                  width: MediaQuery.of(context).size.width - 96,
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder_rectangle.png',
                    image: _productImageList[currentImage],
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget buildProductSliderImageSection() {
    return ValueListenableBuilder(
      valueListenable: _currentImageNotifier,
      builder: (context, int currentImage, child) {
        if (_productImageList.isEmpty) {
          return ShimmerHelper().buildBasicShimmer(height: 190.0);
        } else {
          return CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              aspectRatio: 355 / 375,
              viewportFraction: 1,
              initialPage: 0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 1000),
              autoPlayCurve: Curves.easeInExpo,
              enlargeCenterPage: false,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, reason) {
                _currentImageNotifier.value = index;
              },
            ),
            items: _productImageList.map((i) {
              return Builder(
                builder: (BuildContext context) {
                  return Stack(
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          openPhotoDialog(
                            context,
                            _productImageList[currentImage],
                          );
                        },
                        child: SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder_rectangle.png',
                            image: i,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _productImageList.length,
                            (index) => Container(
                              width: 7.0,
                              height: 7.0,
                              margin: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 4.0,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentImage == index
                                    ? MyTheme.font_grey
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget divider() {
    return Container(color: MyTheme.light_grey, height: 5);
  }
}
