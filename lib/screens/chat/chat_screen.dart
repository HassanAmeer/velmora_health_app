import 'package:velmora/widgets/premium_feature_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/services/chat_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:velmora/widgets/skeletons/chat_skeleton.dart';
import 'package:velmora/widgets/app_loading_widgets.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const ChatScreen({super.key, this.onBackToHome});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  late Stream<QuerySnapshot> _chatStream;
  final ValueNotifier<bool> _isSendingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showDisclaimerNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isAtBottomNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _chatStream = _chatService.getChatMessages();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // If we are within 100 pixels of the bottom, consider it "at bottom"
      final bool isBottom =
          _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 100;
      if (_isAtBottomNotifier.value != isBottom) {
        _isAtBottomNotifier.value = isBottom;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _isSendingNotifier.dispose();
    _showDisclaimerNotifier.dispose();
    _isAtBottomNotifier.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSendingNotifier.value) return;

    _isSendingNotifier.value = true;

    final String localeName = AppLocalizations.of(context).locale.languageCode;
    debugPrint(' 🌐 ChatScreen sending message: localeName=$localeName');

    try {
      await _chatService.sendMessage(message, languageCode: localeName);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('failed_to_send_message')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isSendingNotifier.value = false;
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('failed_to_delete_message')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearChat() async {
    final l10n = AppLocalizations.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('clear_chat') ?? 'Clear Chat'),
        content: Text(
          l10n.translate('clear_chat_confirm') ??
              'Are you sure you want to clear your chat history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.translate('delete') ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.clearChatHistory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.translate('error')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumFeatureGate(
      featureName: 'AI Chat',
      onBackToHome: widget.onBackToHome,
      child: _buildChatContent(context),
    );
  }

  Widget _buildChatContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _scrollToBottom();
                }

                Widget? stateWidget;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  stateWidget = const ChatScreenSkeleton();
                } else if (snapshot.hasError) {
                  stateWidget = Center(
                    child: Text(
                      '${l10n.translate('error_loading_messages')}: ${snapshot.error}',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  stateWidget = Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.adaptSize),
                      child: Text(
                        l10n.aiGreeting,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16.fSize,
                        ),
                      ),
                    ),
                  );
                }

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 160.h,
                      pinned: true,
                      backgroundColor: AppColors.brandPurple,
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (widget.onBackToHome != null) {
                            widget.onBackToHome!();
                            return;
                          }
                          Navigator.pop(context);
                        },
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.white,
                          ),
                          tooltip: l10n.translate('clear_chat') ?? 'Clear Chat',
                          onPressed: _clearChat,
                        ),
                      ],
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        expandedTitleScale: 1.0,
                        titlePadding: EdgeInsets.zero,
                        title: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCollapsed =
                                constraints.maxHeight <=
                                kToolbarHeight +
                                    MediaQuery.of(context).padding.top +
                                    10;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.only(
                                left: isCollapsed ? 0 : 24.w,
                                right: isCollapsed ? 0 : 24.w,
                                bottom: isCollapsed ? 16.h : 24.h,
                              ),
                              alignment: isCollapsed
                                  ? Alignment.bottomCenter
                                  : Alignment.bottomLeft,
                              child: isCollapsed
                                  ? Text(
                                      l10n.chat,
                                      style: TextStyle(
                                        fontSize: 18.fSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              color: Colors.white,
                                              size: 28.adaptSize,
                                            ),
                                            SizedBox(width: 12.w),
                                            Text(
                                              l10n.chat,
                                              style: TextStyle(
                                                fontSize: 32.fSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          l10n.aiCompanion,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontSize: 14.fSize,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                        background: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.brandPurple,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (stateWidget != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: stateWidget,
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final messages = snapshot.data!.docs;
                            final messageData =
                                messages[index].data() as Map<String, dynamic>;
                            final isUser = messageData['isUser'] ?? false;
                            final message = messageData['message'] ?? '';
                            final messageId = messages[index].id;

                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: isUser
                                  ? _buildUserMessage(message, messageId)
                                  : _buildAIMessage(message, messageId),
                            );
                          }, childCount: snapshot.data!.docs.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildChatFooter(),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showDisclaimerNotifier,
        builder: (context, showDisclaimer, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: _isAtBottomNotifier,
            builder: (context, isAtBottom, child) {
              return Padding(
                padding: EdgeInsets.only(bottom: showDisclaimer ? 120.h : 50.h),
                child: FloatingActionButton.small(
                  onPressed: () {
                    if (isAtBottom) {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _scrollToBottom();
                    }
                  },
                  backgroundColor: AppColors.brandPurple.withOpacity(0.8),
                  elevation: 4,
                  child: Icon(
                    isAtBottom ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 20.adaptSize,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAIMessage(String text, String messageId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Icon Avatar
        Container(
          padding: EdgeInsets.all(8.adaptSize),
          decoration: const BoxDecoration(
            color: AppColors.brandPurpleLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 20.adaptSize,
          ),
        ),
        SizedBox(width: 12.w),
        // Message Bubble
        Flexible(
          child: GestureDetector(
            onTapDown: (details) {
              final offset = details.globalPosition;
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  offset.dx,
                  offset.dy,
                  MediaQuery.of(context).size.width - offset.dx,
                  MediaQuery.of(context).size.height - offset.dy,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.adaptSize),
                ),
                elevation: 8,
                items: [
                  PopupMenuItem(
                    onTap: () => _deleteMessage(messageId),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8.w),
                        Text(
                          AppLocalizations.of(context).translate('delete') ??
                              'Delete',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            child: Container(
              padding: EdgeInsets.all(16.adaptSize),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20.adaptSize),
                  bottomLeft: Radius.circular(20.adaptSize),
                  bottomRight: Radius.circular(20.adaptSize),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15.fSize,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(String text, String messageId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Message Bubble
        Flexible(
          child: GestureDetector(
            onTapDown: (details) {
              final offset = details.globalPosition;
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  offset.dx,
                  offset.dy,
                  MediaQuery.of(context).size.width - offset.dx,
                  MediaQuery.of(context).size.height - offset.dy,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.adaptSize),
                ),
                elevation: 8,
                items: [
                  PopupMenuItem(
                    onTap: () => _deleteMessage(messageId),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8.w),
                        Text(
                          AppLocalizations.of(context).translate('delete') ??
                              'Delete',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            child: Container(
              padding: EdgeInsets.all(16.adaptSize),
              decoration: BoxDecoration(
                color: AppColors.brandPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.adaptSize),
                  bottomLeft: Radius.circular(20.adaptSize),
                  bottomRight: Radius.circular(20.adaptSize),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.fSize,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // User Icon Avatar
        Container(
          padding: EdgeInsets.all(8.adaptSize),
          decoration: const BoxDecoration(
            color: AppColors.brandPurple,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: Colors.white, size: 20.adaptSize),
        ),
      ],
    );
  }

  Widget _buildChatFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 5.h),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medical Disclaimer Box
          ValueListenableBuilder<bool>(
            valueListenable: _showDisclaimerNotifier,
            builder: (context, showDisclaimer, child) {
              if (!showDisclaimer) return const SizedBox.shrink();
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.adaptSize),
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6), // Pale Yellow
                      borderRadius: BorderRadius.circular(12.adaptSize),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.orange,
                          size: 18.adaptSize,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).chatDisclaimer,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12.fSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 1.5,
                    right: 1.5,
                    child: GestureDetector(
                      onTap: () {
                        _showDisclaimerNotifier.value = false;
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.orange.shade300,
                        size: 18.adaptSize,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Text Input Field
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F9),
                    borderRadius: BorderRadius.circular(15.adaptSize),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).typeMessage,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.fSize,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      _sendMessage();
                      _messageFocusNode.requestFocus();
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Send Button
              ValueListenableBuilder<bool>(
                valueListenable: _isSendingNotifier,
                builder: (context, isSending, child) {
                  return GestureDetector(
                    onTap: isSending ? null : _sendMessage,
                    child: Container(
                      height: 54.h,
                      width: 54.h,
                      decoration: BoxDecoration(
                        color: isSending
                            ? AppColors.brandPurple.withOpacity(0.5)
                            : AppColors.brandPurple,
                        shape: BoxShape.circle,
                      ),
                      child: isSending
                          ? Padding(
                              padding: EdgeInsets.all(15.adaptSize),
                              child: const AppCircularLoader(
                                size: 20,
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 24.adaptSize,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
