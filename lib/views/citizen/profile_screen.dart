import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_watch/views/authentication/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  
  // Stats
  int _reportedCount = 0;
  int _resolvedCount = 0;
  int _upvotesCount = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), // Same as dashboard
        vsync: this,
    )..forward();
    _loadUserData();
    _loadStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        if (doc.exists) {
            setState(() {
                _userData = doc.data() as Map<String, dynamic>;
            });
        }
    } catch (e) {
        debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadStats() async {
      if (_currentUser == null) return;
      // Ideally fetch real stats from Firestore counting user's issues and upvotes
      // For now, mocking with some data or basic query if possible
      try {
        final issuesSnapshot = await FirebaseFirestore.instance
            .collection('issues')
            .where('userId', isEqualTo: _currentUser!.uid)
            .get();
        
        int issues = issuesSnapshot.docs.length;
        int resolved = 0;
        int upvotes = 0;

        for (var doc in issuesSnapshot.docs) {
            final data = doc.data();
            if (data['status'] == 'Done') resolved++;
            upvotes += (data['upvotes'] ?? 0) as int;
        }

        setState(() {
            _reportedCount = issues;
            _resolvedCount = resolved;
            _upvotesCount = upvotes;
        });

      } catch(e) {
          debugPrint('Error loading stats: $e');
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dashboard background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b).withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        title: const Text(
            'PROFILE',
            style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFf1f5f9), // Dashboard text primary
            letterSpacing: 0.5,
            ),
        ),
        actions: [
            IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF6366f1)),
            onPressed: () {
                // _editProfile(); // Optional
            },
            ),
        ],
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
          : Column(
            children: [
                // User Info Section
                _buildUserInfoSection(),

                // Scrollable Content
                Expanded(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                // Stats Cards
                                FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _fadeController,
                                    curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
                                  ),
                                  child: _buildStatsSection(),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Menu Items (Fade each in sequence)
                                _buildMenuSection(),
                                
                                const SizedBox(height: 40),
                            ],
                        ),
                    ),
                ),
            ],
          ),
    );
  }

  Widget _buildUserInfoSection() {
    final name = _userData?['fullName'] ?? _userData?['name'] ?? 'User';
    final email = _userData?['email'] ?? _currentUser?.email ?? '';
    // Use 'City' or 'city' field
    final city = _userData?['City'] ?? _userData?['city'] ?? 'Unknown City';
    // State isn't usually in standard simple user doc, placeholder if missing
    final state = _userData?['State'] ?? _userData?['state'] ?? 'State'; 
    final profilePicUrl = _userData?['profilePicUrl'];

    return Container(
      width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
                const Color(0xFF6366f1).withOpacity(0.1), // Dashboard gradient
                const Color(0xFFec4899).withOpacity(0.05),
            ],
            ),
            border: const Border(
            bottom: BorderSide(color: Color(0xFF334155), width: 1),
            ),
        ),
        child: Column(
            children: [
            // Profile Avatar
            Stack(
                children: [
                Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [
                        Color(0xFF6366f1), // Dashboard primary
                        Color(0xFFec4899), // Dashboard secondary
                        ],
                    ),
                    border: Border.all(
                        color: const Color(0xFF334155), // Dashboard border
                        width: 3,
                    ),
                    boxShadow: [
                        BoxShadow(
                        color: const Color(0xFF6366f1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        ),
                    ],
                    ),
                    child: ClipOval(
                    child: profilePicUrl != null && profilePicUrl.isNotEmpty
                        ? Image.network(profilePicUrl, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                            _getInitials(name),
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                            ),
                            ),
                        ),
                    ),
                ),
                // Edit icon overlay
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: const Color(0xFF6366f1), // Dashboard primary
                        shape: BoxShape.circle,
                        border: Border.all(
                        color: const Color(0xFF0f172a), // Dashboard background
                        width: 2,
                        ),
                    ),
                    child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                    ),
                    ),
                ),
                ],
            ),
            
            const SizedBox(height: 16),
            
            // User Name
            Text(
                name,
                style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFFf1f5f9), // Dashboard text primary
                ),
            ),
            
            const SizedBox(height: 8),
            
            // Email
            Text(
                email,
                style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94a3b8), // Dashboard secondary text
                ),
            ),
            
            const SizedBox(height: 6),
            
            // Location
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFFec4899), // Dashboard secondary/pink
                ),
                const SizedBox(width: 4),
                Text(
                    '$city, $state',
                    style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94a3b8),
                    ),
                ),
                ],
            ),
            ],
        ),
    );
  }

  Widget _buildStatsSection() {
      // NOTE: Using a Row directly here instead of extra container wrapper 
      // to match structure better if needed, but following prompt wireframe instructions.
      // Prompt says: Container(padding: 20, decoration: ..., child: Row(...))
      // But usually dashboard cards are standalone. Let's follow prompts design.
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF1e293b).withOpacity(0.5), // Light tint
            borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
            children: [
            Expanded(
                child: _buildStatCard(
                _reportedCount.toString(),
                'Issues Reported',
                Icons.assignment,
                0,
                ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                _resolvedCount.toString(),
                'Resolved',
                Icons.check_circle,
                1,
                ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                _upvotesCount.toString(),
                'Total Upvotes',
                Icons.thumb_up,
                2,
                ),
            ),
            ],
        ),
    );
  }

  // Stat card widget (EXACT dashboard stats card)
  Widget _buildStatCard(String value, String label, IconData icon, int index) {
    return FadeTransition(
        opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.2 + (index * 0.1), 1.0, curve: Curves.easeOut),
        ),
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
            color: const Color(0xFF1e293b), // Dashboard card color
            border: Border.all(color: const Color(0xFF334155)), // Dashboard border
            borderRadius: BorderRadius.circular(16), // Dashboard radius
        ),
        child: Column(
            children: [
            // Icon
            Icon(
                icon,
                color: const Color(0xFF6366f1), // Dashboard primary
                size: 28,
            ),
            const SizedBox(height: 12),
            
            // Value with gradient (like dashboard)
            ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFFec4899)],
                ).createShader(bounds),
                child: Text(
                value,
                style: const TextStyle(
                    fontSize: 24, // Slightly smaller to fit 3 cols 
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'monospace', // Dashboard uses monospace for numbers
                ),
                 maxLines: 1,
                ),
            ),
            
            const SizedBox(height: 8),
            
            // Label
            Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                fontSize: 11, // Adjusted for space
                color: Color(0xFF94a3b8), // Dashboard secondary text
                fontWeight: FontWeight.w500,
                height: 1.3,
                ),
                 maxLines: 2,
            ),
            ],
        ),
        ),
    );
  }

  Widget _buildMenuSection() {
      return Column(
      children: [
        _buildAnimatedMenuItem(
          0,
          icon: Icons.settings,
          iconColor: const Color(0xFF6366f1), // Primary
          title: 'Settings',
          onTap: () { 
              // _navigateToSettings(); 
          },
        ),
        const SizedBox(height: 12),
        
        _buildAnimatedMenuItem(
          1,
          icon: Icons.bar_chart,
          iconColor: const Color(0xFF3b82f6), // Blue
          title: 'My Statistics',
          onTap: () {
              // _navigateToStatistics();
          },
        ),
        const SizedBox(height: 12),
        
        _buildAnimatedMenuItem(
          2,
          icon: Icons.info,
          iconColor: const Color(0xFF10b981), // Green
          title: 'About & Help',
          onTap: () {
              // _navigateToAbout();
          },
        ),
        const SizedBox(height: 12),
        
        _buildAnimatedMenuItem(
          3,
          icon: Icons.logout,
          iconColor: const Color(0xFFef4444), // Red/danger
          title: 'Logout',
          onTap: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  Widget _buildAnimatedMenuItem(int index, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
      return FadeTransition(
        opacity: CurvedAnimation(
            parent: _fadeController,
            curve: Interval(0.4 + (index * 0.1), 1.0, curve: Curves.easeOut),
        ),
        child: _buildMenuItem(
            icon: icon,
            iconColor: iconColor,
            title: title,
            onTap: onTap,
        ),
      );
  }

  // Menu item widget (match dashboard card style)
  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF1e293b), // Dashboard card color
            border: Border.all(color: const Color(0xFF334155)), // Dashboard border
            borderRadius: BorderRadius.circular(16), // Dashboard radius
        ),
        child: Row(
            children: [
            // Icon container
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                icon,
                color: iconColor,
                size: 22,
                ),
            ),
            
            const SizedBox(width: 16),
            
            // Title
            Expanded(
                child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFf1f5f9), // Dashboard text primary
                ),
                ),
            ),
            
            // Arrow icon
            const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF64748b), // Dashboard muted
            ),
            ],
        ),
        ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b), // Dashboard card color
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
            'Logout',
            style: TextStyle(
            color: Color(0xFFf1f5f9),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            ),
        ),
        content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
            color: Color(0xFF94a3b8),
            fontSize: 15,
            height: 1.5,
            ),
        ),
        actions: [
            TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
                'Cancel',
                style: TextStyle(
                color: Color(0xFF94a3b8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                ),
            ),
            ),
            TextButton(
            onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                     Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                    );
                }
            },
            child: const Text(
                'Logout',
                style: TextStyle(
                color: Color(0xFFef4444), // Danger color
                fontSize: 16,
                fontWeight: FontWeight.w600,
                ),
            ),
            ),
        ],
        ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> names = name.split(' ');
    if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
