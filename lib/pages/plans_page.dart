import 'package:flutter/material.dart';
import 'new_routine_page.dart';
import 'explore_workouts_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/run_plan.dart';
import 'coach_wizard_page.dart';
import 'workout_library_page.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({Key? key}) : super(key: key);

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  bool started = false;
  int questionIndex = 0;

  // Placeholder for answers, can be expanded for real logic
  final Map<String, dynamic> answers = {};

  void nextQuestion() {
    setState(() {
      questionIndex++;
    });
  }

  void startCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoachWizardPage(),
        fullscreenDialog: true,
      ),
    );
  }

  Widget buildQuestion(BuildContext context) {
    switch (questionIndex) {
      case 0:
        return Stack(
          children: [
            // Semi-transparent background art
            Positioned.fill(
              child: Opacity(
                opacity: 0.18, // Adjust for subtlety
                child: Image.asset(
                  'assets/goals.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text("1. What’s your primary goal?", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    ...[
                      'Build general endurance',
                      'Run my first 5K / 10K / Half',
                      'Improve my race time',
                      'Get back into running',
                      'Train consistently with structure',
                      'Custom (I’ll decide everything)'
                    ].map((label) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RadioListTile<String>(
                        value: label,
                        groupValue: answers['goal'],
                        onChanged: (v) { setState(() { answers['goal'] = v; }); },
                        title: Text(label),
                      ),
                    )),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: answers['goal'] != null ? nextQuestion : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. How long do you want this plan to be?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setStateSB) {
                double weeks = (answers['weeks'] ?? 8).toDouble();
                bool indefinite = answers['indefinite'] == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: indefinite,
                          onChanged: (v) {
                            setStateSB(() {
                              answers['indefinite'] = v;
                            });
                          },
                        ),
                        const Text('Indefinite (ongoing)'),
                      ],
                    ),
                    if (!indefinite) ...[
                      Slider(
                        value: weeks,
                        min: 4,
                        max: 20,
                        divisions: 16,
                        label: '${weeks.round()} weeks',
                        onChanged: (v) {
                          setStateSB(() { answers['weeks'] = v; });
                        },
                      ),
                      Text('${weeks.round()} weeks'),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: indefinite || answers['weeks'] != null ? nextQuestion : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("3. How many days a week can you realistically run?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) => ChoiceChip(
                label: Text('${i+1}'),
                selected: answers['days'] == (i+1),
                onSelected: (selected) { setState(() { answers['days'] = i+1; }); },
              )),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['days'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("4. Do you currently run?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...[
              'Not yet',
              'Occasionally',
              '1-2 times a week',
              '3+ times a week'
            ].map((label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RadioListTile<String>(
                value: label,
                groupValue: answers['current'],
                onChanged: (v) { setState(() { answers['current'] = v; }); },
                title: Text(label),
              ),
            )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['current'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("5. What’s your longest recent run?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setStateSB) {
                double km = (answers['longest'] ?? 5).toDouble();
                return Column(
                  children: [
                    Slider(
                      value: km,
                      min: 0,
                      max: 25,
                      divisions: 25,
                      label: '${km.round()} km',
                      onChanged: (v) {
                        setStateSB(() { answers['longest'] = v; });
                      },
                    ),
                    Text('${km.round()} km'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: answers['longest'] != null ? nextQuestion : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("6. Do you have a preferred long run day?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: answers['day'],
              hint: const Text('No preference'),
              items: [
                ...['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'].map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: (v) { setState(() { answers['day'] = v; }); },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['day'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("7. Do you want the program to include:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ...['Interval training','Hill repeats','Tempo runs','Audio pacing','Voice cues','Heart rate targets'].map((label) => FilterChip(
                  label: Text(label),
                  selected: (answers['include'] ?? <String>[]).contains(label),
                  onSelected: (selected) {
                    setState(() {
                      final list = List<String>.from(answers['include'] ?? <String>[]);
                      if (selected) {
                        list.add(label);
                      } else {
                        list.remove(label);
                      }
                      answers['include'] = list;
                    });
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: nextQuestion,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("8. Would you like to include a rest/recovery week every 4 weeks?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Yes'),
                  selected: answers['recovery'] == true,
                  onSelected: (selected) { setState(() { answers['recovery'] = true; }); },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('No'),
                  selected: answers['recovery'] == false,
                  onSelected: (selected) { setState(() { answers['recovery'] = false; }); },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['recovery'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("9. What kind of program would you like?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('🧘 Zen — gentle, flexible'),
                  selected: answers['program'] == 'Zen',
                  onSelected: (selected) { setState(() { answers['program'] = 'Zen'; }); },
                ),
                ChoiceChip(
                  label: const Text('🎯 Focused — goal-oriented, clear'),
                  selected: answers['program'] == 'Focused',
                  onSelected: (selected) { setState(() { answers['program'] = 'Focused'; }); },
                ),
                ChoiceChip(
                  label: const Text('🔥 Hardcore — aggressive improvement'),
                  selected: answers['program'] == 'Hardcore',
                  onSelected: (selected) { setState(() { answers['program'] = 'Hardcore'; }); },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ['program'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      default:
        return Center(child: Text('All done!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalQuestions = 9;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Progress indicator
          if (started)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: LinearProgressIndicator(
                value: (questionIndex + 1) / totalQuestions,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          const SizedBox(height: 16),
          if (started)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () {
                    setState(() {
                      if (questionIndex == 0) {
                        started = false;
                      } else {
                        questionIndex--;
                      }
                    });
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  final isForward = child.key is ValueKey && (child.key as ValueKey).value == 'q$questionIndex';
                  final offsetTween = Tween<Offset>(
                    begin: isForward ? const Offset(1, 0) : const Offset(-1, 0),
                    end: Offset.zero,
                  );
                  return SlideTransition(
                    position: offsetTween.animate(animation),
                    child: child,
                  );
                },
                child: !started
                    ? Column(
                        key: const ValueKey('start'),
                        children: [
                          Image.asset(
                            'assets/coach.png',
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          ElevatedButton(
                            onPressed: startCoach,
                            child: const Text('Longview Coach'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        key: ValueKey('q$questionIndex'),
                        child: buildQuestion(context),
                      ),
              ),
            ),
          ),
          if (!started)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Libraries',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Browse and add from a collection of curated workouts, intervals, and routines to supplement your plan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WorkoutLibraryPage(),
                          ),
                        );
                      },
                      child: const Text('Your Workout Library'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class CoachWizardPage extends StatefulWidget {
  @override
  _CoachWizardPageState createState() => _CoachWizardPageState();
}

class _CoachWizardPageState extends State<CoachWizardPage> {
  int questionIndex = 0;
  final Map<String, dynamic> answers = {};

  void nextQuestion() {
    setState(() {
      questionIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalQuestions = 9;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SizedBox.expand(
                child: Opacity(
                  opacity: 0.18,
                  child: Image.asset(
                    'assets/goals.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 96), // Increased from 64 to 96 for more space below AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: LinearProgressIndicator(
                        value: (questionIndex + 1) / totalQuestions,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: () {
                            setState(() {
                              if (questionIndex == 0) {
                                Navigator.of(context).pop();
                              } else {
                                questionIndex--;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) {
                            final isForward = child.key is ValueKey && (child.key as ValueKey).value == 'q$questionIndex';
                            final offsetTween = Tween<Offset>(
                              begin: isForward ? const Offset(1, 0) : const Offset(-1, 0),
                              end: Offset.zero,
                            );
                            return SlideTransition(
                              position: offsetTween.animate(animation),
                              child: child,
                            );
                          },
                          child: Container(
                            key: ValueKey('q$questionIndex'),
                            child: _buildQuestion(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    switch (questionIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. What’s your primary goal?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...[
              'Build general endurance',
              'Run my first 5K / 10K / Half',
              'Improve my race time',
              'Get back into running',
              'Train consistently with structure',
              'Custom (I’ll decide everything)'
            ].map((label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RadioListTile<String>(
                value: label,
                groupValue: answers['goal'],
                onChanged: (v) { setState(() { answers['goal'] = v; }); },
                title: Text(label),
              ),
            )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['goal'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. How long do you want this plan to be?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setStateSB) {
                double weeks = (answers['weeks'] ?? 8).toDouble();
                bool indefinite = answers['indefinite'] == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: indefinite,
                          onChanged: (v) {
                            setStateSB(() {
                              answers['indefinite'] = v;
                            });
                          },
                        ),
                        const Text('Indefinite (ongoing)'),
                      ],
                    ),
                    if (!indefinite) ...[
                      Slider(
                        value: weeks,
                        min: 4,
                        max: 20,
                        divisions: 16,
                        label: '${weeks.round()} weeks',
                        onChanged: (v) {
                          setStateSB(() { answers['weeks'] = v; });
                        },
                      ),
                      Text('${weeks.round()} weeks'),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: indefinite || answers['weeks'] != null ? nextQuestion : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("3. How many days a week can you realistically run?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) => ChoiceChip(
                label: Text('${i+1}'),
                selected: answers['days'] == (i+1),
                onSelected: (selected) { setState(() { answers['days'] = i+1; }); },
              )),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['days'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("4. Do you currently run?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...[
              'Not yet',
              'Occasionally',
              '1–2 times a week',
              '3+ times a week'
            ].map((label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RadioListTile<String>(
                value: label,
                groupValue: answers['current'],
                onChanged: (v) { setState(() { answers['current'] = v; }); },
                title: Text(label),
              ),
            )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['current'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("5. What’s your longest recent run?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setStateSB) {
                double km = (answers['longest'] ?? 5).toDouble();
                return Column(
                  children: [
                    Slider(
                      value: km,
                      min: 0,
                      max: 25,
                      divisions: 25,
                      label: '${km.round()} km',
                      onChanged: (v) {
                        setStateSB(() { answers['longest'] = v; });
                      },
                    ),
                    Text('${km.round()} km'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: answers['longest'] != null ? nextQuestion : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("6. Do you have a preferred long run day?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: answers['day'],
              hint: const Text('No preference'),
              items: [
                ...['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'].map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: (v) { setState(() { answers['day'] = v; }); },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['day'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("7. Do you want the program to include:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ...['Interval training','Hill repeats','Tempo runs','Audio pacing','Voice cues','Heart rate targets'].map((label) => FilterChip(
                  label: Text(label),
                  selected: (answers['include'] ?? <String>[]).contains(label),
                  onSelected: (selected) {
                    setState(() {
                      final list = List<String>.from(answers['include'] ?? <String>[]);
                      if (selected) {
                        list.add(label);
                      } else {
                        list.remove(label);
                      }
                      answers['include'] = list;
                    });
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: nextQuestion,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("8. Would you like to include a rest/recovery week every 4 weeks?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Yes'),
                  selected: answers['recovery'] == true,
                  onSelected: (selected) { setState(() { answers['recovery'] = true; }); },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('No'),
                  selected: answers['recovery'] == false,
                  onSelected: (selected) { setState(() { answers['recovery'] = false; }); },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers['recovery'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("9. What kind of program would you like?", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('🧘 Zen — gentle, flexible'),
                  selected: answers['program'] == 'Zen',
                  onSelected: (selected) { setState(() { answers['program'] = 'Zen'; }); },
                ),
                ChoiceChip(
                  label: const Text('🎯 Focused — goal-oriented, clear'),
                  selected: answers['program'] == 'Focused',
                  onSelected: (selected) { setState(() { answers['program'] = 'Focused'; }); },
                ),
                ChoiceChip(
                  label: const Text('🔥 Hardcore — aggressive improvement'),
                  selected: answers['program'] == 'Hardcore',
                  onSelected: (selected) { setState(() { answers['program'] = 'Hardcore'; }); },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ['program'] != null ? nextQuestion : null,
              child: const Text('Confirm'),
            ),
          ],
        );
      default:
        return Center(child: Text('All done!'));
    }
  }
}

