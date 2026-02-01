
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_watch/views/authentication/login_screen.dart';
import 'package:civic_watch/views/citizen/report_issue_screen.dart';
import 'package:civic_watch/views/citizen/issue_detail_screen.dart';
import 'package:civic_watch/views/citizen/my_reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  int _selectedIndex = 0;
  String? _userCity;
  bool _isLoadingCity = true;

  @override
  void initState() {
    super.initState();
    _fetchUserCity();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  Future<void> _fetchUserCity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _userCity = data['City'] ?? data['city'];
            _isLoadingCity = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching city: $e');
      if (mounted) setState(() => _isLoadingCity = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If selected index is MyReports, show that screen directly (it has its own Scaffold)
    // But we need to keep BottomNav visible.
    // Ideally MyReportsScreen shouldn't be a Scaffold if nested, but it is.
    // We can wrap it in a container and remove Scaffold property if we modify it, but let's try standard switching.
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      // App bar only for Home mainly to show Logout?
      // Or move Logout to Profile.
      appBar: _selectedIndex == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _logout(context);
            },
            tooltip: 'Logout',
          ),
        ],
      ) : null,
      body: Stack(
        children: [
          // Background for tabs that need it (Dashboard, Profile etc)
          if (_selectedIndex != 1) _buildAnimatedBackground(),

          _buildBody(),

          // FAB only on Dashboard
          if (_selectedIndex == 0)
            Positioned(
              bottom: 90,
              right: 20,
              child: _buildFAB(),
            ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        // MyReportsScreen is a Scaffold. To nest it inside this Stack while keeping BottomNav on top,
        // we might have issues.
        // But let's try.
        return const Padding(
           padding: EdgeInsets.only(bottom: 70), // Space for bottom nav
           child: MyReportsScreen(),
        );
      case 2:
        return const Center(child: Text('Map View', style: TextStyle(color: Colors.white)));
      case 3:
        // Pass isTab: true to hide the back button and adjust layout
        return const ReportIssueScreen(isTab: true);
      case 4:
         return Center(
             child: ElevatedButton(
                 onPressed: () => _logout(context),
                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
                 child: const Text('Logout', style: TextStyle(color: Colors.white)),
             )
         );
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
     return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(), // Include Header in dashboard tab
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildRecentIssues(),
                        const SizedBox(height: 100), // Bottom nav padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF94a3b8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF94a3b8))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: GradientBackgroundPainter(),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366f1).withOpacity(0.1),
              const Color(0xFFec4899).withOpacity(0.05),
            ],
          ),
          border: const Border(
            bottom: BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFFec4899),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _userCity ?? 'Getting location...',
                      style: TextStyle(
                        color: const Color(0xFF94a3b8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildIconButton(Icons.search),
                    const SizedBox(width: 12),
                    _buildIconButton(Icons.notifications, hasNotification: true),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFFec4899)],
              ).createShader(bounds),
              child: const Text(
                'Hey, Yasar! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Let's make our city better together",
              style: TextStyle(
                color: const Color(0xFF94a3b8),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {bool hasNotification = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: const Color(0xFF334155)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: const Color(0xFF94a3b8), size: 20),
          if (hasNotification)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFef4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoadingCity) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: _buildStatCard('-', 'REPORTED', 0)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('-', 'RESOLVED', 1)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('-', 'IMPACT', 2)),
          ],
        ),
      );
    }
  
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('issues')
          .where('City', isEqualTo: _userCity)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Show loading state or zeros while loading
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('-', 'REPORTED', 0)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('-', 'RESOLVED', 1)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('-', 'IMPACT', 2)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final reportedCount = docs.length;
        final resolvedCount = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Done';
        }).length;
        
        // Calculate impact (e.g., sum of upvotes)
        int impactCount = 0;
        for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Impact algorithm: 1 point per issue + upvotes + (5 points if resolved)
            // Or just sum of upvotes as originally planned. Let's do simple sum of upvotes + comments
            int upvotes = (data['upvotes'] ?? 0) as int;
            impactCount += upvotes;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _buildStatCard(reportedCount.toString(), 'REPORTED', 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(resolvedCount.toString(), 'RESOLVED', 1)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(impactCount.toString(), 'IMPACT', 2)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String number, String label, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.2 + (index * 0.1), 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fadeController,
          curve: Interval(0.2 + (index * 0.1), 1.0, curve: Curves.easeOut),
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6366f1), Color(0xFFec4899)],
                ).createShader(bounds),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF94a3b8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFf1f5f9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionButton('🕳️', 'Pothole', 0)),
              const SizedBox(width: 16),
              Expanded(child: _buildActionButton('💧', 'Sewage', 1)),
              const SizedBox(width: 16),
              Expanded(child: _buildActionButton('🚧', 'Broken', 2)),
              const SizedBox(width: 16),
              Expanded(child: _buildActionButton('🗑️', 'Dirty', 3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String emoji, String label, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.3 + (index * 0.05), 1.0, curve: Curves.easeOut),
      ),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF94a3b8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentIssues() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Issues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFf1f5f9),
                ),
              ),
              Text(
                'See All →',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF6366f1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingCity)
             const Center(child: CircularProgressIndicator())
          else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('issues')
                .where('City', isEqualTo: _userCity)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No issues reported in $_userCity yet',
                      style: TextStyle(
                        color: const Color(0xFF94a3b8).withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }
              
              // Client-side sort and limit to avoid complex index requirements
              final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
                ..sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });
              
              final recentDocs = sortedDocs.take(5).toList();

              return Column(
                children: recentDocs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final data = doc.data() as Map<String, dynamic>;

                  // Determine emoji based on category
                  String emoji = '⚠️';
                  final category = (data['category'] ?? '').toString().toLowerCase();
                  if (category.contains('pothole')) emoji = '🕳️';
                  else if (category.contains('sewage') || category.contains('water')) emoji = '💧';
                  else if (category.contains('garbage') || category.contains('clean')) emoji = '🗑️';
                  else if (category.contains('broken') || category.contains('infra')) emoji = '🚧';
                  else if (category.contains('light') || category.contains('electric')) emoji = '💡';

                  // Format Time
                  String timeStr = 'Just now';
                  if (data['createdAt'] != null) {
                    final timestamp = data['createdAt'] as Timestamp;
                    final diff = DateTime.now().difference(timestamp.toDate());
                    if (diff.inDays > 0) timeStr = '${diff.inDays}d ago';
                    else if (diff.inHours > 0) timeStr = '${diff.inHours}h ago';
                    else if (diff.inMinutes > 0) timeStr = '${diff.inMinutes}m ago';
                  }

                  // Status Color
                  Color statusColor = const Color(0xFFf59e0b); // Default orange
                  final status = (data['status'] ?? 'Reported').toString();
                  if (status == 'Done' || status == 'Resolved') statusColor = const Color(0xFF10b981);
                  else if (status == 'In Work' || status == 'In Progress') statusColor = const Color(0xFF3b82f6);
                  else if (status == 'Rejected') statusColor = const Color(0xFFef4444);

                  return Column(
                    children: [
                      _buildIssueCard(
                        emoji: emoji,
                        imageUrl: data['photoUrl'],
                        title: data['title'] ?? 'Untitled Issue',
                        distance: data['address'] ?? 'Unknown location', // Using address as distance/location placeholder
                        time: timeStr,
                        status: status,
                        statusColor: statusColor,
                        upvotes: data['upvotes'] ?? 0,
                        comments: data['commentCount'] ?? 0,
                        index: index,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IssueDetailScreen(
                                issueId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                      ),
                      if (index < snapshot.data!.docs.length - 1)
                        const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard({
    required String emoji,
    String? imageUrl,
    required String title,
    required String distance,
    required String time,
    required String status,
    required Color statusColor,
    required int upvotes,
    required int comments,
    required int index,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.4 + (index * 0.1), 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fadeController,
          curve: Interval(0.4 + (index * 0.1), 1.0, curve: Curves.easeOut),
        )),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b),
              border: Border.all(color: const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: (imageUrl == null || imageUrl.isEmpty)
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF6366f1).withOpacity(0.2),
                                  const Color(0xFFec4899).withOpacity(0.2),
                                ],
                              )
                            : null,
                        color: const Color(0xFF1e293b),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(emoji,
                                        style: const TextStyle(fontSize: 32)),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 32)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFf1f5f9),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: const Color(0xFF64748b)),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF64748b),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time,
                                  size: 14, color: const Color(0xFF64748b)),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF64748b),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: const Color(0xFF334155),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.thumb_up,
                        size: 16, color: const Color(0xFF6366f1)),
                    const SizedBox(width: 6),
                    Text(
                      upvotes.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF94a3b8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline,
                        size: 16, color: const Color(0xFF94a3b8)),
                    const SizedBox(width: 6),
                    Text(
                      comments.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF94a3b8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366f1), Color(0xFFec4899)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366f1).withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b).withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF334155)),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.assignment, 'Reports', 1),
          _buildNavItem(Icons.map, 'Map', 2),
          _buildNavItem(Icons.flag, 'Issues', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366f1).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366f1), Color(0xFFec4899)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF6366f1)
                  : const Color(0xFF94a3b8),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color(0xFF6366f1)
                    : const Color(0xFF64748b),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for animated gradient background
class GradientBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // First gradient circle
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF6366f1).withOpacity(0.15),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.3),
      radius: size.width * 0.4,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.4,
      paint,
    );

    // Second gradient circle
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFec4899).withOpacity(0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.7),
      radius: size.width * 0.4,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.4,
      paint,
    );

    // Third gradient circle
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFf59e0b).withOpacity(0.08),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.5),
      radius: size.width * 0.5,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// import 'package:flutter/material.dart';

// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Card(
//               child: ListTile(
//                 leading: const Icon(Icons.report),
//                 title: const Text('Report Issue'),
//                 onTap: () {},
//               ),
//             ),
//             Card(
//               child: ListTile(
//                 leading: const Icon(Icons.track_changes),
//                 title: const Text('Track Issues'),
//                 onTap: () {},
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
