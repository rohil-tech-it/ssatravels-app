import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseUploadPage extends StatefulWidget {
  @override
  _FirebaseUploadPageState createState() => _FirebaseUploadPageState();
}

class _FirebaseUploadPageState extends State<FirebaseUploadPage> {
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
  }

  // Initialize Firebase
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Function to upload JSON to Firestore
  Future<void> uploadJsonToFirestore() async {
    setState(() {
      uploading = true;
    });

    try {
      // Load local JSON
      String jsonString = await rootBundle.loadString('assets/data.json');
      List<dynamic> jsonData = json.decode(jsonString);

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Upload each JSON object as a document
      for (var item in jsonData) {
        await firestore.collection('routes')
            .doc(item['id'].toString())
            .set({
          'name': item['name'],
          'price': item['price'],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ JSON uploaded to Firestore successfully!')),
      );
    } catch (e) {
      print('Error uploading JSON: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to upload JSON')),
      );
    }

    setState(() {
      uploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase JSON Upload')),
      body: Center(
        child: uploading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: uploadJsonToFirestore,
                child: Text('Upload JSON to Firestore'),
              ),
      ),
    );
  }
}
