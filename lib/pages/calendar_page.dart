import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Calendar Page',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
