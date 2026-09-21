import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:active_ecommerce_cms_demo_app/app_config.dart';

class AIZImage {
  // Shimmer placeholder — used while image is downloading
  static Widget _shimmerPlaceholder({double? width, double? height}) {
    return Shimmer.fromColors(
      baseColor: Color(0xFFE0E0E0),
      highlightColor: Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }

  static Widget basicImage(String url,
      {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    return CachedNetworkImage(
      fit: fit,
      width: width,
      height: height,
      imageUrl: AppConfig.getSanitizedUrl(url),
      // Decode image at display size — saves RAM & speeds up rendering
      // Guard against Infinity / NaN / zero (causes toInt crash)
      memCacheWidth: (width != null && width.isFinite && width > 0)
          ? (width * 2).toInt()
          : null,
      memCacheHeight: (height != null && height.isFinite && height > 0)
          ? (height * 2).toInt()
          : null,
      // Shimmer while loading
      progressIndicatorBuilder: (context, url, progress) {
        return _shimmerPlaceholder(width: width, height: height);
      },
      errorWidget: (context, url, error) => Image.asset(
        "assets/placeholder_rectangle.png",
        fit: BoxFit.cover,
      ),
    );
  }

  static Widget radiusImage(String? url, double radius,
      {BoxFit fit = BoxFit.cover, bool isShadow = true}) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: CachedNetworkImageProvider(
                AppConfig.getSanitizedUrl(url ?? ""),
              ),
              fit: fit,
              onError: (obj, e) {
                //  return AssetImage("assets/placeholder_rectangle.png");
              }),
          borderRadius: BorderRadius.circular(radius),
          color: Colors.white,
          boxShadow: isShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0), // shadow direction: bottom right
                  )
                ]
              : []),
    );
  }
}
