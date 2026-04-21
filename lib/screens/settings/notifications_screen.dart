import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/screens/settings/notification_details_screen.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/skeletons/notifications_skeleton.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${l10n.translate('minutes_short_ago')}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}${l10n.translate('hours_short_ago')}';
    } else if (diff.inDays == 1) {
      return l10n.translate('yesterday');
    } else {
      return '${diff.inDays}${l10n.translate('days_short_ago')}';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'kegel':
        return Icons.fitness_center;
      case 'ai_chat':
        return Icons.chat_bubble_rounded;
      case 'game':
        return Icons.sports_esports;
      case 'subscription':
        return Icons.card_membership;
      case 'profile':
        return Icons.person_outline;
      default:
        return Icons.notifications_active;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'kegel':
        return Colors.pink;
      case 'ai_chat':
        return AppColors.brandPurple;
      case 'game':
        return Colors.orange;
      case 'subscription':
        return Colors.green;
      case 'profile':
        return Colors.blue;
      default:
        return Colors.amber;
    }
  }

  Future<void> _deleteNotification(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(docId)
          .delete();
    }
  }

  Future<void> _confirmDeleteNotification(String docId) async {
    final l10n = AppLocalizations.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.adaptSize),
          ),
          title: Text(
            l10n.translate('delete_notification'),
            style: TextStyle(fontSize: 20.fSize, fontWeight: FontWeight.bold),
          ),
          content: Text(
            l10n.translate('are_you_sure_you_want_to_delete_this_notification'),
            style: TextStyle(fontSize: 16.fSize, color: Colors.grey.shade700),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16.fSize,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                l10n.translate('delete'),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteNotification(docId);
    }
  }

  Future<void> _markAsRead(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: uid == null
                ? Center(
                    child: Text(
                      l10n.translate('please_login_to_see_notifications'),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(uid)
                        .collection('notifications')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const NotificationsScreenSkeleton();
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                l10n.translate('no_notifications_yet'),
                                style: TextStyle(
                                  fontSize: 16.fSize,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 24.h,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildNotificationItem(doc.id, data);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: const BoxDecoration(
        color: AppColors.brandPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.adaptSize,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.notifications,
            style: TextStyle(
              fontSize: 32.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String docId, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'system';
    final isRead = data['isRead'] as bool? ?? false;
    final timestamp = data['timestamp'] as Timestamp?;

    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    return GestureDetector(
      onTap: () {
        if (!isRead) _markAsRead(docId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDetailsScreen(
              notification: data,
              icon: icon,
              color: color,
              time: _formatTime(timestamp),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.adaptSize),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.adaptSize),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.adaptSize),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.only(right: 8.w),
                          decoration: const BoxDecoration(
                            color: AppColors.brandPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                      GestureDetector(
                        onTap: () => _confirmDeleteNotification(docId),
                        child: Container(
                          padding: EdgeInsets.all(4.adaptSize),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red.withOpacity(0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8.adaptSize),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16.adaptSize,
                            color: Colors.red.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13.fSize,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
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
}
