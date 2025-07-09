import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart'; // Required for unique likes/views

import 'firebase_options.dart'; // Make sure this file exists

// --- DATA MODELS ---

class PortfolioData {
  final String name, position, contactInfo, careerSummary, pictureUrl;
  final String mobile, address;
  final List<Map<String, String>> qualifications, clinicalExperience, expertise, publications, awards, books, editorialRoles, academicActivities;

  PortfolioData({
    this.name = "Prof. Dr. Md. Abdus Shakoor",
    this.position = "Chairman, Physical Medicine & Rehabilitation, BSMMU",
    this.contactInfo = "Email: dmashakoor04@yahoo.com, shakoorma@bsmmu.edu.bd",
    this.mobile = "+880 1819 410080",
    this.address = "Flat # 3/5A, House no- 05, Road # 32, Dhanmondi R/A, Dhaka-1209",
    this.careerSummary = "My total clinical experience is thirty-three years...",
    this.pictureUrl = 'assets/icon/prof-shakoor.png',
    this.qualifications = const [], this.clinicalExperience = const [], this.expertise = const [],
    this.publications = const [], this.awards = const [], this.books = const [],
    this.editorialRoles = const [], this.academicActivities = const [],
  });

  factory PortfolioData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PortfolioData(
      name: data['name'] ?? 'Not Set',
      position: data['position'] ?? 'Not Set',
      contactInfo: data['contactInfo'] ?? 'Not Set',
      mobile: data['mobile'] ?? 'Not Set',
      address: data['address'] ?? 'Not Set',
      careerSummary: data['careerSummary'] ?? 'Not Set',
      pictureUrl: data['pictureUrl'] ?? 'assets/icon/prof-shakoor.png',
      qualifications: List<Map<String, String>>.from((data['qualifications'] ?? []).map((item) => Map<String, String>.from(item))),
      clinicalExperience: List<Map<String, String>>.from((data['clinicalExperience'] ?? []).map((item) => Map<String, String>.from(item))),
      expertise: List<Map<String, String>>.from((data['expertise'] ?? []).map((item) => Map<String, String>.from(item))),
      publications: List<Map<String, String>>.from((data['publications'] ?? []).map((item) => Map<String, String>.from(item))),
      awards: List<Map<String, String>>.from((data['awards'] ?? []).map((item) => Map<String, String>.from(item))),
      books: List<Map<String, String>>.from((data['books'] ?? []).map((item) => Map<String, String>.from(item))),
      editorialRoles: List<Map<String, String>>.from((data['editorialRoles'] ?? []).map((item) => Map<String, String>.from(item))),
      academicActivities: List<Map<String, String>>.from((data['academicActivities'] ?? []).map((item) => Map<String, String>.from(item))),
    );
  }
}

class BlogPost {
  final String id, title, content, imageUrl;
  final String category;
  final Timestamp publishedDate;
  int likes, views;

  BlogPost({
    required this.id, required this.title, required this.content, required this.imageUrl,
    required this.publishedDate, this.likes = 0, this.views = 0, this.category = "Web Design",
  });

  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BlogPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/600x400/E0E7FF/4F46E5?text=Article',
      publishedDate: data['publishedDate'] ?? Timestamp.now(),
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      category: data['category'] ?? 'General',
    );
  }
}

class BlogComment {
  final String username, text;
  final Timestamp timestamp;

  BlogComment({required this.username, required this.text, required this.timestamp});

