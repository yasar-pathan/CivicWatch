import 'package:civic_watch/services/admin_service.dart';
import 'package:civic_watch/views/admin/activity_logs_screen.dart'; // Import this
import 'package:civic_watch/views/admin/city_authorities_screen.dart';
import 'package:civic_watch/views/admin/screens/system_analytics_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminService().fetchAdminDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'System health, authority counts, and quick controls',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                      'State Authorities',
                      data['totalStateAuthorities'] ?? 0,
                      const Color(0xFF38BDF8)),
                  _buildStatCard('Created by Admin', data['totalStateAuthorities'] ?? 0,
                      const Color(0xFFF59E0B)),
                  _buildStatCard('City Authorities',
                      data['totalCityAuthorities'] ?? 0, const Color(0xFF22C55E)),
                  _buildStatCard(
                      'Total Issues', data['totalIssues'] ?? 0, const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    context,
                    'Create New State Authority',
                    Icons.person_add_alt_1,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Use the Create tab to add a new State Authority.'),
                      ));
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Manage State Authorities',
                    Icons.supervised_user_circle,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Use the State Auth tab to manage all State Authorities.'),
                      ));
                    },
                  ),
                  _buildActionButton(
                    context,
                    'View City Authorities',
                    Icons.location_city,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CityAuthoritiesScreen())),
                  ),
                  _buildActionButton(
                    context,
                    'Activity Logs',
                    Icons.history,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ActivityLogsScreen())),
                  ),
                  _buildActionButton(
                    context,
                    'System Analytics',
                    Icons.bar_chart,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SystemAnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 220,
                child: const ActivityLogsPreview(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF334155),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366f1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class ActivityLogsPreview extends StatelessWidget {
  const ActivityLogsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final text = snapshot.error.toString().toLowerCase();
          final permission = text.contains('permission-denied');
          return Center(
            child: Text(
              permission
                  ? 'Activity logs unavailable: publish Firestore rules for admin access.'
                  : 'Could not load recent activity.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No recent activity yet.',
                style: TextStyle(color: Colors.white60)),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white12, height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final action = (data['action'] ?? 'action').toString();
            return ListTile(
              dense: true,
              leading: const Icon(Icons.fiber_manual_record,
                  color: Color(0xFFEC4899), size: 12),
              title: Text(
                action,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            );
          },
        );
      },
    );
  }
}


