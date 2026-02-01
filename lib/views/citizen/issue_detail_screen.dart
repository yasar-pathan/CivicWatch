import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class IssueDetailScreen extends StatefulWidget {
  final String issueId;
  final Map<String, dynamic> data;

  const IssueDetailScreen({
    super.key,
    required this.issueId,
    required this.data,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  final TextEditingController _commentController = TextEditingController();
  bool _isUpvoted = false;
  int _upvoteCount = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _upvoteCount = widget.data['upvotes'] ?? 0;
    _checkIfUpvoted();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _checkIfUpvoted() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final upvotedBy = List<String>.from(widget.data['upvotedBy'] ?? []);
    if (userId != null && upvotedBy.contains(userId)) {
      setState(() {
        _isUpvoted = true;
      });
    }
  }

  Future<void> _toggleUpvote() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef =
        FirebaseFirestore.instance.collection('issues').doc(widget.issueId);

    setState(() {
      if (_isUpvoted) {
        _isUpvoted = false;
        _upvoteCount--;
      } else {
        _isUpvoted = true;
        _upvoteCount++;
      }
    });

    try {
      if (_isUpvoted) {
        await docRef.update({
          'upvotes': FieldValue.increment(1),
          'upvotedBy': FieldValue.arrayUnion([userId]),
        });
      } else {
        await docRef.update({
          'upvotes': FieldValue.increment(-1),
          'upvotedBy': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        if (_isUpvoted) {
          _isUpvoted = false;
          _upvoteCount--;
        } else {
          _isUpvoted = true;
          _upvoteCount++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          // Animated gradient background (Same as Dashboard)
          Positioned.fill(
            child: CustomPaint(
              painter: GradientBackgroundPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(),
                        _buildInfoSection(),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 16),
          const Text(
            'ISSUE DETAILS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFf1f5f9),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Color(0xFF94a3b8),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final photoUrl = widget.data['photoUrl'];
    final category = widget.data['category'] ?? 'Issue';
    String emoji = '⚠️';
    if (category.toString().toLowerCase().contains('pothole')) emoji = '🕳️';
    else if (category.toString().toLowerCase().contains('sewage')) emoji = '💧';
    else if (category.toString().toLowerCase().contains('garbage')) emoji = '🗑️';
    else if (category.toString().toLowerCase().contains('broken')) emoji = '🚧';

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _fadeController,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut))),
        child: GestureDetector(
          onTap: () {
            if (photoUrl != null && photoUrl.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: photoUrl)));
            }
          },
          child: Container(
            height: 300,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'issue_image_${widget.issueId}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFF1e293b),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF1e293b),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 80)),
                            ),
                          ),
                  ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0f172a).withOpacity(0.8),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                // Zoom Icon Hint
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryBadge(),
          const SizedBox(height: 16),
          _buildTitleAndMeta(),
          const SizedBox(height: 24),
          _buildStatusSection(),
          const SizedBox(height: 24),
          _buildDescriptionCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildStatsCard(),
          const SizedBox(height: 24),
          // Comments Section Placeholder
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    final category = widget.data['category'] ?? 'General';
    String emoji = '⚠️';
    if (category.toString().toLowerCase().contains('pothole')) emoji = '🕳️';
    else if (category.toString().toLowerCase().contains('sewage')) emoji = '💧';
    else if (category.toString().toLowerCase().contains('broken')) emoji = '🚧';
    else if (category.toString().toLowerCase().contains('clean')) emoji = '🗑️';

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF6366f1).withOpacity(0.1),
          border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$emoji  $category',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6366f1),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndMeta() {
    // Format Time
    String timeStr = 'Just now';
    if (widget.data['createdAt'] != null) {
      final timestamp = widget.data['createdAt'] as Timestamp;
      final diff = DateTime.now().difference(timestamp.toDate());
      if (diff.inDays > 0) timeStr = '${diff.inDays}d ago';
      else if (diff.inHours > 0) timeStr = '${diff.inHours}h ago';
      else if (diff.inMinutes > 0) timeStr = '${diff.inMinutes}m ago';
    }

    final distance = widget.data['address'] ?? 'Unknown location';
    final userName = widget.data['userName'] ?? 'Anonymous';

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data['title'] ?? 'Untitled Issue',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFf1f5f9),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF64748b)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Posted by: $userName',
                  style: const TextStyle(color: Color(0xFF64748b), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
               const Icon(Icons.access_time, size: 16, color: Color(0xFF64748b)),
               const SizedBox(width: 6),
               Text(
                 timeStr,
                 style: const TextStyle(color: Color(0xFF64748b), fontSize: 13),
               ),
               const SizedBox(width: 16),
               const Icon(Icons.location_on, size: 16, color: Color(0xFFec4899)),
               const SizedBox(width: 6),
               Expanded(
                 child: Text(
                   distance,
                   style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = widget.data['status'] ?? 'Reported';
    Color statusColor = const Color(0xFFf59e0b); // Reported/Recognized
    if (status == 'Done' || status == 'Resolved') statusColor = const Color(0xFF10b981);
    else if (status == 'In Work') statusColor = const Color(0xFF3b82f6);
    else if (status == 'Rejected') statusColor = const Color(0xFFef4444);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              border: Border.all(color: statusColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toString().toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Timeline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Timeline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFf1f5f9),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTimelineItem('Reported', true, isFirst: true),
                _buildTimelineItem('Recognized', status != 'Reported'),
                _buildTimelineItem('In Work', status == 'In Work' || status == 'Done' || status == 'Resolved'),
                _buildTimelineItem('Resolved', status == 'Done' || status == 'Resolved', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, bool isActive, {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF10b981) : const Color(0xFF334155),
                border: Border.all(color: const Color(0xFF0f172a), width: 2),
              ),
              child: isActive ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isActive ? const Color(0xFF10b981).withOpacity(0.5) : const Color(0xFF334155),
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFf1f5f9) : const Color(0xFF64748b),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: const Interval(0.45, 1.0, curve: Curves.easeOut)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFf1f5f9),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.data['description'] ?? 'No description provided.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF94a3b8),
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
      child: Row(
        children: [
          Expanded(child: _buildActionButton(
            '👍', 
            _isUpvoted ? 'Upvoted' : 'Upvote', 
            '($_upvoteCount)',
            isActive: _isUpvoted,
            onTap: _toggleUpvote,
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton(
            '💬', 'Comment', 
            '(${widget.data['commentCount'] ?? 0})',
            onTap: () {}, // Focus on comment field
          )),
        ],
      ),
    );
  }

  Widget _buildActionButton(String emoji, String label, String subLabel, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(
            colors: [Color(0xFF6366f1), Color(0xFFec4899)],
          ) : null,
          color: isActive ? null : const Color(0xFF1e293b),
          border: Border.all(
            color: isActive ? const Color(0xFF6366f1) : const Color(0xFF334155),
            width: isActive ? 2 : 1, // Slightly thicker border when active if no gradient, but here gradient applies
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF94a3b8),
              ),
            ),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.white70 : const Color(0xFF64748b),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6366f1).withOpacity(0.05),
          border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('📊', 'Priority', 'Normal'),
            _buildContainerLine(),
            _buildStatItem('👁️', 'Views', '24'),
            _buildContainerLine(),
            _buildStatItem('👥', 'Impact', 'Local'),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerLine() {
    return Container(height: 30, width: 1, color: const Color(0xFF334155));
  }

  Widget _buildStatItem(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366f1), Color(0xFFec4899)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748b),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCommentsSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFf1f5f9),
          ),
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No comments yet.',
            style: TextStyle(color: Color(0xFF64748b)),
          ),
        ),
      ],
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
           Center(
             child: InteractiveViewer(
               child: Image.network(imageUrl),
             ),
           ),
           Positioned(
             top: MediaQuery.of(context).padding.top + 20,
             right: 20,
             child: GestureDetector(
               onTap: () => Navigator.pop(context),
               child: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.2),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.close, color: Colors.white),
               ),
             ),
           ),
        ],
      ),
    );
  }
}

// Custom painter (Copy from Dashboard for consistency)
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
