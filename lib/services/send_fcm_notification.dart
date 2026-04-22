import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getTokenKey() async {
  //----------------- 1. access by file
  // final jsonKeys =
  //     await rootBundle.loadString('assets/json/pushkey.json');
  // final creds = auth.ServiceAccountCredentials.fromJson(jsonKeys);

  //----------------- 2. access by JSON code
  // past your server private key that's downloaded from the Firebase project settings section
  var jsonKeys = {
    "type": "service_account",
    "project_id": "together-wellness",
    "private_key_id": "f24b42bcd7f4c5b56a70beab1b3fa52516978e3b",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCpdKLEGXcJIAFm\nSz1IQZbQJe1uQYDFv1b8Dm8dLRWJcfNGAnwZMXM0mU3kUBTtfuGaQaFY5y9bIZ2F\nfQQnCvcxdg5P4/MdcWUEsFnCVRIUjvuqt2wMmJzupl7XJUgu81yIO+Rxv3r7SzCU\naO9eMmSCK+NBAVWI8uKiEFcDmrrYa6XOELfm59vbSqG4jbB+VaxKpMUxne7G1ZSG\nmpuRDmHO6KRcnihXMiiEo/b1oiz0D2m05EcRie3sWFOusRzus/pIcSlduLFIXcQM\nZdYZKXtRvJ3PpEDPQVLK7hAOHREaY0SvVjpIuWiYKQiY6EGoZiwD354TUaVx6Chl\nhvswJSjvAgMBAAECggEAI0vzN2uietka0YbsjedzlYnA6g1k2Evhv4D2Lhqc+NMu\nfC+6T7kYKSWhruPraAjczzfKdu041P+sgwimW8eR89CGbKerlT9wbkiZebwklvmt\nfELWk80aKy+mY6QVZAo3BP2MuRDMehmQVemBqppOizq/DGRNv8fv4xgKN+r77mYv\nB6/ohXfKP99j99qhwDAd9W6OMO57QzQplahazqI4PyaZOjmlXhUfgxUSop0Q7Zk9\n7rUEN74BcSShhdQgcldOVrsQX1RstrWBHgVW1dRCkGBKwbRQP61I5HV5NBw5VmAy\n2+dnFWaQ4jbM2FLwRpLxg1iRYENBonQsOugC8AXDSQKBgQDV3tV6n+3Q7dKLQzSi\nwKSYC1GVWUDODyJsF2rpLXosdtLrTzublpzASpe2nBpeRb9sNUrUpMvcVt/TiEyo\nVX2Di+swi9p53kjEQ9rj4YJMBF3eHh7IGJmzKI0uZSi+Cf9W7l710tU16d6SbXbU\nS21HUTzIGAJth8JWDYCBheMeWwKBgQDK1gc7meXGmOYdouNdsHRVr42hAvop2zXf\nKz6dnFNcrm1xeX/jMN5dXWL9gByHYzPjUeYXvSIdE6jfEfBxZtPYwjxJ5rm0Ahdn\nH1fAqxPG91oTps/dyx+O8uEMFmipNHrvO7z7kgvpdCSioZeijnBn6JZoX1PCNMoD\nC2BcvzrL/QKBgQCOmUo7vcDCap/UbRX+YnYcToeyDdWwztSDv8Vv/fuVBBE0BhtX\nbT/M0q9/eWv3aYftrUbcq5ilrGMG1r1OC9ppSHSjZMxiL3zTJ+8dvDG1X7/6ppid\nkBGDLEmeIqLcuyu+GafFPjMdBHd7qHLvr+8H+zmMrL2JrFg+KjiBo/TAOwKBgQDD\nYVamOp/ypOVENtr8LDRjNS8foVaHaviBd45hE2vZIsuZOofNuAz5sjLgLL9OSmh4\n1zLkOvLZP06zUPxiv8HgUXjxVqYalskkNDS7Cg+K4EiMFWq1IivL7niIxC0cj8i7\nGLf5O7ztq0p+vVjq5HmyHYCEGQ79Swwr0pGHxUxFoQKBgGFJJHNvdTgreaYk53N+\nmTBHv+Yr8+Bp//d/frZYRZ3z81xld4jSAu3XYCxTKVmZSVOaEEi+ZIPtT2KlBgKl\npiVy43RMjqZi/4kqNq1bMCr6XWQ6t0HyC59a81TM6wXajH9IqMr2EFW2t/K1CIEl\nAmIJq243GNTrBjvUGPEfmRFK\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@together-wellness.iam.gserviceaccount.com",
    "client_id": "101343182317220545132",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40together-wellness.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  final creds = auth.ServiceAccountCredentials.fromJson(jsonKeys);

  List<String> scopes = [
    'https://www.googleapis.com/auth/userinfo.email',
    // 'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/firebase.database',
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  final client = await auth.clientViaServiceAccount(creds, scopes);

  auth.AccessCredentials credentials = await auth
      .obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(jsonKeys),
        scopes,
        client,
      );

  String tokenIs = credentials.accessToken.data;
  // client.close();
  return tokenIs;
}

sendFCMNotificationf({
  required String recipientToken,
  required String title,
  required String body,
}) async {
  try {
    String serverKeyIs = await getTokenKey();

    // paste your Firebase project ID here
    const String projectId =
        'together-wellness'; // Use your Firebase project ID.

    final response = await http.post(
      Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKeyIs',
      },
      body: jsonEncode({
        'message': {
          'token': recipientToken,
          "notification": {"title": "$title", "body": "$body"},
          "android": {
            "notification": {
              "icon": "ic_notification",
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        },
      }),
    );

    print('👉🔔 Response Status: ${response.statusCode}');
    print('🔔 Response Body: ${response.body}');

    if (response.statusCode == 404) {
      print(
        '❌ 404 Requested entity not found. Check recipient token and project ID.',
      );
    }
  } catch (e) {
    print('❌ Error sending push message: $e');
  }
}


    // for future usage do not remove this
    // 'message': {
    //       'token': recipientToken,
    //       "notification": {
    //         "title": "$title",
    //         "body": "$body",
    //         "image": "https://salerozana.com/images/sales/1707308104.jpeg",
    //         "scheduledTime": "2024-03-08 10:00:00",
    //       },
    //       "data": {
    //         "message": "Offer!",
    //         "image_url": "https://salerozana.com/images/sales/1707308104.jpeg",
    //         "image": "https://salerozana.com/images/sales/1707308104.jpeg",
    //         "customkey": "ABC",
    //       },
    //     },