
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/select_address_provider.dart';
import 'package:active_ecommerce_cms_demo_app/screens/address.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectAddress extends StatefulWidget {
  final int? owner_id;
  const SelectAddress({Key? key, this.owner_id}) : super(key: key);

  @override
  State<SelectAddress> createState() => _SelectAddressState();
}

class _SelectAddressState extends State<SelectAddress> {
  double mWidth = 0;
  double mHeight = 0;

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidth = MediaQuery.of(context).size.width;
    return ChangeNotifierProvider(
      create: (_) => SelectAddressProvider()..init(context),
      child: Consumer<SelectAddressProvider>(
          builder: (context, selectAddressProvider, _) {
            return Directionality(
              textDirection:
              app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  leading: UsefulElements.backButton(context),
                  backgroundColor: MyTheme.white,
                  title: buildAppbarTitle(context),
                ),
                backgroundColor: Colors.white,
                bottomNavigationBar:
                buildBottomAppBar(context, selectAddressProvider),
                body: RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: () => selectAddressProvider.onRefresh(context),
                  displacement: 0,
                  child: Container(
                    child: CustomScrollView(
                      controller: selectAddressProvider.mainScrollController,
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        SliverList(
                            delegate: SliverChildListDelegate([
                              Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: buildShippingInfoList(
                                      selectAddressProvider, context)),
                              buildAddOrEditAddress(context, selectAddressProvider),
                              const SizedBox(
                                height: 100,
                              )
                            ]))
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  Widget buildAddOrEditAddress(BuildContext context, provider) {
    return Container(
      height: 40,
      child: Center(
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Address(
                from_shipping_info: true,
              );
            })).then((value) {
              provider.onPopped(value, context);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              LangText(context)
                  .local
                  .to_add_or_edit_addresses_go_to_address_page,
              style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  color: MyTheme.accent_color),
            ),
          ),
        ),
      ),
    );
  }

  buildShippingInfoList(selectAddressProvider, BuildContext context) {
    if (is_logged_in.$ == false) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
                LangText(context).local.you_need_to_log_in,
                style: TextStyle(color: MyTheme.font_grey),
              )));
    } else if (!selectAddressProvider.faceData &&
        selectAddressProvider.shippingAddressList.isEmpty) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildListShimmer(item_count: 5, item_height: 100.0));
    } else if (selectAddressProvider.shippingAddressList.isNotEmpty) {
      return SingleChildScrollView(
        child: ListView.builder(
          itemCount: selectAddressProvider.shippingAddressList.length,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: buildShippingInfoItemCard(
                  index, selectAddressProvider, context),
            );
          },
        ),
      );
    } else if (selectAddressProvider.faceData &&
        selectAddressProvider.shippingAddressList.isEmpty) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
                LangText(context).local.no_address_is_added,
                style: TextStyle(color: MyTheme.font_grey),
              )));
    }
  }

  GestureDetector buildShippingInfoItemCard(
      index, selectAddressProvider, BuildContext context) {
    var address = selectAddressProvider.shippingAddressList[index];
    bool isAddressValid = address.valid ?? false;

    return GestureDetector(
      onTap: () {
        selectAddressProvider.shippingInfoCardFnc(index, context);
        if (!isAddressValid) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const AlertDialog(
                content: Text(
                  "This address is not available.",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              );
            },
          );
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      child: Opacity(
        opacity: isAddressValid ? 1.0 : 0.6,
        child: Card(
          shape: RoundedRectangleBorder(
            side: selectAddressProvider.selectedShippingAddress == address.id
                ? BorderSide(color: MyTheme.accent_color, width: 2.0)
                : BorderSide(color: MyTheme.light_grey, width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildShippingInfoItemAddress(index, selectAddressProvider),
                buildShippingInfoItemCity(index, selectAddressProvider),
                buildShippingInfoItemArea(index, selectAddressProvider),
                buildShippingInfoItemState(index, selectAddressProvider),
                buildShippingInfoItemCountry(index, selectAddressProvider),
                buildShippingInfoItemPostalCode(index, selectAddressProvider),
                buildShippingInfoItemPhone(index, selectAddressProvider),
                if (!isAddressValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'We no longer deliver in this area.',
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding buildShippingInfoItemPhone(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            child: Text(
              LangText(context).local.phone_ucf,
              style: TextStyle(
                color: MyTheme.grey_153,
              ),
            ),
          ),
          Container(
            width: 200,
            child: Text(
              selectAddressProvider.shippingAddressList[index].phone ?? "",
              maxLines: 2,
              style: TextStyle(
                  color: MyTheme.dark_grey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemPostalCode(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            child: Text(
              LangText(context).local.postal_code,
              style: TextStyle(
                color: MyTheme.grey_153,
              ),
            ),
          ),
          Container(
            width: 200,
            child: Text(
              selectAddressProvider.shippingAddressList[index].postal_code ??
                  "",
              maxLines: 2,
              style: TextStyle(
                  color: MyTheme.dark_grey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemCountry(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            child: Text(
              LangText(context).local.country_ucf,
              style: TextStyle(
                color: MyTheme.grey_153,
              ),
            ),
          ),
          Container(
            width: 200,
            child: Text(
              selectAddressProvider.shippingAddressList[index].country_name ??
                  "",
              maxLines: 2,
              style: TextStyle(
                  color: MyTheme.dark_grey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemState(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            child: Text(
              LangText(context).local.state_ucf,
              style: TextStyle(
                color: MyTheme.grey_153,
              ),
            ),
          ),
          Container(
            width: 200,
            child: Text(
              selectAddressProvider.shippingAddressList[index].state_name ?? "",
              maxLines: 2,
              style: TextStyle(
                  color: MyTheme.dark_grey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildShippingInfoItemArea(index, selectAddressProvider) {
    if (selectAddressProvider.shippingAddressList[index].area_name == null ||
        selectAddressProvider.shippingAddressList[index].area_name!.isEmpty) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            child: const Text(
              "Area",
              style: TextStyle(
                color: MyTheme.grey_153,
              ),
            ),
          ),
          Container(
            width: 200,
            child: Text(
              selectAddressProvider.shippingAddressList[index].area_name ?? "",
              maxLines: 2,
              style: TextStyle(
                  color: MyTheme.dark_grey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemCity(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            child: Text(
              LangText(context).local.city_ucf,
              style: TextStyle(
                color: MyTheme.grey_153,
              ),
            ),
          ),
          Container(
            width: 200,
            child: Text(
              selectAddressProvider.shippingAddressList[index].city_name ?? "",
              maxLines: 2,
              style: TextStyle(
                  color: MyTheme.dark_grey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildShippingInfoItemAddress(index, selectAddressProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            child: Text(
              LangText(context).local.address_ucf,
              style: TextStyle(
                color: MyTheme.grey_153,
              ),
            ),
          ),
          Container(
            width: 175,
            child: Text(
              selectAddressProvider.shippingAddressList[index].address ?? "",
              maxLines: 2,
              style: TextStyle(
                  color: MyTheme.dark_grey, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          buildShippingOptionsCheckContainer(
              selectAddressProvider.selectedShippingAddress ==
                  selectAddressProvider.shippingAddressList[index].id)
        ],
      ),
    );
  }

  Container buildShippingOptionsCheckContainer(bool check) {
    return check
        ? Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0), color: Colors.green),
      child: const Padding(
        padding: EdgeInsets.all(3),
        child: Icon(Icons.check, color: Colors.white, size: 10),
      ),
    )
        : Container();
  }

  BottomAppBar buildBottomAppBar(
      BuildContext context, SelectAddressProvider provider) {
    bool isButtonEnabled = false;
    if (provider.selectedShippingAddress != null &&
        provider.selectedShippingAddress != 0) {
      try {
        var selectedAddress = provider.shippingAddressList
            .firstWhere((address) => address.id == provider.selectedShippingAddress);
        isButtonEnabled = selectedAddress.valid ?? false;
      } catch (e) {
        isButtonEnabled = false;
      }
    }

    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0.0,
      child: Container(
        height: 50,
        child: Btn.minWidthFixHeight(
          minWidth: MediaQuery.of(context).size.width,
          height: 50,
          color: isButtonEnabled ? MyTheme.accent_color : MyTheme.grey_153,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
          child: Text(
            LangText(context).local.continue_to_delivery_info_ucf,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: isButtonEnabled
              ? () {
            provider.onPressProceed(context);
          }
              : null,
        ),
      ),
    );
  }

  Container buildAppbarTitle(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      child: Text(
        LangText(context).local.shipping_info,
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}