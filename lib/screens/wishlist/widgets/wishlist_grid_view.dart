import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../ui_elements/product_card.dart';

class WishListGridView extends StatelessWidget {
  const WishListGridView({
    super.key,
    required List wishlistItems,
  }) : _wishlistItems = wishlistItems;

  final List _wishlistItems;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 0,
        crossAxisSpacing: 14,
        itemCount: _wishlistItems.length,
        shrinkWrap: true,
        padding: EdgeInsets.only(top: 0.0, bottom: 10, left: 18, right: 18),
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return ProductCard(
            id: _wishlistItems[index].product.id,
            slug: _wishlistItems[index].product.slug,
            image: _wishlistItems[index].product.thumbnail_image,
            name: _wishlistItems[index].product.name,
            main_price: _wishlistItems[index].product.base_price,
            // is_wholesale: _wishlistItems[index].product.isWholesale,
            stroked_price: "0",
            has_discount: false, is_wholesale: null,
          );
        },
      ),
    );
  }
}
