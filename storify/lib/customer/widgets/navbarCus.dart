import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/utilis/notification_service.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/customer/widgets/CustomerNotificationPopup.dart';

class CustomerNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomerNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  State<CustomerNavigationBar> createState() => _CustomerNavigationBarState();
}

class _CustomerNavigationBarState extends State<CustomerNavigationBar> {
  bool _showNotifications = false;
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() {
    // Register for notifications updates
    NotificationService()
        .registerNotificationsListChangedCallback(_onNotificationsChanged);

    // Get initial unread count
    _updateUnreadCount();
  }

  void _onNotificationsChanged(List<NotificationItem> notifications) {
    setState(() {
      _notifications = notifications;
      _unreadCount = notifications.where((n) => !n.isRead).length;
    });
  }

  Future<void> _updateUnreadCount() async {
    final count = await NotificationService().getUnreadNotificationsCount();
    setState(() {
      _unreadCount = count;
    });
  }

  @override
  void dispose() {
    // Unregister from notifications updates
    NotificationService()
        .unregisterNotificationsListChangedCallback(_onNotificationsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Navigation bar
        Container(
          height: 64.h,
          color: const Color.fromARGB(255, 36, 50, 69),
          child: Row(
            children: [
              // Logo
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: const Color.fromARGB(255, 105, 65, 198),
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Storify',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation items
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavItem(0, 'Home', Icons.home_outlined),
                    _buildNavItem(1, 'Shop', Icons.shopping_bag_outlined),
                    _buildNavItem(2, 'Orders', Icons.shopping_cart_outlined),
                    _buildNavItem(3, 'Favorites', Icons.favorite_border),
                  ],
                ),
              ),

              // Right side items
              Row(
                children: [
                  // Search
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Colors.white70,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      // Show search
                    },
                  ),

                  // Notifications
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: _showNotifications
                              ? Colors.white
                              : Colors.white70,
                          size: 24.sp,
                        ),
                        onPressed: () {
                          setState(() {
                            _showNotifications = !_showNotifications;
                          });
                        },
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 105, 65, 198),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Profile
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          backgroundColor:
                              const Color.fromARGB(255, 105, 65, 198)
                                  .withOpacity(0.2),
                          child: Text(
                            'C',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color.fromARGB(255, 105, 65, 198),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Customer',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 16.sp,
                          ),
                          onPressed: () {
                            // Show profile menu
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notification popup
        if (_showNotifications)
          Positioned(
            top: 64.h,
            right: 16.w,
            child: CustomerNotificationPopup(
              notifications: _notifications,
              onCloseMenu: () {
                setState(() {
                  _showNotifications = false;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = widget.selectedIndex == index;

    return InkWell(
      onTap: () => widget.onItemSelected(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? const Color.fromARGB(255, 105, 65, 198)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
