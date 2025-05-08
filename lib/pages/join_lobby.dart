import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            onPressed: () {
              //Navigator.push(context, MaterialPageRoute(builder: (context) => const Lobby()));
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