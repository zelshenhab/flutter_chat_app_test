import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

part 'main.g.dart';

@HiveType(typeId: 0)
class Message extends HiveObject {
  @HiveField(0)
  String content;

  @HiveField(1)
  String type;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  bool isMe;

  Message({
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isMe,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MessageAdapter());
  await Hive.openBox('chats');
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ChatsScreen());
  }
}

final List<ChatUser> users = [
  ChatUser(name: 'Viktor Vlasov', avatar: 'VV', chatBoxName: 'chat_viktor'),
  ChatUser(name: 'Sasha Alexeeva', avatar: 'SA', chatBoxName: 'chat_sasha'),
  ChatUser(name: 'Pyotr Zharinov', avatar: 'PZ', chatBoxName: 'chat_pyotr'),
  ChatUser(name: 'Alina Zhukova', avatar: 'AZ', chatBoxName: 'chat_alina'),
];

class ChatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return FutureBuilder<Box<Message>>(
            future: Hive.openBox<Message>(user.chatBoxName),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final box = snapshot.data!;
              final lastMessage = box.isNotEmpty ? box.values.last : null;

              return ListTile(
                leading: CircleAvatar(child: Text(user.avatar)),
                title: Text(
                  user.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMessage != null
                      ? (lastMessage.type == 'text'
                          ? lastMessage.content
                          : '[Image]')
                      : 'No messages yet',
                ),
                trailing: Text(
                  lastMessage != null ? formatTime(lastMessage.timestamp) : '',
                ),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(user: user)),
                    ),
              );
            },
          );
        },
      ),
    );
  }

  String formatTime(DateTime time) {
    return "${time.hour}:${time.minute}";
  }
}

class ChatUser {
  final String name;
  final String avatar;
  final String chatBoxName;

  ChatUser({
    required this.name,
    required this.avatar,
    required this.chatBoxName,
  });
}