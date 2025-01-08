import 'package:flutter/material.dart';
import 'package:new_project/screens/post_details_screen.dart';
import 'package:new_project/services/post_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService postService = PostService();
  final TextEditingController _postController = TextEditingController();
  List<File> _selectedImage = [];

  List<Post> posts = [];
  bool isLoading = true;
  bool isAddingPost = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    try {
      final fetchedPosts = await postService.fetchPosts(token);
      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load posts: $error')),
      );
    }
  }

  Future<void> _addPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty && _selectedImage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or select images.')),
      );
      return;
    }

    setState(() {
      isAddingPost = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return;

      await postService.createPost(content, _selectedImage, token);

      setState(() {
        _postController.clear();
        _selectedImage.clear();
      });

      _loadPosts();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add post: $error')),
      );
    } finally {
      setState(() {
        isAddingPost = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    // Check if files are selected
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImage = pickedFiles.map((file) => File(file.path)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images selected.')),
      );
    }
  }

  void _openGallery(BuildContext context, List<String> images, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: index),
                itemCount: images.length,
                itemBuilder: (context, pageIndex) {
                  return InteractiveViewer(
                    child: Image.network(
                      _getImageUrl(images[pageIndex]),
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'Photo access permission is permanently denied. Please enable it from the app settings.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    return timeago.format(dateTime);
  }

  void _reactToPost(String postId, String reactionType) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    try {
      await postService.reactToPost(postId, token, reactionType);
      await _loadPosts(); // Refresh posts after reaction
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to react to post: $error')),
      );
    }
  }

  String _getMostCommonReaction(List<Reaction> reactions) {
    if (reactions.isEmpty) return 'none';

    final reactionCount = <String, int>{};
    for (var reaction in reactions) {
      reactionCount[reaction.type] = (reactionCount[reaction.type] ?? 0) + 1;
    }

    return reactionCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key; // Return the most common reaction
  }

  IconData _getReactionIcon(String mostCommonReaction) {
    switch (mostCommonReaction) {
      case 'like':
        return Icons.thumb_up;
      case 'love':
        return Icons.favorite;
      case 'happy':
        return Icons.emoji_emotions;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.thumb_up_off_alt; // Default icon
    }
  }

  Color _getReactionColor(String mostCommonReaction) {
    switch (mostCommonReaction) {
      case 'like':
        return Colors.blue;
      case 'love':
        return Colors.red;
      case 'happy':
        return Colors.yellow.shade700;
      case 'angry':
        return Colors.orange;
      default:
        return Colors.grey; // Default color
    }
  }

  void _navigateToPostDetails(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(post: post),
      ),
    );
  }

  String _getImageUrl(String imagePath) {
    const String baseUrl = "http://172.16.0.13:5000"; // Your backend URL
    return "$baseUrl$imagePath";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Add Post Section
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.add, color: Colors.white),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextField(
                                    controller: _postController,
                                    decoration: const InputDecoration(
                                      hintText: 'What\'s on your mind?',
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.image,
                                      color: Colors.blue),
                                  onPressed: _pickImage,
                                ),
                              ],
                            ),
                            if (_selectedImage.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: _selectedImage.length == 1
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        child: Image.file(
                                          _selectedImage.first,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              2, // Two images per row
                                          crossAxisSpacing: 8.0,
                                          mainAxisSpacing: 8.0,
                                        ),
                                        itemCount: _selectedImage.length,
                                        itemBuilder: (context, index) {
                                          return ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            child: Image.file(
                                              _selectedImage[index],
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ElevatedButton(
                              onPressed: isAddingPost ? null : _addPost,
                              child: isAddingPost
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : const Text('Post'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Post List Section
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final mostCommonReaction =
                            _getMostCommonReaction(post.reactions);
                        return GestureDetector(
                          onTap: () => _navigateToPostDetails(post),
                          child: Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(post.username[0]),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        post.username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _getTimeAgo(post.createdAt),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Post content
                                  Text(post.content),
                                  const SizedBox(height: 10),
                                  // Post images
                                  if (post.images.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: post.images.length == 1
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              child: Image.network(
                                                _getImageUrl(post.images.first),
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount:
                                                    2, // Two images per row
                                                crossAxisSpacing: 8.0,
                                                mainAxisSpacing: 8.0,
                                              ),
                                              itemCount: post.images.length,
                                              itemBuilder: (context, index) {
                                                return GestureDetector(
                                                  onTap: () => _openGallery(
                                                      context,
                                                      post.images,
                                                      index),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                    child: Image.network(
                                                      _getImageUrl(
                                                          post.images[index]),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),

                                  const SizedBox(height: 10),
                                  // Reactions and Comments
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            _showReactionMenu(context, post.id),
                                        child: Tooltip(
                                          message: 'React to post',
                                          child: Icon(
                                            _getReactionIcon(
                                                mostCommonReaction),
                                            color: _getReactionColor(
                                                mostCommonReaction),
                                          ),
                                        ),
                                      ),
                                      Text(
                                          '${post.reactions.length} reactions'),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () =>
                                            _navigateToPostDetails(post),
                                        child: const Text('View Post'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Reaction Menu
  void _showReactionMenu(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Tooltip(
              message: 'Like',
              child: IconButton(
                icon: const Icon(Icons.thumb_up, color: Colors.blue),
                onPressed: () {
                  _reactToPost(postId, 'like');
                  Navigator.pop(context);
                },
              ),
            ),
            Tooltip(
              message: 'Love',
              child: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  _reactToPost(postId, 'love');
                  Navigator.pop(context);
                },
              ),
            ),
            Tooltip(
              message: 'Happy',
              child: IconButton(
                icon: const Icon(Icons.emoji_emotions, color: Colors.yellow),
                onPressed: () {
                  _reactToPost(postId, 'happy');
                  Navigator.pop(context);
                },
              ),
            ),
            Tooltip(
              message: 'Angry',
              child: IconButton(
                icon: const Icon(Icons.sentiment_very_dissatisfied,
                    color: Colors.orange),
                onPressed: () {
                  _reactToPost(postId, 'angry');
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
