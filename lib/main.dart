import 'dart:async';

import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/middlewares/auth_middleware.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/screens/filter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:shared_value/shared_value.dart';
import 'package:store_box/store_box.dart';

import 'app_config.dart';
import 'custom/aiz_route.dart';
import 'helpers/main_helpers.dart';
import 'helpers/shared_value_helper.dart';
import 'lang_config.dart';
import 'my_theme.dart';
import 'other_config.dart';
import 'presenter/cart_counter.dart';
import 'presenter/cart_provider.dart';
import 'presenter/currency_presenter.dart';
import 'presenter/home_presenter.dart';
import 'presenter/select_address_provider.dart';
import 'presenter/unRead_notification_counter.dart';
import 'providers/blog_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auction/auction_bidded_products.dart';
import 'screens/auction/auction_products.dart';
import 'screens/auction/auction_products_details.dart';
import 'screens/auction/auction_purchase_history.dart';
import 'screens/auth/registration.dart';
import 'screens/brand_products.dart';
import 'screens/category_list_n_product/category_list.dart';
import 'screens/category_list_n_product/category_products.dart';
import 'screens/checkout/cart.dart';
import 'screens/classified_ads/classified_ads.dart';
import 'screens/classified_ads/classified_product_details.dart';
import 'screens/classified_ads/classified_provider.dart';
import 'screens/classified_ads/my_classified_ads.dart';
import 'screens/coupon/coupons.dart';
import 'screens/flash_deal/flash_deal_list.dart';
import 'screens/flash_deal/flash_deal_products.dart';
import 'screens/followed_sellers.dart';
import 'screens/index.dart';
import 'screens/orders/order_details.dart';
import 'screens/orders/order_list.dart';
import 'screens/package/packages.dart';
import 'screens/product/product_details/product_details.dart';
import 'screens/product/todays_deal_products.dart';
import 'screens/profile.dart';
import 'screens/seller_details.dart';
import 'services/push_notification_service.dart';
import 'single_banner/photo_provider.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        print("Firebase init error: $e");
      }
    }
    try {
      await StoreBox.init();
    } catch (e) {
      print("StoreBox init error: $e");
    }
    if (!kIsWeb) {
      try {
        await FlutterDownloader.initialize(
          debug: true,
          ignoreSsl: true,
        );
      } catch (e) {
        print("FlutterDownloader init error: $e");
      }
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Use transparent system bars – actual edge-to-edge enforcement
        // is handled by enableEdgeToEdge() in MainActivity.kt
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(ProviderScope(child: SharedValue.wrapApp(const MyApp())));
  }, (error, stack) {
    print("----------- FATAL FLUTTER ERROR -----------");
    print(error);
    print(stack);
    print("-------------------------------------------");
  });
}

var routes = GoRouter(
  overridePlatformDefaultLocation: false,
  navigatorKey: OneContext().key,
  initialLocation: "/",
  routes: [

    GoRoute(
      path: "/product/:slug",
      pageBuilder: (BuildContext context, GoRouterState state) =>
          MaterialPage(
            child: ProductDetails(slug: getParameter(state, "slug")),
          ),
    ),
    GoRoute(
      path: "/search",
      pageBuilder: (BuildContext context, GoRouterState state) =>
          MaterialPage(
            child: Filter(search_key: state.uri.queryParameters["keyword"] ?? ""),
          ),
    ),
    GoRoute(
      path: '/',
      name: "Home",
      pageBuilder: (BuildContext context, GoRouterState state) =>
          MaterialPage(child: Index()),
      routes: [
        GoRoute(
          path: "customer_products",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: MyClassifiedAds()),
        ),
        GoRoute(
          path: "customer-products",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: ClassifiedAds()),
        ),
        GoRoute(
          path: "customer-product/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: ClassifiedAdsDetails(slug: getParameter(state, "slug")),
          ),
        ),

        GoRoute(
          path: "customer-packages",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: UpdatePackage()),
        ),
        GoRoute(
          path: "auction_product_bids",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: AuthMiddleware(AuctionBiddedProducts()).next(),
          ),
        ),
        GoRoute(
          path: "users/login",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: Login()),
        ),
        GoRoute(
          path: "users/registration",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: Registration()),
        ),
        GoRoute(
          path: "dashboard",
          name: "Profile",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              AIZRoute.rightTransition(Profile()),
        ),
        GoRoute(
          path: "auction-products",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: AuctionProducts()),
        ),
        GoRoute(
          path: "auction-product/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: AuctionProductsDetails(
              slug: getParameter(state, "slug"),
            ),
          ),
        ),
        GoRoute(
          path: "auction/purchase_history",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: AuthMiddleware(AuctionPurchaseHistory()).next(),
          ),
        ),
        GoRoute(
          path: "brand/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (BrandProducts(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "brands",
          name: "Brands",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: Filter(selected_filter: "brands")),
        ),
        GoRoute(
          path: "cart",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: AuthMiddleware(Cart()).next()),
        ),
        GoRoute(
          path: "categories",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (CategoryList(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "category/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (CategoryProducts(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "flash-deals",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (FlashDealList())),
        ),
        GoRoute(
          path: "flash-deal/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (FlashDealProducts(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "followed-seller",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (FollowedSellers())),
        ),
        GoRoute(
          path: "purchase_history",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (OrderList())),
        ),
        GoRoute(
          path: "purchase_history/details/:id",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (OrderDetails(id: int.parse(getParameter(state, "id")))),
          ),
        ),
        GoRoute(
          path: "sellers",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (Filter(selected_filter: "sellers"))),
        ),
        GoRoute(
          path: "shop/:slug",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(
            child: (SellerDetails(slug: getParameter(state, "slug"))),
          ),
        ),
        GoRoute(
          path: "todays-deal",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (TodaysDealProducts())),
        ),
        GoRoute(
          path: "coupons",
          pageBuilder: (BuildContext context, GoRouterState state) =>
              MaterialPage(child: (Coupons())),
        ),
      ],
    ),
  ],
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {

    super.initState();
    Future.microtask(() async {
      if (OtherConfig.USE_PUSH_NOTIFICATION) {
        PushNotificationService().initialise();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => LocaleProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => CartCounter()),
        // legacy_provider.ChangeNotifierProvider(create: (_) => CartProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => SelectAddressProvider()),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => UnReadNotificationCounter(),
        ),
        legacy_provider.ChangeNotifierProvider(create: (_) => CurrencyPresenter()),
        // legacy_provider.ChangeNotifierProvider(create: (_) => HomePresenter()),
        legacy_provider.ChangeNotifierProvider(create: (_) => BlogProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => PhotoProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => MyClassifiedProvider()),
      ],
      child: legacy_provider.Consumer<LocaleProvider>(
        builder: (context, provider, snapshot) {
          return MaterialApp.router(
            routerConfig: routes,
            title: AppConfig.app_name,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: MyTheme.white,
              scaffoldBackgroundColor: MyTheme.white,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: "PublicSansSerif",
              textTheme: MyTheme.textTheme1,
              fontFamilyFallback: ['NotoSans'],
              scrollbarTheme: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all<bool>(false),
              ),
            ),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            locale: provider.locale,
            supportedLocales: LangConfig().supportedLocales(),
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (AppLocalizations.delegate.isSupported(deviceLocale!)) {
                return deviceLocale;
              }
              return const Locale('en');
            },
          );
        },
      ),
    );
  }
}
