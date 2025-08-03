import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // Replace 'test' and 'demo' with your actual collection and document names.
      future: FirebaseFirestore.instance.collection('test').doc('demo').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return CircularProgressIndicator();

        if (snapshot.hasError)
          return Text('Error: ${snapshot.error}');

        if (!snapshot.hasData || !snapshot.data!.exists)
          return Text('No document found');

        final data = snapshot.data!.data() as Map<String, dynamic>;
        return Text('Document data: ${data.toString()}');
      },
    );
  }
}