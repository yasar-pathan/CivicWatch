import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_watch/models/issue_model.dart';
import 'package:civic_watch/views/citizen/issue_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with SingleTickerProviderStateMixin {
  late GoogleMapController _mapController;
  late AnimationController _animationController;
  Set<Marker> _markers = {};
  Issue? _selectedIssue;
  bool _isLoading = false;
  
  // Default camera position (user's city)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.0225, 72.5714), // Ahmedabad coordinates
    zoom: 12.0,
  );
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), // Dashboard timing
        vsync: this,
    );
    _loadIssues();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dashboard background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b), // Dashboard card color
        elevation: 0,
        title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(
                Icons.map,
                color: Color(0xFF6366f1), // Dashboard primary
                size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
                'MAP VIEW',
                style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFf1f5f9), // Dashboard text primary
                letterSpacing: 0.5,
                ),
            ),
            const SizedBox(width: 8),
            const Icon(
                Icons.search,
                color: Color(0xFF94a3b8), // Dashboard secondary text
                size: 20,
            ),
            ],
        ),
        actions: [
            IconButton(
            icon: const Icon(Icons.layers, color: Color(0xFF94a3b8)),
            onPressed: () {
                // _showMapLayers(); // Optional implementation
            },
            ),
            IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF6366f1)),
            onPressed: () => _goToCurrentLocation(),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _setMapStyle(); // Apply dark theme to map
            },
            markers: _markers,
            onTap: (_) {
              // Dismiss selected issue sheet
              setState(() => _selectedIssue = null);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Custom button in header
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            // Dark mode map style
            mapType: MapType.normal,
          ),
          
          // Legend overlay (top-right)
          Positioned(
            top: 16,
            right: 16,
            child: _buildLegendCard(),
          ),
          
          // Selected issue preview (bottom sheet)
          if (_selectedIssue != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildIssuePreviewSheet(_selectedIssue!),
            ),
          
          // Floating action buttons (optional)
          Positioned(
            bottom: _selectedIssue != null ? 220 : 20,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingButton(
                  Icons.filter_list,
                  () => _showFilterSheet(),
                ),
                const SizedBox(height: 12),
                _buildFloatingButton(
                  Icons.refresh,
                  () => _refreshIssues(),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))),
        ],
      ),
    );
  }

  // Apply dark map theme
  void _setMapStyle() async {
    String style = '''
    [
        {
        "elementType": "geometry",
        "stylers": [{"color": "#1e293b"}]
        },
        {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#94a3b8"}]
        },
        {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#0f172a"}]
        },
        {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#334155"}]
        },
        {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#0f172a"}]
        }
    ]
    ''';
    
    _mapController.setMapStyle(style);
  }

  Widget _buildLegendCard() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: const Color(0xFF1e293b), // Dashboard card color
        border: Border.all(color: const Color(0xFF334155)), // Dashboard border
        borderRadius: BorderRadius.circular(16), // Dashboard radius
        boxShadow: [
            BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
            ),
        ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            // Title
            const Text(
            'Color Coded by Status:',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFf1f5f9), // Dashboard text primary
                letterSpacing: 0.3,
            ),
            ),
            const SizedBox(height: 12),
            // Status indicators (EXACT dashboard status badge colors)
            _buildLegendItem('🔴', 'Reported', const Color(0xFFef4444)),
            const SizedBox(height: 8),
            _buildLegendItem('🟡', 'Recognized', const Color(0xFFf59e0b)),
            const SizedBox(height: 8),
            _buildLegendItem('🔵', 'In Work', const Color(0xFF3b82f6)),
            const SizedBox(height: 8),
            _buildLegendItem('🟢', 'Done', const Color(0xFF10b981)),
        ],
        ),
    );
  }

  Widget _buildLegendItem(String icon, String label, Color color) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            ),
        ),
        const SizedBox(width: 8),
        Text(
            label,
            style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF94a3b8), // Dashboard secondary text
            fontWeight: FontWeight.w500,
            ),
        ),
        ],
    );
  }

  Future<void> _loadIssues() async {
    try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('issues')
            .get();
        
        Set<Marker> markers = {};
        
        for (var doc in snapshot.docs) {
            Issue issue = Issue.fromFirestore(doc);
            
            // Get marker color based on status (EXACT dashboard colors)
            BitmapDescriptor markerIcon = await _getMarkerIcon(issue.status);
            
            markers.add(
            Marker(
                markerId: MarkerId(issue.issueId),
                position: LatLng(issue.latitude, issue.longitude),
                icon: markerIcon,
                onTap: () {
                setState(() {
                    _selectedIssue = issue;
                });
                // Animate camera to marker
                _mapController.animateCamera(
                    CameraUpdate.newLatLng(
                    LatLng(issue.latitude, issue.longitude),
                    ),
                );
                },
                infoWindow: InfoWindow(
                title: issue.title,
                snippet: issue.status,
                ),
            ),
            );
        }
        
        setState(() {
            _markers = markers;
        });
    } catch (e) {
        debugPrint('Error loading issues: $e');
    }
  }

  // Create custom colored marker icons
  Future<BitmapDescriptor> _getMarkerIcon(String status) async {
    Color color;
    
    switch(status) {
        case 'Reported':
        color = const Color(0xFFef4444); // Dashboard red
        break;
        case 'Recognized':
        color = const Color(0xFFf59e0b); // Dashboard amber
        break;
        case 'In Work':
        color = const Color(0xFF3b82f6); // Dashboard blue
        break;
        case 'Done':
        color = const Color(0xFF10b981); // Dashboard green
        break;
        default:
        color = const Color(0xFF64748b); // Dashboard muted
    }
    
    // Use default marker with hue (or create custom)
    double hue = _colorToHue(color);
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  // Convert Color to Hue for marker
  double _colorToHue(Color color) {
    if (color.value == const Color(0xFFef4444).value) return 0.0; // Red
    if (color.value == const Color(0xFFf59e0b).value) return 45.0; // Amber
    if (color.value == const Color(0xFF3b82f6).value) return 220.0; // Blue
    if (color.value == const Color(0xFF10b981).value) return 140.0; // Green
    return 0.0;
  }

  Widget _buildIssuePreviewSheet(Issue issue) {
    return SlideTransition(
        position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
        ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
        )),
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF1e293b), // Dashboard card color
            border: const Border(
            top: BorderSide(color: Color(0xFF334155), width: 1),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, -4),
            ),
            ],
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Drag handle
            Center(
                child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF334155), // Dashboard border
                    borderRadius: BorderRadius.circular(2),
                ),
                ),
            ),
            const SizedBox(height: 16),
            
            // Header: "Selected Issue"
            const Text(
                'Selected Issue:',
                style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748b), // Dashboard muted
                letterSpacing: 0.5,
                ),
            ),
            const SizedBox(height: 12),
            
            // Issue content (EXACT dashboard card layout)
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Image
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
                        ? Image.network(issue.photoUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Center(
                            child: Text(
                            _getCategoryEmoji(issue.category),
                            style: const TextStyle(fontSize: 32),
                            ),
                        ))
                        : Center(
                            child: Text(
                            _getCategoryEmoji(issue.category),
                            style: const TextStyle(fontSize: 32),
                            ),
                        ),
                    ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Title
                        Text(
                        issue.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFf1f5f9), // Dashboard text primary
                            height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // Location
                        Row(
                        children: [
                            const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Color(0xFF64748b),
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
                        const SizedBox(height: 8),
                        
                        // Status badge (EXACT dashboard status badge)
                        _buildStatusBadge(issue.status),
                    ],
                    ),
                ),
                ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats row (same as dashboard)
            Row(
                children: [
                const Icon(Icons.thumb_up, size: 16, color: Color(0xFF6366f1)),
                const SizedBox(width: 6),
                Text(
                    '${issue.upvotes}',
                    style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94a3b8),
                    fontWeight: FontWeight.w500,
                    ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF94a3b8)),
                const SizedBox(width: 6),
                Text(
                    '${issue.commentCount}',
                    style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94a3b8),
                    fontWeight: FontWeight.w500,
                    ),
                ),
                ],
            ),
            
            const SizedBox(height: 16),
            
            // View Details button
            GestureDetector(
                onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => IssueDetailScreen(
                        issueId: issue.issueId,
                        data: {
                          'title': issue.title,
                          'description': issue.description,
                          'photoUrl': issue.photoUrl,
                          'category': issue.category,
                          'address': issue.address,
                          'latitude': issue.latitude,
                          'longitude': issue.longitude,
                          'status': issue.status,
                          'upvotes': issue.upvotes,
                          'commentCount': issue.commentCount,
                          'userId': issue.userId,
                          'createdAt': Timestamp.fromDate(issue.createdAt),
                        },
                    ),
                    ),
                );
                },
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                    colors: [Color(0xFF6366f1), Color(0xFFec4899)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF6366f1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                    ),
                    ],
                ),
                child: const Text(
                    'View Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    ),
                ),
                ),
            ),
            
            const SizedBox(height: 8),
            ],
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
        case 'In Work':
        bgColor = const Color(0xFF3b82f6).withOpacity(0.1);
        textColor = const Color(0xFF3b82f6);
        icon = '🔵';
        break;
        case 'Done':
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

  Widget _buildFloatingButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
            color: const Color(0xFF1e293b), // Dashboard card color
            border: Border.all(color: const Color(0xFF334155)),
            shape: BoxShape.circle,
            boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
            ),
            ],
        ),
        child: Icon(
            icon,
            color: const Color(0xFF6366f1), // Dashboard primary
            size: 24,
        ),
        ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1e293b), // Dashboard card color
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            const Text(
                'Filter Issues on Map',
                style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFf1f5f9), // Dashboard text
                ),
            ),
            const SizedBox(height: 20),
            
            // Filter by status
            const Text(
                'SHOW STATUS',
                style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748b),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                ),
            ),
            const SizedBox(height: 12),
            
            _buildFilterCheckbox('🔴 Reported', true),
            _buildFilterCheckbox('🟡 Recognized', true),
            _buildFilterCheckbox('🔵 In Work', true),
            _buildFilterCheckbox('🟢 Done', false),
            
            const SizedBox(height: 20),
            
            // Filter by category
            const Text(
                'CATEGORY',
                style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748b),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                ),
            ),
            const SizedBox(height: 12),
            
            _buildFilterCheckbox('🕳️ Pothole', true),
            _buildFilterCheckbox('💧 Sewage', true),
            _buildFilterCheckbox('🚧 Broken', true),
            _buildFilterCheckbox('🗑️ Cleanliness', true),
            
            const SizedBox(height: 24),
            
            // Apply button
            GestureDetector(
                onTap: () {
                Navigator.pop(context);
                // _applyFilters(); // Implement filter logic
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Filters Applied (Demo)'),
                        backgroundColor: Color(0xFF6366f1),
                    )
                );
                },
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                    colors: [Color(0xFF6366f1), Color(0xFFec4899)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                    'Apply Filters',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    ),
                ),
                ),
            ),
            ],
        ),
        ),
    );
  }

  Widget _buildFilterCheckbox(String label, bool value) {
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
        color: value 
            ? const Color(0xFF6366f1).withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        border: Border.all(
            color: value 
            ? const Color(0xFF6366f1).withOpacity(0.3)
            : const Color(0xFF334155),
        ),
        borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        children: [
            Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value ? const Color(0xFF6366f1) : const Color(0xFF94a3b8),
            size: 20,
            ),
            const SizedBox(width: 12),
            Text(
            label,
            style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFf1f5f9),
            ),
            ),
        ],
        ),
    );
  }

  void _goToCurrentLocation() async {
    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
            }
            return;
        }
    }
    
    if (permission == LocationPermission.deniedForever) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied')));
        }
        return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
    );
    
    // Animate camera to current location
    _mapController.animateCamera(
        CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
        ),
    );
    
    // Show snackbar
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text('Centered on your location'),
            backgroundColor: Color(0xFF10b981), // Dashboard success
            duration: Duration(seconds: 2),
            ),
        );
    }
  }

  void _refreshIssues() async {
    setState(() => _isLoading = true);
    
    await _loadIssues();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text('✅ Map refreshed'),
            backgroundColor: Color(0xFF10b981),
            duration: Duration(seconds: 1),
            ),
        );
    }
  }

  String _getCategoryEmoji(String category) {
    switch(category.toLowerCase()) {
        case 'pothole': return '🕳️';
        case 'sewage': return '💧';
        case 'broken': return '🚧';
        case 'cleanliness': return '🗑️';
        default: return '📍';
    }
  }
}
