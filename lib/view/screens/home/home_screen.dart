import 'package:flutter/material.dart';
import 'package:golden_owl/view/screens/home/home_bloc/home_form.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_owl/view/screens/home/home_bloc/home_bloc.dart';

import 'home_bloc/home_event.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => HomeBloc(),
      child: HomeForm(),
    );
  }
}
