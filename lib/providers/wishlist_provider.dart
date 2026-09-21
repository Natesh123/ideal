import 'package:active_ecommerce_cms_demo_app/repositories/wishlist_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wishlist_provider.g.dart';

@riverpod
class Wishlist extends _$Wishlist {
  @override
  FutureOr<List<dynamic>> build() async {
    return _fetchWishlistItems();
  }

  Future<List<dynamic>> _fetchWishlistItems() async {
    final wishlistResponse = await WishListRepository().getUserWishlist();
    return wishlistResponse.wishlist_items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWishlistItems());
  }

  Future<void> removeItem(int index) async {
    // Logic to remove item can be added here
  }
}