  factory BlogComment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BlogComment(
      username: data['username'] ?? 'Anonymous',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

// --- MAIN APP & HOME PAGE ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(PortfolioAndBlogApp());
}

class PortfolioAndBlogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prof. Dr. Md. Abdus Shakoor',
      theme: ThemeData(
        primaryColor: const Color(0xFF4F46E5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, GlobalKey> _sectionKeys = {
    "Home": GlobalKey(), "Experience": GlobalKey(), "Expertise": GlobalKey(),
    "Research": GlobalKey(), "Books": GlobalKey(), "Awards": GlobalKey(),
    "Activities": GlobalKey(), "Blog": GlobalKey(), "Contact": GlobalKey(),
  };

  final _contactFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSendingMessage = false;

  void _scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(key.currentContext!,
        duration: const Duration(seconds: 1), curve: Curves.easeInOut);
  }

  Future<void> _sendMessage() async {
    if (_contactFormKey.currentState!.validate()) {
      setState(() => _isSendingMessage = true);
      try {
        await FirebaseFirestore.instance.collection('messages').add({
          'name': _nameController.text,
          'email': _emailController.text,
          'message': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!'), backgroundColor: Colors.green),
        );
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  ImageProvider _getProfileImage(String url) {
    if (url.startsWith('http')) {
      return NetworkImage(url);
    } else {
      return AssetImage(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prof. Dr. Abdus Shakoor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isDesktop)
                      Row(
                        children: [
                          ..._sectionKeys.entries.where((e) => e.key != "Contact").map((e) => _navButton(e.key, e.value)).toList(),
                          const SizedBox(width: 20),
                          ElevatedButton(onPressed: () => _scrollToSection(_sectionKeys["Contact"]!), child: const Text("Get in Touch")),
                          const SizedBox(width: 10),
                          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminLoginPage())), child: const Text("Login")),
                        ],
                      )
                    else
                      Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openEndDrawer())),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      endDrawer: isDesktop ? null : _buildMobileDrawer(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('portfolio').doc('main_data').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Portfolio data not available. Please log in as admin to update the content.", textAlign: TextAlign.center)));

          final data = PortfolioData.fromFirestore(snapshot.data!);
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(key: _sectionKeys["Home"], child: _buildHeroSection(context, data)),
                Container(key: _sectionKeys["Experience"], child: _buildQualificationsSection(context, data)),
                Container(key: _sectionKeys["Expertise"], child: _buildSection("Areas of Expertise", _buildExpertiseGrid(context, data.expertise))),
                Container(key: _sectionKeys["Research"], child: _buildResearchSection(context, data.publications)),
                Container(key: _sectionKeys["Books"], child: _buildBooksAndEditorialSection(context, data)),
                Container(key: _sectionKeys["Awards"], child: _buildSection("Special Achievements & Awards", _buildAwardsWidgets(context, data.awards))),
                Container(key: _sectionKeys["Activities"], child: _buildSection("Other Academic Activities", _buildActivitiesWidgets(data.academicActivities))),
                Container(key: _sectionKeys["Blog"], child: _buildBlogSection(data.name)),
                Container(key: _sectionKeys["Contact"], child: _buildContactSection(context, data)),
                _buildFooter(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _navButton(String title, GlobalKey key) => TextButton(
    onPressed: () => _scrollToSection(key),
    child: Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
  );

  Drawer _buildMobileDrawer() => Drawer(
    child: ListView(
      children: [
        ..._sectionKeys.entries.map((e) => _drawerItem(e.key, e.value)).toList(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.login), title: const Text("Admin Login"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdminLoginPage()));
          },
        )
      ],
    ),
  );

  ListTile _drawerItem(String title, GlobalKey key) => ListTile(
    title: Text(title),
    onTap: () {
      _scrollToSection(key);
      Navigator.pop(context);
    },
  );

  Widget _buildHeroSection(BuildContext context, PortfolioData data) => Container(
    color: const Color(0xFFF0F5FF),
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: MediaQuery.of(context).size.width < 900
            ? _buildMobileHero(data)
            : _buildDesktopHero(data),
      ),
    ),
  );

  Widget _buildDesktopHero(PortfolioData data) => Row(
    children: [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.name, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 16),
            Text(data.position, style: const TextStyle(fontSize: 18, color: Color(0xFF4B5563))),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => _scrollToSection(_sectionKeys["Contact"]!), child: const Text("Contact Me")),
            const SizedBox(height: 40),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Career Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(data.careerSummary, style: const TextStyle(color: Color(0xFF4B5563), height: 1.6)),
                    const SizedBox(height: 12),
                    Text(data.contactInfo, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      const SizedBox(width: 60),
      Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF818CF8), Color(0xFFC4B5FD)])
          ),
          child: CircleAvatar(
            radius: 150,
            backgroundColor: Colors.white,
            backgroundImage: _getProfileImage(data.pictureUrl),
            onBackgroundImageError: (e, s) {},
          ),
        ),
      ),
    ],
  );

  Widget _buildMobileHero(PortfolioData data) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF818CF8), Color(0xFFC4B5FD)])
        ),
        child: CircleAvatar(
          radius: 120,
          backgroundColor: Colors.white,
          backgroundImage: _getProfileImage(data.pictureUrl),
          onBackgroundImageError: (e, s) {},
        ),
      ),
      const SizedBox(height: 30),
      Text(data.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      const SizedBox(height: 12),
      Text(data.position, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Color(0xFF4B5563))),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Career Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(data.careerSummary, style: const TextStyle(color: Color(0xFF4B5563), height: 1.6)),
              const SizedBox(height: 12),
              Text(data.contactInfo, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      )
    ],
  );

  Widget _buildSection(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
    width: double.infinity,
    color: (title.contains("Qualifications") || title.contains("Books")) ? const Color(0xFFF9FAFB) : Colors.white,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 10),
            Container(height: 4, width: 80, color: const Color(0xFF4F46E5)),
            const SizedBox(height: 50),
            if (children.isEmpty) const Text("No data available for this section.") else ...children,
          ],
        ),
      ),
    ),
  );

  Widget _buildQualificationsSection(BuildContext context, PortfolioData data) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;
    var qualificationsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Qualifications & Degrees", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...data.qualifications.map((e) => _buildInfoCard(e['title']!, e['subtitle']!, Icons.check_circle_outline)).toList()
      ],
    );
    var experienceColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Clinical & Teaching Experiences", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...data.clinicalExperience.asMap().entries.map((entry) => _buildTimelineTile(entry.value['title']!, entry.value['subtitle']!, entry.key == 0, entry.key == data.clinicalExperience.length - 1)).toList(),
      ],
    );
    var content = isSmallScreen
        ? Column(children: [qualificationsColumn, const SizedBox(height: 40), experienceColumn])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 2, child: qualificationsColumn),
      const SizedBox(width: 40),
      Expanded(flex: 3, child: experienceColumn),
    ]);
    return _buildSection("Qualifications & Clinical Experience", [content]);
  }

  Widget _buildTimelineTile(String title, String subtitle, bool isFirst, bool isLast) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isFirst ? 4 : 0),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? Theme.of(context).primaryColor : Colors.transparent,
                    border: Border.all(color: isFirst ? Theme.of(context).primaryColor : Colors.grey[400]!, width: 2)),
                child: isFirst
                    ? const Icon(Icons.star, color: Colors.white, size: 12)
                    : Container(height: 12, width: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.grey[400]!, width: 2))),
              ),
              Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : Colors.grey[300])),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[700], height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _buildExpertiseGrid(BuildContext context, List<Map<String, String>> expertise) {
    if (expertise.isEmpty) return [const SizedBox.shrink()];

    final screenWidth = MediaQuery.of(context).size.width;

    return [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 1200 ? 4 : (screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 1)),
          childAspectRatio: 0.9,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: expertise.length,
        itemBuilder: (context, index) {
          final item = expertise[index];
          final icons = [Icons.local_hospital_outlined, Icons.school_outlined, Icons.article_outlined, Icons.group_work_outlined];
          return _buildExpertiseCard(item['title']!, item['subtitle']!, icons[index % icons.length]);
        },
      )
    ];
  }

  Widget _buildExpertiseCard(String title, String subtitle, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(child: Text(subtitle, style: TextStyle(color: Colors.grey[600], height: 1.5))),
        ],
      ),
    ),
  );

  Widget _buildResearchSection(BuildContext context, List<Map<String, String>> publications) => _buildSection("Research Highlights", [
    GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
        childAspectRatio: 2.5, crossAxisSpacing: 20, mainAxisSpacing: 20,
      ),
      itemCount: publications.length > 3 ? 3 : publications.length,
      itemBuilder: (context, index) => _buildPublicationCard(publications[index]['title']!, publications[index]['subtitle']!),
    ),
    const SizedBox(height: 30),
    ExpansionTile(
      title: Text("View Full Research Works (All ${publications.length} Articles)"),
      children: publications.map((pub) => _buildPublicationListItem(pub['title']!, pub['subtitle']!)).toList(),
    )
  ]);

  Widget _buildPublicationCard(String title, String subtitle) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Expanded(child: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );

  Widget _buildPublicationListItem(String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.article_outlined, color: Color(0xFF4F46E5), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildBooksAndEditorialSection(BuildContext context, PortfolioData data) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    var booksColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Books Written", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(height: 3, width: 40, color: Theme.of(context).primaryColor),
        const SizedBox(height: 24),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: data.books.map((book) {
            return SizedBox(
              width: isSmallScreen ? double.infinity : (1100 / 2) - 20,
              child: _buildBookCard(book['title']!, book['published'] ?? '', book['isbn'] ?? ''),
            );
          }).toList(),
        )
      ],
    );

    var editorialColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Editorial Roles", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(height: 3, width: 40, color: Theme.of(context).primaryColor),
        const SizedBox(height: 24),
        Column(
          children: data.editorialRoles.map((e) => _buildInfoCard(e['title']!, e['subtitle']!, Icons.article_outlined)).toList(),
        )
      ],
    );
    return _buildSection("Books & Editorial Roles", [
      isSmallScreen
          ? Column(children: [booksColumn, const SizedBox(height: 50), editorialColumn])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: booksColumn),
        const SizedBox(width: 50),
        Expanded(flex: 2, child: editorialColumn),
      ])
    ]);
  }

  Widget _buildBookCard(String title, String published, String isbn) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (published.isNotEmpty) Text(published, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          if (isbn.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(isbn, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ]
        ],
      ),
    ),
  );

  List<Widget> _buildAwardsWidgets(BuildContext context, List<Map<String, String>> awards) => [
    GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
        childAspectRatio: 1.8, crossAxisSpacing: 20, mainAxisSpacing: 20,
      ),
      itemCount: awards.length,
      itemBuilder: (context, index) => _buildAwardCard(awards[index]['title']!, awards[index]['subtitle']!, awards[index]['year']!),
    )
  ];

  List<Widget> _buildActivitiesWidgets(List<Map<String, String>> activities) =>
      activities.map((e) => _buildInfoCard(e['title']!, e['subtitle']!, Icons.workspaces_outline)).toList();

  Widget _buildAwardCard(String title, String subtitle, String year) => Card(
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.08),
    clipBehavior: Clip.none,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827))),
              const SizedBox(height: 12),
              Text(subtitle, style: TextStyle(color: Colors.grey[700], height: 1.5)),
            ],
          ),
        ),
        Positioned(
          top: 12, right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]),
            child: Text(year, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    ),
  );

  Widget _buildInfoCard(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4F46E5), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildBlogSection(String authorName) => Container(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
    color: Colors.white,
    child: Column(
      children: [
        const Text('My Blog & Articles', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(height: 10),
        Container(height: 4, width: 80, color: const Color(0xFF4F46E5)),
        const SizedBox(height: 50),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').orderBy('publishedDate', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Something went wrong!');
            if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No blog posts yet.");

            final posts = snapshot.data!.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
            final screenWidth = MediaQuery.of(context).size.width;
            int crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 0.85,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) => _blogCard(context, posts[index], authorName),
              ),
            );
          },
        )
      ],
    ),
  );

  Widget _blogCard(BuildContext context, BlogPost post, String authorName) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlogDetailsPage(postId: post.id))),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              post.imageUrl, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400], size: 40)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Text('Published on ${DateFormat.yMMMMd().format(post.publishedDate.toDate())}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), child: Icon(Icons.person, size: 14, color: Theme.of(context).primaryColor)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(authorName, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildContactSection(BuildContext context, PortfolioData data) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    final Widget infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Get in Touch", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text("Feel free to reach out with any questions!", style: TextStyle(fontSize: 18, color: Colors.grey[700])),
        const SizedBox(height: 30),
        _contactInfoRow(Icons.phone_outlined, "Mobile", data.mobile),
        _contactInfoRow(Icons.email_outlined, "Email", data.contactInfo),
        _contactInfoRow(Icons.location_on_outlined, "Address", data.address),
      ],
    );

    final Widget formCard = Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _contactFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Please enter a valid email' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Your Message', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please enter a message' : null,
              ),
              const SizedBox(height: 20),
              _isSendingMessage
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _sendMessage,
                child: const Text("Send Message"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      color: const Color(0xFFF0F5FF),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isDesktop
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: infoColumn),
              const SizedBox(width: 50),
              Expanded(child: formCard),
            ],
          )
              : Column(
            children: [
              infoColumn,
              const SizedBox(height: 40),
              formCard,
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactInfoRow(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 20.0),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(color: Colors.grey[700])),
          ],
        )
      ],
    ),
  );

  Widget _buildFooter(PortfolioData data) => Container(
    padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
    color: const Color(0xFF111827),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text(data.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text("Your journey to comprehensive rehabilitation starts here.", style: TextStyle(fontSize: 16, color: Colors.grey[400])),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(url: "https://facebook.com", imageAsset: 'assets/images/facebook.png'),
                _socialIcon(url: "https://linkedin.com", imageAsset: 'assets/images/linkedin.png'),
                _socialIcon(url: "https://twitter.com", imageAsset: 'assets/images/twitter.png'),
              ],
            ),
            const SizedBox(height: 30),
            Text('© ${DateTime.now().year} ${data.name}. All Rights Reserved.', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Text('Dhaka, Bangladesh. ${DateFormat('EEEE, MMMM d, y, h:mm a').format(DateTime.now())}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    ),
  );

  // UPDATED: Removed the 'color' property
  Widget _socialIcon({required String url, required String imageAsset}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Image.asset(
        imageAsset,
        height: 24,
        width: 24,
        // The 'color' property was removed to show the original icon colors.
        errorBuilder: (context, error, stackTrace) {
          // This fallback is shown if the image asset is not found.
          return const Icon(Icons.circle, color: Colors.white, size: 24);
        },
      ),
    ),
  );
}

