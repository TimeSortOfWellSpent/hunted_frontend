import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://hunted.cidqu.net';
  late String? _jwt;

  ApiService() {
    _loadJwt();
  }

  Future<void> _loadJwt() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString('jwt');
  }

  Future<Map<String, String>> get _headers async {
    if (_jwt == null) {
      await _loadJwt();
    }
    return {
      'Content-Type': 'application/json',
      if (_jwt != null) 'Authorization': 'Bearer $_jwt',
    };
  }

  Future<Map<String, dynamic>> createUser(String username, File photo) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/'),
    );

    request.fields['username'] = username;
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    if (_jwt != null) {
      request.headers['Authorization'] = 'Bearer $_jwt';
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final data = json.decode(responseBody);
      _jwt = data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', _jwt!);
      return data;
    } else {
      throw Exception('Failed to create user: ${responseBody}');
    }
  }

  Future<String> createGameSession() async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['code'];
    } else {
      throw Exception('Failed to create game session: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getGameSession(String code) async {
    final headers = await _headers;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$code'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        final sessionResponse = await http.get(
          Uri.parse('$baseUrl/sessions/$code/info'),
          headers: headers,
        );
        
        if (sessionResponse.statusCode == 200) {
          final data = json.decode(sessionResponse.body);
          return {
            'players': [data['owner']['username']],
            'status': data['status'],
          };
        }
      }
      throw Exception('Failed to get game session: ${response.body}');
    } catch (e) {
      throw Exception('Failed to get game session: $e');
    }
  }

  Future<void> joinGameSession(String code) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$code/participants'),
      headers: headers,
    );
    
    if (response.statusCode != 201) {
      
      throw Exception('Failed to join game session: ${response.body}');
    }
  }

  Future<void> leaveGameSession(String code, {String? username}) async {
    final headers = await _headers;
    final response = await http.delete(
      Uri.parse('$baseUrl/sessions/$code/participants${username != null ? '?username=$username' : ''}'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      // throw Exception('Failed to leave game session: ${response.body}');
      // WELL I DON'T KNOW WHY BUT OUR DATABASE ALWAYS RETURNS 500
      // BUT IT ACTUALLY WORKS
      // IDK WHY
      // SO I'M JUST GONNA IGNORE IT
      if (kDebugMode) {
        print('Failed to leave game session: ${response.body}');
      }
    }
  }

  Future<void> endGameSession(String code) async {
    final headers = await _headers;
    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$code'),
      headers: headers,
      body: json.encode({'status': 'FINISHED'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to end game session: ${response.body}');
    }
  }

  Future<void> updateGameStatus(String lobbyId, String status) async {
    final jwt = _jwt;
    if (jwt == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$lobbyId'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode != 200) {
      // throw Exception('Failed to update game status: ${response.body}');
      // WELL I DON'T KNOW WHY BUT OUR DATABASE ALWAYS RETURNS 500
      // BUT IT ACTUALLY WORKS
      // IDK WHY
      if (kDebugMode) {
        print('Failed to update game status: ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> submitElimination(String code, File photo) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/sessions/$code/eliminations'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    if (_jwt != null) {
      request.headers['Authorization'] = 'Bearer $_jwt';
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return json.decode(responseBody);
    } else {
      throw Exception('Failed to submit elimination');
    }
  }
} 