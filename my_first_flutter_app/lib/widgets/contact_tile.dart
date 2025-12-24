import 'package:flutter/material.dart';
import '../models/contact.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final int unreadCount;

  const ContactTile({super.key, required this.contact, this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<ChatService>(context, listen: false);
    final isBlocked = svc.blockedContacts.contains(contact.id);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white,
        child: Text(
          contact.name.isNotEmpty ? contact.name.substring(0, 1) : '?',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
      title: Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(contact.phone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
              child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF23272F),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF23272F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
                    content: Text('Are you sure you want to delete ${contact.name}?', style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (!context.mounted) return;
                  await svc.deleteContact(contact.id);
                }
              } else if (value == 'block') {
                if (!context.mounted) return;
                await svc.blockContact(contact.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${contact.name} blocked')));
              } else if (value == 'unblock') {
                if (!context.mounted) return;
                await svc.unblockContact(contact.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${contact.name} unblocked')));
              }
            },
            itemBuilder: (context) => [
              if (!isBlocked)
                const PopupMenuItem(
                  value: 'block',
                  child: Text('Block', style: TextStyle(color: Colors.white)),
                ),
              if (isBlocked)
                const PopupMenuItem(
                  value: 'unblock',
                  child: Text('Unblock', style: TextStyle(color: Colors.white)),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
