import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../helpers/shimmer_helper.dart';
import '../presenter/home_presenter.dart';
import '../ui_elements/product_card_black.dart';

class HomeAllProducts2 extends StatelessWidget {
  final HomePresenter homeData;

  const HomeAllProducts2({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    if (homeData.isAllProductInitial) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: homeData.allProductScrollController,
        ),
      );
    } else if (homeData.allProductList.isNotEmpty) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.58,
        ),
        itemCount: homeData.allProductList.length,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final product = homeData.allProductList[index];
          return ProductCardBlack(
            id: product.id,
            slug: product.slug,
            image: product.thumbnail_image,
            name: product.name,
            main_price: product.main_price,
            stroked_price: product.stroked_price,
            has_discount: product.has_discount,
            discount: product.discount,
            is_wholesale: product.isWholesale,
          );
        },
      );
    } else if (homeData.totalAllProductData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
