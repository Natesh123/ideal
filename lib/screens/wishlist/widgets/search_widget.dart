import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:one_context/one_context.dart';

import '../../../custom/btn.dart';
import '../../../custom/toast_component.dart';
import '../../../custom/useful_elements.dart';
import '../../../helpers/reg_ex_inpur_formatter.dart';
import '../../../helpers/shared_value_helper.dart';
import '../../../helpers/shimmer_helper.dart';
import '../../../my_theme.dart';
import '../../../repositories/brand_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/search_repository.dart';
import '../../../repositories/shop_repository.dart';
import '../../../ui_elements/brand_square_card.dart';
import '../../../ui_elements/product_card.dart';
import '../../../ui_elements/shop_square_card.dart';

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
        'product',
        AppLocalizations.of(OneContext().context!)!.product_ucf,
      ),
      WhichFilter(
        'sellers',
        AppLocalizations.of(OneContext().context!)!.sellers_ucf,
      ),
      WhichFilter(
        'brands',
        AppLocalizations.of(OneContext().context!)!.brands_ucf,
      ),
    ];
  }
}

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key, this.selected_filter = "product"});

  final String selected_filter;

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final _amountValidator = RegExInputFormatter.withRegex(
    '^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$',
  );

  final ScrollController _productScrollController = ScrollController();
  final ScrollController _brandScrollController = ScrollController();
  final ScrollController _shopScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ScrollController? _scrollController;
  final ValueNotifier<WhichFilter?> _selectedFilterNotifier = ValueNotifier(null);
  String? _givenSelectedFilterOptionKey; // may be it can come from another page
  final ValueNotifier<String?> _selectedSortNotifier = ValueNotifier("");

  final List<WhichFilter> _which_filter_list = WhichFilter.getWhichFilterList();
  List<DropdownMenuItem<WhichFilter>>? _dropdownWhichFilterItems;
  final List<dynamic> _selectedCategories = [];
  final List<dynamic> _selectedBrands = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  //--------------------
  final ValueNotifier<List<dynamic>> _filterBrandListNotifier = ValueNotifier([]);
  bool _filteredBrandsCalled = false;
  final ValueNotifier<List<dynamic>> _filterCategoryListNotifier = ValueNotifier([]);
  bool _filteredCategoriesCalled = false;

  final ValueNotifier<List<dynamic>> _searchSuggestionListNotifier = ValueNotifier([]);

  //----------------------------------------
  String? _searchKey = "";

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

  //----------------------------------------

  fetchFilteredBrands() async {
    var filteredBrandResponse = await BrandRepository().getFilterPageBrands();
    _filterBrandListNotifier.value = [
      ..._filterBrandListNotifier.value,
      ...filteredBrandResponse.brands!
    ];
    _filteredBrandsCalled = true;
  }

  fetchFilteredCategories() async {
    var filteredCategoriesResponse =
        await CategoryRepository().getFilterPageCategories();
    _filterCategoryListNotifier.value = [
      ..._filterCategoryListNotifier.value,
      ...filteredCategoriesResponse.categories!
    ];
    _filteredCategoriesCalled = true;
  }

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

    _dropdownWhichFilterItems = buildDropdownWhichFilterItems(
      _which_filter_list,
    );
    _selectedFilter = _dropdownWhichFilterItems![0].value;

    for (int x = 0; x < _dropdownWhichFilterItems!.length; x++) {
      if (_dropdownWhichFilterItems![x].value!.option_key ==
          _givenSelectedFilterOptionKey) {
        _selectedFilter = _dropdownWhichFilterItems![x].value;
      }
    }

    fetchFilteredCategories();
    fetchFilteredBrands();

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
      name: _searchKey,
      sort_key: _selectedSortNotifier.value,
      brands: _selectedBrands.join(",").toString(),
      categories: _selectedCategories.join(",").toString(),
      max: _maxPriceController.text.toString(),
      min: _minPriceController.text.toString(),
    );

    _productListNotifier.value = [
      ..._productListNotifier.value,
      ...productResponse.products!
    ];
    _isProductInitialNotifier.value = false;
    _totalProductDataNotifier.value = productResponse.meta!.total;
    _showProductLoadingContainerNotifier.value = false;
  }

  resetProductList() {
    _productListNotifier.value = [];
    _isProductInitialNotifier.value = true;
    _totalProductDataNotifier.value = 0;
    _productPageNotifier.value = 1;
    _showProductLoadingContainerNotifier.value = false;
  }

  fetchBrandData() async {
    var brandResponse = await BrandRepository().getBrands(
      page: _brandPageNotifier.value,
      name: _searchKey,
    );
    _brandListNotifier.value = [
      ..._brandListNotifier.value,
      ...brandResponse.brands!
    ];
    _isBrandInitialNotifier.value = false;
    _totalBrandDataNotifier.value = brandResponse.meta!.total;
    _showBrandLoadingContainerNotifier.value = false;
  }

  resetBrandList() {
    _brandListNotifier.value = [];
    _isBrandInitialNotifier.value = true;
    _totalBrandDataNotifier.value = 0;
    _brandPageNotifier.value = 1;
    _showBrandLoadingContainerNotifier.value = false;
  }

  fetchShopData() async {
    var shopResponse = await ShopRepository().getShops(
      page: _shopPageNotifier.value,
      name: _searchKey,
    );
    _shopListNotifier.value = [
      ..._shopListNotifier.value,
      ...shopResponse.shops
    ];
    _isShopInitialNotifier.value = false;
    _totalShopDataNotifier.value = shopResponse.meta.total;
    _showShopLoadingContainerNotifier.value = false;
  }

  reset() {
    _searchSuggestionListNotifier.value = [];
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

  List<DropdownMenuItem<WhichFilter>> buildDropdownWhichFilterItems(
    List whichFilterList,
  ) {
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
      builder: (context, showProductLoadingContainer, child) {
        return Container(
          height: showProductLoadingContainer ? 36 : 0,
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: ValueListenableBuilder<int?>(
              valueListenable: _totalProductDataNotifier,
              builder: (context, totalProductData, child) {
                return ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _productListNotifier,
                  builder: (context, productList, child) {
                    return Text(
                      totalProductData == productList.length
                          ? AppLocalizations.of(context)!.no_more_products_ucf
                          : AppLocalizations.of(context)!.loading_more_products_ucf,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildBrandLoadingContainer() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showBrandLoadingContainerNotifier,
      builder: (context, showBrandLoadingContainer, child) {
        return Container(
          height: showBrandLoadingContainer ? 36 : 0,
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: ValueListenableBuilder<int?>(
              valueListenable: _totalBrandDataNotifier,
              builder: (context, totalBrandData, child) {
                return ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _brandListNotifier,
                  builder: (context, brandList, child) {
                    return Text(
                      totalBrandData == brandList.length
                          ? AppLocalizations.of(context)!.no_more_brands_ucf
                          : AppLocalizations.of(context)!.loading_more_brands_ucf,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildShopLoadingContainer() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showShopLoadingContainerNotifier,
      builder: (context, showShopLoadingContainer, child) {
        return Container(
          height: showShopLoadingContainer ? 36 : 0,
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: ValueListenableBuilder<int?>(
              valueListenable: _totalShopDataNotifier,
              builder: (context, totalShopData, child) {
                return ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _shopListNotifier,
                  builder: (context, shopList, child) {
                    return Text(
                      totalShopData == shopList.length
                          ? AppLocalizations.of(context)!.no_more_shops_ucf
                          : AppLocalizations.of(context)!.loading_more_shops_ucf,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  //--------------------

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
            return Stack(
              fit: StackFit.loose,
              children: [
                selectedFilter!.option_key == 'product'
                    ? buildProductList()
                    : (selectedFilter.option_key == 'brands'
                        ? buildBrandList()
                        : buildShopList()),
                Positioned(
                  top: 0.0,
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
                          : buildShopLoadingContainer()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.white.withOpacity(0.95),
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0.0,
      actions: [Container()],
      centerTitle: false,
      flexibleSpace: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
        child: Column(
          children: [buildTopAppbar(context), buildBottomAppBar(context)],
        ),
      ),
    );
  }

  Row buildBottomAppBar(BuildContext context) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            // border: Border.symmetric(
            //     vertical: BorderSide(color: MyTheme.light_grey, width: .5),
            //     horizontal: BorderSide(color: MyTheme.light_grey, width: 1))
          ),
          padding: EdgeInsets.fromLTRB(16, 5, 8, 5),
          height: 36,
          width: MediaQuery.of(context).size.width * .33,
          child: ValueListenableBuilder<WhichFilter?>(
            valueListenable: _selectedFilterNotifier,
            builder: (context, selectedFilter, child) {
              return DropdownButton<WhichFilter>(
                dropdownColor: Colors.white,
                isExpanded: true,
                icon: Padding(
                  padding:
                      app_language_rtl.$!
                          ? const EdgeInsets.only(right: 18.0)
                          : const EdgeInsets.only(left: 18.0),
                  child: Icon(Icons.expand_more, color: Colors.black54),
                ),
                hint: Text(
                  AppLocalizations.of(context)!.products_ucf,
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                style: TextStyle(color: Colors.black, fontSize: 13),
                iconSize: 13,
                underline: SizedBox(),
                value: selectedFilter,
                items: _dropdownWhichFilterItems,
                onChanged: (WhichFilter? selectedFilter) {
                  _selectedFilterNotifier.value = selectedFilter;
                  _onWhichFilterChange();
                },
              );
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            if (_selectedFilterNotifier.value!.option_key == "product") {
              _scaffoldKey.currentState!.openEndDrawer();
            } else {
              ToastComponent.showDialog(
                AppLocalizations.of(
                  context,
                )!.you_can_use_sorting_while_searching_for_products,
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // border: Border.symmetric(
              //     vertical: BorderSide(color: MyTheme.light_grey, width: .5),
              //     horizontal:
              //         BorderSide(color: MyTheme.light_grey, width: 1))
            ),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
              child: SizedBox(
                width: 50,
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, size: 13),
                    SizedBox(width: 2),
                    Text(
                      AppLocalizations.of(context)!.filter_ucf,
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (_selectedFilterNotifier.value!.option_key == "product") {
              showDialog(
                context: context,
                builder:
                    (_) => Directionality(
                      textDirection:
                          app_language_rtl.$!
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                      child: AlertDialog(
                        backgroundColor: Colors.white,
                        contentPadding: EdgeInsets.only(
                          top: 16.0,
                          left: 2.0,
                          right: 2.0,
                          bottom: 2.0,
                        ),
                        content: ValueListenableBuilder<String?>(
                          valueListenable: _selectedSortNotifier,
                          builder: (context, selectedSort, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.sort_products_by_ucf,
                                  ),
                                ),
                                RadioListTile(
                                  dense: true,
                                  value: "",
                                  groupValue: selectedSort,
                                  activeColor: MyTheme.font_grey,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    AppLocalizations.of(context)!.def_ault_ucf,
                                  ),
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
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.price_high_to_low,
                                  ),
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
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.price_low_to_high,
                                  ),
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
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.new_arrival_ucf,
                                  ),
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
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.popularity_ucf,
                                  ),
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
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.top_rated_ucf,
                                  ),
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
                              AppLocalizations.of(context)!.close_all_capital,
                              style: TextStyle(color: MyTheme.medium_grey),
                            ),
                            onPressed: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop();
                            },
                          ),
                        ],
                      ),
                    ),
              );
            } else {
              ToastComponent.showDialog(
                AppLocalizations.of(
                  context,
                )!.you_can_use_filters_while_searching_for_products,
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // border: Border.symmetric(
              //     vertical: BorderSide(color: MyTheme.light_grey, width: .5),
              //     horizontal:
              //         BorderSide(color: MyTheme.light_grey, width: 1))
            ),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
              child: SizedBox(
                width: 50,
                child: Row(
                  children: [
                    Icon(Icons.swap_vert, size: 13),
                    SizedBox(width: 2),
                    Text(
                      AppLocalizations.of(context)!.sort_ucf,
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Row buildTopAppbar(BuildContext context) {
    return Row(
      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        IconButton(
          padding: EdgeInsets.zero,
          icon: UsefulElements.backButton(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * .84,
          child: SizedBox(
            height: 58,
            //color: Colors.amber,
            child: Padding(
              padding:
                  MediaQuery.of(context).viewPadding.top >
                          30 //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                      ? const EdgeInsets.fromLTRB(0, 14, 0, 10)
                      : const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 0.0,
                      ),
  Widget buildTopAppbar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * .75,
          child: TypeAheadField(
            suggestionsCallback: (pattern) async {
              if (pattern.length < 2) {
                return [];
              }
              var suggestions = await SearchRepository()
                  .getSearchSuggestionListResponse(
                    query_key: pattern,
                    type: _selectedFilterNotifier.value!.option_key,
                  );
              _searchSuggestionListNotifier.value = suggestions;
              return suggestions;
            },
            loadingBuilder: (context) {
              return Container(
                height: 50,
                color: Colors.white,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.loading_suggestions,
                    style: TextStyle(color: MyTheme.medium_grey),
                  ),
                ),
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
                    color:
                        suggestion.type != "search"
                            ? MyTheme.accent_color
                            : MyTheme.font_grey,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        suggestion.type != "search"
                            ? MyTheme.font_grey
                            : MyTheme.medium_grey,
                  ),
                ),
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
                 _searchKey = suggestion.query;
                 _onSearchSubmit();
               }
             },
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: false,
                onSubmitted: (txt) {
                  _searchKey = txt;
                  _onSearchSubmit();
                },
                decoration: searchContainer(
                  context,
                  AppLocalizations.of(context)!.search_here_ucf,
                  () {
                    _searchKey = controller.text;
                    _onSearchSubmit();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  buildFilterDrawer() {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        child: Container(
          padding: EdgeInsets.only(top: 50),
          color: Colors.white,
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
                                  hintText:
                                      AppLocalizations.of(context)!.minimum_ucf,
                                  hintStyle: TextStyle(
                                    fontSize: 12.0,
                                    color: MyTheme.textfield_grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 1.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 2.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(4.0),
                                ),
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
                                  hintText:
                                      AppLocalizations.of(context)!.maximum_ucf,
                                  hintStyle: TextStyle(
                                    fontSize: 12.0,
                                    color: MyTheme.textfield_grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 1.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 2.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(4.0),
                                ),
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
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.categories_ucf,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<List<dynamic>>(
                          valueListenable: _filterCategoryListNotifier,
                          builder: (context, filterCategoryList, child) {
                            return filterCategoryList.isEmpty
                                ? SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.no_category_is_available,
                                      style: TextStyle(color: MyTheme.font_grey),
                                    ),
                                  ),
                                )
                                : SingleChildScrollView(
                                  child: buildFilterCategoryList(),
                                );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.brands_ucf,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<List<dynamic>>(
                          valueListenable: _filterBrandListNotifier,
                          builder: (context, filterBrandList, child) {
                            return filterBrandList.isEmpty
                                ? SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.no_brand_is_available,
                                      style: TextStyle(color: MyTheme.font_grey),
                                    ),
                                  ),
                                )
                                : SingleChildScrollView(
                                  child: buildFilterBrandsList(),
                                );
                          },
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        _selectedCategories.clear();
                        _selectedBrands.clear();
                        // Trigger re-render of drawer lists
                        _filterCategoryListNotifier.value = [..._filterCategoryListNotifier.value];
                        _filterBrandListNotifier.value = [..._filterBrandListNotifier.value];
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        'CLEAR',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        var min = _minPriceController.text.toString();
                        var max = _maxPriceController.text.toString();
                        bool apply = true;
                        if (min != "" && max != "") {
                          if (max.compareTo(min) < 0) {
                            ToastComponent.showDialog(
                              AppLocalizations.of(
                                context,
                              )!.filter_screen_min_max_warning,
                            );
                            apply = false;
                          }
                        }

                        if (apply) {
                          _applyProductFilter();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'CLEAR',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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

  Widget buildFilterBrandsList() {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: _filterBrandListNotifier,
      builder: (context, filterBrandList, child) {
        return ListView(
          padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: <Widget>[
            ...filterBrandList.map(
              (brand) => StatefulBuilder(
                builder: (context, setInnerState) {
                  return CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    title: Text(brand.name),
                    value: _selectedBrands.contains(brand.id),
                    onChanged: (bool? value) {
                      if (value!) {
                        _selectedBrands.add(brand.id);
                      } else {
                        _selectedBrands.remove(brand.id);
                      }
                      setInnerState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildFilterCategoryList() {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: _filterCategoryListNotifier,
      builder: (context, filterCategoryList, child) {
        return ListView(
          padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: <Widget>[
            ...filterCategoryList.map(
              (category) => StatefulBuilder(
                builder: (context, setInnerState) {
                  return CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    title: Text(category.name),
                    value: _selectedCategories.contains(category.id),
                    onChanged: (bool? value) {
                      if (value!) {
                        _selectedCategories.clear();
                        _selectedCategories.add(category.id);
                      } else {
                        _selectedCategories.remove(category.id);
                      }
                      // Since we want to update the entire list (for exclusive selection check)
                      // we might need to update the parent or use a more granular state.
                      // For categories, it seems it's exclusive selection in the code logic provided.
                      // Actually, clearing and adding means it's single select.
                      // We need to re-render all tiles in buildFilterCategoryList.
                      _filterCategoryListNotifier.value = [..._filterCategoryListNotifier.value];
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Container buildProductList() {
    return Container(
      child: Column(children: [Expanded(child: buildProductScrollableList())]),
    );
  }

  buildProductScrollableList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isProductInitialNotifier,
      builder: (context, isProductInitial, child) {
        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: _productListNotifier,
          builder: (context, productList, child) {
            if (isProductInitial && productList.isEmpty) {
              return SingleChildScrollView(
                child: ShimmerHelper().buildProductGridShimmer(
                  scontroller: _scrollController,
                ),
              );
            } else if (productList.isNotEmpty) {
              return RefreshIndicator(
                color: Colors.white,
                backgroundColor: MyTheme.accent_color,
                onRefresh: _onProductListRefresh,
                child: SingleChildScrollView(
                  controller: _productScrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).viewPadding.top > 40 ? 135 : 135,
                      ),
                      MasonryGridView.count(
                        itemCount: productList.length,
                        controller: _scrollController,
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        padding: EdgeInsets.only(
                          top: 10,
                          bottom: 10,
                          left: 18,
                          right: 18,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            id: productList[index].id,
                            slug: productList[index].slug,
                            image: productList[index].thumbnail_image,
                            name: productList[index].name,
                            main_price: productList[index].main_price,
                            stroked_price: productList[index].stroked_price,
                            has_discount: productList[index].has_discount,
                            discount: productList[index].discount,
                            is_wholesale: productList[index].isWholesale,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return ValueListenableBuilder<int?>(
                valueListenable: _totalProductDataNotifier,
                builder: (context, totalProductData, child) {
                  if (totalProductData == 0) {
                    return Center(
                      child: Text(AppLocalizations.of(context)!.no_product_is_available),
                    );
                  }
                  return Container();
                },
              );
            }
          },
        );
      },
    );
  }

  Container buildBrandList() {
    return Container(
      child: Column(children: [Expanded(child: buildBrandScrollableList())]),
    );
  }

  buildBrandScrollableList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isBrandInitialNotifier,
      builder: (context, isBrandInitial, child) {
        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: _brandListNotifier,
          builder: (context, brandList, child) {
            if (isBrandInitial && brandList.isEmpty) {
              return SingleChildScrollView(
                child: ShimmerHelper().buildSquareGridShimmer(
                  scontroller: _scrollController,
                ),
              );
            } else if (brandList.isNotEmpty) {
              return RefreshIndicator(
                color: Colors.white,
                backgroundColor: MyTheme.accent_color,
                onRefresh: _onBrandListRefresh,
                child: SingleChildScrollView(
                  controller: _brandScrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).viewPadding.top > 40 ? 126 : 135,
                      ),
                      GridView.builder(
                        itemCount: brandList.length,
                        controller: _scrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1,
                        ),
                        padding: EdgeInsets.only(
                          top: 20,
                          bottom: 10,
                          left: 18,
                          right: 18,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return BrandSquareCard(
                            id: brandList[index].id,
                            slug: brandList[index].slug,
                            image: brandList[index].logo,
                            name: brandList[index].name,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return ValueListenableBuilder<int?>(
                valueListenable: _totalBrandDataNotifier,
                builder: (context, totalBrandData, child) {
                  if (totalBrandData == 0) {
                    return Center(
                      child: Text(AppLocalizations.of(context)!.no_brand_is_available),
                    );
                  }
                  return Container();
                },
              );
            }
          },
        );
      },
    );
  }

  Container buildShopList() {
    return Container(
      child: Column(children: [Expanded(child: buildShopScrollableList())]),
    );
  }

  buildShopScrollableList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isShopInitialNotifier,
      builder: (context, isShopInitial, child) {
        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: _shopListNotifier,
          builder: (context, shopList, child) {
            if (isShopInitial && shopList.isEmpty) {
              return SingleChildScrollView(
                controller: _scrollController,
                child: ShimmerHelper().buildSquareGridShimmer(
                  scontroller: _scrollController,
                ),
              );
            } else if (shopList.isNotEmpty) {
              return RefreshIndicator(
                color: Colors.white,
                backgroundColor: MyTheme.accent_color,
                onRefresh: _onShopListRefresh,
                child: SingleChildScrollView(
                  controller: _shopScrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).viewPadding.top > 40 ? 126 : 135,
                      ),
                      GridView.builder(
                        itemCount: shopList.length,
                        controller: _scrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.7,
                        ),
                        padding: EdgeInsets.only(
                          top: 20,
                          bottom: 10,
                          left: 18,
                          right: 18,
                        ),
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return ShopSquareCard(
                            id: shopList[index].id,
                            shopSlug: shopList[index].slug,
                            image: shopList[index].logo,
                            name: shopList[index].name,
                            stars: double.parse(shopList[index].rating.toString()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return ValueListenableBuilder<int?>(
                valueListenable: _totalShopDataNotifier,
                builder: (context, totalShopData, child) {
                  if (totalShopData == 0) {
                    return Center(
                      child: Text(AppLocalizations.of(context)!.no_shop_is_available),
                    );
                  }
                  return Container();
                },
              );
            }
          },
        );
      },
    );
  }

  InputDecoration searchContainer(
    BuildContext context,
    hintText,
    VoidCallback? onTap,
  ) {
    return InputDecoration(
      filled: true,
      suffixIcon: GestureDetector(
        onTap: onTap,
        child: Icon(Icons.search, color: Colors.grey.shade500, size: 25),
      ),
      fillColor: Color(0xffE4E3E8),
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 12.0, color: MyTheme.grey_153),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.noColor, width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.noColor, width: 1.0),
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      ),
      contentPadding: EdgeInsets.only(left: 8.0, top: 10.0, bottom: 15.0),
    );
  }
}
