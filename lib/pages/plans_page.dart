import 'package:flutter/material.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Plans Page',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
