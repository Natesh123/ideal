import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/reg_ex_inpur_formatter.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/brand_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/category_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/product_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/brand_square_card.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/product_card.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/shop_square_card.dart';

import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:one_context/one_context.dart';

import '../repositories/search_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:active_ecommerce_cms_demo_app/providers/filter_provider.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_products.dart';
import 'package:active_ecommerce_cms_demo_app/screens/brand_products.dart';

class WhichFilter {
  String option_key;
  String name;

  WhichFilter(this.option_key, this.name);

  static List<WhichFilter> getWhichFilterList() {
    return <WhichFilter>[
      WhichFilter(
          'product', AppLocalizations.of(OneContext().context!)!.product_ucf),
      WhichFilter(
          'sellers', AppLocalizations.of(OneContext().context!)!.sellers_ucf),
      WhichFilter(
          'brands', AppLocalizations.of(OneContext().context!)!.brands_ucf),
    ];
  }
}

class Filter extends ConsumerStatefulWidget {
  const Filter({
    super.key,
    this.selected_filter = "product",
    this.search_key = "",
  });

  final String selected_filter;
  final String search_key;

  @override
  ConsumerState<Filter> createState() => _FilterState();
}

class _FilterState extends ConsumerState<Filter> {
  final _amountValidator = RegExInputFormatter.withRegex(
      '^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$');

  final ScrollController _productScrollController = ScrollController();
  final ScrollController _brandScrollController = ScrollController();
  final ScrollController _shopScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ScrollController? _scrollController;
  final ValueNotifier<WhichFilter?> _selectedFilterNotifier = ValueNotifier(null);
  String? _givenSelectedFilterOptionKey;
  final ValueNotifier<String?> _selectedSortNotifier = ValueNotifier("");

  final List<WhichFilter> _which_filter_list = WhichFilter.getWhichFilterList();
  List<DropdownMenuItem<WhichFilter>>? _dropdownWhichFilterItems;
  final List<dynamic> _selectedCategories = [];
  final List<dynamic> _selectedBrands = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final List<dynamic> _filterBrandList = [];
  bool _filteredBrandsCalled = false;
  final List<dynamic> _filterCategoryList = [];
  bool _filteredCategoriesCalled = false;

  final List<dynamic> _searchSuggestionList = [];
  final ValueNotifier<String?> _searchKeyNotifier = ValueNotifier("");

  final ValueNotifier<List<dynamic>> _productListNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isProductInitialNotifier = ValueNotifier(true);
  final ValueNotifier<int> _productPageNotifier = ValueNotifier(1);
  final ValueNotifier<int?> _totalProductDataNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _showProductLoadingContainerNotifier = ValueNotifier(false);

  final ValueNotifier<List<dynamic>> _brandListNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isBrandInitialNotifier = ValueNotifier(true);
  final ValueNotifier<int> _brandPageNotifier = ValueNotifier(1);
  final ValueNotifier<int?> _totalBrandDataNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _showBrandLoadingContainerNotifier = ValueNotifier(false);

  final ValueNotifier<List<dynamic>> _shopListNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isShopInitialNotifier = ValueNotifier(true);
  final ValueNotifier<int> _shopPageNotifier = ValueNotifier(1);
  final ValueNotifier<int?> _totalShopDataNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _showShopLoadingContainerNotifier = ValueNotifier(false);
  // fetchFilteredBrands() async {
  //   var filteredBrandResponse = await BrandRepository().getFilterPageBrands();
  //   _filterBrandList.addAll(filteredBrandResponse.brands!);
  //   _filteredBrandsCalled = true;
  //   setState(() {});
  // }

