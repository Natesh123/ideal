import 'package:flutter/material.dart';
import 'cart_seller_item_card_widget.dart';

class CartSellerItemListWidget extends StatelessWidget {
  final int sellerIndex;
  final List shopList;
  final BuildContext? context;

  const CartSellerItemListWidget({
    super.key,
    required this.sellerIndex,
    required this.shopList,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListView.separated(
        separatorBuilder: (context, index) => SizedBox(
          height: 14,
        ),
        itemCount: shopList[sellerIndex].cartItems.length,
        scrollDirection: Axis.vertical,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return CartSellerItemCardWidget(
            sellerIndex: sellerIndex,
            itemIndex: index,
            shopList: shopList,
          );
        },
      ),
    );
  }
}
