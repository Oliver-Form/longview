import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/run_plan.dart';

// Custom formatter to ensure seconds part (MM:SS) seconds <= 59
class SecondsRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final parts = text.split(':');
    // When two minute digits available, clamp to <=59
    if (parts[0].length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      if (minutes > 59) return oldValue;
    }
    // When two second digits available, clamp to <=59
    if (parts.length > 1 && parts[1].length == 2) {
      final seconds = int.tryParse(parts[1]) ?? 0;
      if (seconds > 59) return oldValue;
    }
    return newValue;
  }
}

// Model class for each exercise, with unique key to keep widget identity
class ExerciseItem {
  final String type;
  final Key key;
  ExerciseItem(this.type): key = UniqueKey();
}

class NewRoutinePage extends StatefulWidget {
  final RunPlan? plan;
  final int? index;
  const NewRoutinePage({Key? key, this.plan, this.index}) : super(key: key);

  @override
  _NewRoutinePageState createState() => _NewRoutinePageState();
}

class _NewRoutinePageState extends State<NewRoutinePage> {
  late TextEditingController _titleController;
  late List<ExerciseItem> _exercises;
  late List<Map<String, TextEditingController>> _controllers;
  final _durationFormatter = MaskTextInputFormatter(mask: '##:##', filter: {'#': RegExp(r'\d')});

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize from plan if editing
    if (widget.plan != null) {
      _titleController = TextEditingController(text: widget.plan!.title);
      _exercises = widget.plan!.exercises.map((t) => ExerciseItem(t.type)).toList();
      _controllers = widget.plan!.exercises.map((ex) {
        final map = <String, TextEditingController>{};
        if (ex.type.contains('Time') || ex.type == 'Resting' || ex.type == 'Stretching') {
          map['duration'] = TextEditingController(text: ex.params['duration'] ?? '');
        } else {
          map['value'] = TextEditingController(text: ex.params['value'] ?? '');
        }
        if (ex.params.containsKey('splits')) {
          map['splits'] = TextEditingController(text: ex.params['splits'] ?? '');
        }
        return map;
      }).toList();
    } else {
      _titleController = TextEditingController();
      _exercises = [];
      _controllers = [];
    }
  }

  void _showExerciseMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Running (Distance)'),
              onTap: () {
                setState(() {
                  _exercises.add(ExerciseItem('Running (Distance)'));
                  _controllers.add({'value': TextEditingController()});
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Running (Time)'),
              onTap: () {
                setState(() {
                  _exercises.add(ExerciseItem('Running (Time)'));
                  _controllers.add({'duration': TextEditingController()});
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Walking (Distance)'),
              onTap: () {
                setState(() {
                  _exercises.add(ExerciseItem('Walking (Distance)'));
                  _controllers.add({'value': TextEditingController()});
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Walking (Time)'),
              onTap: () {
                setState(() {
                  _exercises.add(ExerciseItem('Walking (Time)'));
                  _controllers.add({'duration': TextEditingController()});
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Hills'),
              onTap: () {
                setState(() {
                  _exercises.add(ExerciseItem('Hills'));  
                  _controllers.add({'value': TextEditingController()});
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Resting'),
              onTap: () {
                setState(() {
                  _exercises.add(ExerciseItem('Resting'));
                  _controllers.add({'duration': TextEditingController()});
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Stretching'),
              onTap: () {
                setState(() {
                  _exercises.add(ExerciseItem('Stretching'));
                  _controllers.add({'duration': TextEditingController()});
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onReorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exercises.removeAt(oldIndex);
      final ctrl = _controllers.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
      _controllers.insert(newIndex, ctrl);
    });
  }

  Future<void> saveRunPlan() async {
    if (_titleController.text.isEmpty) return;
    final newPlan = RunPlan(
      title: _titleController.text,
      exercises: List.generate(_exercises.length, (i) {
        final type = _exercises[i].type;
        final params = <String, String>{};
        _controllers[i].forEach((key, controller) {
          params[key] = controller.text;
        });
        return ExerciseData(type: type, params: params);
      }),
    );
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('run_plans') ?? [];
    final encoded = jsonEncode(newPlan.toJson());
    if (widget.index != null && widget.index! < list.length) {
      list[widget.index!] = encoded;
    } else {
      list.add(encoded);
    }
    await prefs.setStringList('run_plans', list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Routine'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () async {
                await saveRunPlan();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Routine Title',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              // render added exercises with swipe-to-delete and drag-to-reorder
              const SizedBox(height: 12),
              Expanded(
                child: ReorderableListView(
                  buildDefaultDragHandles: false,
                  onReorder: _onReorderExercises,
                  children: [
                    for (int i = 0; i < _exercises.length; i++)
                      Dismissible(
                        key: _exercises[i].key,
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => setState(() {
                          _exercises.removeAt(i);
                          _controllers.removeAt(i);
                        }),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: ListTile(
                                  leading: const Icon(Icons.drag_handle),
                                  title: Text(_exercises[i].type),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    // For duration exercises, use masked MM:SS input
                                    if (_exercises[i].type == 'Resting' || _exercises[i].type == 'Stretching' || _exercises[i].type.contains('Time'))
                                      TextField(
                                        controller: _controllers[i]['duration'],
                                        decoration: const InputDecoration(
                                          hintText: 'MM:SS',
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          _durationFormatter,
                                          SecondsRangeFormatter(),
                                        ],
                                      )
                                    else
                                      TextField(
                                        controller: _controllers[i]['value'],
                                        decoration: InputDecoration(
                                          labelText: (_exercises[i].type == 'Hills'
                                              ? 'Repeats'
                                              : 'Distance'),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    if (_exercises[i].type == 'Interval Training')
                                      TextField(
                                        controller: _controllers[i]['splits'],
                                        decoration: const InputDecoration(
                                          labelText: 'Splits',
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _showExerciseMenu,
                child: const Text('Add Exercise'),
              ),
              // ...additional form fields go here...
            ],
          ),
        ),
      ),
    );
  }
}

