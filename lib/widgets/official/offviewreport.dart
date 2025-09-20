import 'package:flutter/material.dart';

class ViewReportPage extends StatefulWidget {
  final String reporterName;
  final String profileImage;
  final String reportTime;
  final String reportDate;
  final String status; // "Accepted", "Rejected", "Pending"
  final String postImage;
  final String description;
  final String? statusDescription; // Provided description (used in Rejected)

  const ViewReportPage({
    super.key,
    required this.reporterName,
    required this.profileImage,
    required this.reportTime,
    required this.reportDate,
    required this.status,
    required this.postImage,
    required this.description,
    this.statusDescription,
  });

  @override
  State<ViewReportPage> createState() => _ViewReportPageState();
}

class _ViewReportPageState extends State<ViewReportPage> {
  /// Get color based on status
  Color _statusColor(String status) {
    switch (status) {
      case 'Rejected':
        return Colors.red;
      case 'Accepted':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get icon based on status
  IconData _statusIcon(String status) {
    switch (status) {
      case 'Rejected':
        return Icons.cancel;
      case 'Accepted':
        return Icons.check_circle;
      case 'Pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  /// Default descriptions (only used for Accepted and Pending)
  String _defaultDescription(String status) {
    switch (status) {
      case "Accepted":
        return "Your report has been accepted and assigned to the team.";
      case "Pending":
        return "Your report is waiting for approval by an official. Please check back later for updates.";
      default:
        return "";
    }
  }

  /// Styled status box
  Widget _statusBox(String status, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: status == "Rejected"
            ? Colors.red[50]
            : status == "Accepted"
                ? Colors.green[50]
                : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor(status), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(status), color: _statusColor(status), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _statusColor(status),
                fontSize: 13,
                fontWeight: status == "Rejected"
                    ? FontWeight.normal
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row - Profile + Name/Time + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.profileImage),
                  radius: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.reporterName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "${widget.reportDate} • ${widget.reportTime}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                /// Right side (status pill)
                _pill(
                  label: widget.status,
                  color: _statusColor(widget.status),
                  icon: _statusIcon(widget.status),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Clickable Post Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageView(imagePath: widget.postImage),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.postImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),


            const SizedBox(height: 12),

            /// Description
            Text(widget.description),

            /// Status description box
            if (widget.status == "Accepted")
              _statusBox(widget.status, _defaultDescription("Accepted")),
            if (widget.status == "Pending")
              _statusBox(widget.status, _defaultDescription("Pending")),
            if (widget.status == "Rejected" && widget.statusDescription != null)
              _statusBox(widget.status, widget.statusDescription!),
          ],
        ),
      ),
    );
  }

  /// Pill widget with icon + text
  Widget _pill({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen image view
class FullScreenImageView extends StatelessWidget {
  final String imagePath;

  const FullScreenImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context), // tap anywhere to close
        child: Center(
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain, // ensures image fits nicely
          ),
        ),
      ),
    );
  }
}

