import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/product_repository.dart';

import 'package:active_ecommerce_cms_demo_app/data_model/wholesale_model.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auction/auction_products_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:active_ecommerce_cms_demo_app/app_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

class WholesalesScreen extends StatefulWidget {
  const WholesalesScreen({super.key});

  @override
  State<WholesalesScreen> createState() => _WholesalesScreenState();
}

class _WholesalesScreenState extends State<WholesalesScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<Product>> _productsList = ValueNotifier([]);
  final ValueNotifier<bool> _isInitial = ValueNotifier(true);
  int _page = 1;
  final ValueNotifier<bool> _showLoadingContainer = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _page++;
        _showLoadingContainer.value = true;
        fetchData();
      }
    });
  }

  fetchData() async {
    var response = await ProductRepository().getWholesaleProducts(page: _page);
    _productsList.value = [..._productsList.value, ...response.products.data];
    _isInitial.value = false;
    _showLoadingContainer.value = false;
  }

  reset() {
    _productsList.value = [];
    _isInitial.value = true;
    _page = 1;
    _showLoadingContainer.value = false;
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.mainColor,
      appBar: buildAppBar(context),
      body: Stack(
        children: [
          buildProductList(context),
          Align(
            alignment: Alignment.bottomCenter,
            child: buildLoadingContainer(),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingContainer() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showLoadingContainer,
      builder: (context, showLoading, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: showLoading ? 36 : 0,
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.loading_more_products_ucf,
            ),
          ),
        );
      },
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      automaticallyImplyLeading: false,
      title: Text(
        AppLocalizations.of(context)!.wholesale_products_ucf,
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
    );
  }

  Widget buildProductList(context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isInitial,
      builder: (context, isInitial, child) {
        return ValueListenableBuilder<List<Product>>(
          valueListenable: _productsList,
          builder: (context, products, child) {
            if (isInitial && products.isEmpty) {
              return ShimmerHelper().buildProductGridShimmer(
                scontroller: _scrollController,
              );
            } else if (products.isNotEmpty) {
              return RefreshIndicator(
                color: MyTheme.accent_color,
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: products.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      top: 20.0,
                      bottom: 10,
                      left: 18,
                      right: 18,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      var product = products[index];
                      return WholeSalesProductCard(
                        id: product.id,
                        slug: product.slug,
                        image: product.thumbnailImage,
                        name: product.name,
                        main_price: product.basePrice.toStringAsFixed(2),
                        stroked_price: product.baseDiscountedPrice.toStringAsFixed(2),
                        has_discount: product.discount != 0.0,
                        discount: product.discount_percentage,
                        is_wholesale: true,
                      );
                    },
                  ),
                ),
              );
            } else {
              return Center(
                child: Text(AppLocalizations.of(context)!.no_data_is_available),
              );
            }
          },
        );
      },
    );
  }
}

class WholeSalesProductCard extends StatefulWidget {
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

  const WholeSalesProductCard({
    super.key,
    this.identifier,
    required this.slug,
    this.id,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount = false,
    bool? is_wholesale = false,
    this.discount,
  }) : isWholesale = is_wholesale;

  @override
  _WholeSalesProductCardState createState() => _WholeSalesProductCardState();
}

class _WholeSalesProductCardState extends State<WholeSalesProductCard> {
  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Wholesale status: ${widget.isWholesale}',
    );
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
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          clipBehavior: Clip.hardEdge,
                          borderRadius: BorderRadius.circular(10),
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder.png',
                            image: AppConfig.getSanitizedUrl(widget.image ?? 'assets/placeholder.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (whole_sale_addon_installed.$ && widget.isWholesale!)
                        Positioned(
                          bottom: 0,
                          child: Container(
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
                        ),
                    ],
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
                                ? "${SystemConfig.systemCurrency!.symbol!} ${widget.main_price}"
                                : widget.main_price ?? '',
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: MyTheme.medium_grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      else
                        SizedBox(height: 8.0),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          SystemConfig.systemCurrency != null
                              ? "${SystemConfig.systemCurrency!.symbol!} ${widget.stroked_price}"
                              : widget.stroked_price ?? '',
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Color(0xffE62E04),
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
                        height: 20,
                        width: 48,
                        margin: EdgeInsets.only(top: 8, right: 8, bottom: 15),
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
