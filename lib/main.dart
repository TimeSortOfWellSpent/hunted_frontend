import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hunted_frontend/pages/join_lobby.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'pages/lobby.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class UserState extends ChangeNotifier {
  String? _jwt;
  String? _username;
  final _prefs = SharedPreferences.getInstance();

  String? get jwt => _jwt;
  String? get username => _username;
  bool get isAuthenticated => _jwt != null;

  Future<void> initialize() async {
    final prefs = await _prefs;
    _jwt = prefs.getString('jwt');
    _username = prefs.getString('username');
    notifyListeners();
  }

  Future<void> logout() async {
    _jwt = null;
    _username = null;
    final prefs = await _prefs;
    await prefs.remove('jwt');
    await prefs.remove('username');
    notifyListeners();
  }

  Future<void> authenticate(String username, File? photo) async {
    final uuid = const Uuid().v4();
    if (kDebugMode) {
      print('UUID: $uuid');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://hunted.cidqu.net/users/'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $uuid',
      'accept': 'application/json',
    });

    request.fields['username'] = username;
    
    if (photo != null) {
      final fileName = photo.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      // Determine content type based on file extension
      String contentType;
      if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == 'png') {
        contentType = 'image/png';
      } else {
        throw Exception('Unsupported file type. Please use JPG or PNG images.');
      }
      
      final fileStream = http.ByteStream(photo.openRead());
      final fileLength = await photo.length();
      
      final multipartFile = http.MultipartFile(
        'photo',
        fileStream,
        fileLength,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );
      
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Request fields: ${request.fields}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _jwt = data['access_token'];
        _username = username;
        
        final prefs = await _prefs;
        await prefs.setString('jwt', _jwt!);
        await prefs.setString('username', _username!);
        notifyListeners();
        
        // Navigate to HomeScreen after successful login
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (kDebugMode) {
          print('Failed to authenticate: ${response.body}');
        }
        throw Exception('Failed to authenticate: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during authentication: $e');
      }
      throw Exception('Failed to authenticate: $e');
    }
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final userState = UserState();
    await userState.initialize();
    
    runApp(
      ChangeNotifierProvider.value(
        value: userState,
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint(stackTrace.toString());
    // Show a basic error screen instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Hunted',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Consumer<UserState>(
        builder: (context, userState, child) {
          if (!userState.isAuthenticated) {
            return const UsernameScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _usernameController = TextEditingController();
  File? _image;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Request camera permission first
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required to take a photo')),
      );
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 1000,
        maxHeight: 1000,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final extension = pickedFile.path.split('.').last.toLowerCase();
        
        if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a JPG or PNG image')),
          );
          return;
        }
        
        setState(() {
          _image = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Hunted'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _image == null
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Enter your username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_usernameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a username')),
                  );
                  return;
                }
                if (_image == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a photo')),
                  );
                  return;
                }
                try {
                  await context.read<UserState>().authenticate(
                    _usernameController.text,
                    _image,
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to authenticate: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  void initState() {
    super.initState();
    if (kDebugMode) {
      print('Username: ${context.read<UserState>().username}');
      print('JWT: ${context.read<UserState>().jwt}');
    }
  }

  Future<void> _createGame() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final code = await _apiService.createGameSession();
      if (!mounted) return;
      await _apiService.joinGameSession(code);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Lobby(lobbyId: code, isHost: true),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to create game: ${e.toString()}';
      });
      Fluttertoast.showToast(msg: 'Failed to create game: ${e.toString()}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Hunted'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.github),
          onPressed: () async {
            const url = 'https://github.com/TimeSortOfWellSpent';
            var url_parsed = Uri.parse(url);
            if (!await launchUrl(url_parsed)) {
              throw 'Could not launch $url';
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<UserState>().logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const UsernameScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Spacer(flex: 2),
            Image.asset(
              'assets/HUNTED_TRANSPARENT.png',
              height: 200,
              width: 200,
            ),
            const Spacer(flex: 1),
            ElevatedButton(
              onPressed: () {
                _createGame();
              },
              child: const Text('Host a Lobby'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinLobby()));
              },
              child: const Text('Join a Lobby'),
            ),
            const Spacer(flex: 2), 
            Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                      builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'How To Play',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                width: double.infinity,
                height: 400, // Adjust height for the popup
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    "Welcome to the Hunted Game! Here's how to play:\n\n"
                    "1. Gather your friends and create a lobby.\n"
                    "2. Enter the lobby code to join the game.\n"
                    "3. Your target will be randomly assigned to you.\n"
                    "4. You need to show your phone to your target to hunt them!\n"
                    "5. If you are the target, you need to hide your eyes from your hunter!\n"
                    "6. Last person standing wins!\n\n"
                    "Have fun and enjoy the adventure!",
                    style: TextStyle(fontSize: 16.0, color: Colors.black),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the popup
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
      child: const Text("How To Play"),
    ),
  ),
)
          ],
        ),
      )
    );
  }

}
