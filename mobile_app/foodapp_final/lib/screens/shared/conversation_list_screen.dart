// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:food_app/api/api_constants.dart';
// import 'package:food_app/models/conversation_models.dart';
// import 'package:food_app/providers/auth_provider.dart';
// import 'package:food_app/screens/shared/conversation_detail_screen.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// class ConversationListScreen extends StatefulWidget {
//   const ConversationListScreen({super.key});
//
//   @override
//   State<ConversationListScreen> createState() => _ConversationListScreenState();
// }
//
// class _ConversationListScreenState extends State<ConversationListScreen> {
//   final _storage = const FlutterSecureStorage();
//   List<Conversation> _conversations = [];
//   bool _isLoading = true;
//   String? _errorMessage; // ✨ ADD: State variable for error messages
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchConversations();
//   }
//
//   /// Fetches the list of conversations from the server.
//   Future<void> _fetchConversations() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null; // ✨ ADD: Reset error message on each fetch
//     });
//
//     try {
//       final token = await _storage.read(key: 'jwt_token');
//       if (token == null) {
//         throw Exception('Authentication token not found. Please log in again.');
//       }
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + ApiConstants.conversations),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       if (mounted) {
//         if (response.statusCode == 200) {
//           final List data = jsonDecode(response.body);
//           setState(() {
//             _conversations = data.map((json) => Conversation.fromJson(json)).toList();
//           });
//         } else {
//           // Handle non-200 responses as errors
//           throw Exception('Failed to load conversations');
//         }
//       }
//     } catch (e) {
//       // ✨ ADD: Set the error message if an exception occurs
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Could not load messages. Please pull down to refresh.';
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
//   /// Navigates to the detail screen for a specific conversation.
//   void _navigateToDetail(int conversationId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => ConversationDetailScreen(conversationId: conversationId)),
//     ).then((_) => _fetchConversations()); // Refresh list when returning from a conversation
//   }
//
//   /// Navigates to the detail screen to start a new conversation.
//   void _startNewConversation() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const ConversationDetailScreen(conversationId: null)),
//     ).then((_) => _fetchConversations()); // Refresh list after a new conversation is potentially created
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Determine user role to conditionally show the FAB
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final isCustomer = authProvider.role == 'CUSTOMER';
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Messages')),
//       body: RefreshIndicator(
//         onRefresh: _fetchConversations,
//         child: _buildBody(), // ✨ UPDATE: Logic moved to a separate build method
//       ),
//       floatingActionButton: isCustomer
//           ? FloatingActionButton.extended(
//         onPressed: _startNewConversation,
//         icon: const Icon(Icons.edit),
//         label: const Text('New Message'),
//       )
//           : null,
//     );
//   }
//
//   /// Builds the main body of the scaffold, handling loading, error, and data states.
//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     // ✨ ADD: Display the error message if one exists
//     if (_errorMessage != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Text(
//             _errorMessage!,
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Theme.of(context).colorScheme.error),
//           ),
//         ),
//       );
//     }
//
//     if (_conversations.isEmpty) {
//       return const Center(
//         child: Text('You have no conversations yet.'),
//       );
//     }
//
//     return ListView.builder(
//       itemCount: _conversations.length,
//       itemBuilder: (context, index) {
//         final convo = _conversations[index];
//         return ListTile(
//           leading: CircleAvatar(
//             child: Text(convo.customerUsername.substring(0, 1).toUpperCase()),
//           ),
//           title: Text(
//             convo.subject,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           subtitle: Text('Last update: ${DateFormat.yMMMd().add_jm().format(convo.updatedAt.toLocal())}'),
//           trailing: const Icon(Icons.chevron_right),
//           onTap: () => _navigateToDetail(convo.id),
//         );
//       },
//     );
//   }
// }










import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_app/api/api_constants.dart';
import 'package:food_app/models/conversation_models.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/screens/shared/conversation_detail_screen.dart';
import 'package:food_app/utils/notification_utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final _storage = const FlutterSecureStorage();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.conversations),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          setState(() {
            _conversations = data.map((json) => Conversation.fromJson(json)).toList();
          });
        } else {
          throw Exception('Failed to load conversations');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load messages. Please pull down to refresh.';
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

  void _navigateToDetail(int conversationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationDetailScreen(
          conversationId: conversationId,
          onMessageSent: _fetchConversations, // Pass callback to refresh list
        ),
      ),
    );
  }

  void _startNewConversation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationDetailScreen(
          conversationId: null,
          onMessageSent: _fetchConversations, // Pass callback to refresh list
        ),
      ),
    );
  }

  Future<void> _deleteConversation(int conversationId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final url = Uri.parse('${ApiConstants.baseUrl}/api/conversations/$conversationId');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Deleted',
          message: 'Conversation deleted successfully.',
          isSuccess: true,
        );
        _fetchConversations();
      } else {
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Failed',
          message: 'Could not delete the conversation.',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showAnimatedPopup(
          context,
          title: 'Error',
          message: 'An error occurred while deleting the conversation.',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCustomer = authProvider.role == 'CUSTOMER';

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: _fetchConversations,
        child: _buildBody(isCustomer),
      ),
      floatingActionButton: isCustomer
          ? FloatingActionButton.extended(
        onPressed: _startNewConversation,
        icon: const Icon(Icons.edit),
        label: const Text('New Message'),
      )
          : null,
    );
  }

  Widget _buildBody(bool isCustomer) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Text('You have no conversations yet.'),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final convo = _conversations[index];

        return Dismissible(
          key: Key(convo.id.toString()),
          direction: isCustomer ? DismissDirection.endToStart : DismissDirection.none,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
          ),
          confirmDismiss: (direction) async {
            if (!isCustomer) return false;
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Conversation'),
                content: const Text('Are you sure you want to delete this conversation?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            _deleteConversation(convo.id);
          },
          child: Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(convo.customerUsername.isNotEmpty ? convo.customerUsername[0].toUpperCase() : '?'),
              ),
              title: Text(
                convo.subject,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Last update: ${DateFormat.yMMMd().add_jm().format(convo.updatedAt.toLocal())}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToDetail(convo.id),
            ),
          ),
        );
      },
    );
  }
}
