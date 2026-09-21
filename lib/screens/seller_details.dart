
import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/shop_details_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/product_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auction/auction_products_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SellerDetails extends StatefulWidget {
  String slug;

  SellerDetails({super.key, required this.slug});

  @override
  _SellerDetailsState createState() => _SellerDetailsState();
}

class _SellerDetailsState extends State<SellerDetails> {
  final ScrollController _mainScrollController = ScrollController();
  // ScrollController _scrollController = ScrollController();

  final ValueNotifier<int> _currentSliderNotifier = ValueNotifier(0);
  final List<dynamic> _carouselImageList = [];
  final ValueNotifier<bool> _carouselInitNotifier = ValueNotifier(false);
  Shop? _shopDetails;
  final ValueNotifier<bool> _shopLoadedNotifier = ValueNotifier(false);

  final List<dynamic> _newArrivalProducts = [];
  final ValueNotifier<bool> _newArrivalProductInitNotifier = ValueNotifier(false);
  final List<dynamic> _topProducts = [];
  final ValueNotifier<bool> _topProductInitNotifier = ValueNotifier(false);
  final List<dynamic> _featuredProducts = [];
  final ValueNotifier<bool> _featuredProductInitNotifier = ValueNotifier(false);
  final ValueNotifier<bool?> _isFollowedNotifier = ValueNotifier(null);

  final List<dynamic> _allProductList = [];
  final ValueNotifier<bool> _allProductInitNotifier = ValueNotifier(false);
  final ValueNotifier<int> _pageNotifier = ValueNotifier(1);

  final ValueNotifier<int> _tabIndexNotifier = ValueNotifier(0);

  @override
  void initState() {
    fetchAll();

    _mainScrollController.addListener(() {

      if (_mainScrollController.position.pixels ==
          _mainScrollController.position.maxScrollExtent) {
        if (_tabIndexNotifier.value == 2) {
          ToastComponent.showDialog(
            LangText(context).local.loading_more_products_ucf,
          );
          _pageNotifier.value++;
          fetchAllProductData();
        }
      }
    });
    super.initState();
  }

  Future addFollow(id) async {
    var shopResponse = await ShopRepository().followedAdd(_shopDetails?.id);
    //if(shopResponse.result){
    _isFollowedNotifier.value = shopResponse.result;
    ToastComponent.showDialog(shopResponse.message);
  }

  Future removedFollow(id) async {
    var shopResponse = await ShopRepository().followedRemove(id);

    if (shopResponse.result) {
      _isFollowedNotifier.value = false;
    }
    ToastComponent.showDialog(shopResponse.message);
  }

