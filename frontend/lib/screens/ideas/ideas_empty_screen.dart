import 'package:flutter/material.dart';

class IdeasEmptyScreen extends StatelessWidget {
  const IdeasEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Ideas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
        ),
      ),
    );
  }
}
