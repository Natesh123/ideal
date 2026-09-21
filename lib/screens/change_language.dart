
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/providers/locale_provider.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/coupon_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/language_repository.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  _ChangeLanguageState createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  final ValueNotifier<int> _selected_index = ValueNotifier(0);
  final ScrollController _mainScrollController = ScrollController();
  final _list = [];
  final ValueNotifier<bool> _isInitial = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    fetchList();
  }

  @override
  void dispose() {
    _selected_index.dispose();
    _isInitial.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  fetchList() async {
    var languageListResponse = await LanguageRepository().getLanguageList();
    _list.addAll(languageListResponse.languages!);

    var idx = 0;
    if (_list.isNotEmpty) {
      for (var lang in _list) {
        if (lang.code == app_language.$) {
          _selected_index.value = idx;
        }
        idx++;
      }
    }
    _isInitial.value = false;
  }

  reset() {
    _list.clear();
    _isInitial.value = true;
    _selected_index.value = 0;
  }

  Future<void> _onRefresh() async {
    reset();
    fetchList();
  }

  onPopped(value) {
    reset();
    fetchList();
  }

  onCouponRemove() async {
    var couponRemoveResponse =
    await CouponRepository().getCouponRemoveResponse();

    if (couponRemoveResponse.result == false) {
      ToastComponent.showDialog(couponRemoveResponse.message);
      return;
    }
  }
  onLanguageItemTap(index) async {
    if (index == _selected_index) {
      return;
    }

    final supportedLangCodes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toList();
    String tappedLangCode = _list[index].mobile_app_code;

    if (supportedLangCodes.contains(tappedLangCode)) {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirm_ucf),
            content: Text(
                "Are you Sure to change Language ${_list[index].name}?"),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(
                 'Confirm',
                  style: TextStyle(color: MyTheme.accent_color),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        _selected_index.value = index;

        app_language.$ = _list[_selected_index.value].code;
        app_language.save();
        app_mobile_language.$ = _list[_selected_index.value].mobile_app_code;
        app_mobile_language.save();
        app_language_rtl.$ = _list[_selected_index.value].rtl;
        app_language_rtl.save();

        Provider.of<LocaleProvider>(
          context,
          listen: false,
        ).setLocale(_list[_selected_index.value].mobile_app_code);
        context.go('/');
      }
    } else {
      ToastComponent.showDialog(
          "'${_list[index].name}' is not available right now.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: buildLanguageMethodList(),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
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
        builder: (context) => IconButton(
          padding: EdgeInsets.zero,
          icon: UsefulElements.backButton(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        "${AppLocalizations.of(context)!.change_language_ucf} (${app_language.$}) - (${app_mobile_language.$})",
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

  buildLanguageMethodList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isInitial,
      builder: (context, isInitial, _) {
        if (isInitial && _list.isEmpty) {
          return SingleChildScrollView(
            child: ShimmerHelper().buildListShimmer(
              item_count: 5,
              item_height: 100.0,
            ),
          );
        } else if (_list.isNotEmpty) {
          return SingleChildScrollView(
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return const SizedBox(height: 14);
              },
              itemCount: _list.length,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return buildPaymentMethodItemCard(index);
              },
            ),
          );
        } else if (!isInitial && _list.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_language_is_added,
                style: TextStyle(color: MyTheme.font_grey),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  GestureDetector buildPaymentMethodItemCard(index) {
    return GestureDetector(
      onTap: () {
        onLanguageItemTap(index);
      },
      child: ValueListenableBuilder<int>(
        valueListenable: _selected_index,
        builder: (context, selectedIdx, _) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ).copyWith(
                  border: Border.all(
                    color: selectedIdx == index
                        ? MyTheme.accent_color
                        : MyTheme.light_grey,
                    width: selectedIdx == index ? 1.0 : 0.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: _list[index].image,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "${_list[index].name} - ${_list[index].code} - ${_list[index].mobile_app_code}",
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Color(0xff3E4447),
                                fontSize: 12,
                                height: 1.6,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              app_language_rtl.$!
                  ? Positioned(
                left: 16,
                top: 16,
                child: buildCheckContainer(selectedIdx == index),
              )
                  : Positioned(
                right: 16,
                top: 16,
                child: buildCheckContainer(selectedIdx == index),
              ),
            ],
          );
        },
      ),
    );
  }

  Container buildCheckContainer(bool check) {
    return check
        ? Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: Colors.green,
      ),
      child: const Padding(
        padding: EdgeInsets.all(3),
        child: Icon(Icons.check, color: Colors.white, size: 10),
      ),
    )
        : Container();
  }
}