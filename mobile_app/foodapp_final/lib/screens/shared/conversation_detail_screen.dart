// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/helpers/animation_helper.dart';
// import 'package:food_app/models/conversation_models.dart';
// import 'package:food_app/providers/auth_provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// class ConversationDetailScreen extends StatefulWidget {
//   final int? conversationId;
//   const ConversationDetailScreen({super.key, required this.conversationId});
//
//   @override
//   State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
// }
//
// class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
//   final _storage = const FlutterSecureStorage();
//   final _replyController = TextEditingController();
//   final _subjectController = TextEditingController();
//   final _scrollController = ScrollController();
//
//   Conversation? _conversation;
//   String? _errorMessage;
//   bool _isLoading = true;
//   bool _isSending = false;
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.conversationId != null) {
//       _fetchConversationDetails();
//     } else {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   void dispose() {
//     _replyController.dispose();
//     _subjectController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchConversationDetails() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final response = await http.get(
//         Uri.parse('${ApiConstants.baseUrl}/api/conversations/${widget.conversationId}'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//       if (mounted) {
//         if (response.statusCode == 200) {
//           setState(() {
//             _conversation = Conversation.fromJson(jsonDecode(response.body));
//           });
//         } else {
//           throw Exception('Failed to load conversation details');
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Could not load conversation.';
//         });
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _postMessage() async {
//     if (_replyController.text.isEmpty) return;
//     if (widget.conversationId == null && _subjectController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please provide a subject for your new message.")),
//       );
//       return;
//     }
//
//     setState(() => _isSending = true);
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       http.Response response;
//       final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
//
//       if (widget.conversationId == null) {
//         final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.conversations);
//         final body = jsonEncode({'subject': _subjectController.text, 'content': _replyController.text});
//         response = await http.post(url, headers: headers, body: body);
//       } else {
//         final url = Uri.parse('${ApiConstants.baseUrl}/api/conversations/${widget.conversationId}/reply');
//         final body = jsonEncode({'content': _replyController.text});
//         response = await http.post(url, headers: headers, body: body);
//       }
//
//       if (mounted) {
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           _replyController.clear();
//           showSuccessAnimation(
//             context,
//             animationPath: 'assets/animations/message_sent.json',
//           );
//           if (widget.conversationId != null) {
//             await _fetchConversationDetails();
//             _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
//           } else {
//             Navigator.pop(context);
//           }
//         } else {
//           throw Exception('Failed to send message');
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Error: Could not send message."), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUserEmail = Provider.of<AuthProvider>(context, listen: false).email;
//
//     // ✨ FIX: Handle the case where the user's email is null (not logged in).
//     // This prevents the null-check error when calling _buildBody.
//     if (currentUserEmail == null) {
//       return Scaffold(
//         appBar: AppBar(),
//         body: const Center(
//           child: Text('Cannot verify user. Please log in again.'),
//         ),
//       );
//     }
//
//     final reversedMessages = _conversation?.messages.reversed.toList() ?? [];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_conversation?.subject ?? 'New Message'),
//         actions: [
//           if (widget.conversationId != null)
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _fetchConversationDetails,
//             ),
//         ],
//       ),
//       body: _buildBody(currentUserEmail, reversedMessages),
//     );
//   }
//
//   Widget _buildBody(String currentUserEmail, List<Message> reversedMessages) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_errorMessage != null) {
//       return Center(child: Text(_errorMessage!));
//     }
//     return Column(
//       children: [
//         if (widget.conversationId == null)
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//             child: TextField(
//               controller: _subjectController,
//               decoration: const InputDecoration(
//                 labelText: 'Subject',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//         Expanded(
//           child: _conversation == null
//               ? const Center(child: Text('Type a message to start the conversation.'))
//               : ListView.builder(
//             controller: _scrollController,
//             padding: const EdgeInsets.all(8),
//             reverse: true,
//             itemCount: reversedMessages.length,
//             itemBuilder: (context, index) {
//               final message = reversedMessages[index];
//               final isMe = message.senderEmail == currentUserEmail;
//               return _buildMessageBubble(message, isMe);
//             },
//           ),
//         ),
//         _buildMessageInput(),
//       ],
//     );
//   }
//
//   Widget _buildMessageBubble(Message message, bool isMe) {
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Card(
//         elevation: 2,
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 message.content,
//                 style: TextStyle(color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 '${message.senderUsername} • ${DateFormat.jm().format(message.timestamp.toLocal())}',
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: isMe ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessageInput() {
//     return Container(
//       padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8 + MediaQuery.of(context).viewPadding.bottom),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.1), offset: const Offset(0, -2))],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _replyController,
//               decoration: const InputDecoration(hintText: 'Type your message...', border: InputBorder.none),
//               onSubmitted: _isSending ? null : (_) => _postMessage(),
//               textCapitalization: TextCapitalization.sentences,
//               minLines: 1,
//               maxLines: 5,
//             ),
//           ),
//           IconButton(
//             icon: _isSending
//                 ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
//                 : const Icon(Icons.send),
//             onPressed: _isSending ? null : _postMessage,
//             color: Theme.of(context).colorScheme.primary,
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/helpers/animation_helper.dart';
import 'package:food_app/models/conversation_models.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ConversationDetailScreen extends StatefulWidget {
  final int? conversationId;
  final VoidCallback? onMessageSent;  // Callback to notify list screen

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    this.onMessageSent,
  });

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _storage = const FlutterSecureStorage();
  final _replyController = TextEditingController();
  final _subjectController = TextEditingController();
  final _scrollController = ScrollController();

  Conversation? _conversation;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _fetchConversationDetails();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _subjectController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversationDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/conversations/${widget.conversationId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _conversation = Conversation.fromJson(jsonDecode(response.body));
          });
        } else {
          throw Exception('Failed to load conversation details');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load conversation.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postMessage() async {
    if (_replyController.text.isEmpty) return;
    if (widget.conversationId == null && _subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a subject for your new message.")),
      );
      return;
    }

    setState(() => _isSending = true);
    final token = await _storage.read(key: 'jwt_token');
    http.Response response;
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

    if (widget.conversationId == null) {
      final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.conversations);
      final body = jsonEncode({'subject': _subjectController.text, 'content': _replyController.text});
      response = await http.post(url, headers: headers, body: body);
    } else {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/conversations/${widget.conversationId}/reply');
      final body = jsonEncode({'content': _replyController.text});
      response = await http.post(url, headers: headers, body: body);
    }

    if (mounted) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        _replyController.clear();
        showSuccessAnimation(
          context,
          animationPath: 'assets/animations/success.json',
        );

        // Update local conversation instantly with the new message
        if (widget.conversationId != null && _conversation != null) {
          final newMessageJson = jsonDecode(response.body);
          final newMessage = Message.fromJson(newMessageJson);

          setState(() {
            _conversation!.messages.add(newMessage);
          });

          // Scroll to bottom to show new message
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        // Notify parent list screen to refresh immediately
        widget.onMessageSent?.call();

        if (widget.conversationId == null) {
          Navigator.pop(context);
        }
      }
    }

      if (mounted) setState(() => _isSending = false);

  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = Provider.of<AuthProvider>(context, listen: false).email;

    if (currentUserEmail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Cannot verify user. Please log in again.'),
        ),
      );
    }

    final reversedMessages = _conversation?.messages.reversed.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_conversation?.subject ?? 'New Message'),
        actions: [
          if (widget.conversationId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchConversationDetails,
            ),
        ],
      ),
      body: _buildBody(currentUserEmail, reversedMessages),
    );
  }

  Widget _buildBody(String currentUserEmail, List<Message> reversedMessages) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return Column(
      children: [
        if (widget.conversationId == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        Expanded(
          child: _conversation == null
              ? const Center(child: Text('Type a message to start the conversation.'))
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            reverse: true,
            itemCount: reversedMessages.length,
            itemBuilder: (context, index) {
              final message = reversedMessages[index];
              final isMe = message.senderEmail == currentUserEmail;
              return _buildMessageBubble(message, isMe);
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: TextStyle(color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 5),
              Text(
                '${message.senderUsername} • ${DateFormat.jm().format(message.timestamp.toLocal())}',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8 + MediaQuery.of(context).viewPadding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.1), offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: const InputDecoration(hintText: 'Type your message...', border: InputBorder.none),
              onSubmitted: _isSending ? null : (_) => _postMessage(),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            onPressed: _isSending ? null : _postMessage,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
