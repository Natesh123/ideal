import 'package:active_ecommerce_cms_demo_app/custom/aiz_route.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/cart_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/cart_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/select_address.dart';
import 'package:active_ecommerce_cms_demo_app/screens/guest_checkout_pages/guest_checkout_address.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_riverpod_provider.g.dart';

@riverpod
class CartRiverpod extends _$CartRiverpod {
  @override
  Future<CartResponse?> build() async {
    return fetchCart();
  }

  Future<CartResponse?> fetchCart() async {
    if (user_id.$ == 0) return null;
    return await CartRepository().getCartResponseList(user_id.$);
  }

  Future<void> updateQuantity(int cartId, int quantity) async {
    await CartRepository().getCartProcessResponse(cartId.toString(), quantity.toString());
    ref.invalidateSelf();
  }

  Future<void> increaseQuantity(dynamic item) async {
    if (item.quantity < item.upperLimit) {
      await updateQuantity(item.id, item.quantity + 1);
    }
  }

  Future<void> decreaseQuantity(dynamic item) async {
    if (item.quantity > item.lowerLimit) {
      await updateQuantity(item.id, item.quantity - 1);
    }
  }

  Future<void> deleteItem(int cartId) async {
    final response = await CartRepository().getCartDeleteResponse(cartId);
    if (response.result == true) {
      ref.invalidateSelf();
    }
  }

  Future<void> process(BuildContext context, {required String mode}) async {
    final cartData = state.value;
    if (cartData == null || cartData.data == null || cartData.data!.isEmpty) {
      return;
    }

    var cartIds = [];
    var cartQuantities = [];

    for (var shop in cartData.data!) {
      if (shop.cartItems != null && shop.cartItems!.isNotEmpty) {
        for (var cartItem in shop.cartItems!) {
          cartIds.add(cartItem.id);
          cartQuantities.add(cartItem.quantity);
        }
      }
    }

    if (cartIds.isEmpty) return;

    var cartIdsString = cartIds.join(',').toString();
    var cartQuantitiesString = cartQuantities.join(',').toString();

    var cartProcessResponse = await CartRepository().getCartProcessResponse(
      cartIdsString,
      cartQuantitiesString,
    );

    if (cartProcessResponse.result == false) {
      ToastComponent.showDialog(cartProcessResponse.message);
    } else {
      if (mode == "update") {
        ref.invalidateSelf();
      } else if (mode == "proceed_to_shipping") {
        if (guest_checkout_status.$ && !is_logged_in.$) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GuestCheckoutAddress(),
            ),
          );
        } else {
          AIZRoute.push(context, const SelectAddress()).then((value) {
            ref.invalidateSelf();
          });
        }
      }
    }
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
