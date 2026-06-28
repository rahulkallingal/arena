import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme.dart';
import 'chat_room_screen.dart';
import 'join_by_code_screen.dart';
import 'room_share_dialog.dart';

class RoomDiscoveryScreen extends StatefulWidget {
  const RoomDiscoveryScreen({super.key});

  @override
  State<RoomDiscoveryScreen> createState() => _RoomDiscoveryScreenState();
}

class _RoomDiscoveryScreenState extends State<RoomDiscoveryScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showTrending = true;

  static const List<String> kCategories = [
    'All',
    'Politics',
    'Technology',
    'Science',
    'Society',
    'Entertainment',
    'Sports',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Discover Rooms'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          // Category filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kCategories.length,
              itemBuilder: (context, index) {
                final category = kCategories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Toggle trending
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Checkbox(
                  value: _showTrending,
                  onChanged: (value) {
                    setState(() => _showTrending = value ?? false);
                  },
                ),
                const Text('Show Trending Only'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JoinByCodeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('Join by Code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Room list
          Expanded(
            child: _buildRoomsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isPrivate', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var allRooms = snapshot.data?.docs.map((doc) {
          return Room.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>);
        }).toList() ?? [];
        // Sort by lastActivity on client side to avoid composite index
        allRooms.sort((a, b) => (b.lastActivity ?? DateTime(2000)).compareTo(a.lastActivity ?? DateTime(2000)));

        // Filter rooms - exclude user's own rooms
        var filteredRooms = allRooms
            .where((room) => room.createdBy != currentUserId)
            .toList();

        if (_selectedCategory != 'All') {
          filteredRooms = filteredRooms
              .where((room) => room.category == _selectedCategory)
              .toList();
        }

        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          filteredRooms = filteredRooms
              .where((room) =>
                  room.name.toLowerCase().contains(query) ||
                  room.topic.toLowerCase().contains(query))
              .toList();
        }

        if (_showTrending && filteredRooms.isNotEmpty) {
          // Sort by activity - last activity first (already sorted by stream)
          final now = DateTime.now();
          filteredRooms.sort((a, b) {
            final aTime = a.lastActivity ?? DateTime(2000);
            final bTime = b.lastActivity ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          // Keep only active rooms from last 24 hours
          filteredRooms = filteredRooms
              .where((room) =>
                  room.lastActivity != null &&
                  now.difference(room.lastActivity!).inHours < 24)
              .toList();
        }

        if (filteredRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No rooms found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            return _roomCard(context, filteredRooms[index]);
          },
        );
      },
    );
  }

  Widget _roomCard(BuildContext context, Room room) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(room: room),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.topic,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'share') {
                      showDialog(
                        context: context,
                        builder: (_) => RoomShareDialog(room: room),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Share Room'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    room.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.person, size: 16, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  'Created by ${room.createdByName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
