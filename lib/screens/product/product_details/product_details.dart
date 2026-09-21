
import 'dart:async';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_media.dart';
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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../app_config.dart';
import '../../../custom/box_decorations.dart';
import '../../../custom/btn.dart';
import '../../../custom/device_info.dart';
import '../../../custom/lang_text.dart';
import '../../../custom/quantity_input.dart';
import '../../../custom/toast_component.dart';
import '../../../data_model/product_details_response.dart';
import '../../../helpers/color_helper.dart';
import '../../../helpers/main_helpers.dart';
import '../../../helpers/shared_value_helper.dart';
import '../../../helpers/shimmer_helper.dart';
import '../../../helpers/system_config.dart';
import '../../../my_theme.dart';
import '../../../presenter/cart_counter.dart';
import '../../../repositories/cart_repository.dart';
import '../../../repositories/chat_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/wishlist_repository.dart';
import '../../../ui_elements/mini_product_card.dart';
import '../../../ui_elements/top_selling_products_card.dart';
import '../../brand_products.dart';
import '../../chat/chat.dart';
import '../../checkout/cart.dart';
import '../../seller_details.dart';
import '../../video_description_screen.dart';
import '../product_reviews.dart';
import '../widgets/tappable_icon_widget.dart';
import '../../auth/login.dart';
import 'package:flutter_html/flutter_html.dart';

class ProductDetails extends StatefulWidget {
  String slug;

  ProductDetails({super.key, required this.slug});

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  ValueNotifier<bool> _showCopiedNotifier = ValueNotifier(false);
  ValueNotifier<String?> _appbarPriceStringNotifier = ValueNotifier(". . .");
  ValueNotifier<int> _currentImageNotifier = ValueNotifier(0);
  final ScrollController _mainScrollController = ScrollController(
    initialScrollOffset: 0.0,
  );
  final ScrollController _colorScrollController = ScrollController();
  final ScrollController _variantScrollController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();
  TextEditingController sellerChatTitleController = TextEditingController();
  TextEditingController sellerChatMessageController = TextEditingController();

  ValueNotifier<double> _scrollPositionNotifier = ValueNotifier(0.0);

  Animation? _colorTween;
  late AnimationController _ColorAnimationController;

  final CarouselSliderController _carouselController = CarouselSliderController();
  final List<ProductMedia> _mediaList = [];

  late BuildContext loadingcontext;

  //init values

  ValueNotifier<bool> _isInWishListNotifier = ValueNotifier(false);
  ValueNotifier<bool> _productDetailsFetchedNotifier = ValueNotifier(false);
  ValueNotifier<DetailedProduct?> _productDetailsNotifier = ValueNotifier(null);
  final _productImageList = [];
  final _colorList = [];
  ValueNotifier<int> _selectedColorIndexNotifier = ValueNotifier(0);
  final _selectedChoices = [];
  ValueNotifier<String> _choiceStringNotifier = ValueNotifier("");
  ValueNotifier<String?> _variantNotifier = ValueNotifier("");
  ValueNotifier<String?> _totalPriceNotifier = ValueNotifier("...");
  var _singlePrice;
  var _singlePriceString;
  ValueNotifier<int?> _quantityNotifier = ValueNotifier(1);
  ValueNotifier<int?> _stockNotifier = ValueNotifier(0);
  ValueNotifier<dynamic> _stockTxtNotifier = ValueNotifier(null);

  ValueNotifier<double> _opacityNotifier = ValueNotifier(0);

   final List<dynamic> _relatedProducts = [];
  ValueNotifier<bool> _relatedProductInitNotifier = ValueNotifier(false);
  final List<dynamic> _topProducts = [];
  ValueNotifier<bool> _topProductInitNotifier = ValueNotifier(false);
  String _resolvedSlug = "";

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

