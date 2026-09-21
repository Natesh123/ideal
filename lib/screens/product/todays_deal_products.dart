import 'package:active_ecommerce_cms_demo_app/data_model/product_mini_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/product_repository.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/product_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TodaysDealProducts extends StatefulWidget {
  const TodaysDealProducts({super.key});

  @override
  _TodaysDealProductsState createState() => _TodaysDealProductsState();
}

class _TodaysDealProductsState extends State<TodaysDealProducts> {
  ScrollController? _scrollController;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: buildProductList(context),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Text(
        AppLocalizations.of(context)!.todays_deal_ucf,
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildProductList(context) {
    return FutureBuilder(
      future: ProductRepository().getTodaysDealProducts(),
      builder: (context, AsyncSnapshot<ProductMiniResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Container();
          } else if (snapshot.data!.products!.isEmpty) {
            return Container(
              child: Center(
                child: Text(AppLocalizations.of(context)!.no_data_is_available),
              ),
            );
          } else if (snapshot.hasData) {
            var productResponse = snapshot.data;
            return SingleChildScrollView(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.58,
                ),
                itemCount: productResponse!.products!.length,
                shrinkWrap: true,
                padding: const EdgeInsets.only(
                  top: 20.0,
                  bottom: 10,
                  left: 18,
                  right: 18,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return ProductCard(
                    id: productResponse.products![index].id,
                    slug: productResponse.products![index].slug!,
                    image: productResponse.products![index].thumbnail_image,
                    name: productResponse.products![index].name,
                    main_price: productResponse.products![index].main_price,
                    stroked_price:
                        productResponse.products![index].stroked_price,
                    has_discount:
                        productResponse.products![index].has_discount!,
                    discount: productResponse.products![index].discount,
                    is_wholesale: productResponse.products![index].isWholesale,
                  );
                },
              ),
            );
          }
        }

        return ShimmerHelper().buildProductGridShimmer(
          scontroller: _scrollController,
        );
      },
    );
  }
}
