import 'package:flutter/material.dart';

class ExploreWorkoutsPage extends StatelessWidget {
  const ExploreWorkoutsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Workouts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Curated Workouts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _workoutCard(
            context,
            title: 'Interval Blast',
            description: 'A high-intensity interval session for speed and endurance.',
            color: Colors.blue[50],
          ),
          _workoutCard(
            context,
            title: 'Hill Repeats',
            description: 'Build strength and power with structured hill repeats.',
            color: Colors.green[50],
          ),
          _workoutCard(
            context,
            title: 'Tempo Builder',
            description: 'Sustain a challenging pace to improve your lactate threshold.',
            color: Colors.orange[50],
          ),
          _workoutCard(
            context,
            title: 'Long Run Adventure',
            description: 'A scenic, steady long run for endurance and enjoyment.',
            color: Colors.purple[50],
          ),
          const SizedBox(height: 32),
          Text(
            'More coming soon! 🎨',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _workoutCard(BuildContext context, {required String title, required String description, Color? color}) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary),
        onTap: () {
          // TODO: Show workout details or add to library
        },
      ),
    );
  }
}
