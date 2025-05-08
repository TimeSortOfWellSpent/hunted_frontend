import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hunted_frontend/pages/lobby.dart';

class JoinLobby extends StatefulWidget {
  const JoinLobby({super.key});
  @override
  State<JoinLobby> createState() => _JoinLobbyState();
}

class _JoinLobbyState extends State<JoinLobby> {
  final TextEditingController lobbyCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Lobby'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Lobby Code'),
              controller: lobbyCodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () async {
              final response = await http.post(
                Uri.parse('http://localhost:3000/api/join-lobby'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'code': lobbyCodeController.text}),
              );

              if (response.statusCode == 200) {
                final lobby = jsonDecode(response.body);
                Navigator.push(context, MaterialPageRoute(builder: (context) => Lobby(lobby: lobby, isHost: false)));
              } else if (response.statusCode == 400) {
                Fluttertoast.showToast(msg: 'Lobby not found', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
              }              
              else {
                Fluttertoast.showToast(msg: 'Failed to join lobby', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
              }

              debugPrint(lobbyCodeController.text);
            },
            child: const Text('Join the Lobby'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}