  Future checkFollowed() async {
    if (SystemConfig.systemUser != null &&
        SystemConfig.systemUser!.id != null) {
      var shopResponse = await ShopRepository().followedCheck(
        _shopDetails?.id ?? 0,
      );
      // print(shopResponse.result);
      // print(shopResponse.message);

      _isFollowedNotifier.value = shopResponse.result;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _mainScrollController.dispose();
    super.dispose();
  }

  fetchAllProductData() async {
    var productResponse = await ProductRepository().getShopProducts(
      id: _shopDetails?.id ?? 0,
      page: _pageNotifier.value,
    );
    _allProductList.addAll(productResponse.products!);
    _allProductInitNotifier.value = true;
  }

  fetchAll() {
    fetchShopDetails();
  }

  fetchOthers() {
    checkFollowed();
    fetchNewArrivalProducts();
    fetchTopProducts();
    fetchFeaturedProducts();
    fetchAllProductData();
  }

  fetchShopDetails() async {
    var shopDetailsResponse = await ShopRepository().getShopInfo(widget.slug);

    //print('ss:' + shopDetailsResponse.toString());
    if (shopDetailsResponse.shop != null) {
      _shopDetails = shopDetailsResponse.shop;
    }

    if (_shopDetails != null) {
      fetchOthers();
      _shopDetails?.sliders?.forEach((slider) {
        _carouselImageList.add(slider);
      });
    }
    _carouselInitNotifier.value = true;
    _shopLoadedNotifier.value = true;
  }

  fetchNewArrivalProducts() async {
    var newArrivalProductResponse = await ShopRepository()
        .getNewFromThisSellerProducts(id: _shopDetails?.id);
    _newArrivalProducts.addAll(newArrivalProductResponse.products!);
    _newArrivalProductInitNotifier.value = true;
  }

  fetchTopProducts() async {
    var topProductResponse = await ShopRepository()
        .getTopFromThisSellerProducts(id: _shopDetails?.id);
    _topProducts.addAll(topProductResponse.products!);
    _topProductInitNotifier.value = true;
  }

  fetchFeaturedProducts() async {
    var featuredProductResponse = await ShopRepository()
        .getfeaturedFromThisSellerProducts(id: _shopDetails?.id);
    _featuredProducts.addAll(featuredProductResponse.products!);
    _featuredProductInitNotifier.value = true;
  }

  reset() {
    _shopDetails = null;
    _carouselImageList.clear();
    _carouselInitNotifier.value = false;
    _newArrivalProducts.clear();
    _topProducts.clear();
    _featuredProducts.clear();
    _topProductInitNotifier.value = false;
    _newArrivalProductInitNotifier.value = false;
    _featuredProductInitNotifier.value = false;

    _allProductList.clear();
    _allProductInitNotifier.value = false;
    _pageNotifier.value = 1;
    _isFollowedNotifier.value = null;
    _shopLoadedNotifier.value = false;
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        //bottomNavigationBar: buildBottomAppBar(context),
        body: RefreshIndicator(
          color: MyTheme.accent_color,
          backgroundColor: Colors.white,
          onRefresh: _onPageRefresh,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  buildCarouselSlider(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 0.0),
                    child:
                        _shopDetails == null
                            ? buildShopDetailsShimmer()
                            : buildShopDetails(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0, 20.0, 18.0, 0.0),
                    child:
                        _shopDetails == null
                            ? buildTabOptionShimmer(context)
                            : buildTabOption(context),
                  ),
                  buildTabBarBody(context),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTabBarBody(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _tabIndexNotifier,
      builder: (context, tabIndex, child) {
        if (tabIndex == 1) {
          return _shopDetails != null
              ? buildTopSelling(context)
              : ShimmerHelper().buildProductGridShimmer();
        }
        if (tabIndex == 2) {
          return _shopDetails != null
              ? buildAllProducts(context)
              : ShimmerHelper().buildProductGridShimmer();
        }
        return _shopDetails != null
            ? buildStoreHome(context)
            : buildStoreHomeShimmer(context);
      },
    );
  }

  Container buildTopSelling(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 20.0, 18.0, 0.0),
            child: Text(
              AppLocalizations.of(context)!.top_selling_products_ucf,
              style: TextStyle(
                color: MyTheme.font_grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          buildTopSellingProducts(),
        ],
      ),
    );
  }

  Container buildAllProducts(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 20.0, 18.0, 0.0),
            child: Text(
              AppLocalizations.of(context)!.all_products_ucf,
              style: TextStyle(
                color: MyTheme.font_grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          buildAllProductList(),
        ],
      ),
    );
  }

  Widget buildStoreHome(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_featuredProducts.isNotEmpty) buildFeaturedProductsSection(),
        SizedBox(height: 24),
        Container(
          color: MyTheme.mainColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 14.0, 0.0, 4.0),
                child: Text(
                  AppLocalizations.of(context)!.new_arrivals_products_ucf,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              buildNewArrivalProducts(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildStoreHomeShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildFeaturedProductsShimmerSection(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18.0, 20.0, 18.0, 0.0),
          child: ShimmerHelper().buildBasicShimmer(
            height: 15,
            width: 90,
            radius: 0,
          ),
        ),
        ShimmerHelper().buildProductGridShimmer(),
      ],
    );
  }

  //////Featured Products///////////
  Widget buildFeaturedProductsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        height: 296,
        decoration: BoxDecoration(color: Color(0xffF2F1F6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 20),
              child: Text(
                LangText(context).local.featured_products_ucf,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ),
            Container(
              height: 240,
              padding: EdgeInsets.only(top: 15),
              width: double.infinity,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 20),
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: 200,
                    width: 140,
                    child: FeaturedProductCard(
                      id: _featuredProducts[index].id,
                      slug: _featuredProducts[index].slug,
                      image: _featuredProducts[index].thumbnail_image,
                      name: _featuredProducts[index].name,
                      main_price: _featuredProducts[index].main_price,
                      stroked_price: _featuredProducts[index].stroked_price,
                      // has_discount: _featuredProducts[index].has_discount,
                      is_wholesale: null,
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return Container(width: 14);
                },
                itemCount: _featuredProducts.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFeaturedProductsShimmerSection() {
    return Container(
      margin: EdgeInsets.only(top: 20.0),
      height: 280,
      decoration: BoxDecoration(
        color: MyTheme.mainColor,
        image: DecorationImage(image: AssetImage("assets/background_1.png")),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18.0, top: 20),
            child: Column(
              children: [
                ShimmerHelper().buildBasicShimmer(
                  height: 15,
                  width: 90,
                  radius: 0,
                ),
              ],
            ),
          ),
          Container(
            height: 239,
            padding: EdgeInsets.only(top: 10, bottom: 20),
            width: double.infinity,
            child: ListView.separated(
              itemCount: 10,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 18),
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 196,
                  width: 124,
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 196,
                    width: 124,
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Container(width: 14);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabOption(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _tabIndexNotifier,
      builder: (context, tabIndex, child) {
        return Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildTabOptionItem(context, tabIndex, 0, LangText(context).local.store_home_ucf),
              buildTabOptionItem(context, tabIndex, 1, LangText(context).local.top_selling_products_ucf),
              buildTabOptionItem(context, tabIndex, 2, LangText(context).local.all_products_ucf),
            ],
          ),
        );
      },
    );
  }

  Widget buildTabOptionShimmer(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 800),
            height: 30,
            width: DeviceInfo(context).width! / 4,
            decoration: BoxDecorations.buildBoxDecoration_1(),
            child: ShimmerHelper().buildBasicShimmer(
              height: 30,
              width: DeviceInfo(context).width! / 4,
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 800),
            height: 30,
            width: DeviceInfo(context).width! / 4,
            decoration: BoxDecorations.buildBoxDecoration_1(),
            child: ShimmerHelper().buildBasicShimmer(
              height: 30,
              width: DeviceInfo(context).width! / 4,
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 800),
            height: 30,
            width: DeviceInfo(context).width! / 4,
            decoration: BoxDecorations.buildBoxDecoration_1(),
            child: ShimmerHelper().buildBasicShimmer(
              height: 30,
              width: DeviceInfo(context).width! / 4,
            ),
          ),
        ],
      ),
    );
  }

  AnimatedContainer buildTabOptionItem(
    BuildContext context,
    int tabIndex,
    index,
    String text,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      height: 31,
      width: DeviceInfo(context).width! / 3.5,
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child: Btn.basic(
        padding: EdgeInsets.zero,
        color: tabIndex == index ? MyTheme.accent_color : MyTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        onPressed: () {
          _tabIndexNotifier.value = index;
        },
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color:
                tabIndex == index
                    ? MyTheme.white
                    : MyTheme.dark_font_grey,
            fontWeight:
                tabIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  ///////Top Carosel Slider /////////////

  buildCarouselSlider(context) {
    if (_shopDetails == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ShimmerHelper().buildBasicShimmer(height: 100.0),
      );
    } else if (_carouselImageList.isNotEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0.5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: CarouselSlider(
          options: CarouselOptions(
            height: 177,
            aspectRatio: 3.7,
            viewportFraction: 1.0,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
            autoPlayAnimationDuration: Duration(milliseconds: 1000),
            autoPlayCurve: Curves.easeInExpo,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              _currentSliderNotifier.value = index;
            },
          ),
          items:
              _carouselImageList.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Stack(
                      children: <Widget>[
                        SizedBox(
                          height: 177,
                          width: double.infinity,
                          child: ClipRRect(
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/placeholder_rectangle.png',
                              image: i,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                _carouselImageList.map((url) {
                                  int index = _carouselImageList.indexOf(url);
                                  return Container(
                                    width: 8.0, // Size of the indicator
                                    height: 8.0,
                                    margin: EdgeInsets.symmetric(
                                      vertical: 10.0,
                                      horizontal: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            _currentSliderNotifier.value == index
                                                ? Colors
                                                    .white // White border for active indicator
                                                : Color(
                                                  0xffE62E04,
                                                ), // Red border for inactive
                                        width: 1.0, // Width of the border
                                      ),
                                      color:
                                          _currentSliderNotifier.value == index
                                              ? Color(
                                                0xffE62E04,
                                              ) // Red fill for active indicator
                                              : Colors
                                                  .transparent, // No fill for inactive indicator
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            0.2,
                                          ), // Shadow color
                                          spreadRadius:
                                              2, // Spread of the shadow
                                          blurRadius:
                                              4, // Blur radius for softness
                                          offset: Offset(
                                            0,
                                            2,
                                          ), // Offset for shadow position
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }).toList(),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget buildTopSellingProducts() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      itemCount: _topProducts.length,
      shrinkWrap: true,
      padding: EdgeInsets.only(top: 10.0, bottom: 10, left: 18, right: 18),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return FeaturedProductCard(
          id: _topProducts[index].id,
          slug: _topProducts[index].slug,
          image: _topProducts[index].thumbnail_image,
          name: _topProducts[index].name,
          main_price: _topProducts[index].main_price,
          stroked_price: _topProducts[index].stroked_price,
          has_discount: _topProducts[index].has_discount,
          discount: _topProducts[index].discount,
          is_wholesale: _topProducts[index].isWholesale,
        );
      },
    );
  }

  ///New Arrivals Product
  Widget buildNewArrivalProducts(context) {
    if (!_newArrivalProductInitNotifier.value && _newArrivalProducts.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(),
      );
    } else if (_newArrivalProducts.isNotEmpty) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        itemCount: _newArrivalProducts.length,
        shrinkWrap: true,
        padding: EdgeInsets.only(top: 10.0, bottom: 10, left: 18, right: 18),
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return FeaturedProductCard(
            id: _newArrivalProducts[index].id,
            slug: _newArrivalProducts[index].slug,
            image: _newArrivalProducts[index].thumbnail_image,
            name: _newArrivalProducts[index].name,
            main_price: _newArrivalProducts[index].main_price,
            stroked_price: _newArrivalProducts[index].stroked_price,
            has_discount: _newArrivalProducts[index].has_discount,
            discount: _newArrivalProducts[index].discount,
            is_wholesale: _newArrivalProducts[index].isWholesale,
          );
        },
      );
    } else if (_newArrivalProducts.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return Container(); // should never be happening
    }
  }

  Widget buildAllProductList() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      itemCount: _allProductList.length,
      shrinkWrap: true,
      padding: EdgeInsets.only(top: 10.0, bottom: 10, left: 18, right: 18),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return FeaturedProductCard(
          id: _allProductList[index].id,
          slug: _allProductList[index].slug,
          image: _allProductList[index].thumbnail_image,
          name: _allProductList[index].name,
          main_price: _allProductList[index].main_price,
          stroked_price: _allProductList[index].stroked_price,
          has_discount: _allProductList[index].has_discount,
          discount: _allProductList[index].discount,
          is_wholesale: _allProductList[index].isWholesale,
        );
      },
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      toolbarHeight: 50,
      leading: Builder(
        builder:
            (context) => IconButton(
              padding: EdgeInsets.zero,
              icon: UsefulElements.backButton(context),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: buildAppbarShopTitle(),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  //Shop details
  Widget buildShopDetails() {
    return Container(
      //color: Colors.red,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            //  decoration: BoxDecorations.buildBoxDecoration_1(),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 20,
                  spreadRadius: 0.0,
                  offset: Offset(0.0, 10.0), // shadow direction: bottom right
                ),
              ],
            ),
            padding: EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder.png',
                image: _shopDetails?.logo ?? "",
                fit: BoxFit.cover,
                imageErrorBuilder: (BuildContext, Object, StackTrace) {
                  return Image.asset('assets/placeholder_rectangle.png');
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 10),
            width: DeviceInfo(context).width! / 2.5,
            height: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _shopDetails?.name ?? "",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                buildRatingWithCountRow(),
                Text(
                  _shopDetails?.address ?? "",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Color(0xff6B7377),
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Container(
            height: 28,
            width: 91,
            decoration: BoxDecoration(
              color: Color(0xffFEF0D7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 20,
                  spreadRadius: 0.0,
                  offset: Offset(0.0, 10.0), // shadow direction: bottom right
                ),
              ],
              borderRadius: BorderRadius.circular(3.0),
            ),
            child: Btn.basic(
              padding: EdgeInsets.zero,
              color:
                  _isFollowedNotifier.value != null && _isFollowedNotifier.value!
                      ? MyTheme.green_light
                      : MyTheme.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color:
                      _isFollowedNotifier.value != null && _isFollowedNotifier.value!
                          ? MyTheme.green
                          : MyTheme.golden,
                ),
              ),
              onPressed: () {
                if (!is_logged_in.$) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Login();
                      },
                    ),
                  );
                  return;
                }
                if (_isFollowedNotifier.value != null) {
                  if (_isFollowedNotifier.value!) {
                    removedFollow(_shopDetails?.id);
                  } else {
                    addFollow(_shopDetails?.id);
                  }
                }

                ///TODO Seller
              },
              child: Text(
                _isFollowedNotifier.value != null && _isFollowedNotifier.value!
                    ? LangText(context).local.followed_ucf
                    : LangText(context).local.follow_ucf,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      _isFollowedNotifier.value != null && _isFollowedNotifier.value!
                          ? MyTheme.green
                          : MyTheme.golden,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildShopDetailsShimmer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecorations.buildBoxDecoration_1(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: ShimmerHelper().buildBasicShimmer(height: 60, width: 60),
          ),
        ),
        Flexible(
          child: Container(
            //color: Colors.amber,
            padding: EdgeInsets.only(left: 10),
            width: DeviceInfo(context).width! / 2,
            height: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerHelper().buildBasicShimmer(
                  height: 16,
                  width: DeviceInfo(context).width! / 4,
                ),
                ShimmerHelper().buildBasicShimmer(
                  height: 16,
                  width: DeviceInfo(context).width! / 4,
                ),
                ShimmerHelper().buildBasicShimmer(
                  height: 16,
                  width: DeviceInfo(context).width! / 4,
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 30,
          decoration: BoxDecorations.buildBoxDecoration_1(),
          child: ShimmerHelper().buildBasicShimmer(
            height: 30,
            width: DeviceInfo(context).width! / 4,
          ),
        ),
      ],
    );
  }

  buildAppbarShopTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: DeviceInfo(context).width! - 70,
          child: Text(
            _shopDetails?.name ?? "",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: MyTheme.dark_font_grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Row buildRatingWithCountRow() {
    return Row(
      children: [
        RatingBar(
          itemSize: 14.0,
          ignoreGestures: true,
          initialRating: double.parse((_shopDetails?.rating ?? 0).toString()),
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          ratingWidget: RatingWidget(
            full: Icon(Icons.star, color: Colors.amber),
            half: Icon(Icons.star_half, color: Colors.amber),
            empty: Icon(Icons.star, color: Color.fromRGBO(224, 224, 225, 1)),
          ),
          //  itemPadding: EdgeInsets.only(right: 4.0),
          onRatingUpdate: (rating) {
            print(rating);
          },
        ),
      ],
    );
  }
}

