# Firebase Configuration & Auth Flow

## Initialization
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...

await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

Authentication

    Providers Enabled: Google Sign-In and Phone Authentication.

    Database Handoff Flow: Upon successful Firebase Auth, the uid must be extracted immediately. This uid must then be upserted into the Supabase users table to link the relational e-commerce data to the authenticated Firebase user.

Notifications & Cloud Messaging

    Firebase Cloud Messaging (FCM): We'll need to handle notifications. FCM is configured for this purpose.

    Token Management: Device tokens should be captured on login. These tokens must be stored in the newly created fcm_tokens column within the Supabase users table to allow targeting specific users for order updates and marketing pushes.

    