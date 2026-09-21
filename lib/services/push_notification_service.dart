
import 'dart:convert';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_details.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:one_context/one_context.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:active_ecommerce_cms_demo_app/screens/flash_deal/flash_deal_products.dart';
import 'package:active_ecommerce_cms_demo_app/screens/notification/notification_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/seller_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/brand_products.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_products.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:active_ecommerce_cms_demo_app/screens/filter.dart';
import 'package:active_ecommerce_cms_demo_app/screens/flash_deal/flash_deal_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/cart.dart';
import 'package:active_ecommerce_cms_demo_app/screens/coupon/coupons.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/todays_deal_products.dart';
import 'package:active_ecommerce_cms_demo_app/screens/classified_ads/classified_product_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auction/auction_products_details.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // For data-only messages in background, we need to show local notification manually
  if (message.notification == null) {
     PushNotificationService.showNotification(
       title: message.data['title'],
       body: message.data['body'],
       data: message.data
     );
  }
}


class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future initialise() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_stat_v7');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          Map<String, dynamic> data = jsonDecode(response.payload!);
          handleMessageNavigation(data);
        }
      },
    );

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? fcmToken = await _fcm.getToken();
    print("-- FCM Token From Initialise --");
    print(fcmToken);
    if (is_logged_in.$ == true && fcmToken != null) {
      await ProfileRepository().getDeviceTokenUpdateResponse(fcmToken);
    }
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      handleMessageNavigation(initialMessage.data);
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground Message Received: ${message.notification?.title}");
      _showLocalNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App Opened from Background by Notification: ${message.data}");
      handleMessageNavigation(message.data);
    });
  }
  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    String? title = notification?.title ?? message.data['title'];
    String? body = notification?.body ?? message.data['body'];

    if (title != null && body != null) {
      flutterLocalNotificationsPlugin.show(
        notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch >> 10,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_stat_v7',
            color: const Color(0xffE62E04),
            largeIcon: const DrawableResourceAndroidBitmap('ic_large_final'),
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  static void showNotification({String? title, String? body, Map<String, dynamic>? data}) {
    if (title != null && body != null) {
      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch >> 10,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_stat_v7',
            color: const Color(0xffE62E04),
            largeIcon: const DrawableResourceAndroidBitmap('ic_large_final'),
          ),
        ),
        payload: data != null ? jsonEncode(data) : null,
      );
    }
  }
  void handleMessageNavigation(Map<String, dynamic> data) async {
    print("handleMessageNavigation called with data: ${jsonEncode(data)}");
    print("All keys received: ${data.keys.toList()}");
    
    // Add a small delay to ensure OneContext is ready, especially on app launch
    await Future.delayed(const Duration(milliseconds: 500));
    
    String itemType = data['item_type'] ?? '';
    String itemTypeId = data['item_type_id'] ?? '';
    
    print("itemType: $itemType, itemTypeId: $itemTypeId");

    // Handle update without requiring login
    if (itemType == 'update' && data['url'] != null) {
      _checkVersionAndShowUpdate(data['version'], data['url']);
      return;
    }

    // Public routes (no login required)
    if (itemType == 'product' && itemTypeId.isNotEmpty) {
      OneContext().push(MaterialPageRoute(builder: (_) {
        return ProductDetails(slug: itemTypeId);
      }));
      return;
    } else if (itemType == 'flash_deal' && itemTypeId.isNotEmpty) {
      OneContext().push(MaterialPageRoute(builder: (_) {
        return FlashDealProducts(slug: itemTypeId);
      }));
      return;
    } else if (itemType == 'shop' && itemTypeId.isNotEmpty) {
      OneContext().push(MaterialPageRoute(builder: (_) {
        return SellerDetails(slug: itemTypeId);
      }));
      return;
    }

    // Routes requiring login
    if (is_logged_in.$ == false && itemType != 'custom') {
      _showLoginDialog();
      return;
    }

    if (itemType == 'custom' || data['link'] != null || data['url'] != null) {
      String? url = (data['link'] ?? data['url'])?.toString();
      
      // If primary link keys are empty, search all keys for a URL
      if (url == null || url.isEmpty) {
        print("Link/URL keys empty, searching all keys for a URL...");
        for (var entry in data.entries) {
          if (entry.value.toString().startsWith('http')) {
            url = entry.value.toString();
            print("Found URL in key '${entry.key}': $url");
            break;
          }
        }
      }

      if (url != null && url.isNotEmpty) {
        String finalUrl = url;
        if (_handleInternalLink(finalUrl)) {
          return;
        }

        // If not internal, open externally
        canLaunchUrl(Uri.parse(finalUrl)).then((value) {
          if (value) {
            launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
          }
        });
        return;
      }
    }

    // Robust order identification
    bool isOrderRelated = itemType.toLowerCase().contains('order') ||
                          itemType.toLowerCase().contains('delivery') ||
                          itemType == 'order_status' ||
                          itemType == 'order_updated';

    // Fallback for ID keys
    String effectiveId = itemTypeId.isNotEmpty ? itemTypeId : (data['item_id'] ?? data['id'] ?? '').toString();

    if (isOrderRelated && effectiveId.isNotEmpty) {
      print("Order related notification detected. Type: $itemType, Effective ID: $effectiveId");
      try {
        int id = int.parse(effectiveId);
        OneContext().push(MaterialPageRoute(builder: (_) {
          return OrderDetails(
            id: id,
            from_notification: true,
          );
        }));
      } catch (e) {
        print("Error parsing order ID: $e. Content: $effectiveId");
      }
    } else if (itemType == 'notice' || itemType == 'common') {
      OneContext().push(MaterialPageRoute(builder: (_) {
        return const NotificationList();
      }));
    }
  }

  bool _handleInternalLink(String url) {
    try {
      print("Processing internal link: $url");
      Uri uri = Uri.parse(url);
      List<String> segments = uri.pathSegments;
      print("Path segments: $segments");

      if (segments.isEmpty) return false;

      // Handle /product/:slug (robust to prefixes)
      int productIndex = segments.indexOf('product');
      if (productIndex != -1 && segments.length > productIndex + 1) {
        String slug = segments[productIndex + 1];
        OneContext().push(MaterialPageRoute(builder: (_) => ProductDetails(slug: slug)));
        return true;
      }

      // Handle /flash-deal/:slug
      int flashDealIndex = segments.indexOf('flash-deal');
      if (flashDealIndex != -1 && segments.length > flashDealIndex + 1) {
        String slug = segments[flashDealIndex + 1];
        print("Flash deal detected. Slug: $slug");
        OneContext().push(MaterialPageRoute(builder: (_) => FlashDealProducts(slug: slug)));
        return true;
      }

      // Handle /shop/:slug or /seller/:slug
      int shopIndex = segments.indexOf('shop');
      if (shopIndex == -1) shopIndex = segments.indexOf('seller');
      if (shopIndex != -1 && segments.length > shopIndex + 1) {
        String slug = segments[shopIndex + 1];
        OneContext().push(MaterialPageRoute(builder: (_) => SellerDetails(slug: slug)));
        return true;
      }

      // Handle /brand/:slug
      int brandIndex = segments.indexOf('brand');
      if (brandIndex != -1 && segments.length > brandIndex + 1) {
        String slug = segments[brandIndex + 1];
        OneContext().push(MaterialPageRoute(builder: (_) => BrandProducts(slug: slug)));
        return true;
      }

      // Handle /category/:slug
      int categoryIndex = segments.indexOf('category');
      if (categoryIndex != -1 && segments.length > categoryIndex + 1) {
        String slug = segments[categoryIndex + 1];
        OneContext().push(MaterialPageRoute(builder: (_) => CategoryProducts(slug: slug)));
        return true;
      }

      // Handle /purchase_history/details/:id
      int purchaseIndex = segments.indexOf('purchase_history');
      if (purchaseIndex != -1 && segments.length > purchaseIndex + 2 && segments[purchaseIndex + 1] == 'details') {
        int? id = int.tryParse(segments[purchaseIndex + 2]);
        if (id != null) {
          OneContext().push(MaterialPageRoute(builder: (_) => OrderDetails(id: id, from_notification: true)));
          return true;
        }
      }

      // Handle /search?keyword=...
      int searchIndex = segments.indexOf('search');
      if (searchIndex != -1) {
        String keyword = uri.queryParameters['keyword'] ?? "";
        OneContext().push(MaterialPageRoute(builder: (_) => Filter(search_key: keyword)));
        return true;
      }

      // Handle /customer-product/:slug
      int classifiedIndex = segments.indexOf('customer-product');
      if (classifiedIndex != -1 && segments.length > classifiedIndex + 1) {
        String slug = segments[classifiedIndex + 1];
        OneContext().push(MaterialPageRoute(builder: (_) => ClassifiedAdsDetails(slug: slug)));
        return true;
      }

      // Handle /auction-product/:slug
      int auctionIndex = segments.indexOf('auction-product');
      if (auctionIndex != -1 && segments.length > auctionIndex + 1) {
        String slug = segments[auctionIndex + 1];
        OneContext().push(MaterialPageRoute(builder: (_) => AuctionProductsDetails(slug: slug)));
        return true;
      }

      // Handle /cart
      if (segments.contains('cart')) {
        OneContext().push(MaterialPageRoute(builder: (_) => const Cart()));
        return true;
      }

      // Handle /coupons
      if (segments.contains('coupons')) {
        OneContext().push(MaterialPageRoute(builder: (_) => const Coupons()));
        return true;
      }

      // Handle /todays-deal
      if (segments.contains('todays-deal')) {
        OneContext().push(MaterialPageRoute(builder: (_) => const TodaysDealProducts()));
        return true;
      }

      // Handle /flash-deals (List)
      if (segments.contains('flash-deals')) {
        OneContext().push(MaterialPageRoute(builder: (_) => const FlashDealList()));
        return true;
      }

      return false;
    } catch (e) {
      print("Error parsing internal link: $e");
      return false;
    }
  }

  Future<void> _checkVersionAndShowUpdate(String? newVersion, String url) async {
    if (newVersion == null) return;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    if (_isNewerVersion(currentVersion, newVersion)) {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  bool _isNewerVersion(String current, String news) {
    List<String> currentParts = current.split('.');
    List<String> newsParts = news.split('.');

    for (int i = 0; i < newsParts.length; i++) {
      int c = i < currentParts.length ? int.parse(currentParts[i]) : 0;
      int n = int.parse(newsParts[i]);
      if (n > c) return true;
      if (c > n) return false;
    }
    return false;
  }

  void _showLoginDialog() {
    OneContext().showDialog(
      builder: (context) => AlertDialog(
        title: const Text("You are not logged in"),
        content: const Text("Please log in to see the details"),
        actions: <Widget>[
          Btn.basic(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Btn.basic(
            child: const Text('Login'),
            onPressed: () {
              Navigator.of(context).pop();
              OneContext().push(MaterialPageRoute(builder: (_) => const Login()));
            },
          ),
        ],
      ),
    );
  }
}