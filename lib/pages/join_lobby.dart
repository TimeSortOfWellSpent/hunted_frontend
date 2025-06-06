import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hunted_frontend/pages/lobby.dart';
import 'package:hunted_frontend/services/api_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class JoinLobby extends StatefulWidget {
  const JoinLobby({super.key});
  @override
  State<JoinLobby> createState() => _JoinLobbyState();
}

class _JoinLobbyState extends State<JoinLobby> {
  final TextEditingController lobbyCodeController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  Future<void> _joinGame() async {
    if (lobbyCodeController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a game code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.joinGameSession(lobbyCodeController.text);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Lobby(
            lobbyId: lobbyCodeController.text,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to join game: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Lobby'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
            child: PinCodeTextField(
              length: 6,
              animationType: AnimationType.fade,
              animationDuration: Duration(milliseconds: 300),
              enableActiveFill: false,
              controller: lobbyCodeController,
              onCompleted: (v) {
              },
              onChanged: (value) {
              },
              beforeTextPaste: (text) {
                return true;
              }, appContext: context,
            )
            
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () async {
              final jwt = context.read<UserState>().jwt;
              if (jwt == null) { 
                Fluttertoast.showToast(msg: 'Please login to join a lobby', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
                return;
              }
              final response = await http.post(
                Uri.parse('https://hunted.cidqu.net/sessions/${lobbyCodeController.text}/participants'),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwt'},
              );

              if (response.statusCode == 201) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Lobby(lobbyId: lobbyCodeController.text, isHost: false)));
              } else if (response.statusCode == 400) {
                Fluttertoast.showToast(msg: 'Lobby not found', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
              } else if (response.statusCode == 409) {
                Fluttertoast.showToast(msg: 'Player name already taken', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
              } else {
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