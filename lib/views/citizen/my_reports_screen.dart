import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:civic_watch/models/issue_model.dart';
import 'package:civic_watch/views/citizen/issue_detail_screen.dart';
import 'package:civic_watch/views/citizen/edit_issue_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  int _selectedFilter = 0; // 0: All, 1: Active, 2: Resolved
  
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dashboard background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
                child: RefreshIndicator(
                    onRefresh: () async {
                        setState(() {});
                        await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: const Color(0xFF6366f1),
                    backgroundColor: const Color(0xFF1e293b),
                    child: Column(
                        children: [
                            _buildStatsCards(),
                            const SizedBox(height: 20),
                            _buildFilterTabs(),
                            const SizedBox(height: 16),
                            _buildIssuesList(),
                        ],
                    ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6366f1), Color(0xFFec4899)],
                ).createShader(bounds),
                child: const Text(
                  'My Reports',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                children: [
                  _buildIconButton(Icons.filter_list),
                  const SizedBox(width: 12),
                  _buildIconButton(Icons.search),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Track and manage your reported issues',
            style: TextStyle(
              color: Color(0xFF94a3b8),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: const Color(0xFF334155)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF94a3b8), size: 20),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('issues')
                .where('userId', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
                 int total = 0;
                 int active = 0;
                 int resolved = 0;

                 if (snapshot.hasData) {
                     total = snapshot.data!.docs.length;
                     active = snapshot.data!.docs.where((doc) => doc['status'] != 'Done' && doc['status'] != 'Resolved').length;
                     resolved = snapshot.data!.docs.where((doc) => doc['status'] == 'Done' || doc['status'] == 'Resolved').length;
                 }

                return Row(
                    children: [
                    Expanded(child: _buildStatCard(total.toString(), 'TOTAL', Icons.assignment, 0)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(active.toString(), 'ACTIVE', Icons.pending, 1)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(resolved.toString(), 'RESOLVED', Icons.check_circle, 2)),
                    ],
                );
            }
        ),
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.2 + (index * 0.1), 1.0, curve: Curves.easeOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6366f1),
              size: 24,
            ),
            const SizedBox(height: 8),
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
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94a3b8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildFilterTab('All', 0, _selectedFilter == 0)),
          const SizedBox(width: 12),
          Expanded(child: _buildFilterTab('Active', 1, _selectedFilter == 1)),
          const SizedBox(width: 12),
          Expanded(child: _buildFilterTab('Resolved', 2, _selectedFilter == 2)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [
              const Color(0xFF6366f1).withOpacity(0.2),
              const Color(0xFFec4899).withOpacity(0.1),
            ],
          ) : null,
          color: isSelected ? null : const Color(0xFF1e293b),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366f1) : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFFf1f5f9) : const Color(0xFF94a3b8),
          ),
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('issues')
          .where('userId', isEqualTo: currentUserId)
          // Removed orderBy to avoid index requirement errors
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF6366f1)),
            ));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }
          
          List<Issue> issues = snapshot.data!.docs
            .map((doc) => Issue.fromFirestore(doc))
            .toList();
            
          // Client-side sort
          issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          if (_selectedFilter == 1) { // Active
            issues = issues.where((i) => i.status != 'Done' && i.status != 'Resolved').toList();
          } else if (_selectedFilter == 2) { // Resolved
            issues = issues.where((i) => i.status == 'Done' || i.status == 'Resolved').toList();
          }

          if (issues.isEmpty) {
              return _buildEmptyState();
          }
          
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              return _buildIssueCard(issues[index], index);
            },
          );
        },
      ),
    );
  }

  Widget _buildIssueCard(Issue issue, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.3 + (index * 0.1) > 1.0 ? 1.0 : 0.3 + (index * 0.1), 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fadeController,
          curve: Interval(0.3 + (index * 0.1) > 1.0 ? 1.0 : 0.3 + (index * 0.1), 1.0, curve: Curves.easeOut),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6366f1).withOpacity(0.2),
                          const Color(0xFFec4899).withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: issue.photoUrl.isNotEmpty
                        ? Image.network(
                            issue.photoUrl,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              _getCategoryEmoji(issue.category),
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFf1f5f9),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, 
                              size: 14, 
                              color: Color(0xFF64748b)
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                issue.address,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748b),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, 
                              size: 14, 
                              color: Color(0xFF64748b)
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeAgo(issue.createdAt),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748b),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBadge(issue.status),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                height: 1,
                color: const Color(0xFF334155),
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
              Row(
                children: [
                  const Icon(Icons.thumb_up, 
                    size: 16, 
                    color: Color(0xFF6366f1)
                  ),
                  const SizedBox(width: 6),
                  Text(
                    issue.upvotes.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94a3b8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline, 
                    size: 16, 
                    color: Color(0xFF94a3b8)
                  ),
                  const SizedBox(width: 6),
                  Text(
                    issue.commentCount.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94a3b8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF6366f1).withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      issue.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6366f1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    Icons.visibility,
                    const Color(0xFF6366f1),
                    () => _viewIssue(issue),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    Icons.edit,
                    const Color(0xFFf59e0b),
                    () => _editIssue(issue),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    Icons.delete,
                    const Color(0xFFef4444),
                    () => _deleteIssue(issue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor, textColor;
    String icon;
    
    switch(status) {
      case 'Reported':
        bgColor = const Color(0xFFef4444).withOpacity(0.1);
        textColor = const Color(0xFFef4444);
        icon = '🔴';
        break;
      case 'Recognized':
        bgColor = const Color(0xFFf59e0b).withOpacity(0.1);
        textColor = const Color(0xFFf59e0b);
        icon = '🟡';
        break;
      case 'InWork':
      case 'In Progress':
        bgColor = const Color(0xFF3b82f6).withOpacity(0.1);
        textColor = const Color(0xFF3b82f6);
        icon = '🔵';
        break;
      case 'Done':
      case 'Resolved':
        bgColor = const Color(0xFF10b981).withOpacity(0.1);
        textColor = const Color(0xFF10b981);
        icon = '🟢';
        break;
      default:
        bgColor = const Color(0xFF64748b).withOpacity(0.1);
        textColor = const Color(0xFF64748b);
        icon = '⚪';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: textColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch(category.toLowerCase()) {
      case 'pothole': return '🕳️';
      case 'sewage': return '💧';
      case 'broken infrastructure': return '🚧';
      case 'broken': return '🚧';
      case 'cleanliness': return '🗑️';
      default: return '📍';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366f1).withOpacity(0.2),
                    const Color(0xFFec4899).withOpacity(0.2),
                  ],
                ),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 60,
                color: Color(0xFF6366f1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Reports Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFf1f5f9),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start reporting civic issues\nto make your city better',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94a3b8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewIssue(Issue issue) {
    // We need to fetch data as map for the detail screen
    FirebaseFirestore.instance.collection('issues').doc(issue.issueId).get().then((doc) {
        if(doc.exists && mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => IssueDetailScreen(
                    issueId: issue.issueId,
                    data: doc.data() as Map<String, dynamic>,
                ),
                ),
            );
        }
    });

  }

  void _editIssue(Issue issue) {
    if (issue.status != 'Reported') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit issue after it has been verified'),
          backgroundColor: Color(0xFFf59e0b),
        ),
      );
      return;
    }
    
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditIssueScreen(issue: issue),
        ),
    );
  }

  void _deleteIssue(Issue issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Issue?',
          style: TextStyle(
            color: Color(0xFFf1f5f9),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this issue?',
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
              await _performDelete(issue);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFef4444),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(Issue issue) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Deleting issue...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF1e293b),
        ),
      );
      
      if (issue.photoUrl.isNotEmpty) {
        try {
            await FirebaseStorage.instance.refFromURL(issue.photoUrl).delete();
        } catch (_) { 
            // Ignore storage errors if file doesn't exist
        }
      }
      
      // Delete comments
      QuerySnapshot comments = await FirebaseFirestore.instance
        .collection('comments')
        .where('issueId', isEqualTo: issue.issueId)
        .get();
      
      for (var doc in comments.docs) {
        await doc.reference.delete();
      }
      
      await FirebaseFirestore.instance
        .collection('issues')
        .doc(issue.issueId)
        .delete();
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text('✅ Issue deleted successfully'),
            backgroundColor: Color(0xFF10b981),
            ),
        );
      }
      
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text('Failed to delete issue. Please try again.'),
            backgroundColor: Color(0xFFef4444),
            ),
        );
      }
    }
  }
}
