import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const ReviewPage({super.key, required this.post});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _rating = 0;
  String _responseTime = '';
  final TextEditingController _commentController = TextEditingController();

  List<String> responseOptions = ['Fast', 'Moderate', 'Slow'];

  void _submitReview() {
    if (_rating == 0 || _responseTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please rate and select response time")),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review submitted!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final String description = post['description'] ?? 'No description';
    final String imageUrl = post['image'] ?? '';
    final String dateTime = post['createdAt'] ?? '';
    final String formattedDate = dateTime.isNotEmpty
        ? DateFormat.yMMMd().add_jm().format(DateTime.parse(dateTime))
        : '';

    return Scaffold(
      appBar: AppBar(title: const Text("Review Response")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl),
              ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(fontSize: 16)),
            if (formattedDate.isNotEmpty)
              Text("Posted: $formattedDate", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 30),
            const Text("Rate the Response:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => setState(() => _rating = rating),
              ),
            ),
            const SizedBox(height: 30),
            const Text("How fast was the response:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 10,
              children: responseOptions.map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: _responseTime == option,
                  onSelected: (_) => setState(() => _responseTime = option),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text("Additional Comments (optional):", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(controller: _commentController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _submitReview, child: const Text("Submit Review")),
          ],
        ),
      ),
    );
  }
}
