import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';

class NotificationPopup extends StatefulWidget {
  final Function onCloseMenu;
  final List<NotificationItem> notifications;

  const NotificationPopup({
    Key? key,
    required this.onCloseMenu,
    required this.notifications,
  }) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.w,
      constraints: BoxConstraints(
        maxHeight: 500.h,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        await NotificationService().markAllNotificationsAsRead();
                      },
                      child: Text(
                        'Mark all as read',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20.sp,
                      ),
                      onPressed: () => widget.onCloseMenu(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.white24,
            height: 1,
          ),
          
          // Notifications list
          widget.notifications.isEmpty
              ? _buildEmptyState()
              : Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white12,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final notification = widget.notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 48.sp,
            color: Colors.white24,
          ),
          SizedBox(height: 16.h),
          Text(
            'No notifications yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'ll see notifications here when there are updates',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return InkWell(
      onTap: () async {
        // Mark as read when clicked
        if (!notification.isRead) {
          await NotificationService().markNotificationAsRead(notification.id);
        }
        
        // Handle navigation or other actions based on notification type
        if (notification.relatedId != null) {
          // Navigate to related item (e.g., order details)
          print('Navigate to item with ID: ${notification.relatedId}');
          
          // Example navigation to order details
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => ViewOrderScreen(orderId: notification.relatedId!),
          //   ),
          // );
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        color: notification.isRead
            ? Colors.transparent
            : Colors.white.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 105, 65, 198).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getNotificationIcon(notification.title),
                  color: const Color.fromARGB(255, 105, 65, 198),
                  size: 20.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 105, 65, 198),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.message,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(notification.timestamp),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.sp,
                      color: Colors.white54,
                    ),
                  ),
                  if (notification.relatedId != null && 
                      (notification.title.contains('Accepted') || 
                       notification.title.contains('Rejected')))
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to order details
                              print('Navigate to order: ${notification.relatedId}');
                              // Implement navigation to order details
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'View Order',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains('Order Created')) {
      return Icons.shopping_cart_outlined;
    } else if (title.contains('Accepted')) {
      return Icons.check_circle_outline;
    } else if (title.contains('Rejected')) {
      return Icons.cancel_outlined;
    } else if (title.contains('Status')) {
      return Icons.local_shipping_outlined;
    } else {
      return Icons.notifications_outlined;
    }
  }
}