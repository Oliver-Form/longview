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
        // Welcome page
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/goals.png',
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/coach.png', height: 120, fit: BoxFit.contain),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to Longview Coach!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Let’s build a running plan that fits your life, goals, and preferences.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: nextQuestion,
                      child: const Text('Get Started'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        // Program creation explanation
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/goals.png',
                fit: BoxFit.cover,
              ),
            ), 
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      'How it works',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Answer a few quick questions and Longview will create a personalized running program for you. You can always adjust your plan later!',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: nextQuestion,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 2:
        // 1. What’s your primary goal?
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/goals.png',
                fit: BoxFit.cover,
              ),
            ),
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
      case 3:
        // 2. How long do you want this plan to be?
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
                            setState(() {});
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
                          setState(() {});
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
      case 4:
        // 3. How many days a week can you realistically run?
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
      case 5:
        // 4. Do you currently run?
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

  // Define the new question flow
  late final List<_WizardQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = [
      // 1. Primary goal
      _WizardQuestion(
        key: 'primary_goal',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("What is your primary goal?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...['General fitness', 'Train for a race', 'Improve speed or endurance'].map((label) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RadioListTile<String>(
                  value: label,
                  groupValue: answers['primary_goal'],
                  onChanged: (v) { setStateParent(() { answers['primary_goal'] = v; }); },
                  title: Text(label),
                ),
              )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['primary_goal'] != null ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 2. Race distance (if race)
      _WizardQuestion(
        key: 'race_distance',
        builder: (context, answers, onNext, setStateParent) {
          if (answers['primary_goal'] != 'Train for a race') return const SizedBox.shrink();
          return _WizardBackground(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("What race distance are you training for?", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ...['5K', '10K', 'Half marathon', 'Marathon', 'Other'].map((d) => RadioListTile<String>(
                  value: d,
                  groupValue: answers['race_distance'],
                  onChanged: (v) { setStateParent(() { answers['race_distance'] = v; }); },
                  title: Text(d),
                )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: answers['race_distance'] != null ? onNext : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          );
        },
      ),
      // 3. Race date (if race)
      _WizardQuestion(
        key: 'race_date',
        builder: (context, answers, onNext, setStateParent) {
          if (answers['primary_goal'] != 'Train for a race') return const SizedBox.shrink();
          return _WizardBackground(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("When is your race?", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setStateParent(() { answers['race_date'] = picked; });
                    }
                  },
                  child: Text(answers['race_date'] != null ?
                    'Selected: \\${answers['race_date'].toString().split(' ')[0]}' : 'Pick a date'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: answers['race_date'] != null ? onNext : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          );
        },
      ),
      // 4. Consistent running in past 2 months
      _WizardQuestion(
        key: 'recent_running',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Have you done consistent running in the past 2 months?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...['Yes', 'No'].map((label) => RadioListTile<String>(
                value: label,
                groupValue: answers['recent_running'],
                onChanged: (v) { setStateParent(() { answers['recent_running'] = v; }); },
                title: Text(label),
              )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['recent_running'] != null ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 5. How far can you currently run without stopping?
      _WizardQuestion(
        key: 'current_run_duration',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How far can you currently run without stopping?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...['Less than 5 minutes', '5–15 minutes', '15–30 minutes', '30+ minutes'].map((label) => RadioListTile<String>(
                value: label,
                groupValue: answers['current_run_duration'],
                onChanged: (v) { setStateParent(() { answers['current_run_duration'] = v; }); },
                title: Text(label),
              )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['current_run_duration'] != null ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 6. Running experience
      _WizardQuestion(
        key: 'experience',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How would you describe your running experience?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...['Beginner', 'Intermediate', 'Experienced'].map((label) => RadioListTile<String>(
                value: label,
                groupValue: answers['experience'],
                onChanged: (v) { setStateParent(() { answers['experience'] = v; }); },
                title: Text(label),
              )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['experience'] != null ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 7. Days per week
      _WizardQuestion(
        key: 'days_per_week',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How many days per week can you run?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) => ChoiceChip(
                  label: Text('${i+1}'),
                  selected: answers['days_per_week'] == (i+1),
                  onSelected: (selected) { setStateParent(() { answers['days_per_week'] = i+1; }); },
                )),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['days_per_week'] != null ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 8. Which days available
      _WizardQuestion(
        key: 'days_available',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Which days are you available to run?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ...['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d) => FilterChip(
                    label: Text(d),
                    selected: (answers['days_available'] ?? <String>[]).contains(d),
                    onSelected: (selected) {
                      setStateParent(() {
                        final list = List<String>.from(answers['days_available'] ?? <String>[]);
                        if (selected) {
                          list.add(d);
                        } else {
                          list.remove(d);
                        }
                        answers['days_available'] = list;
                      });
                    },
                  )),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (answers['days_available'] != null && (answers['days_available'] as List).isNotEmpty) ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 9. Longest run slider
      _WizardQuestion(
        key: 'longest_run',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("What’s the longest you’re willing to run on your longest run?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setStateSB) {
                  double value = (answers['longest_run'] ?? 30).toDouble();
                  return Column(
                    children: [
                      Slider(
                        value: value,
                        min: 10,
                        max: 180,
                        divisions: 34,
                        label: '${value.round()} min',
                        onChanged: (v) {
                          setStateSB(() { answers['longest_run'] = v; });
                          setStateParent(() {});
                        },
                      ),
                      Text('${value.round()} minutes'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['longest_run'] != null ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 10. Simple or variety plan
      _WizardQuestion(
        key: 'plan_type',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Do you want a simple plan or one with more variety (intervals, tempos, hills)?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...['Simple (easy + long runs only)', 'Variety (includes speed & structure)'].map((label) => RadioListTile<String>(
                value: label,
                groupValue: answers['plan_type'],
                onChanged: (v) { setStateParent(() { answers['plan_type'] = v; }); },
                title: Text(label),
              )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['plan_type'] != null ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
      // 11. Injuries/limitations
      _WizardQuestion(
        key: 'injuries',
        builder: (context, answers, onNext, setStateParent) => _WizardBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Any injuries or limitations we should account for?", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...['No', 'Yes'].map((label) => RadioListTile<String>(
                value: label,
                groupValue: answers['injuries'],
                onChanged: (v) { setStateParent(() { answers['injuries'] = v; }); },
                title: Text(label),
              )),
              if (answers['injuries'] == 'Yes') ...[
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Please describe',
                  ),
                  onChanged: (v) { setStateParent(() { answers['injuries_note'] = v; }); },
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: answers['injuries'] != null ? onNext : null,
                child: const Text('Finish'),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Helper: find next visible question index (forward or backward)
  int _findNextVisibleIndex(int start, {bool forward = true}) {
    int idx = start;
    while (idx >= 0 && idx < _questions.length) {
      final testWidget = _questions[idx].builder(context, answers, () {}, setState);
      if (testWidget is! SizedBox || (testWidget is SizedBox && (testWidget.width != 0 || testWidget.height != 0))) {
        return idx;
      }
      idx += forward ? 1 : -1;
    }
    return idx.clamp(0, _questions.length - 1);
  }

  void nextQuestion() {
    setState(() {
      int nextIdx = questionIndex + 1;
      nextIdx = _findNextVisibleIndex(nextIdx, forward: true);
      if (nextIdx >= _questions.length) {
        // Done, pop or show summary
        Navigator.of(context).pop();
        return;
      }
      questionIndex = nextIdx;
    });
  }

  void prevQuestion() {
    setState(() {
      int prevIdx = questionIndex - 1;
      if (prevIdx < 0) {
        Navigator.of(context).pop();
        return;
      }
      prevIdx = _findNextVisibleIndex(prevIdx, forward: false);
      questionIndex = prevIdx;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = _questions.where((q) {
      // Only count visible questions for progress
      final testWidget = q.builder(context, answers, () {}, setState);
      return testWidget is! SizedBox || (testWidget is SizedBox && (testWidget.width != 0 || testWidget.height != 0));
    }).length;
    final currentVisibleIndex = () {
      int idx = 0;
      for (int i = 0; i <= questionIndex && i < _questions.length; i++) {
        final testWidget = _questions[i].builder(context, answers, () {}, setState);
        if (testWidget is! SizedBox || (testWidget is SizedBox && (testWidget.width != 0 || testWidget.height != 0))) {
          idx++;
        }
      }
      return idx;
    }();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/goals.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // X button in top left
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Exit setup',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                  child: LinearProgressIndicator(
                    value: totalQuestions > 0 ? (currentVisibleIndex / totalQuestions) : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Back button (now always shown)
                Padding(
                  padding: const EdgeInsets.only(left: 0, bottom: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: () {
                        if (questionIndex == 0) {
                          Navigator.of(context).pop();
                        } else {
                          prevQuestion();
                        }
                      },
                    ),
                  ),
                ),
                // White question container
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 280,
                          maxWidth: 400,
                        ),
                        child: Container(
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
                            child: _questions[questionIndex].builder(context, answers, nextQuestion, setState),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardBackground extends StatelessWidget {
  final Widget child;
  const _WizardBackground({required this.child});
  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _WizardQuestion {
  final String key;
  final Widget Function(BuildContext context, Map<String, dynamic> answers, VoidCallback onNext, void Function(VoidCallback fn) setStateParent) builder;
  _WizardQuestion({required this.key, required this.builder});
}

