
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:flutter/material.dart';
import '../custom/aiz_image.dart';

class MiniProductCard extends StatefulWidget {
  int? id;
  String slug;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;
  bool? is_wholesale;
  var discount;
  MiniProductCard({
    super.key,
    this.id,
    required this.slug,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount,
    this.is_wholesale = false,
    this.discount,
  });

  @override
  _MiniProductCardState createState() => _MiniProductCardState();
}

class _MiniProductCardState extends State<MiniProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            slug: widget.slug,
          );
        }));
      },
      child: SizedBox(
        width: 140,

        child: Stack(children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AIZImage.basicImage(
                            widget.image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ))),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 12, 8, 6),
                  child: Text(
                    widget.name!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        color: MyTheme.font_grey_Light,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text(
                    SystemConfig.systemCurrency != null
                        ? widget.main_price!.replaceAll(
                            SystemConfig.systemCurrency!.code!,
                            SystemConfig.systemCurrency!.symbol!)
                        : widget.main_price!,
                    maxLines: 1,
                    style: TextStyle(
                        color: Color(0xff000000),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
        ]),
      ),
    );
  }
}
