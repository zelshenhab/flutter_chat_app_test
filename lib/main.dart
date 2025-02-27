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
