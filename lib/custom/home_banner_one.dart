
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../helpers/shimmer_helper.dart';
import '../my_theme.dart';
import '../presenter/home_presenter.dart';
import 'aiz_image.dart';

class HomeBannerOne extends StatelessWidget {
  final HomePresenter? homeData;
  final BuildContext? context;

  const HomeBannerOne({super.key, this.homeData, this.context});

  @override
  Widget build(BuildContext context) {
    if (homeData == null) {
      return SizedBox(
        height: 100,
        child: Center(child: Text('No data available')),
      );
    }

    if (homeData!.isBannerOneInitial && homeData!.bannerOneImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18,
          top: 10,
          bottom: 20,
        ),
        child: ShimmerHelper().buildBasicShimmer(height: 120),
      );
    } else if (homeData!.bannerOneImageList.isNotEmpty) {
      return CarouselSlider(
        options: CarouselOptions(
          height: 166,
          aspectRatio: 1.1,
          viewportFraction: .43,
          initialPage: 0,
          padEnds: false,
          enableInfiniteScroll: true,
          autoPlay: true,
          onPageChanged: (index, reason) {},
        ),
        items: homeData!.bannerOneImageList.map((bannerItem) {
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
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xff000000).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        final String? fullUrl = bannerItem.url;

                        if (fullUrl == null || fullUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No link available')),
                          );
                          return;
                        }

                        try {
                          final Uri uri = Uri.parse(fullUrl);
                          String goPath = uri.path;
                          if (uri.hasQuery) {
                            goPath += "?${uri.query}";
                          }
                          
                          if (goPath.isNotEmpty && goPath != "/") {
                             GoRouter.of(context).push(goPath);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unknown link type')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid link: $e')),
                          );
                        }
                      },
                      child: AIZImage.radiusImage(
                        bannerItem.photo,
                        6,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      );
    } else if (!homeData!.isBannerOneInitial &&
        homeData!.bannerOneImageList.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return Container(height: 100);
    }
  }
}