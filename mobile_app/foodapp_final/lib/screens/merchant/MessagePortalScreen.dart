// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/helpers/animation_helper.dart';
// // ✨ ADD: Import for the detail screen
// import 'package:food_app/screens/shared/conversation_detail_screen.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
//
// // Ensure this model matches the data from your API
// class Message {
//   final String id;
//   final String subject;
//   final String sender;
//   final DateTime timestamp;
//
//   Message({
//     required this.id,
//     required this.subject,
//     required this.sender,
//     required this.timestamp,
//   });
//
//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['id'].toString(),
//       subject: json['subject'],
//       sender: json['customerUsername'],
//       timestamp: DateTime.parse(json['updatedAt']),
//     );
//   }
// }
//
// class MessagePortalScreen extends StatefulWidget {
//   const MessagePortalScreen({super.key});
//   @override
//   State<MessagePortalScreen> createState() => _MessagePortalScreenState();
// }
//
// class _MessagePortalScreenState extends State<MessagePortalScreen> {
//   final _storage = const FlutterSecureStorage();
//   final List<Message> _messages = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMessages();
//   }
//
//   Future<void> _fetchMessages() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       if (token == null) throw Exception('Authentication failed.');
//
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.conversations),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (!mounted) return;
//
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         setState(() {
//           _messages.clear();
//           _messages.addAll(data.map((json) => Message.fromJson(json)).toList());
//         });
//       } else {
//         throw Exception('Failed to load messages from the server.');
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   void _deleteMessage(int index) async {
//     final message = _messages[index];
//     setState(() {
//       _messages.removeAt(index);
//     });
//
//     showSuccessAnimation(
//       context,
//       animationPath: 'assets/animations/success.json',
//     );
//
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       final response = await http.delete(
//         Uri.parse('${ApiConstants.baseUrl}/api/conversations/${message.id}'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (response.statusCode != 200 && response.statusCode != 204) {
//         throw Exception('Failed to delete on server.');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Error: Could not delete message.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         setState(() {
//           _messages.insert(index, message);
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Message Portal'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _fetchMessages,
//         child: _buildBody(),
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (_errorMessage != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Text(
//             'Error: $_errorMessage\nPlease pull down to refresh.',
//             textAlign: TextAlign.center,
//           ),
//         ),
//       );
//     }
//
//     if (_messages.isEmpty) {
//       return const Center(
//         child: Text(
//           'You have no messages yet.',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       );
//     }
//
//     return ListView.builder(
//       itemCount: _messages.length,
//       itemBuilder: (context, index) {
//         final message = _messages[index];
//         return Dismissible(
//           key: Key(message.id),
//           direction: DismissDirection.endToStart,
//           onDismissed: (direction) {
//             _deleteMessage(index);
//           },
//           background: Container(
//             color: Colors.red.shade700,
//             alignment: Alignment.centerRight,
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: const Icon(Icons.delete_forever, color: Colors.white),
//           ),
//           child: Card(
//             margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             child: ListTile(
//               leading: CircleAvatar(
//                 child: Text(message.sender.substring(0, 1).toUpperCase()),
//               ),
//               title: Text(message.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
//               subtitle: Text('From: ${message.sender}'),
//               trailing: Text(
//                 DateFormat.yMd().format(message.timestamp.toLocal()),
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//               onTap: () {
//                 // ✨ FIX: Uncommented the navigation logic to open the conversation
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ConversationDetailScreen(
//                       conversationId: int.parse(message.id),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/helpers/animation_helper.dart';
// ✨ ADD: Import for the detail screen
import 'package:food_app/screens/shared/conversation_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Ensure this model matches the data from your API
class Message {
  final String id;
  final String subject;
  final String sender;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.subject,
    required this.sender,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      subject: json['subject'],
      sender: json['customerUsername'],
      timestamp: DateTime.parse(json['updatedAt']),
    );
  }
}

class MessagePortalScreen extends StatefulWidget {
  const MessagePortalScreen({super.key});
  @override
  State<MessagePortalScreen> createState() => _MessagePortalScreenState();
}

class _MessagePortalScreenState extends State<MessagePortalScreen> {
  final _storage = const FlutterSecureStorage();
  final List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('Authentication failed.');

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.conversations),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(data.map((json) => Message.fromJson(json)).toList());
        });
      } else {
        throw Exception('Failed to load messages from the server.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(int index) async {
    final message = _messages[index];

    // Show confirmation dialog before deleting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      // User cancelled deletion, so do not remove from list
      setState(() {}); // Refresh to reset Dismissible state
      return;
    }

    setState(() {
      _messages.removeAt(index);
    });

    showSuccessAnimation(
      context,
      animationPath: 'assets/animations/success.json',
    );

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/conversations/${message.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete on server.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not delete message.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _messages.insert(index, message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Portal'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMessages,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_errorMessage\nPlease pull down to refresh.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'You have no messages yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Dismissible(
          key: Key(message.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            // Show confirmation dialog on swipe
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Message'),
                content: const Text('Are you sure you want to delete this message?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            return confirm == true;
          },
          onDismissed: (direction) {
            _deleteMessage(index);
          },
          background: Container(
            color: Colors.red.shade700,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_forever, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(message.sender.substring(0, 1).toUpperCase()),
              ),
              title: Text(message.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('From: ${message.sender}'),
              trailing: Text(
                DateFormat.yMd().format(message.timestamp.toLocal()),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConversationDetailScreen(
                      conversationId: int.parse(message.id),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
