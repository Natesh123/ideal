import 'dart:io';

import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/main.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/bottom_appbar_index.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/cart_counter.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/cart.dart';
import 'package:active_ecommerce_cms_demo_app/screens/home.dart';
import 'package:active_ecommerce_cms_demo_app/screens/profile.dart';
import 'package:active_ecommerce_cms_demo_app/screens/chat/local_chatbot.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class Main extends StatefulWidget {
  Main({super.key, go_back = true});
  late bool go_back;

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _dialogShowing = ValueNotifier(false);
  var _children = [];
  CartCounter counter = CartCounter();
  BottomAppbarIndex bottomAppbarIndex = BottomAppbarIndex();

  fetchAll() {
    getCartCount();
  }

  void onTapped(int i) {
    fetchAll();

    if (guest_checkout_status.$ && (i == 2)) {
    } else if (!guest_checkout_status.$ && (i == 2) && !is_logged_in.$) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
      return;
    }

    if (i == 3) {
      routes.push("/dashboard");
      return;
    }
    _currentIndex.value = i;
  }

  getCartCount() async {
    Provider.of<CartCounter>(context, listen: false).getCount();
  }

  @override
  void initState() {
    print("Main screen initState. Index: ${_currentIndex.value}, Wholesale user: ${is_wholesale_user.$}");
    _children = [
      Home(),
      CategoryList(slug: "", is_base_category: true),
      Cart(has_bottomnav: true, from_navigation: true, counter: counter),
      Profile(),
    ];
    fetchAll();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.initState();
  }

  Future<bool> willPop() async {
    print(_currentIndex.value);
    if (_currentIndex.value != 0) {
      fetchAll();
      _currentIndex.value = 0;
    } else {
      if (_dialogShowing.value) {
        return Future.value(false);
      }
      _dialogShowing.value = true;

      final shouldPop =
          (await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Directionality(
                textDirection:
                    app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
                child: AlertDialog(
                  content: Text(
                    AppLocalizations.of(context)!.do_you_want_close_the_app,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Platform.isAndroid ? SystemNavigator.pop() : exit(0);
                      },
                      child: Text(AppLocalizations.of(context)!.yes_ucf),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: Text(AppLocalizations.of(context)!.no_ucf),
                    ),
                  ],
                ),
              );
            },
          )) ??
          false;

      _dialogShowing.value = false;

      return shouldPop;
    }
    return Future.value(false);
  }

  Widget _buildChatbotFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: BlinkingChatbotButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LocalChatbotScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    is_wholesale_user.of(context);
    return WillPopScope(
      onWillPop: willPop,
      child: Directionality(
        textDirection:
            app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: ValueListenableBuilder<int>(
          valueListenable: _currentIndex,
          builder: (context, currentIndex, child) {
            return Scaffold(
              extendBody: true,
              body: _children[currentIndex],
              floatingActionButton: _buildChatbotFAB(),
              bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  onTap: onTapped,
                  currentIndex: currentIndex,
                  backgroundColor: Colors.white.withOpacity(0.95),
                  unselectedItemColor: Color.fromRGBO(168, 175, 179, 1),
                  selectedItemColor: MyTheme.accent_color,
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MyTheme.accent_color,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(168, 175, 179, 1),
                    fontSize: 12,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.asset(
                          "assets/home.png",
                          color: currentIndex == 0
                              ? MyTheme.accent_color
                              : Color.fromRGBO(153, 153, 153, 1),
                          height: 16,
                        ),
                      ),
                      label: AppLocalizations.of(context)!.home_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.asset(
                          "assets/categories.png",
                          color: currentIndex == 1
                              ? MyTheme.accent_color
                              : Color.fromRGBO(153, 153, 153, 1),
                          height: 16,
                        ),
                      ),
                      label: AppLocalizations.of(context)!.categories_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: badges.Badge(
                          badgeStyle: badges.BadgeStyle(
                            shape: badges.BadgeShape.circle,
                            badgeColor: MyTheme.accent_color,
                            borderRadius: BorderRadius.circular(10),
                            padding: EdgeInsets.all(5),
                          ),
                          badgeAnimation: badges.BadgeAnimation.slide(
                            toAnimate: false,
                          ),
                          badgeContent: Consumer<CartCounter>(
                            builder: (context, cart, child) {
                              return Text(
                                "${cart.cartCounter}",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white),
                              );
                            },
                          ),
                          child: Image.asset(
                            "assets/cart.png",
                            color: currentIndex == 2
                                ? MyTheme.accent_color
                                : Color.fromRGBO(153, 153, 153, 1),
                            height: 16,
                          ),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.cart_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.asset(
                          "assets/profile.png",
                          color: currentIndex == 3
                              ? MyTheme.accent_color
                              : Color.fromRGBO(153, 153, 153, 1),
                          height: 16,
                        ),
                      ),
                      label: AppLocalizations.of(context)!.profile_ucf,
                    ),
                  ],
                ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class BlinkingChatbotButton extends StatefulWidget {
  final VoidCallback onPressed;

  const BlinkingChatbotButton({super.key, required this.onPressed});

  @override
  State<BlinkingChatbotButton> createState() => _BlinkingChatbotButtonState();
}

class _BlinkingChatbotButtonState extends State<BlinkingChatbotButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerTranslate;
  late Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400), // Cycle length
    )..repeat();

    // Shimmer sweep: slides from left (-80px) to right (150px) in the first 60% of the duration
    _shimmerTranslate = Tween<double>(begin: -80.0, end: 150.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Very gentle organic breathing scale (0.97 to 1.03) over the entire cycle
    _breathScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _breathScale.value,
            child: SizedBox(
              width: 150,
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Red Pill Button with internal Shimmer
                  Positioned(
                    left: 20,
                    right: 0,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xffE8181B), // Solid brand red
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffE8181B).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Stack(
                          children: [
                            // Button Content
                            const Positioned.fill(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center, // Perfect vertical alignment
                                children: [
                                  SizedBox(width: 36), // Space for overflowing avatar
                                  Expanded(
                                    child: Text(
                                      "Ask AI",
                                      style: TextStyle(
                                        fontFamily: "PublicSansSerif",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                ],
                              ),
                            ),
                            // Glossy Shimmer Sweep overlay
                            Positioned(
                              left: _shimmerTranslate.value,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Container(
                                  width: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.4),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Overflowing Avatar on the left
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white, // White background
                        border: Border.all(
                          color: const Color(0xffE8181B),
                          width: 2.5, // Crisp border
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.smart_toy, // Flat red robot mascot
                          color: Color(0xffE8181B),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