  fetchAll() async {
    _resolvedSlug = widget.slug;
    if (_resolvedSlug.startsWith("ID:")) {
      var parts = _resolvedSlug.split(":");
      String productId = parts[1];
      String productName = parts.skip(2).join(":");
      
      try {
        var searchResponse = await ProductRepository().getFilteredProducts(
          name: productName,
        );
        if (searchResponse.products != null && searchResponse.products!.isNotEmpty) {
          var matchingProduct = searchResponse.products!.firstWhere(
            (p) => p.id.toString() == productId,
            orElse: () => searchResponse.products!.first,
          );
          _resolvedSlug = matchingProduct.slug!;
        }
      } catch (e) {
        print("Error resolving slug for product ID $productId: $e");
      }
    }

    fetchProductDetails();
    if (is_logged_in.$ == true) {
      fetchWishListCheckInfo();
    }
    fetchRelatedProducts();
    fetchTopProducts();
  }

  fetchProductDetails() async {
    var productDetailsResponse = await ProductRepository().getProductDetails(
      slug: _resolvedSlug,
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
        .getFrequentlyBoughProducts(slug: _resolvedSlug);
    _relatedProducts.addAll(relatedProductResponse.products!);
    _relatedProductInitNotifier.value = true;
  }

  fetchTopProducts() async {
    var topProductResponse = await ProductRepository()
        .getTopFromThisSellerProducts(slug: _resolvedSlug);
    _topProducts.addAll(topProductResponse.products!);
    _topProductInitNotifier.value = true;
  }

  setProductDetailValues() {
    DetailedProduct? productDetails = _productDetailsNotifier.value;
    if (_productDetailsNotifier.value != null) {
      print("Product Description: ${_productDetailsNotifier.value!.description}");
      // controller.loadHtmlString(makeHtml(_productDetailsNotifier.value!.description!));
      _appbarPriceStringNotifier.value = productDetails!.price_high_low;
      _singlePrice = productDetails.calculable_price;
      _singlePriceString = productDetails.main_price;
      _stockNotifier.value = productDetails.current_stock;
      _mediaList.clear();


      if (productDetails.photos != null) {
        for (var photo in productDetails.photos!) {
          _mediaList.add(ProductMedia(type: 'image', url: photo.path!));
        }
      }
      if (productDetails.videos != null) {
        for (var video in productDetails.videos!) {
          String? thumbnail = video.thumbnail;
          if (thumbnail == null || thumbnail.isEmpty) {
            thumbnail = productDetails.thumbnail_image;
          }
          _mediaList.add(ProductMedia(type: 'hosted_video', url: video.path!, thumbnail: video.thumbnail));
        }
      }
      if (productDetails.video_link != null) {
        for (var ytLink in productDetails.video_link!) {
          String? videoId = YoutubePlayer.convertUrlToId(ytLink);
          if (videoId != null && videoId.isNotEmpty) {
            bool isShort = ytLink.toString().contains('/shorts/');
            _mediaList.add(ProductMedia(
              type: 'youtube_video',
              url: ytLink,
              thumbnail: YoutubePlayer.getThumbnail(videoId: videoId),
              isShort: isShort,
            ));
          }
        }
      }

      for (var choice_opiton in productDetails.choice_options!) {
        _selectedChoices.add(choice_opiton.options![0]);
      }
      for (var color in productDetails.colors!) {
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
        .isProductInUserWishList(product_slug: _resolvedSlug);

    if (wishListCheckResponse.is_in_wishlist != null) {
      _isInWishListNotifier.value = wishListCheckResponse.is_in_wishlist!;
    } else {
      _isInWishListNotifier.value = false;
    }
  }

  addToWishList() async {
    var wishListCheckResponse = await WishListRepository().add(
      product_slug: _resolvedSlug,
    );
    _isInWishListNotifier.value = wishListCheckResponse.is_in_wishlist;
  }

  removeFromWishList() async {
    var wishListCheckResponse = await WishListRepository().remove(
      product_slug: _resolvedSlug,
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
    var colorString =
    _colorList.isNotEmpty
        ? _colorList[_selectedColorIndexNotifier.value].toString().replaceAll("#", "")
        : "";

    var variantResponse = await ProductRepository().getVariantWiseInfo(
      slug: _resolvedSlug,
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
        if(_mediaList.isNotEmpty) {
          _carouselController.jumpToPage(pindex);
        }
      }
      pindex++;
    });
    setQuantity(_quantityNotifier.value);
  }

  reset() {
    restProductDetailValues();
    _mediaList.clear();
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
    _mediaList.clear();
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
      _quantityNotifier.value,
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

  onCopyTap() {
    _showCopiedNotifier.value = true;
    Timer timer = Timer(Duration(seconds: 3), () {
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
                            onCopyTap();
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
                      _showCopiedNotifier.value
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
                          duration: Duration(milliseconds: 200),
                          child: Container(
                            padding: EdgeInsets.only(left: 8),
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
                          valueListenable: _productDetailsNotifier,
                          builder: (context, DetailedProduct? productDetails, child) {
                            return ProductMediaSlider(
                              mediaList: _mediaList,
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
                                  (context) => GestureDetector(
                                onTap: (){
                                  Navigator.of(context).pop();

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
                                        ? Color.fromRGBO(230, 46, 4, 1)
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
                child: ValueListenableBuilder(
                  valueListenable: _productDetailsNotifier,
                  builder: (context, DetailedProduct? productDetails, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
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
                              offset: Offset(0.0, 0.0),
                            ),
                          ],
                        ),
                        child: Column(
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
                                          style: TextStyle(
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
                                  SizedBox(height: 13),
                                  productDetails != null
                                      ? buildRatingAndWishButtonRow()
                                      : ShimmerHelper().buildBasicShimmer(
                                          height: 30.0,
                                        ),
                                  if (productDetails != null &&
                                      productDetails.estShippingTime != null &&
                                      productDetails.estShippingTime! > 0)
                                    buildShippingTime()
                                  else if (productDetails == null)
                                    ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                                  SizedBox(height: 12),
                                  productDetails != null
                                      ? buildMainPriceRow()
                                      : ShimmerHelper().buildBasicShimmer(
                                          height: 30.0,
                                        ),
                                  SizedBox(height: 14),
                                  Visibility(
                                    visible: club_point_addon_installed.$,
                                    child: productDetails != null
                                        ? buildClubPointRow()
                                        : ShimmerHelper().buildBasicShimmer(
                                            height: 30.0,
                                          ),
                                  ),
                                  SizedBox(height: 9),
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
                                  SizedBox(height: 11),
                                  productDetails != null
                                      ? buildChoiceOptionList()
                                      : buildVariantShimmers(),
                                  productDetails != null
                                      ? (_colorList.isNotEmpty ? buildColorRow() : Container())
                                      : ShimmerHelper().buildBasicShimmer(
                                          height: 30.0,
                                        ),
                                  SizedBox(height: 20),
                                  Visibility(
                                    visible: whole_sale_addon_installed.$,
                                    child: productDetails != null
                                        ? productDetails.wholesale!.isNotEmpty
                                            ? buildWholeSaleQuantityPrice()
                                            : SizedBox.shrink()
                                        : ShimmerHelper().buildBasicShimmer(
                                            height: 30.0,
                                          ),
                                  ),
                                  productDetails != null
                                      ? buildQuantityRow()
                                      : ShimmerHelper().buildBasicShimmer(
                                          height: 30.0,
                                        ),
                                ],
                              ),
                            ),
                            SizedBox(height: 27),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: productDetails != null
                                  ? buildTotalPriceRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: ValueListenableBuilder(
                  valueListenable: _productDetailsNotifier,
                  builder: (context, DetailedProduct? productDetails, child) {
                    if (productDetails == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: ShimmerHelper().buildBasicShimmer(height: 100),
                      );
                    }
                    return Column(
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
                          //  margin: EdgeInsets.only(top: 10),
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
                                child: buildExpandableDescription(),
                              ),
                            ],
                          ),
                        ),
                        if (productDetails.downloads != null)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              InkWell(
                                onTap: () async {
                                  print(productDetails.downloads);
                                  var url = Uri.parse(
                                    productDetails.downloads ?? "",
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return ProductReviews(id: productDetails.id);
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
                    );
                  },
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
    //print("sl:" +  _productDetails!.shop_logo);
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
                    image: AppConfig.getSanitizedUrl(_productDetailsNotifier.value!.shop_logo!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          _productDetailsNotifier.value!.added_by == "admin"
              ? Container()
              : SizedBox(
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
                    offset: Offset(0.0, 10.0), // shadow direction: bottom right
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
    return ValueListenableBuilder(
      valueListenable: _totalPriceNotifier,
      builder: (context, String? totalPrice, child) {
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
                  child: SizedBox(
                    width: 75,
                    child: Text(
                      AppLocalizations.of(context)!.total_price_ucf,
                      style: TextStyle(color: Color(0xff6B7377), fontSize: 10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Text(
                  SystemConfig.systemCurrency != null
                      ? (totalPrice ?? "0").replaceAll(
                    SystemConfig.systemCurrency!.code!,
                    SystemConfig.systemCurrency!.symbol!,
                  )
                      : SystemConfig.systemCurrency!.symbol! +
                      (totalPrice ?? "0"),
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
      },
    );
  }

  Row buildQuantityRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.quantity_ucf,
              style: TextStyle(
                color: Color(0xff6B7377),
                fontFamily: 'Public Sans',
              ),
            ),
          ),
        ),
        SizedBox(
          height: 30,
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              buildQuantityDownButton(),
              SizedBox(width: 1),
              ValueListenableBuilder(
                valueListenable: _quantityNotifier,
                builder: (context, int? quantity, child) {
                  return SizedBox(
                    width: 30,
                    child: Center(
                      child: QuantityInputField.show(
                        quantityText,
                        isDisable: quantity == 0,
                        onSubmitted: () {
                          _quantityNotifier.value = int.parse(quantityText.text);
                          fetchAndSetVariantWiseInfo();
                        },
                      ),
                    ),
                  );
                },
              ),
              buildQuantityUpButton(),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _stockTxtNotifier,
          builder: (context, dynamic stockTxt, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "$stockTxt",
                style: TextStyle(color: Color(0xff6B7377), fontSize: 14),
              ),
            );
          },
        ),
      ],
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
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null || productDetails.choice_options == null) {
          return const SizedBox.shrink();
        }
        return ListView.builder(
          itemCount: productDetails.choice_options!.length,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: buildChoiceOpiton(productDetails.choice_options, index),
            );
          },
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
                style: TextStyle(color: Colors.black),
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
      padding: app_language_rtl.$!
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: ValueListenableBuilder(
        valueListenable: _choiceStringNotifier,
        builder: (context, String choiceString, child) {
          bool isSelected = _selectedChoices[choiceOptionsIndex] == option;
          return InkWell(
            onTap: () {
              _onVariantChange(choiceOptionsIndex, option);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? MyTheme.accent_color : MyTheme.noColor,
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
                      color: isSelected
                          ? MyTheme.accent_color
                          : Colors.black,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
              style: TextStyle(color: Colors.black),
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
    return ValueListenableBuilder(
      valueListenable: _selectedColorIndexNotifier,
      builder: (context, int selectedColorIndex, child) {
        bool isSelected = selectedColorIndex == index;
        return InkWell(
          onTap: () {
            _onColorChange(index);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400),
            width: isSelected ? 28 : 20,
            height: isSelected ? 28 : 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: ColorHelper.getColorFromColorCode(_colorList[index]),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.25 : 0.16),
                  blurRadius: isSelected ? 10 : 6,
                  spreadRadius: isSelected ? 2.0 : 0.0,
                  offset: isSelected ? Offset(0.0, 6.0) : Offset(0.0, 3.0),
                ),
              ],
            ),
            child: isSelected ? buildColorCheckerContainer() : Container(height: 25),
          ),
        );
      },
    );
  }

  buildColorCheckerContainer() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: /*Icon(Icons.check, color: Colors.white, size: 16),*/ Image.asset(
        "assets/white_tick.png",
        width: 16,
        height: 16,
      ),
    );
  }

  Widget buildWholeSaleQuantityPrice() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null || productDetails.wholesale == null) {
          return const SizedBox.shrink();
        }
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
          rows: List<DataRow>.generate(productDetails.wholesale!.length, (index) {
            return DataRow(
              cells: <DataCell>[
                DataCell(
                  Text(
                    productDetails.wholesale![index].minQty.toString(),
                    style: TextStyle(
                      color: Color.fromRGBO(152, 152, 153, 1),
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    productDetails.wholesale![index].maxQty.toString(),
                    style: TextStyle(
                      color: Color.fromRGBO(152, 152, 153, 1),
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    convertPrice(
                      productDetails.wholesale![index].price.toString(),
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
      },
    );
  }

  Widget buildClubPointRow() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null || productDetails.earn_point == null || productDetails.earn_point! <= 0) {
          return const SizedBox.shrink();
        }
        return Container(
          constraints: BoxConstraints(maxWidth: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            color: Color(0xffFFF4E8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset("assets/clubpoint.png", width: 18, height: 12),
                    SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.club_point_ucf,
                      style: TextStyle(
                        color: Color(0xff6B7377),
                        fontSize: 10,
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Text(
                  productDetails.earn_point.toString(),
                  style: TextStyle(color: Color(0xffF7941D), fontSize: 12.0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Row buildMainPriceRow() {
    return Row(
      children: [
        ValueListenableBuilder(
          valueListenable: _totalPriceNotifier,
          builder: (context, String? totalPrice, child) {
            return Text(
              SystemConfig.systemCurrency != null
                  ? (totalPrice ?? "...").replaceAll(
                SystemConfig.systemCurrency!.code!,
                SystemConfig.systemCurrency!.symbol!,
              )
                  : (totalPrice ?? "..."),
              style: TextStyle(
                color: MyTheme.price_color,
                fontFamily: 'Public Sans',
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: _productDetailsNotifier,
          builder: (context, DetailedProduct? productDetails, child) {
            if (productDetails == null) return const SizedBox.shrink();
            return Row(
              children: [
                Visibility(
                  visible: productDetails.has_discount!,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      SystemConfig.systemCurrency != null
                          ? productDetails.stroked_price!.replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!,
                      )
                          : productDetails.stroked_price!,
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Color(0xffA8AFB3),
                        fontFamily: 'Public Sans',
                        fontSize: 12.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: productDetails.has_discount!,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "${productDetails.discount}",
                      style: TextStyle(
                        fontSize: 12,
                        color: MyTheme.accent_color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Text(
                  "/${productDetails.unit}",
                  style: TextStyle(
                    color: MyTheme.accent_color,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
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
                  appbarPriceString!,
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
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        return ValueListenableBuilder(
          valueListenable: _stockNotifier,
          builder: (context, int? stock, child) {
            if (productDetails != null && stock != null && stock <= 0) {
              return BottomAppBar(
                color: MyTheme.white.withOpacity(0.9),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 23, vertical: 10),
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    color: Colors.grey,
                  ),
                  child: Center(
                    child: Text(
                      "Out of Stock",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }
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
                            color: MyTheme.golden_shadow,
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
                        color: Color(0xff23272B),
                        boxShadow: [
                          BoxShadow(
                            color: MyTheme.black_shadow,
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
          },
        );
      },
    );
  }

  buildRatingAndWishButtonRow() {
    return ValueListenableBuilder(
      valueListenable: _productDetailsNotifier,
      builder: (context, DetailedProduct? productDetails, child) {
        if (productDetails == null) return const SizedBox.shrink();
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ProductReviews(
                      id: productDetails.id,
                    )));
          },
          child: Row(
            children: [
              RatingBar(
                itemSize: 15.0,
                ignoreGestures: true,
                initialRating: double.parse(productDetails.rating.toString()),
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                ratingWidget: RatingWidget(
                  full: Icon(Icons.star, color: Colors.amber),
                  half: Icon(Icons.star_half, color: Colors.amber),
                  empty: Icon(Icons.star, color: Color.fromRGBO(224, 224, 225, 1)),
                ),
                itemPadding: EdgeInsets.only(right: 1.0),
                onRatingUpdate: (rating) {},
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  "(${productDetails.rating_count})",
                  style: TextStyle(
                    color: Color.fromRGBO(152, 152, 153, 1),
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
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 10,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "${productDetails.estShippingTime}  ${LangText(context).local.days_ucf}",
                style: TextStyle(
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
        if (productDetails == null || productDetails.brand == null || productDetails.brand!.id! <= 0) {
          return Container();
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
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 75,
                  child: Text(
                    AppLocalizations.of(context)!.brand_ucf,
                    style: TextStyle(
                      color: Colors.black,
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
                  style: TextStyle(
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

  /// Strips HTML tags and CSS that trigger Flutter's
  /// 'Feature tag must be exactly four characters long' assertion
  /// which is a known flutter_html 3.0.0 issue with <font> tags and
  /// font-feature-settings CSS values.
  String sanitizeDescription(String html) {
    // Replace <font ...> and </font> tags (keep inner content)
    String result = html.replaceAllMapped(
      RegExp(r'<font[^>]*>', caseSensitive: false),
      (_) => '',
    );
    result = result.replaceAll(RegExp(r'</font>', caseSensitive: false), '');
    // Remove font-feature-settings and @font-face CSS rules
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
    print("Building Expandable Description: ${_productDetailsNotifier.value?.description}");
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
                    }),
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
                    }),
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
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemCount: _topProducts.length,
              scrollDirection: Axis.vertical,
              padding: EdgeInsets.only(top: 16),
              physics: NeverScrollableScrollPhysics(),
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
                style: TextStyle(color: MyTheme.font_grey),
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
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3,
                ),
              ),
              Padding(
                padding: app_language_rtl.$!
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
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
                separatorBuilder: (context, index) => SizedBox(width: 16),
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
            style: TextStyle(color: MyTheme.font_grey),
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
          offset: Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 36,
    child: IconButton(
      icon: Icon(Icons.add, size: 16, color: MyTheme.dark_grey),
      onPressed: () {
        if (_quantityNotifier.value! < _stockNotifier.value!) {
          _quantityNotifier.value = (_quantityNotifier.value!) + 1;
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
          offset: Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 30,
    child: IconButton(
      icon: Center(
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
      return ValueListenableBuilder(
        valueListenable: _currentImageNotifier,
        builder: (context, int currentImage, child) {
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
                    padding:
                    app_language_rtl.$!
                        ? EdgeInsets.only(left: 8.0)
                        : EdgeInsets.only(right: 8.0),
                    child: ListView.builder(
                      itemCount: _productImageList.length,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        int itemIndex = index;
                        return GestureDetector(
                          onTap: () {
                            _currentImageNotifier.value = itemIndex;
                            print(_currentImageNotifier.value);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 2.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                currentImage == itemIndex
                                    ? MyTheme.accent_color
                                    : Color.fromRGBO(112, 112, 112, .3),
                                width: currentImage == itemIndex ? 2 : 1,
                              ),
                              //shape: BoxShape.rectangle,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                              /*Image.asset(
                                            singleProduct.product_images[index])*/
                              FadeInImage.assetNetwork(
                                placeholder: 'assets/placeholder.png',
                                image: AppConfig.getSanitizedUrl(_productImageList[index]),
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
                  child: Container(
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder_rectangle.png',
                      image: AppConfig.getSanitizedUrl(_productImageList[currentImage]),
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
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
                imageProvider: NetworkImage(AppConfig.getSanitizedUrl(path)),
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
  <style>
    body {
      margin: 0;
      padding: 8px;
      color: #000000; /* NEW: Set a default text color to black */
      background-color: #ffffff; /* NEW: Set a default white background */
    }
    /* This makes sure images scale down to fit the screen width */
    img {
      max-width: 100%;
      height: auto;
    }
    /* This makes tables scrollable horizontally */
    table {
      display: block;
      width: 100% !important;
      overflow-x: auto;
      white-space: nowrap;
      -webkit-overflow-scrolling: touch;
    }
    /* This helps ensure all text content wraps correctly */
    * {
       word-wrap: break-word;
       overflow-wrap: break-word;
    }
  </style>
</head>
<body>
    $string
</body>
</html>
""";
  }

}

class ProductMediaSlider extends StatefulWidget {
  final List<ProductMedia> mediaList;
  final CarouselSliderController carouselController;

  const ProductMediaSlider({
    super.key,
    required this.mediaList,
    required this.carouselController,
  });

  @override
  State<ProductMediaSlider> createState() => _ProductMediaSliderState();
}

class _ProductMediaSliderState extends State<ProductMediaSlider> {
  final ValueNotifier<int> _currentImageNotifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    if (widget.mediaList.isEmpty) {
      return ShimmerHelper().buildBasicShimmer(
        height: 355.0,
      );
    } else {
      return ValueListenableBuilder<int>(
        valueListenable: _currentImageNotifier,
        builder: (context, currentImage, child) {
          return CarouselSlider(
            carouselController: widget.carouselController,
        options: CarouselOptions(
            height: 395.0,
            viewportFraction: 1,
            initialPage: 0,
            enableInfiniteScroll: widget.mediaList.length > 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 1000),
            autoPlayCurve: Curves.easeInExpo,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              _currentImageNotifier.value = index;
            }),
        items: widget.mediaList.map(
              (mediaItem) {
            return Builder(
              builder: (BuildContext context) {
                Widget child;
                if (mediaItem.type == 'image') {
                  child = InkWell(
                    onTap: () {
                      openPhotoDialog(context, mediaItem.url);
                    },
                    child: SizedBox(
                      height: double.infinity,
                      width: double.infinity,
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: AppConfig.getSanitizedUrl(mediaItem.url),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                } else {
                  child = GestureDetector(
                    onTap: () {
                      if (mediaItem.type == 'hosted_video') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => VideoScreen(videoUrl: mediaItem.url)));
                      } else if (mediaItem.type == 'youtube_video') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => YoutubePlayerScreen(youtubeUrl: mediaItem.url)));
                      }
                    },
                    child: _buildThumbnail(mediaItem),
                  );
                }

                return Container(
                  child: Stack(
                    children: <Widget>[
                      child,
                      Align(
                        alignment: const Alignment(0.0, 0.9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.mediaList.length,
                                (index) => Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentImage == index
                                    ? MyTheme.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ).toList(),
      );
      }
      );
    }
  }

  Widget _buildThumbnail(ProductMedia mediaItem) {
    return Container(
      color: MyTheme.light_grey,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          if (mediaItem.thumbnail != null && mediaItem.thumbnail!.isNotEmpty)
            FadeInImage.assetNetwork(
              placeholder: 'assets/placeholder.png',
              image: AppConfig.getSanitizedUrl(mediaItem.thumbnail!),
              fit: BoxFit.cover,
            )
          else if (mediaItem.type == 'hosted_video')
            VideoThumbnailGenerator(videoUrl: mediaItem.url)
          else
            Container(color: MyTheme.light_grey),

          Center(
            child: Builder(
              builder: (context) {
                if (mediaItem.isShort) {
                  return Image.asset(
                    'assets/shorts_logo.png',
                    height: 50,
                    width: 50,
                  );
                } else if (mediaItem.type == 'youtube_video') {
                  return Image.asset(
                    'assets/youtube_logo.png',
                    height: 50,
                    width: 50,
                  );
                } else {
                  return Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white.withOpacity(0.85),
                    size: 60.0,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  openPhotoDialog(BuildContext context, path) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Stack(
          children: [
            PhotoView(
              enableRotation: true,
              heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
              imageProvider: NetworkImage(AppConfig.getSanitizedUrl(path)),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: ShapeDecoration(
                  color: MyTheme.medium_grey_50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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
      );
    },
  );
}

