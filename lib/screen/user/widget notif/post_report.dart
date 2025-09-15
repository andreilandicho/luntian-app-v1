import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Details", style: TextStyle(fontFamily: 'Poppins')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(post['userProfile'])),
              title: Text(post['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              subtitle: Text("Posted just now", style: TextStyle(color: Colors.grey[600])),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: post['priorityColor'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(post['priorityLabel'], style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PageView(
                children: post['images'].map<Widget>((img) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          child: PhotoView(imageProvider: AssetImage(img)),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(img, fit: BoxFit.cover),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text(post['postContent'], style: const TextStyle(fontSize: 16, fontFamily: 'Poppins')),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      post['upvoted'] = !(post['upvoted'] ?? false);
                      if (post['upvoted']) {
                        post['upvotes'] = (post['upvotes'] ?? 0) + 1;
                        if (post['downvoted'] == true) {
                          post['downvoted'] = false;
                          post['downvotes'] = (post['downvotes'] ?? 1) - 1;
                        }
                      } else {
                        post['upvotes'] = (post['upvotes'] ?? 1) - 1;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_upward_rounded,
                      color: post['upvoted'] ? Colors.green : Colors.grey[600]),
                ),
                Text("${post['upvotes'] ?? 0}"),
                const SizedBox(width: 30),
                IconButton(
                  onPressed: () {
                    setState(() {
                      post['downvoted'] = !(post['downvoted'] ?? false);
                      if (post['downvoted']) {
                        post['downvotes'] = (post['downvotes'] ?? 0) + 1;
                        if (post['upvoted'] == true) {
                          post['upvoted'] = false;
                          post['upvotes'] = (post['upvotes'] ?? 1) - 1;
                        }
                      } else {
                        post['downvotes'] = (post['downvotes'] ?? 1) - 1;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_downward_rounded,
                      color: post['downvoted'] ? Colors.red : Colors.grey[600]),
                ),
                Text("${post['downvotes'] ?? 0}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
