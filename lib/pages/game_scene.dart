import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GameScreen extends StatefulWidget {
  final Map<String, dynamic> lobby;
  final bool isHost;
  final String playerName;
  const GameScreen({super.key, required this.lobby, required this.isHost, this.playerName = ''});

  @override
  State<GameScreen> createState() => _GameScreen();
}

class _GameScreen extends State<GameScreen> {
  List<String> players = [];
  bool isGameStarted = false;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      updateGameState();
    });
  }

  Future<void> updateGameState() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/lobby/${widget.lobby['id']}'),
    );
    if (response.statusCode == 200) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lobby['name'])),
      body: Column(
        children: [
          
        ],
      ),
      floatingActionButton: Visibility(
        visible: widget.isHost,
        child: FloatingActionButton(
          onPressed: () {
            http.post(
              Uri.parse('http://localhost:3000/api/lobby/${widget.lobby['id']}/start'),
            );
          }
        ),
      ),
    );
  }
}