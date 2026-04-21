// Flutter Loop
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<String?> uploadFileByChunked(String base64) async {
  int chunkSize = 256 * 1024;
  int totalChunks = (base64.length / chunkSize).ceil();
  String? finalResult;

  for (int i = 0; i < totalChunks; i++) {
    int start = i * chunkSize;
    int end = (start + chunkSize < base64.length)
        ? start + chunkSize
        : base64.length;
    String chunk = base64.substring(start, end);

    var response = await http.post(
      Uri.parse('https://link.thelocalrent.com/api/upload_base64_chunks'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer Ajkasdqnlwqlk",
      },
      body: jsonEncode({
        "chunk_data": chunk,
        "chunk_index": i,
        "total_chunks": totalChunks,
        "folder_name": "couple-ai",
        "is_secret": false,
      }),
    );
    debugPrint("Chunk $i Status: ${response.statusCode}");
    finalResult = response.body;
    debugPrint("Chunk $i Response: $finalResult");
  }
  return finalResult;
}
