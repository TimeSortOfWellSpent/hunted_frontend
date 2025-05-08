import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hunted_frontend/pages/lobby.dart';

class CreateLobby extends StatefulWidget {
  const CreateLobby({super.key});
  @override
  State<CreateLobby> createState() => _CreateLobbyState();
}

class _CreateLobbyState extends State<CreateLobby> {
  final TextEditingController lobbyNameController = TextEditingController();

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
              decoration: const InputDecoration(hintText: 'Lobby Name'),
              controller: lobbyNameController,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () async {
              final response = await http.post(
                Uri.parse('http://localhost:3000/api/create-lobby'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'name': lobbyNameController.text}),
              );

              if (response.statusCode == 200) {
                final lobby = jsonDecode(response.body);
                Navigator.push(context, MaterialPageRoute(builder: (context) => Lobby(lobby: lobby, isHost: true)));
              } else {
                Fluttertoast.showToast(msg: 'Failed to create lobby', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
              }

              //Navigator.push(context, MaterialPageRoute(builder: (context) => const Lobby()));
              debugPrint(lobbyNameController.text);
            },
            child: const Text('Create Lobby'),
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