///Featured Products
class FeaturedProductCard extends StatefulWidget {
  final dynamic identifier;
  final int? id;
  final String slug;
  final String? image;
  final String? name;
  final String? main_price;
  final String? stroked_price;
  final bool has_discount;
  final bool? isWholesale;
  final String? discount;

  const FeaturedProductCard({
    super.key,
    this.identifier,
    required this.slug,
    this.id,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount = false,
    this.isWholesale = false,
    this.discount,
    required is_wholesale,
  });

  @override
  _FeaturedProductCardState createState() => _FeaturedProductCardState();
}

class _FeaturedProductCardState extends State<FeaturedProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return widget.identifier == 'auction'
                  ? AuctionProductsDetails(slug: widget.slug)
                  : ProductDetails(slug: widget.slug);
            },
          ),
        );
      },
      child: Container(
        //decoration: BoxDecorations.buildBoxDecoration_1(),
        //decoration: BoxDecoration(color: Color(0xffF6F5FA)),
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      clipBehavior: Clip.hardEdge,
                      borderRadius: BorderRadius.circular(10),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: widget.image ?? 'assets/placeholder.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          widget.name ?? 'No Name',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      if (widget.has_discount)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Text(
                            SystemConfig.systemCurrency != null
                                ? widget.stroked_price?.replaceAll(
                                      SystemConfig.systemCurrency!.code!,
                                      SystemConfig.systemCurrency!.symbol!,
                                    ) ??
                                    ''
                                : widget.stroked_price ?? '',
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: MyTheme.medium_grey,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        )
                      else
                        SizedBox(height: 4.0),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          SystemConfig.systemCurrency != null
                              ? widget.main_price?.replaceAll(
                                    SystemConfig.systemCurrency!.code!,
                                    SystemConfig.systemCurrency!.symbol!,
                                  ) ??
                                  ''
                              : widget.main_price ?? '',
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.has_discount)
                      Container(
                        // padding:
                        //     EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        height: 20,
                        width: 48,
                        margin: EdgeInsets.only(
                          top: 8,
                          right: 8,
                          bottom: 15,
                        ), // Adjusted margin
                        decoration: BoxDecoration(
                          color: const Color(0xffe62e04),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x14000000),
                              offset: Offset(-1, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.discount ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.8,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                            ),
                            softWrap: false,
                          ),
                        ),
                      ),
                    if (whole_sale_addon_installed.$ && widget.isWholesale!)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x14000000),
                              offset: Offset(-1, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          "Wholesale",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.8,
                          ),
                          textHeightBehavior: TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                          ),
                          softWrap: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
