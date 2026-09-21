import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:active_ecommerce_cms_demo_app/providers/cart_riverpod_provider.dart';
import '../app_config.dart';
import '../helpers/system_config.dart';
import '../my_theme.dart';
import 'box_decorations.dart';
import 'device_info.dart';
class CartSellerItemCardWidget extends ConsumerWidget {
  final int sellerIndex;
  final int itemIndex;
  final List shopList;
  const CartSellerItemCardWidget(
      {super.key,
        required this.shopList,
        required this.sellerIndex,
        required this.itemIndex});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItem = shopList[sellerIndex].cartItems[itemIndex];
    final bool isOutOfStock =
        (cartItem.digital ?? 0) == 0 && cartItem.stock == 0;
    final bool showQuantityControls =
        !isOutOfStock && (cartItem.digital ?? 0) != 1;
    return Container(
      height: 120,
      decoration: BoxDecoration(
          color: isOutOfStock ? Colors.grey.shade300 : Colors.white,
          borderRadius: BorderRadius.circular(6)),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(
              width: DeviceInfo(context).width! / 4,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(6), right: Radius.zero),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: AppConfig.getSanitizedUrl(cartItem.productThumbnailImage!),
                        fit: BoxFit.contain,
                      )),
                  if (isOutOfStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(6), right: Radius.zero),
                      ),
                      child: const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: DeviceInfo(context).width! / 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cartItem.productName!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 23.0),
                      child: Row(
                        children: [
                          Text(
                            SystemConfig.systemCurrency != null
                                ? cartItem.price!.replaceAll(
                                SystemConfig.systemCurrency!.code!,
                                SystemConfig.systemCurrency!.symbol!)
                                : cartItem.price!,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(
                                color: MyTheme.accent_color,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            Container(
              width: 32,
              margin: showQuantityControls
                  ? null
                  : const EdgeInsets.only(right: 8.0),
              child: Column(
                mainAxisAlignment: showQuantityControls
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      ref.read(cartRiverpodProvider.notifier).deleteItem(cartItem.id);
                    },
                    child: Padding(
                      padding: showQuantityControls
                          ? const EdgeInsets.only(bottom: 14.0)
                          : EdgeInsets.zero,
                      child: Image.asset(
                        'assets/trash.png',
                        height: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showQuantityControls)
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (cartItem.auctionProduct == 0) {
                          ref.read(cartRiverpodProvider.notifier).increaseQuantity(cartItem);
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration:
                        BoxDecorations.buildCartCircularButtonDecoration(),
                        child: Icon(
                          Icons.add,
                          color: cartItem.auctionProduct == 0
                              ? MyTheme.accent_color
                              : MyTheme.grey_153,
                          size: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        cartItem.quantity.toString(),
                        style: const TextStyle(
                            color: MyTheme.accent_color, fontSize: 16),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (cartItem.auctionProduct == 0) {
                          ref.read(cartRiverpodProvider.notifier).decreaseQuantity(cartItem);
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration:
                        BoxDecorations.buildCartCircularButtonDecoration(),
                        child: Icon(
                          Icons.remove,
                          color: cartItem.auctionProduct == 0
                              ? MyTheme.accent_color
                              : MyTheme.grey_153,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ]),
    );
  }
}