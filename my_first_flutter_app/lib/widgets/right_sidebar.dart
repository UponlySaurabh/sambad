import 'package:flutter/material.dart';

class RightSidebar extends StatelessWidget {
  final VoidCallback? onAddContact;
  final VoidCallback? onInvite;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;
  final bool showCall;
  const RightSidebar({this.onAddContact, this.onInvite, this.onCall, this.onVideoCall, this.showCall = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF181A20),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(-2, 0))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.deepPurple, size: 32),
            tooltip: 'Add Contact',
            onPressed: onAddContact,
          ),
          const SizedBox(height: 18),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.deepPurple, size: 32),
            tooltip: 'Invite Friends',
            onPressed: onInvite,
          ),
          if (showCall) ...[
            const SizedBox(height: 18),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.greenAccent, size: 32),
              tooltip: 'Call',
              onPressed: onCall,
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.blueAccent, size: 32),
              tooltip: 'Video Call',
              onPressed: onVideoCall,
            ),
          ],
        ],
      ),
    );
  }
}