  // fetchFilteredCategories() async {
  //   var filteredCategoriesResponse =
  //       await CategoryRepository().getFilterPageCategories();
  //   _filterCategoryList.addAll(filteredCategoriesResponse.categories!);
  //   _filteredCategoriesCalled = true;
  //   setState(() {});
  // }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _productScrollController.dispose();
    _brandScrollController.dispose();
    _shopScrollController.dispose();
    super.dispose();
  }

  init() {
    _givenSelectedFilterOptionKey = widget.selected_filter;

    _dropdownWhichFilterItems =
        buildDropdownWhichFilterItems(_which_filter_list);
    _selectedFilterNotifier.value = _dropdownWhichFilterItems![0].value;

    for (int x = 0; x < _dropdownWhichFilterItems!.length; x++) {
      if (_dropdownWhichFilterItems![x].value!.option_key ==
          _givenSelectedFilterOptionKey) {
        _selectedFilterNotifier.value = _dropdownWhichFilterItems![x].value;
      }
    }

    if (widget.search_key.isNotEmpty) {
      _searchController.text = widget.search_key;
      _searchKeyNotifier.value = widget.search_key;
    }

    // fetchFilteredCategories();
    // fetchFilteredBrands();

    if (_selectedFilterNotifier.value!.option_key == "sellers") {
      fetchShopData();
    } else if (_selectedFilterNotifier.value!.option_key == "brands") {
      fetchBrandData();
    } else {
      fetchProductData();
    }

    //set scroll listeners

    _productScrollController.addListener(() {
      if (_productScrollController.position.pixels ==
          _productScrollController.position.maxScrollExtent) {
        _productPageNotifier.value++;
        _showProductLoadingContainerNotifier.value = true;
        fetchProductData();
      }
    });

    _brandScrollController.addListener(() {
      if (_brandScrollController.position.pixels ==
          _brandScrollController.position.maxScrollExtent) {
        _brandPageNotifier.value++;
        _showBrandLoadingContainerNotifier.value = true;
        fetchBrandData();
      }
    });

    _shopScrollController.addListener(() {
      if (_shopScrollController.position.pixels ==
          _shopScrollController.position.maxScrollExtent) {
        _shopPageNotifier.value++;
        _showShopLoadingContainerNotifier.value = true;
        fetchShopData();
      }
    });
  }

  fetchProductData() async {
    var productResponse = await ProductRepository().getFilteredProducts(
        page: _productPageNotifier.value,
        name: _searchKeyNotifier.value,
        sort_key: _selectedSortNotifier.value,
        brands: _selectedBrands.join(","),
        categories: _selectedCategories.join(","),
        max: _maxPriceController.text,
        min: _minPriceController.text);

    if (productResponse.products != null) {
      _productListNotifier.value = [..._productListNotifier.value, ...productResponse.products!];
    }
    _isProductInitialNotifier.value = false;
    _totalProductDataNotifier.value = productResponse.meta?.total;
    _showProductLoadingContainerNotifier.value = false;
  }

  fetchBrandData() async {
    var brandResponse =
        await BrandRepository().getBrands(page: _brandPageNotifier.value, name: _searchKeyNotifier.value);
    _brandListNotifier.value = [..._brandListNotifier.value, ...brandResponse.brands!];
    _isBrandInitialNotifier.value = false;
    _totalBrandDataNotifier.value = brandResponse.meta?.total;
    _showBrandLoadingContainerNotifier.value = false;
  }

  fetchShopData() async {
    var shopResponse =
        await ShopRepository().getShops(page: _shopPageNotifier.value, name: _searchKeyNotifier.value);
    _shopListNotifier.value = [..._shopListNotifier.value, ...shopResponse.shops!];
    _isShopInitialNotifier.value = false;
    _totalShopDataNotifier.value = shopResponse.meta?.total;
    _showShopLoadingContainerNotifier.value = false;
  }

  reset() {
    _searchSuggestionList.clear();
  }

  resetProductList() {
    _productListNotifier.value = [];
    _isProductInitialNotifier.value = true;
    _totalProductDataNotifier.value = 0;
    _productPageNotifier.value = 1;
    _showProductLoadingContainerNotifier.value = false;
  }

  resetBrandList() {
    _brandListNotifier.value = [];
    _isBrandInitialNotifier.value = true;
    _totalBrandDataNotifier.value = 0;
    _brandPageNotifier.value = 1;
    _showBrandLoadingContainerNotifier.value = false;
  }

  resetShopList() {
    _shopListNotifier.value = [];
    _isShopInitialNotifier.value = true;
    _totalShopDataNotifier.value = 0;
    _shopPageNotifier.value = 1;
    _showShopLoadingContainerNotifier.value = false;
  }

  Future<void> _onProductListRefresh() async {
    reset();
    resetProductList();
    fetchProductData();
  }

  Future<void> _onBrandListRefresh() async {
    reset();
    resetBrandList();
    fetchBrandData();
  }

  Future<void> _onShopListRefresh() async {
    reset();
    resetShopList();
    fetchShopData();
  }

  _applyProductFilter() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onSearchSubmit() {
    reset();
    if (_selectedFilterNotifier.value!.option_key == "sellers") {
      resetShopList();
      fetchShopData();
    } else if (_selectedFilterNotifier.value!.option_key == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  _onSortChange() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onWhichFilterChange() {
    // Handled by Riverpod
  }

  List<DropdownMenuItem<WhichFilter>> buildDropdownWhichFilterItems(
      List whichFilterList) {
    List<DropdownMenuItem<WhichFilter>> items = [];
    for (WhichFilter which_filter_item
        in whichFilterList as Iterable<WhichFilter>) {
      items.add(
        DropdownMenuItem(
          value: which_filter_item,
          child: Text(which_filter_item.name),
        ),
      );
    }
    return items;
  }

  Widget buildProductLoadingContainer() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showProductLoadingContainerNotifier,
      builder: (context, showLoading, child) {
        return ValueListenableBuilder<int?>(
          valueListenable: _totalProductDataNotifier,
          builder: (context, totalData, child) {
            return ValueListenableBuilder<List<dynamic>>(
              valueListenable: _productListNotifier,
              builder: (context, productList, child) {
                return Container(
                  height: showLoading ? 36 : 0,
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Text(totalData == productList.length
                        ? AppLocalizations.of(context)!.no_more_products_ucf
                        : AppLocalizations.of(context)!.loading_more_products_ucf),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildBrandLoadingContainer() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showBrandLoadingContainerNotifier,
      builder: (context, showLoading, child) {
        return ValueListenableBuilder<int?>(
          valueListenable: _totalBrandDataNotifier,
          builder: (context, totalData, child) {
            return ValueListenableBuilder<List<dynamic>>(
              valueListenable: _brandListNotifier,
              builder: (context, brandList, child) {
                return Container(
                  height: showLoading ? 36 : 0,
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Text(totalData == brandList.length
                        ? AppLocalizations.of(context)!.no_more_brands_ucf
                        : AppLocalizations.of(context)!.loading_more_brands_ucf),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildShopLoadingContainer() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showShopLoadingContainerNotifier,
      builder: (context, showLoading, child) {
        return ValueListenableBuilder<int?>(
          valueListenable: _totalShopDataNotifier,
          builder: (context, totalData, child) {
            return ValueListenableBuilder<List<dynamic>>(
              valueListenable: _shopListNotifier,
              builder: (context, shopList, child) {
                return Container(
                  height: showLoading ? 36 : 0,
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Text(totalData == shopList.length
                        ? AppLocalizations.of(context)!.no_more_shops_ucf
                        : AppLocalizations.of(context)!.loading_more_shops_ucf),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        endDrawer: buildFilterDrawer(),
        key: _scaffoldKey,
        backgroundColor: MyTheme.mainColor,
        body: ValueListenableBuilder<WhichFilter?>(
          valueListenable: _selectedFilterNotifier,
          builder: (context, selectedFilter, child) {
            return Stack(fit: StackFit.loose, children: [
              selectedFilter!.option_key == 'product'
                  ? buildProductList()
                  : (selectedFilter.option_key == 'brands'
                      ? buildBrandList()
                      : buildShopList()),
              Positioned(
                top: 10.0,
                left: 0.0,
                right: 0.0,
                child: buildAppBar(context),
              ),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: selectedFilter.option_key == 'product'
                      ? buildProductLoadingContainer()
                      : (selectedFilter.option_key == 'brands'
                          ? buildBrandLoadingContainer()
                          : buildShopLoadingContainer()))
            ]);
          },
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
        backgroundColor: MyTheme.mainColor.withOpacity(0.95),
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0.0,
        actions: [
          Container(),
        ],
        centerTitle: false,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 0.0),
          child: Column(
            children: [buildTopAppbar(context), buildBottomAppBar(context)],
          ),
        ));
  }

  Row buildBottomAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                  vertical: BorderSide(color: MyTheme.light_grey, width: .5),
                  horizontal: BorderSide(color: MyTheme.light_grey, width: 1))),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          height: 36,
          width: MediaQuery.of(context).size.width * .33,
          child: ValueListenableBuilder<WhichFilter?>(
            valueListenable: _selectedFilterNotifier,
            builder: (context, selectedFilter, child) {
              return DropdownButton<WhichFilter>(
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(5),
                icon: Padding(
                  padding: app_language_rtl.$!
                      ? const EdgeInsets.only(right: 18.0)
                      : const EdgeInsets.only(left: 18.0),
                  child: Icon(Icons.expand_more, color: Colors.black54),
                ),
                hint: Text(
                  AppLocalizations.of(context)!.products_ucf,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                  ),
                ),
                style: TextStyle(color: Colors.black, fontSize: 13),
                iconSize: 13,
                underline: SizedBox(),
                value: selectedFilter,
                items: _dropdownWhichFilterItems,
                isExpanded: true,
                onChanged: (WhichFilter? selectedFilter) {
                  ref.read(filterProviderProvider.notifier).updateFilterType(
                      selectedFilter!.option_key == "product" 
                          ? FilterType.product 
                          : (selectedFilter.option_key == "brands" ? FilterType.brands : FilterType.sellers)
                  );
                  _selectedFilterNotifier.value = selectedFilter;
                  _onWhichFilterChange();
                },
              );
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            _selectedFilterNotifier.value!.option_key == "product"
                ? _scaffoldKey.currentState!.openEndDrawer()
                : ToastComponent.showDialog(
                    AppLocalizations.of(context)!
                        .you_can_use_sorting_while_searching_for_products,
                  );
          },
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.symmetric(
                    vertical: BorderSide(color: MyTheme.light_grey, width: .5),
                    horizontal:
                        BorderSide(color: MyTheme.light_grey, width: 1))),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
                child: SizedBox(
              width: 50,
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 13,
                  ),
                  SizedBox(width: 2),
                  Text(
                    AppLocalizations.of(context)!.filter_ucf,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )),
          ),
        ),
        GestureDetector(
          onTap: () {
            _selectedFilterNotifier.value!.option_key == "product"
                ? showDialog(
                    context: context,
                    builder: (_) => Directionality(
                          textDirection: app_language_rtl.$!
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: AlertDialog(
                            content: ValueListenableBuilder<String?>(
                              valueListenable: _selectedSortNotifier,
                              builder: (context, selectedSort, child) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24.0),
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .sort_products_by_ucf,
                                        )),
                                    RadioListTile(
                                      dense: true,
                                      value: "",
                                      groupValue: selectedSort,
                                      activeColor: MyTheme.font_grey,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(AppLocalizations.of(context)!
                                          .def_ault_ucf),
                                      onChanged: (dynamic value) {
                                        _selectedSortNotifier.value = value;
                                        _onSortChange();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    RadioListTile(
                                      dense: true,
                                      value: "price_high_to_low",
                                      groupValue: selectedSort,
                                      activeColor: MyTheme.font_grey,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(AppLocalizations.of(context)!
                                          .price_high_to_low),
                                      onChanged: (dynamic value) {
                                        _selectedSortNotifier.value = value;
                                        _onSortChange();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    RadioListTile(
                                      dense: true,
                                      value: "price_low_to_high",
                                      groupValue: selectedSort,
                                      activeColor: MyTheme.font_grey,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(AppLocalizations.of(context)!
                                          .price_low_to_high),
                                      onChanged: (dynamic value) {
                                        _selectedSortNotifier.value = value;
                                        _onSortChange();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    RadioListTile(
                                      dense: true,
                                      value: "new_arrival",
                                      groupValue: selectedSort,
                                      activeColor: MyTheme.font_grey,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(AppLocalizations.of(context)!
                                          .new_arrival_ucf),
                                      onChanged: (dynamic value) {
                                        _selectedSortNotifier.value = value;
                                        _onSortChange();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    RadioListTile(
                                      dense: true,
                                      value: "popularity",
                                      groupValue: selectedSort,
                                      activeColor: MyTheme.font_grey,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(AppLocalizations.of(context)!
                                          .popularity_ucf),
                                      onChanged: (dynamic value) {
                                        _selectedSortNotifier.value = value;
                                        _onSortChange();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    RadioListTile(
                                      dense: true,
                                      value: "top_rated",
                                      groupValue: selectedSort,
                                      activeColor: MyTheme.font_grey,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(AppLocalizations.of(context)!
                                          .top_rated_ucf),
                                      onChanged: (dynamic value) {
                                        _selectedSortNotifier.value = value;
                                        _onSortChange();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                            actions: [
                              Btn.basic(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .close_all_capital,
                                  style: TextStyle(color: MyTheme.medium_grey),
                                ),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                },
                              ),
                            ],
                          ),
                        ))
                : ToastComponent.showDialog(
                    AppLocalizations.of(context)!
                        .you_can_use_filters_while_searching_for_products,
                  );
          },
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.symmetric(
                    vertical: BorderSide(color: MyTheme.light_grey, width: .5),
                    horizontal:
                        BorderSide(color: MyTheme.light_grey, width: 1))),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
                child: SizedBox(
              width: 50,
              child: Row(
                children: [
                  Icon(
                    Icons.swap_vert,
                    size: 13,
                  ),
                  SizedBox(width: 2),
                  Text(
                    AppLocalizations.of(context)!.sort_ucf,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )),
          ),
        )
      ],
    );
  }

  Row buildTopAppbar(BuildContext context) {
    return Row(

        children: <Widget>[
          IconButton(
            padding: EdgeInsets.zero,
            icon: UsefulElements.backButton(context),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * .85,
              height: 70,
              child: Container(
                child: Padding(
                    padding: MediaQuery.of(context).viewPadding.top >
                            30
                        ? const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 0.0)
                        : const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 0.0),
                    child: TypeAheadField(
                      suggestionsCallback: (pattern) async {
                        var suggestions = await SearchRepository()
                            .getSearchSuggestionListResponse(
                                query_key: pattern,
                                type: _selectedFilterNotifier.value!.option_key);

                        return suggestions;
                      },
                      loadingBuilder: (context) {
                        return Container(
                          height: 40,
                          color: Colors.white,
                          child: Center(
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .loading_suggestions,
                                  style:
                                      TextStyle(color: MyTheme.medium_grey))),
                        );
                      },
                      itemBuilder: (context, dynamic suggestion) {
                        var subtitle =
                            "${AppLocalizations.of(context)!.searched_for_all_lower} ${suggestion.count} ${AppLocalizations.of(context)!.times_all_lower}";
                        if (suggestion.type != "search") {
                          subtitle =
                              "${suggestion.type_string} ${AppLocalizations.of(context)!.found_all_lower}";
                        }
                        return ListTile(
                          tileColor: Colors.white,
                          dense: true,
                          title: Text(
                            suggestion.query,
                            style: TextStyle(
                                color: suggestion.type != "search"
                                    ? MyTheme.accent_color
                                    : MyTheme.font_grey),
                          ),
                          subtitle: Text(subtitle,
                              style: TextStyle(
                                  color: suggestion.type != "search"
                                      ? MyTheme.font_grey
                                      : MyTheme.medium_grey)),
                        );
                      },
                      onSelected: (dynamic suggestion) {
                        if (suggestion.type == "product") {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return ProductDetails(
                              slug: "ID:${suggestion.id}:${suggestion.query}",
                            );
                          }));
                        } else if (suggestion.type == "category") {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return CategoryProducts(
                              slug: suggestion.id.toString(),
                            );
                          }));
                        } else if (suggestion.type == "brand") {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return BrandProducts(
                              slug: suggestion.id.toString(),
                            );
                          }));
                        } else {
                          _searchController.text = suggestion.query;
                          _searchKeyNotifier.value = suggestion.query;
                          _onSearchSubmit();
                        }
                      },
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          obscureText: false,
                          decoration: InputDecoration(
                              filled: true,
                              fillColor: MyTheme.white,
                              suffixIcon: Icon(Icons.search,
                                  color: MyTheme.medium_grey),
                              hintText:
                                  AppLocalizations.of(context)!.search_here_ucf,
                              hintStyle: TextStyle(
                                  fontSize: 12.0,
                                  color: MyTheme.textfield_grey),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: MyTheme.noColor, width: 0.5),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: MyTheme.noColor, width: 1.0),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              contentPadding: EdgeInsets.only(
                                  left: 8.0, top: 5.0, bottom: 5.0)),
                        );
                      },
                    )),
              ),
            ),
          ),
        ]);
  }

  buildFilterDrawer() {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.only(top: 50),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.price_range_ucf,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .minimum_ucf,
                                    hintStyle: TextStyle(
                                        fontSize: 12.0,
                                        color: MyTheme.textfield_grey),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.textfield_grey,
                                          width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.textfield_grey,
                                          width: 2.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(4.0)),
                              ),
                            ),
                          ),
                          Text(" - "),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .maximum_ucf,
                                    hintStyle: TextStyle(
                                        fontSize: 12.0,
                                        color: MyTheme.textfield_grey),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.textfield_grey,
                                          width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.textfield_grey,
                                          width: 2.0),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4.0),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(4.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!.categories_ucf,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final categoriesAsync = ref.watch(filterCategoriesProvider);
                          return categoriesAsync.when(
                            data: (categories) => buildFilterCategoryList(categories),
                            loading: () => Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Text('Error: $err'),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!.brands_ucf,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final brandsAsync = ref.watch(filterBrandsListProvider);
                          return brandsAsync.when(
                            data: (brands) => buildFilterBrandsList(brands),
                            loading: () => Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Text('Error: $err'),
                          );
                        },
                      ),
                    ]),
                  )
                ]),
              ),
              SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        _selectedCategories.clear();
                        _selectedBrands.clear();
                      },
                      child: Text(
                        AppLocalizations.of(context)!.clear_all_capital,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () {
                        var min = _minPriceController.text.toString();
                        var max = _maxPriceController.text.toString();
                        bool apply = true;
                        if (min != "" && max != "") {
                          if (max.compareTo(min) < 0) {
                            ToastComponent.showDialog(
                              AppLocalizations.of(context)!
                                  .filter_screen_min_max_warning,
                            );
                            apply = false;
                          }
                        }

                        if (apply) {
                          ref.read(filterProviderProvider.notifier).updatePriceRange(min, max);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)!.apply_all_capital,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView buildFilterBrandsList(List brands) {
    final selectedBrands = ref.watch(filterProviderProvider).selectedBrands;
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ...brands
            .map(
              (brand) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(brand.name),
                value: selectedBrands.contains(brand.id),
                onChanged: (bool? value) {
                  ref.read(filterProviderProvider.notifier).toggleBrand(brand.id);
                },
              ),
            )
            
      ],
    );
  }

  ListView buildFilterCategoryList(List categories) {
    final selectedCategories = ref.watch(filterProviderProvider).selectedCategories;
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ...categories
            .map(
              (category) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(category.name),
                value: selectedCategories.contains(category.id),
                onChanged: (bool? value) {
                  ref.read(filterProviderProvider.notifier).toggleCategory(category.id);
                },
              ),
            )
            
      ],
    );
  }

  Container buildProductList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildProductScrollableList(),
          )
        ],
      ),
    );
  }

  buildProductScrollableList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isProductInitialNotifier,
      builder: (context, isInitial, child) {
        if (isInitial) {
          return SingleChildScrollView(
              child: ShimmerHelper()
                  .buildProductGridShimmer(scontroller: _scrollController));
        }

        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: _productListNotifier,
          builder: (context, items, child) {
            if (items.isEmpty) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.no_product_is_available));
            }
            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: MyTheme.accent_color,
              onRefresh: _onProductListRefresh,
              child: SingleChildScrollView(
                controller: _productScrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  children: [
                    SizedBox(
                        height:
                            MediaQuery.of(context).viewPadding.top > 40 ? 150 : 135),
                    GridView.builder(
                      itemCount: items.length,
                      controller: _scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.58,
                      ),
                      padding:
                          const EdgeInsets.only(top: 10, bottom: 10, left: 18, right: 18),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          id: items[index].id,
                          slug: items[index].slug,
                          image: items[index].thumbnail_image,
                          name: items[index].name,
                          main_price: items[index].main_price,
                          stroked_price: items[index].stroked_price,
                          has_discount: items[index].has_discount,
                          discount: items[index].discount,
                          is_wholesale: items[index].isWholesale,
                        );
                      },
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Container buildBrandList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildBrandScrollableList(),
          )
        ],
      ),
    );
  }

  buildBrandScrollableList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isBrandInitialNotifier,
      builder: (context, isInitial, child) {
        if (isInitial) {
          return SingleChildScrollView(
              child: ShimmerHelper()
                  .buildSquareGridShimmer(scontroller: _scrollController));
        }

        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: _brandListNotifier,
          builder: (context, items, child) {
            if (items.isEmpty) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.no_brand_is_available));
            }
            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: MyTheme.accent_color,
              onRefresh: _onBrandListRefresh,
              child: SingleChildScrollView(
                controller: _brandScrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  children: [
                    SizedBox(
                        height:
                            MediaQuery.of(context).viewPadding.top > 40 ? 140 : 135),
                    GridView.builder(
                      itemCount: items.length,
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1),
                      padding:
                          EdgeInsets.only(top: 20, bottom: 10, left: 18, right: 18),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return BrandSquareCard(
                          id: items[index].id,
                          slug: items[index].slug,
                          image: items[index].logo,
                          name: items[index].name,
                        );
                      },
                    )
                   ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Container buildShopList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildShopScrollableList(),
          )
        ],
      ),
    );
  }

  buildShopScrollableList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isShopInitialNotifier,
      builder: (context, isInitial, child) {
        if (isInitial) {
          return SingleChildScrollView(
              controller: _scrollController,
              child: ShimmerHelper()
                  .buildSquareGridShimmer(scontroller: _scrollController));
        }

        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: _shopListNotifier,
          builder: (context, items, child) {
            if (items.isEmpty) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.no_shop_is_available));
            }
            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: MyTheme.accent_color,
              onRefresh: _onShopListRefresh,
              child: SingleChildScrollView(
                controller: _shopScrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  children: [
                    SizedBox(
                        height:
                            MediaQuery.of(context).viewPadding.top > 40 ? 140 : 135),
                    GridView.builder(
                      itemCount: items.length,
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.7),
                      padding:
                          EdgeInsets.only(top: 20, bottom: 10, left: 18, right: 18),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return ShopSquareCard(
                          id: items[index].id,
                          shopSlug: items[index].slug,
                          image: items[index].logo,
                          name: items[index].name,
                          stars: double.parse(items[index].rating.toString()),
                        );
                      },
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
