import 'package:flutter/material.dart';

class PhonebookPermissionDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onDeny;
  const PhonebookPermissionDialog({super.key, required this.onAllow, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF23272F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Phonebook Access', style: TextStyle(color: Colors.white)),
      content: const Text(
        'To extract contacts, the app needs access to your phone book. This is only used to add friends and is not stored or shared.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: onDeny,
          child: const Text('Deny', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: onAllow,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Allow',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
