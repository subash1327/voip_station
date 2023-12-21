import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(options: options);
  }

  static FirebaseOptions get options {
    return const FirebaseOptions(
      appId: '1:880328920017:android:1a45611a7229648067aef0',
      messagingSenderId: '880328920017',
      projectId: 'voip-station',
      apiKey: 'AIzaSyB5dlPEE7MD1hk47rxj7ZjZzAlD1OyXqEo',
      storageBucket: 'voip-station.appspot.com'
    );
  }
}