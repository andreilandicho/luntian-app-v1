import 'package:flutter/material.dart';

class ActionProgressTracker extends StatefulWidget {
  const ActionProgressTracker({super.key});

  @override
  State<ActionProgressTracker> createState() => _ActionProgressTrackerState();
}

class _ActionProgressTrackerState extends State<ActionProgressTracker> {
  String? selectedPersonnel;
  final TextEditingController daysController = TextEditingController();
  final TextEditingController assignedController = TextEditingController();

  Widget buildStageContainer({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Deployment Stage
        buildStageContainer(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          title: "DEPLOYMENT",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Select personnel",
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, // decrease height
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                      ),
                      value: selectedPersonnel,
                      onChanged: (value) {
                        setState(() {
                          selectedPersonnel = value;
                        });
                      },
                      items: ["Team A", "Team B", "Team C"]
                          .map((team) => DropdownMenuItem(
                                value: team,
                                child: Text(team),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: selectedPersonnel == null
                        ? null
                        : () {
                            debugPrint("Assigned to: $selectedPersonnel");
                          },
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text("Assign"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Note: Select the team responsible for this action",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        // Waiting for Action Stage
        buildStageContainer(
          icon: Icons.access_time,
          iconColor: Colors.orange,
          title: "Waiting for Action",
          child: Column(
            children: [
              TextField(
                controller: daysController,
                decoration: const InputDecoration(
                  labelText: "Days needed to finish",
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: assignedController,
                decoration: const InputDecoration(
                  labelText: "Assigned to",
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),

        // Proof of Action Stage
        buildStageContainer(
          icon: Icons.verified,
          iconColor: Colors.blue,
          title: "Proof of Action",
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Accept"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Reject"),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                child: const Text("View"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
