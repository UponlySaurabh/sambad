import 'package:flutter/material.dart';
import 'chat_page.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final List<String> _groups = ['General']; // initial group

  Future<void> _createGroup() async {
    final controller = TextEditingController();

    final String? name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create group'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Group name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(context, value);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name != null && name.trim().isNotEmpty) {
      setState(() {
        _groups.add(name.trim());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Create group',
            onPressed: _createGroup,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final groupName = _groups[index];
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.group),
            ),
            title: Text(groupName),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    name: groupName,
                    isPrivate: false, // groups are non-private
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
