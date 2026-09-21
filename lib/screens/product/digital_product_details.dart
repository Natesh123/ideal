import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_html/flutter_html.dart';
import '../auth/login.dart';

import '../../app_config.dart';
import '../../custom/box_decorations.dart';
import '../../custom/btn.dart';
import '../../custom/device_info.dart';
import '../../custom/lang_text.dart';
import '../../custom/quantity_input.dart';
import '../../custom/toast_component.dart';
import '../../data_model/product_details_response.dart';
import '../../helpers/color_helper.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../helpers/shimmer_helper.dart';
import '../../helpers/system_config.dart';
import '../../my_theme.dart';
import '../../presenter/cart_counter.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/wishlist_repository.dart';
import '../../ui_elements/mini_product_card.dart';
import '../../ui_elements/top_selling_products_card.dart';
import '../brand_products.dart';
import '../chat/chat.dart';
import '../checkout/cart.dart';
import '../seller_details.dart';
import '../video_description_screen.dart';
import 'product_reviews.dart';
import 'widgets/product_slider_image_widget.dart';
import 'widgets/tappable_icon_widget.dart';

class DigitalProductDetails extends StatefulWidget {
  String slug;

  DigitalProductDetails({super.key, required this.slug});

  @override
  _DigitalProductDetailsState createState() => _DigitalProductDetailsState();
}

