import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/notification_repository.dart';
import 'package:flutter/material.dart';

import '../../custom/loading.dart';
import '../../custom/toast_component.dart';
import '../../helpers/shimmer_helper.dart';
import '../../my_theme.dart';
import 'widgets/notification_card.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final ValueNotifier<List<dynamic>> _notificationListNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isFetchingNotifier = ValueNotifier(true);
  List<String> notificationIds = [];
  final ValueNotifier<bool> _isAllSelectedNotifier = ValueNotifier(false);

  fetch() async {
    var notificationResponse =
        await NotificationRepository().getAllNotification();
    _notificationListNotifier.value = [
      ..._notificationListNotifier.value,
      ...(notificationResponse.data as Iterable)
    ];
    _isFetchingNotifier.value = false;
  }

  cleanAll() {
    _isFetchingNotifier.value = true;
    notificationIds = [];
    _notificationListNotifier.value = [];
    _isAllSelectedNotifier.value = false;
  }

  resetAll() {
    cleanAll();
    fetch();
  }

  @override
  void initState() {
    fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyTheme.white,
        iconTheme: IconThemeData(color: MyTheme.dark_grey),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LangText(context).local.notification_ucf,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MyTheme.dark_font_grey),
            ),
            PopupMenuButton<int>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Text(LangText(context).local.delete_selection),
                ),
              ],
              onSelected: (value) async {
                if (value == 1) {
                  // print('delete on selection');
                  // if empty list then return
                  if (notificationIds.isEmpty) {
                    ToastComponent.showDialog(
                      LangText(context).local.nothing_selected,
                    );
                    return;
                  }
                  // show loading and delete selected notification
                  Loading.show(context);
                  var notificationResponse = await NotificationRepository()
                      .notificationBulkDelete(notificationIds);
                  Loading.close();
                  if (notificationResponse.result) {
                    ToastComponent.showDialog(
                      notificationResponse.message,
                    );
                  }
                  // reset all list
                  if (notificationResponse.result) {
                    resetAll();
                  }
                }
              },
            )
          ],
        ),
      ),
      body: SafeArea(
          child: ValueListenableBuilder<bool>(
        valueListenable: _isFetchingNotifier,
        builder: (context, isFetching, child) {
          return isFetching == false
              ? buildShowNotificationSection()
              : ShimmerHelper().buildListShimmer(
                  item_count: 10,
                  item_height: 60.0,
                );
        },
      )),
    );
  }

  Widget buildShowNotificationSection() {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: _notificationListNotifier,
      builder: (context, notificationList, child) {
        return Container(
            padding: EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                notificationList.isNotEmpty
                    ? SizedBox(
                        height: 50,
                        width: DeviceInfo(context).width,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isAllSelectedNotifier,
                          builder: (context, isAllSelected, child) {
                            return CheckboxListTile(
                              title: Text(LangText(context).local.select_all),
                              value: isAllSelected,
                              onChanged: (bool? value) {
                                _isAllSelectedNotifier.value = value!;
                                var updatedList = List<dynamic>.from(notificationList);
                                notificationIds = [];
                                for (var notification in updatedList) {
                                  notification.isChecked = _isAllSelectedNotifier.value;
                                  if (_isAllSelectedNotifier.value) {
                                    notificationIds.add(notification.id);
                                  }
                                }
                                _notificationListNotifier.value = updatedList;
                              },
                            );
                          },
                        ),
                      )
                    : SizedBox.shrink(),
                notificationList.isNotEmpty
                    ? Flexible(
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: notificationList.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(
                            height: 10,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return NotificationListCard(
                              id: notificationList[index].id!,
                              type: notificationList[index].type!,
                              status: notificationList[index].data!.status,
                              orderId: notificationList[index].data!.orderId,
                              orderCode: notificationList[index].data!.orderCode,
                              notificationText:
                                  notificationList[index].notificationText,
                              link: notificationList[index].data!.link,
                              dateTime: notificationList[index].date,
                              image: notificationList[index].image,
                              // for all checked
                              isChecked: notificationList[index].isChecked,
                              onSelect: (String id, bool isChecked) {
                                var updatedList = List<dynamic>.from(notificationList);
                                updatedList[index].isChecked = isChecked;
                                _notificationListNotifier.value = updatedList;
                                
                                if (isChecked) {
                                  notificationIds.add(id);
                                } else {
                                  notificationIds.remove(id);
                                }
                                print(notificationIds);
                              },
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                        LangText(context).local.no_notification_ucf,
                      )),
              ],
            ));
      },
    );
  }
}
