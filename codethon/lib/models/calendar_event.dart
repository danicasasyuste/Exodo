class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
    );
  }
}
