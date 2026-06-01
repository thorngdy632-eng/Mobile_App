// lib/models/scheduled_job.dart

/// Represents a scheduled agricultural transport job
class ScheduledJob {
  final int id;
  final String date;
  final String time;
  final String service;
  final String location;
  final String distance;
  final JobStatus status;

  const ScheduledJob({
    required this.id,
    required this.date,
    required this.time,
    required this.service,
    required this.location,
    required this.distance,
    required this.status,
  });
}

enum JobStatus { confirmed, pending }

extension JobStatusExtension on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.confirmed:
        return 'បញ្ជាក់';
      case JobStatus.pending:
        return 'រង់ចាំ';
    }
  }
}