// --- BLOG DETAILS PAGE ---
class BlogDetailsPage extends StatefulWidget {
  final String postId;
  const BlogDetailsPage({Key? key, required this.postId}) : super(key: key);

  @override
  _BlogDetailsPageState createState() => _BlogDetailsPageState();
}

class _BlogDetailsPageState extends State<BlogDetailsPage> {
  final _commentController = TextEditingController();
  final _subscribeEmailController = TextEditingController();
  bool _isLiked = false;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _handleView();
    _checkIfLiked();
  }

  Future<void> _handleView() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> viewedPosts = prefs.getStringList('viewed_posts') ?? [];

    if (!viewedPosts.contains(widget.postId)) {
      FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({'views': FieldValue.increment(1)});
      viewedPosts.add(widget.postId);
      await prefs.setStringList('viewed_posts', viewedPosts);
    }
  }

  Future<void> _checkIfLiked() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> likedPosts = prefs.getStringList('liked_posts') ?? [];
    if (mounted) {
      setState(() {
        _isLiked = likedPosts.contains(widget.postId);
      });
    }
  }

  Future<void> _handleLike(BlogPost post) async {
    if (_isLiking) return;
    setState(() => _isLiking = true);

    final prefs = await SharedPreferences.getInstance();
    List<String> likedPosts = prefs.getStringList('liked_posts') ?? [];

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    if (_isLiked) {
      postRef.update({'likes': FieldValue.increment(-1)});
      likedPosts.remove(widget.postId);
    } else {
      postRef.update({'likes': FieldValue.increment(1)});
      likedPosts.add(widget.postId);
    }

    await prefs.setStringList('liked_posts', likedPosts);

    if (mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _isLiking = false;
      });
    }
  }

  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;
    FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
      'text': _commentController.text, 'username': 'Anonymous', 'timestamp': Timestamp.now(),
    });
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleSubscription() async {
    final email = _subscribeEmailController.text.trim();
    if (email.isNotEmpty && email.contains('@')) {
      await FirebaseFirestore.instance.collection('subscribers').add({
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thank you for subscribing!'),
        backgroundColor: Colors.green,
      ));
      _subscribeEmailController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid email address.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading post."));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());

          final post = BlogPost.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 900;
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildMainContent(post)),
                          const SizedBox(width: 40),
                          Expanded(flex: 1, child: _buildSidebar(context)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildMainContent(post),
                          const SizedBox(height: 40),
                          _buildSidebar(context),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BlogPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(post.category.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(width: 16),
            Text(DateFormat('dd MMMM y').format(post.publishedDate.toDate()), style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        Text(post.title, style: GoogleFonts.playfairDisplay(fontSize: 42, fontWeight: FontWeight.bold, height: 1.2)),
        const SizedBox(height: 24),
        _buildActionRow(post),
        const Divider(height: 40),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 300,
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(post.content.replaceAll("\\n", "\n\n"), style: const TextStyle(fontSize: 17, height: 1.8, color: Color(0xFF333333))),
        const Divider(height: 50),
        const Text('Comments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildCommentsSection(),
        const SizedBox(height: 30),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: 'Write a comment...',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _postComment),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BlogPost post) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.grey,
          ),
          onPressed: () => _handleLike(post),
        ),
        StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text("...");
              return Text('${snapshot.data!['likes'] ?? 0} Likes');
            }
        ),
        const SizedBox(width: 24),
        const Icon(Icons.visibility_outlined, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('${post.views} Views'),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Column(
      children: [
        _buildRecentPosts(context),
        const SizedBox(height: 30),
        _buildSubscribeCard(),
      ],
    );
  }

  Widget _buildRecentPosts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent Posts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('id', isNotEqualTo: widget.postId)
              .orderBy('id')
              .orderBy('publishedDate', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final posts = snapshot.data!.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
            return Column(
              children: posts.map((post) => _buildRecentPostItem(context, post)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentPostItem(BuildContext context, BlogPost post) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BlogDetailsPage(postId: post.id)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(post.imageUrl, width: 80, height: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd MMMM y').format(post.publishedDate.toDate()), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeCard() {
    return Card(
      color: Colors.grey[100],
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Subscribe", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Get the latest posts delivered right to your inbox", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: _subscribeEmailController,
              decoration: const InputDecoration(
                  labelText: 'Email ID',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderSide: BorderSide.none)
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _handleSubscription,
              child: const Text("Submit"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.pink.shade300,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("No comments yet."));
      final comments = snapshot.data!.docs.map((doc) => BlogComment.fromFirestore(doc)).toList();
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: comments.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final comment = comments[index];
          return ListTile(
            leading: CircleAvatar(child: Text(comment.username[0].toUpperCase())),
            title: Text(comment.username),
            subtitle: Text(comment.text),
          );
        },
      );
    },
  );
}


