import 'package:civic_watch/views/authority/city/screens/city_issues_list_screen.dart';
import 'package:flutter/material.dart';

class CityEscalatedTab extends StatelessWidget {
  const CityEscalatedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CityIssuesListScreen(
      embedded: true,
      initialStatus: 'All',
      onlyEscalated: true,
    );
  }
}
