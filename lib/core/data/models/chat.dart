class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = '',
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.type = MessageType.text,
  });

  static List<ChatMessage> get demo => [
        ChatMessage(
          id: 'M001',
          senderId: '2',
          senderName: 'Michael Chen',
          content: 'Hi Sarah, how is the project going?',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isMe: false,
        ),
        ChatMessage(
          id: 'M002',
          senderId: '1',
          senderName: 'Sarah Johnson',
          content: 'Going well! We are on track for the deadline.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
          isMe: true,
        ),
        ChatMessage(
          id: 'M003',
          senderId: '2',
          senderName: 'Michael Chen',
          content: "Great to hear! Let me know if you need any support.",
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
          isMe: false,
        ),
        ChatMessage(
          id: 'M004',
          senderId: '1',
          senderName: 'Sarah Johnson',
          content: 'Will do, thanks!',
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
          isMe: true,
        ),
      ];
}

enum MessageType { text, image, file, audio }

class ChatRoom {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String avatarUrl;
  final bool isOnline;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl = '',
    this.isOnline = false,
  });

  static List<ChatRoom> get demo => [
        ChatRoom(
          id: 'C001',
          name: 'Michael Chen',
          lastMessage: "Great to hear! Let me know if you need any support.",
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 2,
          isOnline: true,
        ),
        ChatRoom(
          id: 'C002',
          name: 'HR Department',
          lastMessage: 'Please submit your timesheets by Friday.',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
          unreadCount: 0,
        ),
        ChatRoom(
          id: 'C003',
          name: 'Engineering Team',
          lastMessage: 'Sprint planning at 2 PM today.',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 8)),
          unreadCount: 5,
          isOnline: true,
        ),
        ChatRoom(
          id: 'C004',
          name: 'Jessica Williams',
          lastMessage: 'See you at lunch!',
          lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
          unreadCount: 0,
        ),
      ];
}
