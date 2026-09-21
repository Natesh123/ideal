
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/flash%20deals%20banner/flash_deal_banner.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/home_presenter.dart';
import 'package:active_ecommerce_cms_demo_app/screens/filter.dart';
import 'package:active_ecommerce_cms_demo_app/screens/flash_deal/flash_deal_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/todays_deal_products.dart';

import 'package:active_ecommerce_cms_demo_app/single_banner/sincle_banner_page.dart';
import 'package:flutter/material.dart';
import '../custom/feature_categories_widget.dart';
import '../custom/featured_product_horizontal_list_widget.dart';
import '../custom/home_all_products_2.dart';
import '../custom/home_banner_one.dart';
import '../custom/home_carousel_slider.dart';
import '../custom/home_search_box.dart';
import '../custom/pirated_widget.dart';
import 'wholesales_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presenter/home_presenter.dart';

class Home extends ConsumerStatefulWidget {
  const Home({
    super.key,
    this.title,
    this.show_back_button = false,
    this.go_back = true,
  });

  final String? title;
  final bool show_back_button;
  final bool go_back;

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> with TickerProviderStateMixin {
  dynamic _homePresenter;

  @override
  void initState() {
    super.initState();
    _homePresenter = ref.read(homePresenterProviderProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homePresenter.onRefresh();
      precacheImage(const AssetImage("assets/todays_deal.png"), context);
      precacheImage(const AssetImage("assets/flash_deal.png"), context);
      precacheImage(const AssetImage("assets/brands.png"), context);

    });
    _homePresenter.mainScrollListener();
    _homePresenter.initPiratedAnimation(this);
  }

  @override
  void dispose() {
    _homePresenter?.pirated_logo_controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homePresenterProviderProvider);
    is_wholesale_user.of(context);
    print("Wholesale status in Home: ${is_wholesale_user.$}");
    // Wholesale users see only wholesale products
    if (is_wholesale_user.$ == true) {
      return WillPopScope(
        onWillPop: () async => widget.go_back,
        child: Directionality(
          textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
          child: const WholesalesScreen(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => widget.go_back,
      child: Directionality(
        textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Scaffold(
            appBar: const _HomeAppBar(),
            backgroundColor: Colors.white,

            body: Stack(
              children: [
                RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: homeData.onRefresh,
                  displacement: 0,
                  child: CustomScrollView(
                    controller: homeData.mainScrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: <Widget>[
                      _buildHeaderSection(context, homeData),
                      ListenableBuilder(
                        listenable: homeData,
                        builder: (context, child) => _buildFeaturedCategoriesSection(context, homeData),
                      ),
                      /*ListenableBuilder(
                        listenable: homeData,
                        builder: (context, child) {
                          return homeData.isFlashDeal
                              ? _buildFlashDealSection(context, homeData)
                              : const SliverToBoxAdapter(child: SizedBox.shrink());
                        },
                      ),*/
                      const SliverList(
                        delegate: SliverChildListDelegate.fixed([PhotoWidget()]),
                      ),
                      ListenableBuilder(
                        listenable: homeData,
                        builder: (context, child) => _buildFeaturedProductsSection(context, homeData),
                      ),
                      ListenableBuilder(
                        listenable: homeData,
                        builder: (context, child) => _buildAllProductsSection(context, homeData),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ListenableBuilder(
                    listenable: homeData,
                    builder: (context, child) => _buildProductLoadingContainer(context, homeData),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverList _buildHeaderSection(BuildContext context, HomePresenter homeData) {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (AppConfig.purchase_code == "") PiratedWidget(homeData: homeData),
        const SizedBox(height: 2),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: homeData,
          builder: (context, child) => HomeCarouselSlider(homeData: homeData, context: context),
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: homeData,
          builder: (context, child) => _HomeMenu(homeData: homeData),
        ),
        const SizedBox(height: 16),

        ListenableBuilder(
          listenable: homeData,
          builder: (context, child) => HomeBannerOne(context: context, homeData: homeData),
        ),
      ]),
    );
  }

  SliverToBoxAdapter _buildFeaturedCategoriesSection(BuildContext context, HomePresenter homeData) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 10.0, 18.0, 0.0),
            child: Text(
              AppLocalizations.of(context)!.featured_categories_ucf,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            height: 175,
            child: FeaturedCategoriesWidget(homeData: homeData),
          ),
        ],
      ),
    );
  }

  SliverList _buildFlashDealSection(BuildContext context, HomePresenter homeData) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
          child: Text(
            AppLocalizations.of(context)!.flash_deals_ucf,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        FlashDealBanner(context: context, homeData: homeData),
      ]),
    );
  }

