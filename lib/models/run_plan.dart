class RunPlan {
  final String title;
  final List<ExerciseData> exercises;

  RunPlan({required this.title, required this.exercises});

  Map<String, dynamic> toJson() => {
    'title': title,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory RunPlan.fromJson(Map<String, dynamic> json) => RunPlan(
    title: json['title'] as String,
    exercises: (json['exercises'] as List<dynamic>)
        .map((e) => ExerciseData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class ExerciseData {
  final String type;
  final Map<String, String> params;

  ExerciseData({required this.type, required this.params});

  Map<String, dynamic> toJson() => {
    'type': type,
    'params': params,
  };

  factory ExerciseData.fromJson(Map<String, dynamic> json) => ExerciseData(
    type: json['type'] as String,
    params: Map<String, String>.from(json['params'] as Map),
  );
}
