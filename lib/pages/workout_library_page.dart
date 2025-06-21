import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/run_plan.dart';
import 'new_routine_page.dart';
import 'explore_workouts_page.dart';

class WorkoutLibraryPage extends StatefulWidget {
  const WorkoutLibraryPage({Key? key}) : super(key: key);

  @override
  State<WorkoutLibraryPage> createState() => _WorkoutLibraryPageState();
}

class _WorkoutLibraryPageState extends State<WorkoutLibraryPage> {
  List<RunPlan> _routines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('run_plans') ?? [];
    setState(() {
      _routines = list.map((e) => RunPlan.fromJson(jsonDecode(e))).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Workout Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NewRoutinePage(),
                        ),
                      );
                      _loadRoutines();
                    },
                    child: const Text('New Routine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ExploreWorkoutsPage(),
                        ),
                      );
                    },
                    child: const Text('Explore'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_routines.isEmpty)
              const Expanded(child: Center(child: Text('No routines yet. Tap "New Routine" to create one!')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _routines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final plan = _routines[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => NewRoutinePage(plan: plan, index: i),
                                        ),
                                      );
                                      _loadRoutines();
                                    } else if (value == 'delete') {
                                      final prefs = await SharedPreferences.getInstance();
                                      final list = prefs.getStringList('run_plans') ?? [];
                                      if (i < list.length) {
                                        list.removeAt(i);
                                        await prefs.setStringList('run_plans', list);
                                      }
                                      setState(() {
                                        _routines.removeAt(i);
                                      });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...plan.exercises.map((ex) => Text(
                              '${ex.type}: ' + (ex.params['duration'] ?? ex.params['value'] ?? ex.params['splits'] ?? ''),
                              style: Theme.of(context).textTheme.bodyMedium,
                            )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
