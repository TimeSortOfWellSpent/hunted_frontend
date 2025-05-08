import 'package:flutter/material.dart';

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
            onPressed: () {
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