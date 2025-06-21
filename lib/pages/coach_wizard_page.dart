import 'package:flutter/material.dart';

class CoachWizardPage extends StatefulWidget {
  const CoachWizardPage({Key? key}) : super(key: key);

  @override
  State<CoachWizardPage> createState() => _CoachWizardPageState();
}

class _CoachWizardPageState extends State<CoachWizardPage> {
  int questionIndex = 0;
  final Map<String, dynamic> answers = {};
  bool started = true;

  void nextQuestion() {
    setState(() {
      questionIndex++;
    });
  }

  Widget buildQuestion(BuildContext context) {
    switch (questionIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/goals.png',
                height: 300,
                width: 300,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
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
      // ...existing code for other questions...
      default:
        return Center(child: Text('All done!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalQuestions = 9;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Longview Coach'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
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
                    child: buildQuestion(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
