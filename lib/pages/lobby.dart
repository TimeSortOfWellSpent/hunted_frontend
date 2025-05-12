import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hunted_frontend/pages/game_scene.dart';
class Lobby extends StatefulWidget {
  final Map<String, dynamic> lobby;
  final bool isHost;

  const Lobby({super.key, required this.lobby, required this.isHost});

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  List<String> players = [];

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      updateCurrentPlayers();
      getGameState();
    });
  }

  Future<void> getGameState() async {
    
  }

  Future<void> updateCurrentPlayers() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/lobby/${widget.lobby['id']}'),
    );
    if (response.statusCode == 200) {
      final lobby = jsonDecode(response.body);
      setState(() {
        players = lobby['players'].map((player) => player['name']).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lobby['name'])),
      body: Column(
        children: [
          Text('Number of Players: ${players.length}'),
          const SizedBox(height: 20),
          ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Card(
                  child: Text(players[index]),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: widget.isHost,
        child: FloatingActionButton(
          onPressed: () {
            //Navigator.push(context, MaterialPageRoute(builder: (context) => const GameScreen(lobby: ,)));
            http.post(
              Uri.parse('http://localhost:3000/api/lobby/${widget.lobby['id']}/start'),
            );
          }
        ),
      ),
    );
  }
}