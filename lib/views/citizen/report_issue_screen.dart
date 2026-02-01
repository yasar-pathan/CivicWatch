import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportIssueScreen extends StatefulWidget {
  final bool isTab;
  const ReportIssueScreen({super.key, this.isTab = false});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // State
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;
  String _locationText = 'No location captured';
  bool _fetchingLocation = false;
  bool _locationError = false;
  String? _selectedCategory;
  bool _isSubmitting = false;
  
  // Validation
  bool _titleError = false;
  bool _descriptionError = false;
  
  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _categories = [
    'Pothole',
    'Sewage',
    'Broken Infrastructure',
    'Cleanliness',
  ];

  @override
  void initState() {
    super.initState();
    _playAnimations();
  }
  
  void _playAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Camera/Gallery Implementation
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        _getCurrentLocation();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6366f1)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6366f1)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Location Implementation
  Future<void> _getCurrentLocation() async {
    setState(() {
      _fetchingLocation = true;
      _locationError = false;
      _locationText = 'Fetching location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Attempt to request service enabling (Android specific often, but good to try or just wait)
        // Some plugins allow opening settings
        bool opened = await Geolocator.openLocationSettings();
        if (opened) {
             // Wait for user to toggle? It's async. We might just fail and ask them to retry.
        }
        
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
         if (!serviceEnabled) {
             setState(() {
                _locationText = 'Location services disabled. Tap to retry.';
                _locationError = true;
                _fetchingLocation = false;
            });
            return;
         }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = 'Location permission denied';
            _locationError = true;
            _fetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission permanent denied';
          _locationError = true;
          _fetchingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';
          if (place.street != null && place.street!.isNotEmpty) {
            address += '${place.street}, ';
          }
          if (place.locality != null) {
            address += place.locality!;
          }
          
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _locationText = address;
              _fetchingLocation = false;
            });
          }
        } else {
           if (mounted) {
            setState(() {
              _currentPosition = position;
              _locationText = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
              _fetchingLocation = false;
            });
          }
        }
      } catch (e) {
        // Fallback if geocoding fails
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _locationText = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
            _fetchingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to get location';
          _locationError = true;
          _fetchingLocation = false;
        });
      }
    }
  }

  // Submission Implementation
  Future<String> _uploadImage(File image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('issues/$fileName');
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
         throw 'Storage bucket or file not found. Please check Firebase Console.';
      } else if (e.code == 'unauthorized') {
         throw 'Permission denied. Check Storage Rules.';
      } else {
         // The 404 error from the log often comes as an 'unknown' or specific java exception wrapped
         // We'll throw the message which might help.
         throw 'Upload failed: ${e.message}. Ensure Storage is enabled in Console.';
      }
    } catch (e) {
      throw 'Upload failed: $e';
    }
  }

  Future<void> _submitIssue() async {
    // Validation
    if (_imageFile == null) {
      _showError('Please upload a photo');
      return;
    }
    
    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = true);
      return;
    } else {
      setState(() => _titleError = false);
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _descriptionError = true);
      return;
    } else {
      setState(() => _descriptionError = false);
    }
    
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }
    
    if (_currentPosition == null) {
      _showError('Location not available');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Upload image to Firebase Storage
      String photoUrl = await _uploadImage(_imageFile!);
      
      // Fetch user details for City
      String city = 'Unknown';
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data.containsKey('City')) {
            city = data['City'];
          } else if (data.containsKey('city')) {
             city = data['city'];
          }
        }
      } catch (e) {
        debugPrint('Error fetching user city: $e');
      }
      
      // Create issue in Firestore
      await FirebaseFirestore.instance.collection('issues').add({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'photoUrl': photoUrl, // Keeping this as it's useful, though not explicitly in the user's list from text, they said "data should be stored... latitude longitude... detected" and "tell me if u need anything". I will keep photoUrl as it's essential for the app.
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'address': _locationText,
        'City': city,
        'status': 'Reported',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        
        // Extended fields for local functioning (optional but good practice to keep until told to remove)
        'upvotes': 0,
        'commentCount': 0,
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Issue reported successfully!'),
          backgroundColor: Color(0xFF10b981),
        ),
      );

      // Navigate back or show success
      if (widget.isTab) {
          // Clear form instead of popping?
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
              _imageFile = null;
              _selectedCategory = null;
              _currentPosition = null;
              _locationText = 'No location captured';
          });
          // Maybe show a dialog
      } else {
         Navigator.pop(context);
      }
      
    } catch (e) {
      _showError('Failed to submit issue. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFef4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _buildPhotoUploadSection(),
                        const SizedBox(height: 24),
                        _buildLocationSection(),
                        const SizedBox(height: 24),
                        _buildFormFields(),
                        const SizedBox(height: 24),
                        _buildCategorySection(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Loading Overlay
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF10b981),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: widget.isTab ? 20 : 8,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
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
          if (!widget.isTab)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFf1f5f9)),
              onPressed: () => Navigator.pop(context),
            ),
          if (!widget.isTab) const SizedBox(width: 8),
          const Text(
            'REPORT ISSUE',
            style: TextStyle(
              color: Color(0xFFf1f5f9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _fadeController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFffffff).withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: _imageFile != null
                ? Border.all(
                    color: const Color(0xFF334155),
                    style: BorderStyle.solid,
                  )
                : null,
          ),
          child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Text(
                          'Tap to Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : CustomPaint(
                painter: DashedBorderPainter(),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Color(0xFF6366f1),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tap to Capture Photo',
                      style: TextStyle(
                        color: Color(0xFFf1f5f9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'or',
                      style: TextStyle(
                        color: Color(0xFF94a3b8),
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        color: Color(0xFF94a3b8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    Color bgColor = _locationError 
        ? const Color(0xFFef4444).withOpacity(0.1) 
        : const Color(0xFF10b981).withOpacity(0.1);
    Color borderColor = _locationError
        ? const Color(0xFFef4444).withOpacity(0.2)
        : const Color(0xFF10b981).withOpacity(0.2);
    Color textColor = _locationError
        ? const Color(0xFFef4444)
        : const Color(0xFF10b981);
    IconData icon = _locationError ? Icons.warning_amber_rounded : Icons.check_circle_outline;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            if (_fetchingLocation)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            else
              Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _locationText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!_fetchingLocation)
              IconButton(
                icon: Icon(
                    _locationError ? Icons.refresh : Icons.refresh, 
                    size: 20
                ),
                color: textColor,
                onPressed: _getCurrentLocation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Issue Title
        const Text(
          'Issue Title *',
          style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Color(0xFFf1f5f9)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFffffff).withOpacity(0.05),
            hintText: 'Enter issue title',
            hintStyle: const TextStyle(color: Color(0xFF64748b)),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _titleError ? const Color(0xFFef4444) : const Color(0xFF334155),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366f1)),
            ),
          ),
          onChanged: (_) {
            if (_titleError) setState(() => _titleError = false);
          },
        ),
        if (_titleError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'This field is required',
              style: TextStyle(color: Color(0xFFef4444), fontSize: 12),
            ),
          ),
        
        const SizedBox(height: 24),

        // Description
        const Text(
          'Description *',
          style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          style: const TextStyle(color: Color(0xFFf1f5f9)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFffffff).withOpacity(0.05),
            hintText: 'Describe the issue in detail',
            hintStyle: const TextStyle(color: Color(0xFF64748b)),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _descriptionError ? const Color(0xFFef4444) : const Color(0xFF334155),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366f1)),
            ),
          ),
          onChanged: (_) {
            if (_descriptionError) setState(() => _descriptionError = false);
          },
        ),
        if (_descriptionError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'This field is required',
              style: TextStyle(color: Color(0xFFef4444), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category:',
          style: TextStyle(
            color: Color(0xFFf1f5f9),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? null : const Color(0xFF1e293b),
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6366f1).withOpacity(0.2),
                            const Color(0xFFec4899).withOpacity(0.1),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366f1) : const Color(0xFF334155),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFf1f5f9) : const Color(0xFF94a3b8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: GestureDetector(
        onTap: _submitIssue,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10b981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10b981).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'SUBMIT ISSUE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94a3b8).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final ui.Path dashedPath = ui.Path();
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
