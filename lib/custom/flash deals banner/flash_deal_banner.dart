import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/aiz_image.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/home_presenter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class FlashDealBanner extends StatelessWidget {
  final HomePresenter? homeData;
  final BuildContext? context;

  const FlashDealBanner({super.key, this.homeData, this.context});

  @override
  Widget build(BuildContext context) {
    if (homeData == null) {
      return SizedBox(
        height: 100,
        child: Center(child: Text('No data available')),
      );
    }
    if (homeData!.isFlashDealInitial &&
        homeData!.flashDealBannerImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18,
          top: 10,
          bottom: 20,
        ),
        child: ShimmerHelper().buildBasicShimmer(height: 120),
      );
    }
    else if (homeData!.flashDealBannerImageList.isNotEmpty) {
      return CarouselSlider(
        options: CarouselOptions(
          height: 237,
          aspectRatio: 1,
          viewportFraction: .60,
          initialPage: 0,
          padEnds: false,
          enableInfiniteScroll: true,
          autoPlay: true,
          onPageChanged: (index, reason) {
          },
        ),
        items:
            homeData!.flashDealBannerImageList.map((i) {
              return Builder(
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 0,
                      top: 0,
                      bottom: 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(
                              0xff000000,
                            ).withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        child: InkWell(
                          onTap: () {

                            var url =
                                i.url?.split(AppConfig.DOMAIN_PATH).last;
                            if (url != null && url.isNotEmpty) {
                              GoRouter.of(context).go(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Invalid URL')),
                              );
                            }
                          },
                          child: AIZImage.radiusImage(i.photo, 6),

                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      );
    }
    // When images are not found and loading is complete
    else if (!homeData!.isFlashDealInitial &&
        homeData!.flashDealBannerImageList.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }

    else {
      return Container(height: 100);
    }
  }
}
