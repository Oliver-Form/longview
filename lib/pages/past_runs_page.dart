import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stride/models/run.dart';

class PastRunsPage extends StatefulWidget {
  const PastRunsPage({Key? key}) : super(key: key);

  @override
  PastRunsPageState createState() => PastRunsPageState();
}

class PastRunsPageState extends State<PastRunsPage> {
  List<Run> _runs = [];

  @override
  void initState() {
    super.initState();
    loadRuns();
  }

  Future<void> loadRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('runs') ?? '[]';
    final runs = Run.listFromJson(jsonString);
    setState(() => _runs = runs.reversed.toList()); // latest first
  }

  @override
  Widget build(BuildContext context) {
    if (_runs.isEmpty) {
      return Center(
        child: Text('No past runs', style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _runs.length,
      itemBuilder: (context, index) {
        final run = _runs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: run.imagePath.isNotEmpty ?
              Image.file(File(run.imagePath), width: 60, height: 60, fit: BoxFit.cover)
              : const SizedBox(width:60, height:60),
            title: Text(run.distance),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(run.time),
                if (run.comment.isNotEmpty) Text(run.comment),
              ],
            ),
          ),
        );
      },
    );
  }
}
