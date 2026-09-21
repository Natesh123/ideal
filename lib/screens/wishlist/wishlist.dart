import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/wishlist_repository.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:active_ecommerce_cms_demo_app/providers/wishlist_provider.dart' as riverpod_provider;

import 'widgets/wishlist_grid_view.dart';

class Wishlist extends ConsumerStatefulWidget {
  const Wishlist({super.key});

  @override
  ConsumerState<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends ConsumerState<Wishlist> {
  final ScrollController _mainScrollController = ScrollController();

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> _onPageRefresh() async {
    return ref.read(riverpod_provider.wishlistProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
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
              SliverList(delegate: SliverChildListDelegate([buildWishlist()])),
            ],
          ),
        ),
      ),
    );
  }

  buildWishlist() {
    if (is_logged_in.$ == false) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.you_need_to_log_in,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }

    final wishlistAsync = ref.watch(riverpod_provider.wishlistProvider);

    return wishlistAsync.when(
      data: (wishlistItems) {
        if (wishlistItems.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_item_is_available,
                style: TextStyle(color: MyTheme.font_grey),
              ),
            ),
          );
        }
        return WishListGridView(wishlistItems: wishlistItems);
      },
      loading: () => SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(item_count: 10),
      ),
      error: (error, stack) => SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "Error loading wishlist",
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: UsefulElements.backButton(context),
              onPressed: () => Navigator.of(context).pop(),
            ),
      ),
      title: Text(
        AppLocalizations.of(context)!.my_wishlist_ucf,
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

  // buildWishListItem(index) {
  //   return InkWell(
  //     onTap: () {
  //       Navigator.push(context, MaterialPageRoute(builder: (context) {
  //         return ProductDetails(
  //           slug: _wishlistItems[index].product.slug,
  //         );
  //       }));
  //     },
  //     child: Stack(
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.only(left: 12.0, right: 12.0),
  //           child: Card(
  //             shape: RoundedRectangleBorder(
  //               side: new BorderSide(color: MyTheme.light_grey, width: 1.0),
  //               borderRadius: BorderRadius.circular(16.0),
  //             ),
  //             elevation: 0.0,
  //             child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   Container(
  //                       width: 100,
  //                       height: 100,
  //                       child: ClipRRect(
  //                           borderRadius: BorderRadius.horizontal(
  //                               left: Radius.circular(16), right: Radius.zero),
  //                           child: FadeInImage.assetNetwork(
  //                             placeholder: 'assets/placeholder.png',
  //                             image:
  //                                 _wishlistItems[index].product.thumbnail_image,
  //                             fit: BoxFit.cover,
  //                           ))),
  //                   Container(
  //                     width: 240,
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Padding(
  //                           padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
  //                           child: Text(
  //                             _wishlistItems[index].product.name,
  //                             overflow: TextOverflow.ellipsis,
  //                             maxLines: 2,
  //                             style: TextStyle(
  //                                 color: MyTheme.font_grey,
  //                                 fontSize: 14,
  //                                 height: 1.6,
  //                                 fontWeight: FontWeight.w400),
  //                           ),
  //                         ),
  //                         Padding(
  //                           padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
  //                           child: Text(
  //                             _wishlistItems[index].product.base_price,
  //                             textAlign: TextAlign.left,
  //                             overflow: TextOverflow.ellipsis,
  //                             maxLines: 1,
  //                             style: TextStyle(
  //                                 color: MyTheme.accent_color,
  //                                 fontSize: 14,
  //                                 fontWeight: FontWeight.w600),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ]),
  //           ),
  //         ),
  //         app_language_rtl.$!
  //             ? Positioned(
  //                 bottom: 8,
  //                 left: 12,
  //                 child: IconButton(
  //                   icon: Icon(Icons.delete_forever_outlined,
  //                       color: MyTheme.medium_grey),
  //                   onPressed: () {
  //                     _onPressRemove(index);
  //                   },
  //                 ),
  //               )
  //             : Positioned(
  //                 bottom: 8,
  //                 right: 12,
  //                 child: IconButton(
  //                   icon: Icon(Icons.delete_forever_outlined,
  //                       color: MyTheme.medium_grey),
  //                   onPressed: () {
  //                     _onPressRemove(index);
  //                   },
  //                 ),
  //               ),
  //       ],
  //     ),
  //   );
  // }
}