class _DigitalProductDetailsState extends State<DigitalProductDetails>
    with TickerProviderStateMixin {
  final ValueNotifier<bool> _showCopiedNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _appbarPriceStringNotifier = ValueNotifier(". . .");
  final ValueNotifier<int> _currentImageNotifier = ValueNotifier(0);
  final ScrollController _mainScrollController = ScrollController(
    initialScrollOffset: 0.0,
  );
  final ScrollController _colorScrollController = ScrollController();
  final ScrollController _variantScrollController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();
  TextEditingController sellerChatTitleController = TextEditingController();
  TextEditingController sellerChatMessageController = TextEditingController();

  final ValueNotifier<double> _scrollPositionNotifier = ValueNotifier(0.0);

  Animation? _colorTween;
  late AnimationController _ColorAnimationController;

  final CarouselSliderController _carouselController = CarouselSliderController();
  late BuildContext loadingcontext;

  //init values

  final ValueNotifier<bool> _isInWishListNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _productDetailsFetchedNotifier = ValueNotifier(false);
  final ValueNotifier<DetailedProduct?> _productDetailsNotifier = ValueNotifier(null);
  final _productImageList = [];
  final _colorList = [];
  final ValueNotifier<int> _selectedColorIndexNotifier = ValueNotifier(0);
  final _selectedChoices = [];
  final ValueNotifier<String> _choiceStringNotifier = ValueNotifier("");
  final ValueNotifier<String?> _variantNotifier = ValueNotifier("");
  final ValueNotifier<String?> _totalPriceNotifier = ValueNotifier("...");
  var _singlePrice;
  var _singlePriceString;
  final ValueNotifier<int?> _quantityNotifier = ValueNotifier(1);
  final ValueNotifier<int?> _stockNotifier = ValueNotifier(0);
  final ValueNotifier<dynamic> _stockTxtNotifier = ValueNotifier(null);

  final ValueNotifier<double> _opacityNotifier = ValueNotifier(0.0);

  final List<dynamic> _relatedProducts = [];
  final ValueNotifier<bool> _relatedProductInitNotifier = ValueNotifier(false);
  final List<dynamic> _topProducts = [];
  final ValueNotifier<bool> _topProductInitNotifier = ValueNotifier(false);

  @override
  void initState() {
    quantityText.text = "${_quantityNotifier.value ?? 0}";
    _ColorAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 0),
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


  fetchAll() {
    fetchProductDetails();
    if (is_logged_in.$ == true) {
      fetchWishListCheckInfo();
    }
    fetchRelatedProducts();
    fetchTopProducts();
  }

  fetchProductDetails() async {
    var productDetailsResponse = await ProductRepository().getProductDetails(
      slug: widget.slug,
      userId: user_id.$,
    );

    if (productDetailsResponse.detailed_products!.isNotEmpty) {
      _productDetailsNotifier.value = productDetailsResponse.detailed_products![0];
      sellerChatTitleController.text =
          productDetailsResponse.detailed_products![0].name!;
    }

    setProductDetailValues();
  }

  fetchRelatedProducts() async {
    var relatedProductResponse = await ProductRepository()
        .getFrequentlyBoughProducts(slug: widget.slug);
    _relatedProducts.addAll(relatedProductResponse.products!);
    _relatedProductInitNotifier.value = true;
  }

  fetchTopProducts() async {
    var topProductResponse = await ProductRepository()
        .getTopFromThisSellerProducts(slug: widget.slug);
    _topProducts.addAll(topProductResponse.products!);
    _topProductInitNotifier.value = true;
  }

  setProductDetailValues() {
    if (_productDetailsNotifier.value != null) {
      print("Digital Product Description: ${_productDetailsNotifier.value!.description}");
      // controller.loadHtmlString(makeHtml(_productDetailsNotifier.value!.description!));
      _appbarPriceStringNotifier.value = _productDetailsNotifier.value!.price_high_low;
      _singlePrice = _productDetailsNotifier.value!.calculable_price;
      _singlePriceString = _productDetailsNotifier.value!.main_price;
      // fetchVariantPrice();
      _stockNotifier.value = _productDetailsNotifier.value!.current_stock;
      for (var photo in _productDetailsNotifier.value!.photos!) {
        _productImageList.add(photo.path);
      }

      for (var choice_opiton in _productDetailsNotifier.value!.choice_options!) {
        _selectedChoices.add(choice_opiton.options![0]);
      }
      for (var color in _productDetailsNotifier.value!.colors!) {
        _colorList.add(color);
      }
      setChoiceString();
      fetchAndSetVariantWiseInfo(change_appbar_string: true);
      _productDetailsFetchedNotifier.value = true;
    }
  }

  setChoiceString() {
    _choiceStringNotifier.value = _selectedChoices.join(",").toString();
    print(_choiceStringNotifier.value);
  }


  fetchWishListCheckInfo() async {
    var wishListCheckResponse = await WishListRepository()
        .isProductInUserWishList(product_slug: widget.slug);

    if (wishListCheckResponse.is_in_wishlist != null) {
      _isInWishListNotifier.value = wishListCheckResponse.is_in_wishlist!;
    } else {
      _isInWishListNotifier.value = false;
    }
  }

  addToWishList() async {
    var wishListCheckResponse = await WishListRepository().add(
      product_slug: widget.slug,
    );

    _isInWishListNotifier.value = wishListCheckResponse.is_in_wishlist;
  }

  removeFromWishList() async {
    var wishListCheckResponse = await WishListRepository().remove(
      product_slug: widget.slug,
    );

    _isInWishListNotifier.value = wishListCheckResponse.is_in_wishlist;
  }

  onWishTap() {
    if (is_logged_in.$ == false) {
      showLoginWarning();
      return;
    }

    if (_isInWishListNotifier.value) {
      _isInWishListNotifier.value = false;
      removeFromWishList();
    } else {
      _isInWishListNotifier.value = true;
      addToWishList();
    }
  }

  setQuantity(quantity) {
    quantityText.text = "${quantity ?? 0}";
  }

  fetchAndSetVariantWiseInfo({bool change_appbar_string = true}) async {
    var colorString = _colorList.isNotEmpty
        ? _colorList[_selectedColorIndexNotifier.value].toString().replaceAll("#", "")
        : "";

    var variantResponse = await ProductRepository().getVariantWiseInfo(
      slug: widget.slug,
      color: colorString,
      variants: _choiceStringNotifier.value,
      qty: _quantityNotifier.value,
    );
    _stockNotifier.value = variantResponse.variantData!.stock;
    _stockTxtNotifier.value = variantResponse.variantData!.stockTxt;
    if (_quantityNotifier.value! > _stockNotifier.value!) {
      _quantityNotifier.value = _stockNotifier.value;
    }

    _variantNotifier.value = variantResponse.variantData!.variant;
    _totalPriceNotifier.value = variantResponse.variantData!.price;

    int pindex = 0;
    _productDetailsNotifier.value!.photos?.forEach((photo) {
      if (photo.variant == _variantNotifier.value &&
          variantResponse.variantData!.image != "") {
        _currentImageNotifier.value = pindex;
        _carouselController.jumpToPage(pindex);
      }
      pindex++;
    });
    setQuantity(_quantityNotifier.value);
  }

  reset() {
    restProductDetailValues();
    _currentImageNotifier.value = 0;
    _productImageList.clear();
    _colorList.clear();
    _selectedChoices.clear();
    _relatedProducts.clear();
    _topProducts.clear();
    _choiceStringNotifier.value = "";
    _variantNotifier.value = "";
    _selectedColorIndexNotifier.value = 0;
    _quantityNotifier.value = 1;
    _productDetailsFetchedNotifier.value = false;
    _isInWishListNotifier.value = false;
    sellerChatTitleController.clear();
  }

  restProductDetailValues() {
    _appbarPriceStringNotifier.value = " . . .";
    _productDetailsNotifier.value = null;
    _productImageList.clear();
    _currentImageNotifier.value = 0;
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  _onVariantChange(choice_options_index, value) {
    _selectedChoices[choice_options_index] = value;
    setChoiceString();
    fetchAndSetVariantWiseInfo();
  }

  _onColorChange(index) {
    _selectedColorIndexNotifier.value = index;
    fetchAndSetVariantWiseInfo();
  }

  onPressAddToCart(context, snackbar) {
    addToCart(mode: "add_to_cart", context: context, snackbar: snackbar);
  }

  onPressBuyNow(context) {
    addToCart(mode: "buy_now", context: context);
  }

  addToCart({mode, BuildContext? context, snackbar}) async {
    if (is_logged_in.$ == false) {
      showLoginWarning();
      return;
    }

    /*if (!guest_checkout_status.$) {
      if (is_logged_in.$ == false) {
        context?.go("/users/login");
        return;
      }
    }*/

    var cartAddResponse = await CartRepository().getCartAddResponse(
      _productDetailsNotifier.value!.id,
      _variantNotifier.value,
      user_id.$,
      1,
    );

    temp_user_id.$ = cartAddResponse.tempUserId;
    temp_user_id.save();

    if (cartAddResponse.result == false) {
      ToastComponent.showDialog(cartAddResponse.message);
      return;
    } else {
      Provider.of<CartCounter>(context!, listen: false).getCount();

      if (mode == "add_to_cart") {
        if (snackbar != null) {
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
        }
        reset();
        fetchAll();
      } else if (mode == 'buy_now') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Cart(has_bottomnav: false);
            },
          ),
        ).then((value) {
          onPopped(value);
        });
      }
    }
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  onCopyTap(ValueSetter<bool> setShowCopied) {
    setShowCopied(true);
    Timer timer = Timer(Duration(seconds: 3), () {
      setShowCopied(false);
    });
  }

  onPressShare(context) {
    return showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: _showCopiedNotifier,
          builder: (context, bool showCopied, child) {
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
                          minWidth: 75,
                          height: 26,
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
                            onCopyTap((val) => _showCopiedNotifier.value = val);
                            Clipboard.setData(
                              ClipboardData(text: _productDetailsNotifier.value!.link ?? ""),
                            );
                            Clipboard.setData(
                              ClipboardData(text: _productDetailsNotifier.value!.link!),
                            ).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Copied to clipboard"),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(milliseconds: 300),
                                ),
                              );
                            });
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
                          minWidth: 75,
                          height: 26,
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

  onTapSellerChat() {
    return showDialog(
      context: context,
      builder:
          (_) => Directionality(
            textDirection:
                app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.title_ucf,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: sellerChatTitleController,
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.enter_title_ucf,
                              hintStyle: TextStyle(
                                fontSize: 12.0,
                                color: MyTheme.textfield_grey,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: MyTheme.textfield_grey,
                                  width: 0.5,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: MyTheme.textfield_grey,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "${AppLocalizations.of(context)!.message_ucf} *",
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          height: 55,
                          child: TextField(
                            controller: sellerChatMessageController,
                            autofocus: false,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(
                                    context,
                                  )!.enter_message_ucf,
                              hintStyle: TextStyle(
                                fontSize: 12.0,
                                color: MyTheme.textfield_grey,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: MyTheme.textfield_grey,
                                  width: 0.5,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: MyTheme.textfield_grey,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              contentPadding: EdgeInsets.only(
                                right: 16.0,
                                left: 8.0,
                                top: 16.0,
                                bottom: 16.0,
                              ),
                            ),
                          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 30,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: MyTheme.light_grey,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.close_all_capital,
                          style: TextStyle(color: MyTheme.font_grey),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    SizedBox(width: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 30,
                        color: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: MyTheme.light_grey,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.send_all_capital,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          onPressSendMessage();
                        },
                      ),
                    ),
                  ],
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
              SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.please_wait_ucf),
            ],
          ),
        );
      },
    );
  }

  showLoginWarning() {
    ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
    );
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Login();
    }));
  }

  onPressSendMessage() async {
    if (!is_logged_in.$) {
      showLoginWarning();
      return;
    }
    loading();
    var title = sellerChatTitleController.text.toString();
    var message = sellerChatMessageController.text.toString();

    if (title == "" || message == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.title_or_message_empty_warning,
      );
      return;
    }

    var conversationCreateResponse = await ChatRepository()
        .getCreateConversationResponse(
          product_id: _productDetailsNotifier.value!.id,
          title: title,
          message: message,
        );

    Navigator.of(loadingcontext).pop();

    if (conversationCreateResponse.result == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.could_not_create_conversation,
      );
      return;
    }

    sellerChatTitleController.clear();
    sellerChatMessageController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Chat(
            conversation_id: conversationCreateResponse.conversation_id,
            messenger_name: conversationCreateResponse.shop_name,
            messenger_title: conversationCreateResponse.title,
            messenger_image: conversationCreateResponse.shop_logo,
          );
        },
      ),
    ).then((value) {
      onPopped(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    SnackBar addedToCartSnackbar = SnackBar(
      content: Text(
        AppLocalizations.of(context)!.added_to_cart,
        style: TextStyle(color: MyTheme.font_grey),
      ),
      backgroundColor: MyTheme.soft_accent_color,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.show_cart_all_capital,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Cart(has_bottomnav: false);
              },
            ),
          ).then((value) {
            onPopped(value);
          });
        },
        textColor: MyTheme.accent_color,
        disabledTextColor: Colors.grey,
      ),
    );

    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        backgroundColor: MyTheme.mainColor,
        bottomNavigationBar: buildBottomAppBar(context, addedToCartSnackbar),
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
              SliverAppBar(
                elevation: 0,
                scrolledUnderElevation: 0.0,
                backgroundColor: MyTheme.mainColor,
                pinned: true,
                automaticallyImplyLeading: false,
                expandedHeight: 355.0,
                title: ValueListenableBuilder(
                  valueListenable: _scrollPositionNotifier,
                  builder: (context, double scrollPosition, child) {
                    return ValueListenableBuilder(
                      valueListenable: _productDetailsNotifier,
                      builder: (context, DetailedProduct? productDetails, child) {
                        return AnimatedOpacity(
                          opacity: scrollPosition > 250 ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.only(left: 8),
                            width: DeviceInfo(context).width! / 2,
                            child: Text(
                              "${productDetails != null ? productDetails.name : ''}",
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
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: ValueListenableBuilder(
                          valueListenable: _currentImageNotifier,
                          builder: (context, int currentImage, child) {
                            return ProductSliderImageWidget(
                              productImageList: _productImageList,
                              currentImage: currentImage,
                              carouselController: _carouselController,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 48,
                          left: 33,
                          right: 33,
                        ),
                        child: Row(
                          children: [
                            Builder(
                              builder:
                                  (context) => InkWell(
                                    onTap: () {
                                      return Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      decoration:
                                          BoxDecorations.buildCircularButtonDecoration_for_productDetails(),
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

                            // Show product name in appbar
                            Spacer(),
                            // Cart button at top
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return Cart(has_bottomnav: false);
                                    },
                                  ),
                                ).then((value) {
                                  onPopped(value);
                                });
                              },
                              child: Container(
                                decoration:
                                    BoxDecorations.buildCircularButtonDecoration_for_productDetails(),
                                width: 32,
                                height: 32,
                                padding: EdgeInsets.all(2),
                                child: badges.Badge(
                                  position: badges.BadgePosition.topEnd(
                                    top: -6,
                                    end: -6,
                                  ),
                                  badgeStyle: badges.BadgeStyle(
                                    shape: badges.BadgeShape.circle,
                                    badgeColor: MyTheme.accent_color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  badgeAnimation: badges.BadgeAnimation.slide(
                                    toAnimate: true,
                                  ),
                                  stackFit: StackFit.loose,
                                  badgeContent: Consumer<CartCounter>(
                                    builder: (context, cart, child) {
                                      return Text(
                                        "${cart.cartCounter}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/cart.png",
                                      color: MyTheme.dark_font_grey,
                                      height: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            InkWell(
                              onTap: () {
                                onPressShare(context);
                              },
                              child: TappableIconWidget(
                                icon: Icons.share_outlined,
                                color: MyTheme.dark_font_grey,
                              ),
                            ),
                            SizedBox(width: 15),
                            InkWell(
                              onTap: () {
                                onWishTap();
                              },
                              child: ValueListenableBuilder(
                                valueListenable: _isInWishListNotifier,
                                builder: (context, bool isInWishList, child) {
                                  return TappableIconWidget(
                                    icon: Icons.favorite,
                                    color: isInWishList
                                        ? const Color.fromRGBO(230, 46, 4, 1)
                                        : MyTheme.dark_font_grey,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 20,
                          spreadRadius: 0.0,
                          offset: Offset(
                            0.0,
                            0.0,
                          ),
                        ),
                      ],
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: _productDetailsNotifier,
                      builder: (context, DetailedProduct? productDetails, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  productDetails != null
                                      ? Text(
                                    productDetails.name!,
                                    style: const TextStyle(
                                      color: Color(0xff3E4447),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Public Sans',
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                  )
                                      : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                                  const SizedBox(height: 13),
                                  productDetails != null
                                      ? buildRatingAndWishButtonRow()
                                      : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                                  if (productDetails != null &&
                                      productDetails.estShippingTime != null &&
                                      productDetails.estShippingTime! > 0)
                                    productDetails != null
                                        ? buildShippingTime()
                                        : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                                  const SizedBox(height: 12),
                                  productDetails != null
                                      ? buildMainPriceRow()
                                      : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                                  const SizedBox(height: 14),
                                  Visibility(
                                    visible: club_point_addon_installed.$,
                                    child: productDetails != null
                                        ? buildClubPointRow()
                                        : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  productDetails != null
                                      ? buildBrandRow()
                                      : ShimmerHelper().buildBasicShimmer(
                                    height: 50.0,
                                  ),
                                ],
                              ),
                            ),
                            productDetails != null
                                ? buildSellerRow(context)
                                : ShimmerHelper().buildBasicShimmer(height: 50.0),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 11),
                                  productDetails != null
                                      ? buildChoiceOptionList()
                                      : buildVariantShimmers(),
                                  productDetails != null
                                      ? (_colorList.isNotEmpty
                                      ? buildColorRow()
                                      : Container())
                                      : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                                  const SizedBox(height: 20),
                                  Visibility(
                                    visible: whole_sale_addon_installed.$,
                                    child: productDetails != null
                                        ? productDetails.wholesale!.isNotEmpty
                                        ? buildWholeSaleQuantityPrice()
                                        : const SizedBox.shrink()
                                        : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                                  ),
                                  productDetails != null
                                      ? const SizedBox()
                                      : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 27),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: productDetails != null
                                  ? buildTotalPriceRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                height: 30.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

  //for description
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 16,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),

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
                                color: Color(0xff3E4447),
                                fontFamily: 'Public Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              0.0,
                              8.0,
                              8.0,
                            ),
                            child:
                                ValueListenableBuilder(
                                  valueListenable: _productDetailsNotifier,
                                  builder: (context, DetailedProduct? productDetails, child) {
                                    return productDetails != null
                                        ? buildExpandableDescription()
                                        : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 8.0,
                                      ),
                                      child: ShimmerHelper().buildBasicShimmer(
                                        height: 60.0,
                                      ),
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_productDetailsNotifier.value?.downloads != null)
                      Column(
                        children: [
                          SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              print(_productDetailsNotifier.value?.downloads);
                              var url = Uri.parse(
                                _productDetailsNotifier.value?.downloads ?? "",
                              );
                              print(url);
                              launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
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
                                      )!.downloads_ucf,
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
                        ],
                      ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () {

                        if (_productDetailsNotifier.value!.video_link == null || _productDetailsNotifier.value!.video_link!.isEmpty) {
                          ToastComponent.showDialog(
                            AppLocalizations.of(context)!.video_not_available,
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return VideoDescription(

                                url: _productDetailsNotifier.value!.video_link![0],
                              );
                            },
                          ),
                        ).then((value) {
                          onPopped(value);
                        });
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 0,
                              blurRadius: 16,
                              offset: Offset(
                                0,
                                0,
                              ), // changes position of shadow
                            ),
                          ],
                        ),
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
                                AppLocalizations.of(context)!.video_ucf,
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontSize: 13,
                                  fontFamily: 'Public Sans',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/arrow.png",
                                color: Color(0xff6B7377),
                                height: 11,
                                width: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ProductReviews(id: _productDetailsNotifier.value!.id);
                            },
                          ),
                        ).then((value) {
                          onPopped(value);
                        });
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 0,
                              blurRadius: 16,
                              offset: Offset(
                                0,
                                0,
                              ), // changes position of shadow
                            ),
                          ],
                        ),
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
                                AppLocalizations.of(context)!.reviews_ucf,
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontFamily: 'Public Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
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
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0, 22.0, 18.0, 0.0),
                    child: Text(
                      AppLocalizations.of(context)!.products_you_may_also_like,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  buildProductsMayLikeList(),
                ]),
              ),

              //Top selling product
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
                    child: Text(
                      AppLocalizations.of(context)!.top_selling_products_ucf,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                    child: buildTopSellingProductList(),
                  ),
                  Container(height: 83),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSellerRow(BuildContext context) {
    //print("sl:" +  _productDetailsNotifier.value!.shop_logo);
    return Container(
      color: Color(0xffF6F7F8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _productDetailsNotifier.value!.added_by == "admin"
              ? Container()
              : InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SellerDetails(
                            slug: _productDetailsNotifier.value?.shop_slug ?? "",
                          ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: Color.fromRGBO(112, 112, 112, 0.298),
                        width: 1,
                      ),
                      //shape: BoxShape.rectangle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: _productDetailsNotifier.value!.shop_logo!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
          SizedBox(
            width: MediaQuery.of(context).size.width * (.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.seller_ucf,
                  style: TextStyle(
                    color: Color(0xff6B7377),
                    fontFamily: 'Public Sans',
                    fontSize: 10,
                  ),
                ),
                Text(
                  _productDetailsNotifier.value!.shop_name!,
                  style: TextStyle(
                    color: Color(0xff3E4447),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Visibility(
            visible: conversation_system_status.$,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (is_logged_in == false) {
                        ToastComponent.showDialog(
                          LangText(context).local.you_need_to_log_in,
                        );
                        return;
                      }

                      onTapSellerChat();
                    },
                    child: Image.asset(
                      'assets/chat.png',
                      height: 16,
                      width: 16,
                      color: Color(0xff6B7377),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTotalPriceRow() {
    return Container(
      height: 40,
      color: Color(0xffFEF0D7),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            child: Padding(
              padding: app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: Text(
                AppLocalizations.of(context)!.total_price_ucf,
                style: const TextStyle(
                  color: Color.fromRGBO(153, 153, 153, 1),
                ),
              ),
            ),
          ),
          Spacer(),
          ValueListenableBuilder(
            valueListenable: _totalPriceNotifier,
            builder: (context, String? totalPrice, child) {
              return Text(
                totalPrice ?? "",
                style: TextStyle(
                  color: MyTheme.accent_color,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  TextEditingController quantityText = TextEditingController(text: "0");

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

  buildChoiceOptionList() {
    return ListView.builder(
      itemCount: _productDetailsNotifier.value!.choice_options!.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: buildChoiceOpiton(_productDetailsNotifier.value!.choice_options, index),
        );
      },
    );
  }

  buildChoiceOpiton(choiceOptions, choiceOptionsIndex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 14.0, 0.0, 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                app_language_rtl.$!
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
            child: SizedBox(
              width: 75,
              child: Text(
                choiceOptions[choiceOptionsIndex].title,
                style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - (107 + 45),
            child: Scrollbar(
              controller: _variantScrollController,
              child: Wrap(
                children: List.generate(
                  choiceOptions[choiceOptionsIndex].options.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      width: 75,
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: buildChoiceItem(
                        choiceOptions[choiceOptionsIndex].options[index],
                        choiceOptionsIndex,
                        index,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildChoiceItem(option, choiceOptionsIndex, index) {
    return Padding(
      padding:
          app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onVariantChange(choiceOptionsIndex, option);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  _selectedChoices[choiceOptionsIndex] == option
                      ? MyTheme.accent_color
                      : MyTheme.noColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3.0),
            color: MyTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                spreadRadius: 1,
                offset: Offset(0.0, 3.0),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 3.0,
            ),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                  color:
                      _selectedChoices[choiceOptionsIndex] == option
                          ? MyTheme.accent_color
                          : Color.fromRGBO(80, 80, 80, 1),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildColorRow() {
    return Row(
      children: [
        Padding(
          padding:
              app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.color_ucf,
              style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          alignment:
              app_language_rtl.$!
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          height: 40,
          width: MediaQuery.of(context).size.width - (107 + 44),
          child: Scrollbar(
            controller: _colorScrollController,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(width: 10);
              },
              itemCount: _colorList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [buildColorItem(index)],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildColorItem(index) {
    return InkWell(
      onTap: () {
        _onColorChange(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        width: _selectedColorIndexNotifier.value == index ? 28 : 20,
        height: _selectedColorIndexNotifier.value == index ? 28 : 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: ColorHelper.getColorFromColorCode(_colorList[index]),
          boxShadow: [
            _selectedColorIndexNotifier.value == index
                ? BoxShadow(
                  color: Colors.black.withOpacity(
                    _selectedColorIndexNotifier.value == index ? 0.25 : 0.12,
                  ),
                  blurRadius: 10,
                  spreadRadius: 2.0,
                  offset: Offset(0.0, 6.0),
                )
                : BoxShadow(
                  color: Colors.black.withOpacity(
                    _selectedColorIndexNotifier.value == index ? 0.25 : 0.16,
                  ),
                  blurRadius: 6,
                  spreadRadius: 0.0,
                  offset: Offset(0.0, 3.0),
                ),
          ],
        ),
        child:
            _selectedColorIndexNotifier.value == index
                ? buildColorCheckerContainer()
                : Container(height: 25),
      ),
    );
  }

  buildColorCheckerContainer() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child:  Image.asset(
        "assets/white_tick.png",
        width: 16,
        height: 16,
      ),
    );
  }

  Widget buildWholeSaleQuantityPrice() {
    return DataTable(

      columnSpacing: DeviceInfo(context).width! * 0.125,

      columns: [
        DataColumn(
          label: Text(
            LangText(context).local.min_qty_ucf,
            style: TextStyle(fontSize: 12, color: MyTheme.dark_grey),
          ),
        ),
        DataColumn(
          label: Text(
            LangText(context).local.max_qty_ucf,
            style: TextStyle(fontSize: 12, color: MyTheme.dark_grey),
          ),
        ),
        DataColumn(
          label: Text(
            LangText(context).local.unit_price_ucf,
            style: TextStyle(fontSize: 12, color: MyTheme.dark_grey),
          ),
        ),
      ],
      rows: List<DataRow>.generate(_productDetailsNotifier.value!.wholesale!.length, (index) {
        return DataRow(
          cells: <DataCell>[
            DataCell(
              Text(
                _productDetailsNotifier.value!.wholesale![index].minQty.toString(),
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 12,
                ),
              ),
            ),
            DataCell(
              Text(
                _productDetailsNotifier.value!.wholesale![index].maxQty.toString(),
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 12,
                ),
              ),
            ),
            DataCell(
              Text(
                convertPrice(
                  _productDetailsNotifier.value!.wholesale![index].price.toString(),
                ),
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget buildClubPointRow() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null || productDetails.earn_point! <= 0) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 249, 249, 1),
            border: Border.all(color: const Color.fromRGBO(255, 248, 248, 1), width: 1),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.club_point_ucf,
                  style: TextStyle(color: MyTheme.font_grey, fontSize: 12.0),
                ),
                const Spacer(),
                Text(
                  "${productDetails.earn_point}",
                  style: TextStyle(color: MyTheme.accent_color, fontSize: 12.0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildMainPriceRow() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null) return const SizedBox.shrink();
        return Row(
          children: [
            Text(
              productDetails.main_price!,
              style: TextStyle(
                color: MyTheme.accent_color,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            Visibility(
              visible: productDetails.has_discount!,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  productDetails.stroked_price!,
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: MyTheme.medium_grey,
                    fontSize: 12.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: productDetails.has_discount!,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "${productDetails.discount}",
                  style: const TextStyle(
                    color: MyTheme.medium_grey,
                    fontSize: 12.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: ValueListenableBuilder(
        valueListenable: _appbarPriceStringNotifier,
        builder: (context, String? appbarPriceString, child) {
          return SizedBox(
            height: kToolbarHeight +
                statusBarHeight -
                (MediaQuery.of(context).viewPadding.top > 40 ? 32.0 : 16.0),
            child: SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.only(top: 22.0),
                child: Text(
                  appbarPriceString ?? "",
                  style: TextStyle(fontSize: 16, color: MyTheme.font_grey),
                ),
              ),
            ),
          );
        },
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          child: IconButton(
            icon: Icon(Icons.share_outlined, color: MyTheme.dark_grey),
            onPressed: () {
              onPressShare(context);
            },
          ),
        ),
      ],
    );
  }

  Widget buildBottomAppBar(BuildContext context, addedToCartSnackbar) {
    return BottomNavigationBar(
      backgroundColor: MyTheme.white.withOpacity(0.9),
      items: [
        BottomNavigationBarItem(
          backgroundColor: Colors.transparent,
          label: '',
          icon: InkWell(
            onTap: () {
              onPressAddToCart(context, addedToCartSnackbar);
            },
            child: Container(
              margin: EdgeInsets.only(left: 23, right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: MyTheme.accent_color,
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.accent_color_shadow,
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              height: 50,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.add_to_cart_ucf,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        BottomNavigationBarItem(
          label: "",
          icon: InkWell(
            onTap: () {
              onPressBuyNow(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 14, right: 23),
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: MyTheme.golden,
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.golden_shadow,
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.buy_now_ucf,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  buildRatingAndWishButtonRow() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null) return const SizedBox.shrink();
        return Row(
          children: [
            RatingBar(
              itemSize: 15.0,
              ignoreGestures: true,
              initialRating: double.parse(productDetails.rating.toString()),
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              ratingWidget: RatingWidget(
                full: const Icon(Icons.star, color: Colors.amber),
                half: const Icon(Icons.star_half, color: Colors.amber),
                empty: const Icon(Icons.star, color: Color.fromRGBO(224, 224, 225, 1)),
              ),
              itemPadding: const EdgeInsets.only(right: 1.0),
              onRatingUpdate: (rating) {
                //print(rating);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "(${productDetails.rating_count})",
                style: const TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  buildShippingTime() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null) return const SizedBox.shrink();
        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                LangText(context).local.estimate_shipping_time_ucf,
                style: const TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 10,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "${productDetails.estShippingTime}  ${LangText(context).local.days_ucf}",
                style: const TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  buildBrandRow() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null || productDetails.brand!.id! <= 0) {
          return const SizedBox.shrink();
        }
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return BrandProducts(slug: productDetails.brand!.slug!);
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
                      color: Color(0xff6B7377),
                      fontSize: 10,
                      fontFamily: 'Public Sans',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  productDetails.brand!.name!,
                  style: const TextStyle(
                    color: Color(0xff3E4447),
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  String sanitizeDescription(String html) {
    String result = html.replaceAllMapped(
      RegExp(r'<font[^>]*>', caseSensitive: false),
      (_) => '',
    );
    result = result.replaceAll(RegExp(r'</font>', caseSensitive: false), '');
    result = result.replaceAll(
      RegExp(r'font-feature-settings\s*:[^;"]+;?', caseSensitive: false),
      '',
    );
    result = result.replaceAll(
      RegExp(r'@font-face\s*\{[^}]*\}', caseSensitive: false),
      '',
    );
    return result;
  }

  buildExpandableDescription() {
    print("Building Digital Expandable Description: ${_productDetailsNotifier.value?.description}");
    return ExpandableNotifier(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
            Expandable(
              collapsed: SizedBox(
                height: 50,
                child: Html(
                  data: sanitizeDescription(_productDetailsNotifier.value!.description!),
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(13),
                      color: Color(0xff3E4447),
                      fontFamily: 'Public Sans',
                    ),
                  },
                ),
              ),
              expanded: Container(
                child: Html(
                  data: sanitizeDescription(_productDetailsNotifier.value!.description!),
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(13),
                      color: Color(0xff3E4447),
                      fontFamily: 'Public Sans',
                    ),
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Builder(
                  builder: (context) {
                    var controller = ExpandableController.of(context)!;
                    return Btn.basic(
                      padding: EdgeInsets.zero,
                      child: Text(
                        !controller.expanded
                            ? AppLocalizations.of(context)!.view_more
                            : AppLocalizations.of(context)!.show_less_ucf,
                        style: TextStyle(
                          color: Color(0xff0077B6),
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
    );
  }

  buildTopSellingProductList() {
    return ValueListenableBuilder(
      valueListenable: _topProductInitNotifier,
      builder: (context, bool topProductInit, child) {
        if (topProductInit == false && _topProducts.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ShimmerHelper().buildBasicShimmer(height: 75.0),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ShimmerHelper().buildBasicShimmer(height: 75.0),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ShimmerHelper().buildBasicShimmer(height: 75.0),
              ),
            ],
          );
        } else if (_topProducts.isNotEmpty) {
          return SingleChildScrollView(
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemCount: _topProducts.length,
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.only(top: 16),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return TopSellingProductsCard(
                  id: _topProducts[index].id,
                  slug: _topProducts[index].slug,
                  image: _topProducts[index].thumbnail_image,
                  name: _topProducts[index].name,
                  main_price: _topProducts[index].main_price,
                  stroked_price: _topProducts[index].stroked_price,
                  has_discount: _topProducts[index].has_discount,
                );
              },
            ),
          );
        } else {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_top_selling_products_from_this_seller,
                style: const TextStyle(color: MyTheme.font_grey),
              ),
            ),
          );
        }
      },
    );
  }

  buildProductsMayLikeList() {
    return ValueListenableBuilder(
      valueListenable: _relatedProductInitNotifier,
      builder: (context, bool relatedProductInit, child) {
        if (relatedProductInit == false && _relatedProducts.isEmpty) {
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
        } else if (_relatedProducts.isNotEmpty) {
          return SingleChildScrollView(
            child: SizedBox(
              height: 248,
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                padding: const EdgeInsets.all(16),
                itemCount: _relatedProducts.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return MiniProductCard(
                    id: _relatedProducts[index].id,
                    slug: _relatedProducts[index].slug,
                    image: _relatedProducts[index].thumbnail_image,
                    name: _relatedProducts[index].name,
                    main_price: _relatedProducts[index].main_price,
                    stroked_price: _relatedProducts[index].stroked_price,
                    is_wholesale: _relatedProducts[index].isWholesale,
                    discount: _relatedProducts[index].discount,
                    has_discount: _relatedProducts[index].has_discount,
                  );
                },
              ),
            ),
          );
        } else {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_related_product,
                style: const TextStyle(color: MyTheme.font_grey),
              ),
            ),
          );
        }
      },
    );
  }

  buildQuantityUpButton() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.16),
          blurRadius: 6,
          spreadRadius: 0.0,
          offset: const Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 36,
    child: IconButton(
      icon: Icon(Icons.add, size: 16, color: MyTheme.dark_grey),
      onPressed: () {
        if (_quantityNotifier.value! < _stockNotifier.value!) {
          _quantityNotifier.value = _quantityNotifier.value! + 1;
          fetchAndSetVariantWiseInfo();
        }
      },
    ),
  );

  buildQuantityDownButton() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.16),
          blurRadius: 6,
          spreadRadius: 0.0,
          offset: const Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 30,
    child: IconButton(
      icon: const Center(
        child: Icon(Icons.remove, size: 16, color: Color(0xff707070)),
      ),
      onPressed: () {
        if (_quantityNotifier.value! > 1) {
          _quantityNotifier.value = _quantityNotifier.value! - 1;
          fetchAndSetVariantWiseInfo();
        }
      },
    ),
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
                  thumbVisibility: false,
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

  void openPhotoDialog(BuildContext context, path) => showDialog(
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

  String makeHtml(String string) {
    return """
<!DOCTYPE html>
<html>

<head>

<meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="${AppConfig.RAW_BASE_URL}/public/assets/css/vendors.css">
  <style>
  *{
  margin:0 !important;
  padding:0 !important;
  }

    #scaled-frame {
    }
  </style>
</head>

<body id="main_id">
  <div id="scaled-frame">
$string
  </div>
</body>

</html>
""";
  }
}
