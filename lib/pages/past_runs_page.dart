import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stride/models/run.dart';
import 'package:intl/intl.dart';

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // display formatted start time
                Text(
                  '${DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(run.startTime).toLocal())}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                // show duration
                Text(
                  'Duration: ${run.time}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Distance: ${run.distance}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (run.imagePath.isNotEmpty)
                  Image.file(File(run.imagePath), width: double.infinity, height: 200, fit: BoxFit.cover)
                else
                  Container(width: double.infinity, height: 200, color: Colors.grey[300]),
                const SizedBox(height: 12),
                if (run.comment.isNotEmpty)
                  Text(run.comment, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
