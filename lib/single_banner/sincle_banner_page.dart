
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'photo_provider.dart';
import 'package:go_router/go_router.dart';

class PhotoWidget extends StatefulWidget {
  const PhotoWidget({super.key});

  @override
  _PhotoWidgetState createState() => _PhotoWidgetState();
}

class _PhotoWidgetState extends State<PhotoWidget> {
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _hasErrorNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() async {
    try {
      await Provider.of<PhotoProvider>(context, listen: false).fetchPhotos();
    } catch (e) {
      _hasErrorNotifier.value = true;
    } finally {
      _isLoadingNotifier.value = false;
    }
  }



  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return ShimmerHelper().buildBasicShimmer(height: 50);
        }

        return ValueListenableBuilder<bool>(
          valueListenable: _hasErrorNotifier,
          builder: (context, hasError, child) {
            if (hasError) {
              return Center(child: Text('Error loading photos'));
            }

            return Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                if (photoProvider.singleBanner.isEmpty) {
                  return Center(child: Text('No photos available.'));
                }

                final photoData = photoProvider.singleBanner[0];
                return GestureDetector(
                  onTap: () {
                    try {
                      final Uri uri = Uri.parse(photoData.url);
                      String goPath = uri.path;
                      if (uri.hasQuery) {
                        goPath += "?${uri.query}";
                      }

                      if (goPath.isNotEmpty && goPath != "/") {
                        context.push(goPath);
                      } else {
                        print('Empty or root URL path: ${photoData.url}');
                      }
                    } catch (e) {
                      print('Navigation error: $e');
                    }
                  },
                  child: Image.network(photoData.photo),
                );
              },
            );
          },
        );
      },
    );
  }
}