  SliverList _buildFeaturedProductsSection(BuildContext context, HomePresenter homeData) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Container(
          height: 305,
          color: const Color(0xffF2F1F6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 0, 0),
                child: Text(
                  AppLocalizations.of(context)!.featured_products_ucf,
                  style: const TextStyle(
                    color: Color(0xff000000),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                child: FeaturedProductHorizontalListWidget(homeData: homeData),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  SliverList _buildAllProductsSection(BuildContext context, HomePresenter homeData) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Container(
          color: const Color(0xffF2F1F6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 0.0, 20.0, 0.0),
                child: Text(
                  AppLocalizations.of(context)!.all_products_ucf,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
             HomeAllProducts2( homeData: homeData),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildProductLoadingContainer(BuildContext context, HomePresenter homeData) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: homeData.showAllLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          homeData.totalAllProductData == homeData.allProductList.length
              ? AppLocalizations.of(context)!.no_more_products_ucf
              : AppLocalizations.of(context)!.loading_more_products_ucf,
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      elevation: 0,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Image.asset(
              "assets/app_logo.png",
              height: 35,
              width: 35,
            ),
          ),
          Expanded(
            child: Container(
              height: 35,
              child: TextField(
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return Filter(search_key: value);
                    }));
                  }
                },
                decoration: InputDecoration(
                  hintText: AppConfig.search_bar_text,
                  hintStyle: const TextStyle(fontSize: 12.0, color: Color(0xff7B7980)),
                  filled: true,
                  fillColor: const Color(0xfff3f3f3),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/search.png',
                      color: const Color(0xff7B7980),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
class _HomeMenu extends StatelessWidget {
  final HomePresenter homeData;

  const _HomeMenu({required this.homeData});

  @override
  Widget build(BuildContext context) {
    if (!homeData.isFlashDeal && !homeData.isTodayDeal) {
      return SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ShimmerHelper().buildHorizontalGridShimmerWithAxisCount(
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            item_count: 4,
            mainAxisExtent: 160.0,
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> menuItems = _getMenuItems(context);

    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        scrollDirection: Axis.horizontal,
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final Color containerColor = _getContainerColor(index);

          final Widget container = Container(
            margin: const EdgeInsets.only(right: 12),
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: containerColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  item['image'],
                  color: item['textColor'],
                  height: 20,
                  width: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  item['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: item['textColor'],
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );

          return GestureDetector(
            onTap: item['onTap'],
            child: (index == 0 && homeData.isTodayDeal) ? PulsingContainer(child: container) : container,
          );
        },
      ),
    );
  }

  Color _getContainerColor(int index) {
    if (index == 0 && homeData.isTodayDeal) {
      return const Color(0xff000000);
    } else if (index == 1 || (index == 0 && !homeData.isTodayDeal)) {
      return const Color(0xffFF5500);
    } else {
      return const Color(0xffE9EAEB);
    }
  }

  List<Map<String, dynamic>> _getMenuItems(BuildContext context) {
    return [
      if (homeData.isTodayDeal)
        {
          "title": AppLocalizations.of(context)!.todays_deal_ucf,
          "image": "assets/todays_deal.png",
          "onTap": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodaysDealProducts())),
          "textColor": Colors.white,
        },
      /*if (homeData.isFlashDeal)
        {
          "title": AppLocalizations.of(context)!.flash_deal_ucf,
          "image": "assets/flash_deal.png",
          "onTap": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashDealList())),
          "textColor": Colors.white,
        },*/
      {
        "title": AppLocalizations.of(context)!.brands_ucf,
        "image": "assets/brands.png",
        "onTap": () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Filter(selected_filter: "brands"))),
        "textColor": Colors.white,
      },

    ];
  }
}

class PulsingContainer extends StatefulWidget {
  final Widget child;
  const PulsingContainer({super.key, required this.child});

  @override
  State<PulsingContainer> createState() => _PulsingContainerState();
}

class _PulsingContainerState extends State<PulsingContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    // Scale between 95% and 105% of original size
    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}