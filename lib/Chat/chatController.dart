import 'package:flutter/material.dart';

class ChatController {
  // List to hold personal chat data
  List<Map<String, dynamic>> _personalChatList = [
    {
      "name": "Alice",
      "message": "Hey! How are you?",
      "time": "10:30 AM",
      "isRead": false,
      "type": "text", // Add type field to differentiate between text and images
    },
    {
      "name": "Bob",
      "message": "See you later!",
      "time": "11:00 AM",
      "isRead": true,
      "type": "text",
    },
  ];

  // List to hold group chat data
  List<Map<String, dynamic>> _groupChatList = [
    {
      "name": "RXZ Members",
      "message": "Hey! How are you?",
      "time": "10:30 AM",
      "isRead": false,
      "type": "text",
    },
  ];

  // List to hold system chat data
  List<Map<String, dynamic>> _systemChatList = [
    {
      "name": "Motorsport",
      "message": "Hey! How are you?",
      "time": "10:30 AM",
      "isRead": false,
      "type": "text",
    },
  ];

  // Getter for personal chats
  List<Map<String, dynamic>> get personalChatList => _personalChatList;

  // Getter for group chats
  List<Map<String, dynamic>> get groupChatList => _groupChatList;

  // Getter for system chats
  List<Map<String, dynamic>> get systemChatList => _systemChatList;

  // Getter for all messages based on chat name
  List<Map<String, dynamic>> getMessages(String chatName) {
    // Search for personal, group, or system chat based on the name
    if (_personalChatList.any((chat) => chat['name'] == chatName)) {
      return _personalChatList.where((chat) => chat['name'] == chatName).toList();
    } else if (_groupChatList.any((chat) => chat['name'] == chatName)) {
      return _groupChatList.where((chat) => chat['name'] == chatName).toList();
    } else {
      return _systemChatList.where((chat) => chat['name'] == chatName).toList();
    }
  }


  // Method to mark a chat as read
  void markAsRead(int index, {bool isGroup = false, bool isSystem = false}) {
    List<Map<String, dynamic>> chatList;

    if (isSystem) {
      chatList = _systemChatList;
    } else if (isGroup) {
      chatList = _groupChatList;
    } else {
      chatList = _personalChatList;
    }

    if (!chatList[index]["isRead"]) {
      chatList[index]["isRead"] = true;
    }
  }

  // Method to add a new personal message
  void addNewPersonalMessage(String name, String message, String time, String type) {
    _personalChatList.add({
      "name": name,
      "message": message,
      "time": time,
      "isRead": false,
      "type": type, // Add type to specify if it's text or image
    });
  }

  // Method to add a new group message
  void addNewGroupMessage(String name, String message, String time, String type) {
    _groupChatList.add({
      "name": name,
      "message": message,
      "time": time,
      "isRead": false,
      "type": type,
    });
  }

  // Method to add a new system message
  void addNewSystemMessage(String name, String message, String time, String type) {
    _systemChatList.add({
      "name": name,
      "message": message,
      "time": time,
      "isRead": false,
      "type": type,
    });
  }

  // Method to add an image message (shared for personal, group, and system)
  void addImageMessage(String name, String imagePath, String time, String type) {
    if (type == 'personal') {
      addNewPersonalMessage(name, imagePath, time, 'image');
    } else if (type == 'group') {
      addNewGroupMessage(name, imagePath, time, 'image');
    } else {
      addNewSystemMessage(name, imagePath, time, 'image');
    }
  }
}
