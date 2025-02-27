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

  @override
  Widget build(BuildContext context) {
    if (!isBoxReady) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.user.name)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(child: Text(widget.user.avatar)),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<Message> box, _) {
                final messages = box.values.toList();

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Align(
                      alignment:
                          message.isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message.isMe ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            message.type == 'text'
                                ? Text(
                                  message.content,
                                  style: TextStyle(
                                    color:
                                        message.isMe
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                )
                                : Image.file(
                                  File(message.content),
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _sendImageMessage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _sendTextMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
