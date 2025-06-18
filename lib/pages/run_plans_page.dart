import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_run_page.dart';
import 'dart:convert';
import '../models/run_plan.dart';

class RunPlansPage extends StatefulWidget {
  const RunPlansPage({Key? key}) : super(key: key);

  @override
  _RunPlansPageState createState() => _RunPlansPageState();
}

class _RunPlansPageState extends State<RunPlansPage> {
  List<RunPlan> _runs = [];

  @override
  void initState() {
    super.initState();
    loadRuns();
  }

  Future<void> loadRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('run_plans') ?? [];
    setState(() {
      _runs = list.map((s) => RunPlan.fromJson(jsonDecode(s))).toList();
    });
  }

  void _onAddRun() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateRunPage()))
        .then((saved) {
          if (saved == true) loadRuns();
        });
  }

  void _onTapRun(int index) {
    // TODO: navigate to edit run screen
    final plan = _runs[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan: ${plan.title} (${plan.exercises.length} exercises)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run Plans')),
      body: _runs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.directions_run, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No runs yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Tap + to add a new run', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _runs.length,
              itemBuilder: (context, index) {
                final plan = _runs[index];
                return Dismissible(
                  key: ValueKey('${plan.title}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Run Plan'),
                        content: Text('Are you sure you want to delete "${plan.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    final prefs = await SharedPreferences.getInstance();
                    final list = prefs.getStringList('run_plans') ?? [];
                    list.removeAt(index);
                    await prefs.setStringList('run_plans', list);
                    setState(() => _runs.removeAt(index));
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.run_circle),
                      title: Text(plan.title),
                      subtitle: Text('${plan.exercises.length} exercises'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              // TODO: start this plan
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Start plan: ${plan.title}')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) => CreateRunPage(
                                      plan: plan,
                                      index: index,
                                    ),
                                  ))
                                  .then((saved) {
                                    if (saved == true) loadRuns();
                                  });
                            },
                          ),
                        ],
                      ),
                      onTap: () => _onTapRun(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddRun,
        child: const Icon(Icons.add),
        tooltip: 'Add Run',
      ),
    );
  }
}

// im not saying it was your fault