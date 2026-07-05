import 'package:flutter/material.dart';

class SuccessReviewPage extends StatefulWidget {
  const SuccessReviewPage({super.key});

  @override
  State<SuccessReviewPage> createState() => _SuccessReviewPageState();
}

class _SuccessReviewPageState extends State<SuccessReviewPage> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Confirmed")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Success!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("Your appointment has been booked successfully."),
            const SizedBox(height: 40),
            const Text("Rate your experience:"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: "Write your feedback here...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle your API call here
                debugPrint("Rating: $_rating, Review: ${_reviewController.text}");
              },
              child: const Text("Submit Review"),
            ),
          ],
        ),
      ),
    );
  }
}