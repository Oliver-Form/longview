import 'dart:convert';

class Run {
  final String time;
  final String distance;
  final String imagePath;
  final String comment;

  Run({
    required this.time,
    required this.distance,
    required this.imagePath,
    required this.comment,
  });

  factory Run.fromJson(Map<String, dynamic> json) => Run(
        time: json['time'] as String,
        distance: json['distance'] as String,
        imagePath: json['imagePath'] as String,
        comment: json['comment'] as String,
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'distance': distance,
        'imagePath': imagePath,
        'comment': comment,
      };

  static List<Run> listFromJson(String jsonString) {
    final List<dynamic> data = json.decode(jsonString);
    return data.map((e) => Run.fromJson(e)).toList();
  }

  static String listToJson(List<Run> runs) {
    final List<Map<String, dynamic>> data = runs.map((r) => r.toJson()).toList();
    return json.encode(data);
  }
}
