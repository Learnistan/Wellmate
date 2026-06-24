import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class OpenAIRemoteDataSource {
  final FirebaseFunctions functions;

  OpenAIRemoteDataSource(this.functions);

  Future<String> sendMessage(String message) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please login first.');
    }

    final callable = FirebaseFunctions
        .instanceFor(region: 'us-central1')
        .httpsCallable('chatWithOpenAI');

    final result = await callable.call({
      'message': message,
    });

    return result.data['reply'] as String;
  }
}