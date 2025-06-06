import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hunted_frontend/pages/game_scene.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hunted_frontend/services/api_service.dart';

class Lobby extends StatefulWidget {
  final String lobbyId;
  final bool isHost;

  const Lobby({super.key, required this.lobbyId, required this.isHost});

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  List<String> players = [];
  bool isGameStarted = false;
  final _apiService = ApiService();
  Timer? _gameStateTimer;

  @override
  void initState() {
    super.initState();
    _gameStateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        getGameState();
      }
    });
  }

  @override
  void dispose() {
    _gameStateTimer?.cancel();
    super.dispose();
  }

  Future<void> getGameState() async {
    if (!mounted) return;
    
    try {
      final response = await _apiService.getGameSession(widget.lobbyId);
      if (!mounted) return;
      
      if (response['status'] == 'in_progress') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScene(
              gameId: widget.lobbyId,
              username: context.read<UserState>().username ?? '',
            ),
          ),
        );
        return;
      }
      
      setState(() {
        // Get other players from response
        final otherPlayers = List<String>.from(response['players'] ?? []);
        // Add current user to the list
        final currentUser = context.read<UserState>().username;
        if (currentUser != null) {
          // Filter out our own username from other players
          final filteredPlayers = otherPlayers.where((player) => player != currentUser).toList();
          players = [currentUser, ...filteredPlayers];
        } else {
          players = otherPlayers;
        }
      });
    } catch (e) {
      debugPrint('Error getting game state: $e');
      // If we're the host and get an error, show just the host
      if (widget.isHost && mounted) {
        setState(() {
          final currentUser = context.read<UserState>().username;
          players = currentUser != null ? [currentUser] : ['Host'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleLeave();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lobby - ${widget.lobbyId}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLeave,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Number of Players: ${players.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.isHost && players.length == 1)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Waiting for other players to join...',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final isCurrentUser = players[index] == context.read<UserState>().username;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: isCurrentUser 
                          ? const BorderSide(color: Colors.deepPurple, width: 2)
                          : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentUser ? Colors.deepPurple : Colors.grey[300],
                          child: Text(
                            players[index][0].toUpperCase(),
                            style: TextStyle(
                              color: isCurrentUser ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          players[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          isCurrentUser ? 'You' : 'Player',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: widget.isHost && !isCurrentUser
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _showKickConfirmation(players[index]),
                            )
                          : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Visibility(
          visible: widget.isHost,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final jwt = context.read<UserState>().jwt;
              if (jwt == null) {
                Fluttertoast.showToast(msg: 'Please login to start the game', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
                return;
              }
              try {
                await _apiService.updateGameStatus(widget.lobbyId, 'in_progress');
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScene(
                      gameId: widget.lobbyId,
                      username: context.read<UserState>().username ?? '',
                    ),
                  ),
                );
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to start game: ${e.toString()}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Game'),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLeave() async {
    try {
      if (widget.isHost) {
        await _apiService.endGameSession(widget.lobbyId);
      } else {
        await _apiService.leaveGameSession(widget.lobbyId);
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to leave game: ${e.toString()}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
    }
  }

  Future<void> _removePlayer(String username) async {
    try {
      await _apiService.leaveGameSession(widget.lobbyId, username: username);
      // Refresh the game state to update the player list
      await getGameState();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to remove player: ${e.toString()}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
    }
  }

  Future<void> _showKickConfirmation(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick Player'),
        content: Text('Are you sure you want to kick $username from the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Kick'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removePlayer(username);
    }
  }
}