import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/text_styles.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/cart_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/cart_response.dart';
import 'package:active_ecommerce_cms_demo_app/providers/cart_riverpod_provider.dart';
import '../../custom/cart_seller_item_list_widget.dart';

class Cart extends ConsumerStatefulWidget {
  const Cart({
    super.key,
    this.has_bottomnav,
    this.from_navigation = false,
    this.counter,
  });

  final bool? has_bottomnav;
  final bool from_navigation;
  final CartCounter? counter;

  @override
  ConsumerState<Cart> createState() => _CartState();
}

class _CartState extends ConsumerState<Cart> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // ref.read(cartRiverpodProvider.notifier).fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartRiverpodProvider);

    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xffF2F1F6),
        appBar: buildAppBar(context),
        body: cartAsync.when(
          data: (cartResponse) {
            final shopList = cartResponse?.data ?? [];
            return Stack(
              children: [
                RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: () async => ref.invalidate(cartRiverpodProvider),
                  displacement: 0,
                  child: CustomScrollView(
                    controller: ScrollController(), // Temporary or migrate from CartProvider
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: buildCartSellerList(shopList, context),
                          ),
                          Container(
                            height: widget.has_bottomnav!
                                ? MediaQuery.of(context).size.height * 0.2
                                : 100,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: buildBottomContainer(cartResponse),
                ),
              ],
            );
          },
          loading: () => ShimmerHelper().buildListShimmer(item_count: 5),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Container buildBottomContainer(CartResponse? cartResponse) {
    final bool canProceed =
        (cartResponse?.data?.isNotEmpty ?? false) && 
        !(cartResponse?.data?.any((seller) => seller.cartItems?.any((item) => (item.digital ?? 0) == 0 && item.stock == 0) ?? false) ?? false);

    return Container(
      decoration: const BoxDecoration(color: Color(0xffF2F1F6)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: MyTheme.soft_accent_color,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      AppLocalizations.of(context)!.total_amount_ucf,
                      style: TextStyle(
                        color: MyTheme.dark_font_grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      cartResponse?.grandTotal?.replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!,
                      ) ?? ". . .",
                      style: const TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    height: 58,
                    width: (MediaQuery.of(context).size.width - 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: MyTheme.accent_color, width: 1),
                      borderRadius: app_language_rtl.$!
                          ? BorderRadius.circular(6.0)
                          : BorderRadius.circular(6.0),
                    ),
                    child: Btn.basic(
                      minWidth: MediaQuery.of(context).size.width,
                      color: canProceed ? MyTheme.accent_color : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.proceed_to_shipping_ucf,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: canProceed
                          ? () {
                              // Perform checkout
                              ref.read(cartRiverpodProvider.notifier).process(context, mode: "proceed_to_shipping");
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xffF2F1F6),
      leading: Builder(
        builder: (context) => widget.from_navigation
            ? UsefulElements.backToMain(context, go_back: false)
            : UsefulElements.backButton(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.shopping_cart_ucf,
        style: TextStyles.buildAppBarTexStyle(),
      ),
      elevation: 0.0,
    );
  }

  Widget buildCartSellerList(List shopList, BuildContext context) {
    if (shopList.isNotEmpty) {
      return ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 26),
        itemCount: shopList.length,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  children: [
                    Text(
                      shopList[index].name,
                      style: TextStyle(
                        color: MyTheme.dark_font_grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      shopList[index].subTotal.replaceAll(
                        SystemConfig.systemCurrency!.code,
                        SystemConfig.systemCurrency!.symbol,
                      ) ??
                          '',
                      style: const TextStyle(
                        color: MyTheme.accent_color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CartSellerItemListWidget(
                sellerIndex: index,
                shopList: shopList,
                context: context,
              ),
            ],
          );
        },
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.cart_is_empty,
              style: const TextStyle(color: MyTheme.font_grey),
            ),
          ],
        ),
      );
    }
  }
}