// lib/screens/customer/customer_conversation_screen.dart
import 'package:flutter/material.dart';
import 'package:food_app/helpers/animation_helper.dart'; // Import the helper

class CustomerConversationScreen extends StatefulWidget {
  const CustomerConversationScreen({super.key});
  @override
  State<CustomerConversationScreen> createState() => _CustomerConversationScreenState();
}

class _CustomerConversationScreenState extends State<CustomerConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _conversation = ['Hi, I have a question.'];
  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    setState(() { _isSending = true; });

    final messageText = _messageController.text;

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // On success:
    setState(() {
      _conversation.add(messageText);
      _isSending = false;
      _messageController.clear();
    });

    // ✅ ANIMATION: Call the success animation helper on send
    showSuccessAnimation(
      context,
      animationPath: 'assets/animations/message_sent.json',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Canteen')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _conversation.length,
              itemBuilder: (context, index) => Align(
                alignment: Alignment.centerRight,
                child: Card(
                  color: Theme.of(context).primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(_conversation[index], style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
          Padding( // Message Input UI
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type your message...'),
                  ),
                ),
                _isSending
                    ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                    : IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}