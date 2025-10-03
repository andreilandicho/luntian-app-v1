// submitted_solutions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/maintenance/submitted_solutions.dart';
import 'package:flutter_application_1/services/maintenance/submitted_solution_service.dart';
import 'package:flutter_application_1/widgets/official/offsubmitted_solution_card.dart';

class SubmittedSolutionsPage extends StatefulWidget {
  const SubmittedSolutionsPage({super.key});

  @override
  State<SubmittedSolutionsPage> createState() => _SubmittedSolutionsPageState();
}

class _SubmittedSolutionsPageState extends State<SubmittedSolutionsPage> {
  late Future<List<SubmittedSolution>> _futureSolutions;

  @override
  void initState() {
    super.initState();
    _futureSolutions = SubmittedSolutionService().fetchSubmittedSolutions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      body: FutureBuilder<List<SubmittedSolution>>(
        future: _futureSolutions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final solutions = snapshot.data ?? [];
          if (solutions.isEmpty) {
            return const Center(child: Text('No submitted solutions.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: solutions.length,
            itemBuilder: (context, index) {
              final solution = solutions[index];
              return SubmittedSolutionCard(solution: solution);
            },
          );
        },
      ),
    );
  }
}