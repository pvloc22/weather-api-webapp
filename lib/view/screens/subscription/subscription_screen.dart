import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/view/screens/subscription/subscription_bloc/subscription_bloc.dart';
import 'package:golden_owl/view/screens/subscription/subscription_bloc/subscription_form.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionBloc(),
      child: SubscriptionForm(),
    );
  }
} 