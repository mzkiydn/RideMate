class Shift {
  final String id;
  final String day;
  final String date;
  final String startTime;
  final String endTime;
  final double ratePerHour;
  final int totalVacancies;
  final List<Map<String, String>> applicants; // Each applicant has an ID and a status
  final String availability;
  final String jobScope;

  Shift({
    required this.id,
    required this.day,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.ratePerHour,
    required this.totalVacancies,
    required this.applicants,
    required this.availability,
    required this.jobScope,
  });

  factory Shift.fromMap(Map<String, dynamic> data, String documentId) {
    return Shift(
      id: documentId,
      day: data['Day'] ?? '',
      date: data['Date'] ?? '',
      startTime: data['Start'] ?? '',
      endTime: data['End'] ?? '',
      ratePerHour: (data['Rate'] ?? 0).toDouble(),
      totalVacancies: data['Vacancy'] ?? 0,
      applicants: (data['Applicant'] as List<dynamic>?)
          ?.map((applicant) => {
        'id': applicant['id']?.toString() ?? '',
        'Status': applicant['Status']?.toString() ?? 'None',
      })
          .toList() ?? [],
      availability: data['Availability'] ?? 'Available',
      jobScope: data['Scope'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Day': day,
      'Date': date,
      'Start': startTime,
      'End': endTime,
      'Rate': ratePerHour,
      'Vacancy': totalVacancies,
      'Applicant': applicants.map((applicant) => {
        'id': applicant['id'],
        'Status': applicant['Status'],
      }).toList(),
      'Availability': availability,
      'Scope': jobScope,
    };
  }
}
