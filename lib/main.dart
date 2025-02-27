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

// Chat Screen
class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Box<Message> box;
  final TextEditingController _controller = TextEditingController();
  final picker = ImagePicker();
  bool isBoxReady = false;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    box = await Hive.openBox<Message>(widget.user.chatBoxName);
    setState(() {
      isBoxReady = true;
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final message = Message(
      content: text,
      type: 'text',
      timestamp: DateTime.now(),
      isMe: true,
    );
    await box.add(message);
    _controller.clear();
    setState(() {}); // Update UI
  }

  Future<void> _sendImageMessage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final message = Message(
        content: pickedFile.path,
        type: 'image',
        timestamp: DateTime.now(),
        isMe: true,
      );
      await box.add(message);
      setState(() {});
    }
  }
