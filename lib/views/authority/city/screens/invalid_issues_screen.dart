import 'package:civic_watch/views/authority/city/screens/city_issues_list_screen.dart';
import 'package:flutter/material.dart';

class InvalidIssuesScreen extends StatelessWidget {
  const InvalidIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CityIssuesListScreen(
      title: 'Invalid/Spam Issues',
      initialStatus: 'Invalid',
      onlyInvalid: true,
    );
  }
}