// --- ADMIN SECTION: LOGIN PAGE ---

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboardPage()));
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message ?? 'An error occurred'; });
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 5,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Admin Panel', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 30),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ADMIN SECTION: DASHBOARD PAGE ---

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
              },
            )
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.message_rounded), text: 'Messages'),
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
              Tab(icon: Icon(Icons.person_rounded), text: 'Portfolio'),
              Tab(icon: Icon(Icons.article_rounded), text: 'Blog'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MessagesView(),
            DashboardView(),
            EditPortfolioPage(),
            BlogManagementPage(),
          ],
        ),
      ),
    );
  }
}

// --- ADMIN SECTION: MESSAGES VIEW ---

class MessagesView extends StatelessWidget {
  Future<void> _replyByEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch(e) {
      print('Could not launch $emailLaunchUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No messages yet."));
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data() as Map<String, dynamic>;
            final timestamp = message['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('d MMM y, hh:mm a').format(timestamp.toDate())
                : 'No date';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            message['name'] ?? 'No Name',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message['email'] ?? 'No Email',
                      style: TextStyle(color: Colors.blue.shade700, fontStyle: FontStyle.italic),
                    ),
                    const Divider(height: 24),
                    Text(
                      message['message'] ?? 'No message content.',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.reply, size: 18),
                        label: const Text('Reply via Email'),
                        onPressed: () => _replyByEmail(message['email']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
// --- ADMIN SECTION: DASHBOARD VIEW ---

class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) return const Center(child: Text("Could not load data."));

        int postCount = snapshot.data!.docs.length;
        int totalViews = 0;
        int totalLikes = 0;

        for (var doc in snapshot.data!.docs) {
          final post = BlogPost.fromFirestore(doc);
          totalViews += post.views;
          totalLikes += post.likes;
        }

        return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("At a Glance", style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(context, 'Total Posts', '$postCount', Icons.article, Colors.blue),
                        _buildStatCard(context, 'Total Views', '$totalViews', Icons.visibility, Colors.orange),
                        _buildStatCard(context, 'Total Likes', '$totalLikes', Icons.thumb_up, Colors.green),
                      ],
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// --- ADMIN SECTION: EDIT PORTFOLIO PAGE ---

class EditPortfolioPage extends StatefulWidget {
  @override
  _EditPortfolioPageState createState() => _EditPortfolioPageState();
}

class _EditPortfolioPageState extends State<EditPortfolioPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String _errorMessage = '';

  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _contactController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _summaryController = TextEditingController();
  final _pictureUrlController = TextEditingController();

  List<Map<String, String>> _qualifications = [];
  List<Map<String, String>> _clinicalExperience = [];
  List<Map<String, String>> _expertise = [];
  List<Map<String, String>> _publications = [];
  List<Map<String, String>> _awards = [];
  List<Map<String, String>> _academicActivities = [];
  List<Map<String, String>> _books = [];
  List<Map<String, String>> _editorialRoles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('portfolio').doc('main_data').get();
      if (doc.exists) {
        final data = PortfolioData.fromFirestore(doc);
        _nameController.text = data.name;
        _positionController.text = data.position;
        _contactController.text = data.contactInfo;
        _mobileController.text = data.mobile;
        _addressController.text = data.address;
        _summaryController.text = data.careerSummary;
        _pictureUrlController.text = data.pictureUrl;
        _qualifications = List.from(data.qualifications);
        _clinicalExperience = List.from(data.clinicalExperience);
        _expertise = List.from(data.expertise);
        _publications = List.from(data.publications);
        _awards = List.from(data.awards);
        _academicActivities = List.from(data.academicActivities);
        _books = List.from(data.books);
        _editorialRoles = List.from(data.editorialRoles);
      } else {
        _resetAllDataToDefault();
      }
    } catch (e) {
      setState(() => _errorMessage = "Failed to load data: $e");
      _resetAllDataToDefault();
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _resetAllDataToDefault() {
    setState(() {
      _qualifications = PortfolioDataProvider.getInitialQualifications();
      _clinicalExperience = PortfolioDataProvider.getInitialClinicalExperience();
      _expertise = PortfolioDataProvider.getInitialExpertise();
      _publications = PortfolioDataProvider.getInitialPublications();
      _awards = PortfolioDataProvider.getInitialAwards();
      _books = PortfolioDataProvider.getInitialBooks();
      _editorialRoles = PortfolioDataProvider.getInitialEditorialRoles();
      _academicActivities = PortfolioDataProvider.getInitialAcademicActivities();
    });
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('portfolio').doc('main_data').set({
        'name': _nameController.text,
        'position': _positionController.text,
        'contactInfo': _contactController.text,
        'mobile': _mobileController.text,
        'address': _addressController.text,
        'careerSummary': _summaryController.text,
        'pictureUrl': _pictureUrlController.text,
        'qualifications': _qualifications,
        'clinicalExperience': _clinicalExperience,
        'expertise': _expertise,
        'publications': _publications,
        'awards': _awards,
        'academicActivities': _academicActivities,
        'books': _books,
        'editorialRoles': _editorialRoles,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Portfolio Updated Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Failed to save: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      File file = File(image.path);
      try {
        String fileName = 'profile_picture/${DateTime.now().millisecondsSinceEpoch}.png';
        UploadTask task = FirebaseStorage.instance.ref().child(fileName).putFile(file);
        TaskSnapshot snapshot = await task;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _pictureUrlController.text = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Image uploaded! Save changes to apply.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Image upload failed: $e")));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage));

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMainInfoSection(),
          const Divider(height: 40),
          _buildEditableList("Qualifications", _qualifications, onReset: () => setState(() => _qualifications = PortfolioDataProvider.getInitialQualifications())),
          const Divider(height: 40),
          _buildEditableList("Clinical Experiences", _clinicalExperience, onReset: () => setState(() => _clinicalExperience = PortfolioDataProvider.getInitialClinicalExperience())),
          const Divider(height: 40),
          _buildEditableList("Areas of Expertise", _expertise, onReset: () => setState(() => _expertise = PortfolioDataProvider.getInitialExpertise())),
          const Divider(height: 40),
          _buildEditableList("Publications", _publications, onReset: () => setState(() => _publications = PortfolioDataProvider.getInitialPublications())),
          const Divider(height: 40),
          _buildEditableList("Awards", _awards, hasYear: true, onReset: () => setState(() => _awards = PortfolioDataProvider.getInitialAwards())),
          const Divider(height: 40),
          _buildEditableList("Books Written", _books, isBook: true, onReset: () => setState(() => _books = PortfolioDataProvider.getInitialBooks())),
          const Divider(height: 40),
          _buildEditableList("Editorial Roles", _editorialRoles, onReset: () => setState(() => _editorialRoles = PortfolioDataProvider.getInitialEditorialRoles())),
          const Divider(height: 40),
          _buildEditableList("Other Academic Activities", _academicActivities, onReset: () => setState(() => _academicActivities = PortfolioDataProvider.getInitialAcademicActivities())),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _saveData,
            icon: const Icon(Icons.save),
            label: const Text("Save All Portfolio Data"),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoSection() {
    return ExpansionTile(
      title: Text("Main Info & Summary", style: Theme.of(context).textTheme.titleLarge),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _positionController, decoration: const InputDecoration(labelText: 'Position/Title', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _pictureUrlController, decoration: const InputDecoration(labelText: 'Profile Picture URL', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              ElevatedButton.icon(onPressed: _uploadProfilePicture, icon: const Icon(Icons.upload), label: const Text("Upload Picture")),
              const SizedBox(height: 16),
              TextFormField(controller: _summaryController, decoration: const InputDecoration(labelText: 'Career Summary', border: OutlineInputBorder()), maxLines: 5),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildEditableList(String title, List<Map<String, String>> list, {VoidCallback? onReset, bool hasYear = false, bool isBook = false}) {
    return ExpansionTile(
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (onReset != null)
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Reset"),
                onPressed: onReset,
              ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () => setState(() => list.insert(0, {'title': '', 'subtitle': '', 'year': '', 'published': '', 'isbn': ''})),
            ),
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int index = entry.key;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: entry.value['title'],
                    decoration: const InputDecoration(labelText: 'Title/Name'),
                    onChanged: (val) => list[index]['title'] = val,
                    maxLines: null,
                  ),
                  const SizedBox(height: 8),
                  if (isBook) ...[
                    TextFormField(
                      initialValue: entry.value['published'],
                      decoration: const InputDecoration(labelText: 'Published Info (e.g., "Published 2024")'),
                      onChanged: (val) => list[index]['published'] = val,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: entry.value['isbn'],
                      decoration: const InputDecoration(labelText: 'ISBN (e.g., "ISBN: ...")'),
                      onChanged: (val) => list[index]['isbn'] = val,
                    ),
                  ] else ...[
                    TextFormField(
                      initialValue: entry.value['subtitle'],
                      decoration: const InputDecoration(labelText: 'Subtitle/Description'),
                      onChanged: (val) => list[index]['subtitle'] = val,
                      maxLines: null,
                    ),
                  ],
                  if(hasYear) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: entry.value['year'],
                      decoration: const InputDecoration(labelText: 'Year'),
                      onChanged: (val) => list[index]['year'] = val,
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => list.removeAt(index)),
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// --- ADMIN SECTION: BLOG MANAGEMENT PAGE ---

class BlogManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('publishedDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No posts found. Add one!"));
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = BlogPost.fromFirestore(posts[index]);
              return ListTile(
                leading: Image.network(post.imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 50, height: 50, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400]))),
                title: Text(post.title),
                subtitle: Text('Likes: ${post.likes}, Views: ${post.views}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPostPage(post: post)))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePost(context, post.id)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPostPage())),
        label: const Text('New Post'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, String postId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Post deleted successfully.")));
    }
  }
}

// --- ADMIN SECTION: ADD/EDIT POST PAGE ---

class AddEditPostPage extends StatefulWidget {
  final BlogPost? post;
  const AddEditPostPage({Key? key, this.post}) : super(key: key);

  @override
  _AddEditPostPageState createState() => _AddEditPostPageState();
}

class _AddEditPostPageState extends State<AddEditPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
      _imageUrlController.text = widget.post!.imageUrl;
      _categoryController.text = widget.post!.category;
    } else {
      _categoryController.text = 'Web Design';
    }
  }

  Future<void> _uploadPostImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      File file = File(image.path);
      try {
        String fileName = 'post_images/${DateTime.now().millisecondsSinceEpoch}.png';
        UploadTask task = FirebaseStorage.instance.ref().child(fileName).putFile(file);
        TaskSnapshot snapshot = await task;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _imageUrlController.text = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Image uploaded! Save post to apply.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Image upload failed: $e")));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> postData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'imageUrl': _imageUrlController.text,
        'category': _categoryController.text,
        'id': widget.post?.id ?? FirebaseFirestore.instance.collection('posts').doc().id,
      };

      if (widget.post == null) {
        postData['publishedDate'] = Timestamp.now();
        postData['likes'] = 0;
        postData['views'] = 0;
        await FirebaseFirestore.instance.collection('posts').doc(postData['id']).set(postData);
      } else {
        await FirebaseFirestore.instance.collection('posts').doc(widget.post!.id).update(postData);
      }
      if(mounted) Navigator.of(context).pop();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save post: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? 'Add New Post' : 'Edit Post'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _isLoading ? null : _savePost)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_imageUrlController.text.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrlController.text,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.photo_library, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Category cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Image URL cannot be empty' : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _uploadPostImage,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Image"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content', hintText: 'Use \\n for new lines', border: OutlineInputBorder()),
                maxLines: 15,
                validator: (value) => value!.isEmpty ? 'Content cannot be empty' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// --- PORTFOLIO DEFAULT DATA PROVIDER ---
class PortfolioDataProvider {
  static List<Map<String, String>> getInitialQualifications() =>
      [
        {
          'title': 'M.B.B.S.',
          'subtitle': 'Shere-E-Bangla Medical College, Barisal, Bangladesh. September 1989.'
        },
        {
          'title': 'FCPS',
          'subtitle': 'Fellow of the College of Physician and Surgeon Dhaka, Bangladesh. January 2000.'
        },
        {
          'title': 'PhD',
          'subtitle': 'The University of Chittagong, Bangladesh. Specialist in Physical Medicine and Rehabilitation.'
        },
      ];

  static List<Map<String, String>> getInitialClinicalExperience() =>
      [
        {
          'title': 'Oct 01, 2016 – Present',
          'subtitle': 'Professor, Department of Physical Medicine and Rehabilitation, BSMMU, Dhaka'
        },
        {
          'title': 'Nov 05, 2007 – Sep 30, 2016',
          'subtitle': 'Associate Professor, PM&R Dept., BSMMU, Dhaka'
        },
        {
          'title': 'Oct 09, 2003 – Nov 05, 2007',
          'subtitle': 'Assistant Professor, PM&R Dept., BSMMU, Dhaka'
        },
        {
          'title': 'Jul 05, 2000 – Oct 07, 2003',
          'subtitle': 'Assistant Professor, Department of Physical Medicine, Chittagong Medical College'
        },
      ];

  static List<Map<String, String>> getInitialExpertise() =>
      [
        {
          'title': 'Clinical Rehabilitation',
          'subtitle': 'Comprehensive assessment & management of musculoskeletal and neuro-rehabilitation patients.'
        },
        {
          'title': 'Academic Teaching',
          'subtitle': 'MBBS, FCPS & MD curriculum development and hands-on training for students & postgraduates.'
        },
        {
          'title': 'Research & Publications',
          'subtitle': 'Principal investigator on BMRC projects; author of 95+ peer-reviewed articles.'
        },
        {
          'title': 'Consultancy & Workshops',
          'subtitle': 'Expert advisor on program design & invited speaker at national/international conferences.'
        },
      ];

  static List<Map<String, String>> getInitialAwards() =>
      [
        {
          'title': 'University Gold Medal in Research',
          'subtitle': 'For basic research in the field of Medical Science.',
          'year': '2016'
        },
        {
          'title': 'UGC Gold Medal',
          'subtitle': 'Awarded by University Grants Commission of Bangladesh.',
          'year': '2006'
        },
        {
          'title': 'Bangladesh Bioethics Award (BBS)',
          'subtitle': 'Asian Bioethics Conference, for contributions in bioethics.',
          'year': '2019'
        },
      ];

  static List<Map<String, String>> getInitialBooks() =>
      [
        {
          'title': 'Physical Modalities in Rehabilitation Medicine',
          'published': 'Published 2024',
          'isbn': 'ISBN: 978-984-99076-7-1'
        },
        {
          'title': 'Baatroger Karon o Chikitsha',
          'published': 'Published 2009',
          'isbn': 'ISBN: 978-984-414-359-3'
        },
        {'title': 'Betha Niramoya Bayam', 'published': '', 'isbn': ''},
      ];

  static List<Map<String, String>> getInitialEditorialRoles() =>
      [
        {
          'title': 'Executive Editor',
          'subtitle': 'PMR Bulletin (Official bulletin of The Bangladesh Association of Physical Medicine and Rehabilitation)'
        },
        {
          'title': 'Editorial Board Member',
          'subtitle': 'Bangladesh Journal of Bioethics. ISSN: 2226-9231 • eISSN: 2078-1458'
        },
        {
          'title': 'Editorial Board Member',
          'subtitle': 'Bangladesh Journal of Medical Science. ISSN: 2223-4721 • eISSN: 2076-0299'
        },
      ];

  static List<Map<String, String>> getInitialAcademicActivities() =>
      [
        {
          'title': 'Faculty Member, Physical Medicine & Rehabilitation, BCPS',
          'subtitle': 'since July 2000; Member Secretary April 2019–April 2023.'
        },
        {
          'title': 'Chairman, Ethics Review Board, Bangladesh Bioethics Society',
          'subtitle': '2014–Present'
        },
        {
          'title': 'Member, National Research Ethics Committee of Bangladesh',
          'subtitle': '2015–Present'
        },
      ];

  static List<Map<String, String>> getInitialPublications() =>
      [
        {
          'title': 'Effects of Pulmonary Rehabilitation on the Patients with COVID-19 infection.',
          'subtitle': 'Shakoor MA, M Moniruzzaman M, Atiquzzaman M, Islam MM, Dewan PD et al. Bangladesh Medical Res Counc Bull 2023; 49: 56-62.'
        },
        {
          'title': 'Absorption of Electromagnetic Radiation on Human Lower Back Region.',
          'subtitle': 'M A Shakoor, M Moyeenuzzaman, R Azimb, S R Chakraborty, M T Islamc, M Samsuzzaman. Jurnal Kejuruteraan 33(1) 2021: 145-149.'
        },
        {
          'title': 'Effects of Manual Continuous Home Cervical Traction in Cervical Spondylosis.',
          'subtitle': 'Shakoor MA, Emran MA, Zaman AKA, Moyeenuzzaman M. Bangladesh Med Res Counc Bull 2020; 46:128-133.'
        },
      ];
}
