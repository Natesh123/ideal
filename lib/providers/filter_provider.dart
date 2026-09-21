import 'package:active_ecommerce_cms_demo_app/repositories/brand_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/category_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/product_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/shop_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filter_provider.g.dart';

enum FilterType { product, sellers, brands }

class FilterState {
  final FilterType selectedFilter;
  final String searchKey;
  final String selectedSort;
  final List<int> selectedCategories;
  final List<int> selectedBrands;
  final String minPrice;
  final String maxPrice;
  final bool isProductInitial;
  final bool isBrandInitial;
  final bool isShopInitial;

  FilterState({
    this.selectedFilter = FilterType.product,
    this.searchKey = "",
    this.selectedSort = "",
    this.selectedCategories = const [],
    this.selectedBrands = const [],
    this.minPrice = "",
    this.maxPrice = "",
    this.isProductInitial = true,
    this.isBrandInitial = true,
    this.isShopInitial = true,
  });

  FilterState copyWith({
    FilterType? selectedFilter,
    String? searchKey,
    String? selectedSort,
    List<int>? selectedCategories,
    List<int>? selectedBrands,
    String? minPrice,
    String? maxPrice,
    bool? isProductInitial,
    bool? isBrandInitial,
    bool? isShopInitial,
  }) {
    return FilterState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchKey: searchKey ?? this.searchKey,
      selectedSort: selectedSort ?? this.selectedSort,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isProductInitial: isProductInitial ?? this.isProductInitial,
      isBrandInitial: isBrandInitial ?? this.isBrandInitial,
      isShopInitial: isShopInitial ?? this.isShopInitial,
    );
  }
}

@riverpod
class FilterProvider extends _$FilterProvider {
  @override
  FilterState build() {
    return FilterState();
  }

  void updateSearchKey(String key) {
    state = state.copyWith(searchKey: key);
    refreshData();
  }

  void updateFilterType(FilterType type) {
    state = state.copyWith(selectedFilter: type);
    refreshData();
  }

  void updateSort(String sort) {
    state = state.copyWith(selectedSort: sort);
    refreshData();
  }

  void updatePriceRange(String min, String max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
    refreshData();
  }

  void toggleCategory(int categoryId) {
    final newList = List<int>.from(state.selectedCategories);
    if (newList.contains(categoryId)) {
      newList.remove(categoryId);
    } else {
      newList.add(categoryId);
    }
    state = state.copyWith(selectedCategories: newList);
  }

  void toggleBrand(int brandId) {
    final newList = List<int>.from(state.selectedBrands);
    if (newList.contains(brandId)) {
      newList.remove(brandId);
    } else {
      newList.add(brandId);
    }
    state = state.copyWith(selectedBrands: newList);
  }

  void applyFilters() {
    refreshData();
  }

  void refreshData() {
    // This will trigger the future providers to reload
    // ref.invalidate(filterItemsProvider);
  }
}

@riverpod
Future<List<dynamic>> filterItems(FilterItemsRef ref) async {
  final filterState = ref.watch(filterProviderProvider);
  
  switch (filterState.selectedFilter) {
    case FilterType.product:
      final response = await ProductRepository().getFilteredProducts(
        page: 1,
        name: filterState.searchKey,
        sort_key: filterState.selectedSort,
        brands: filterState.selectedBrands.join(","),
        categories: filterState.selectedCategories.join(","),
        max: filterState.maxPrice,
        min: filterState.minPrice,
      );
      return response.products ?? [];
    case FilterType.brands:
      final response = await BrandRepository().getBrands(
        page: 1,
        name: filterState.searchKey,
      );
      return response.brands ?? [];
    case FilterType.sellers:
      final response = await ShopRepository().getShops(
        page: 1,
        name: filterState.searchKey,
      );
      return response.shops ?? [];
  }
}

@riverpod
Future<List<dynamic>> filterCategories(FilterCategoriesRef ref) async {
  final response = await CategoryRepository().getFilterPageCategories();
  return response.categories ?? [];
}

@riverpod
Future<List<dynamic>> filterBrandsList(FilterBrandsListRef ref) async {
  final response = await BrandRepository().getFilterPageBrands();
  return response.brands ?? [];
}
