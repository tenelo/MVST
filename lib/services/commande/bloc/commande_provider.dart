import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'commande_bloc.dart';
import 'commande_state.dart';

// ignore: camel_case_types
class ticketsProvider extends BlocProvider<ticketsBloc> {
  ticketsProvider({
    super.key,
  }) : super(
          create: (context) => ticketsBloc(context),
          child: const ticketsView(),
        );
}

class ticketsView extends StatelessWidget {
  const ticketsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: close_sinks
    //final commandeBloc = BlocProvider.of<ticketsBloc>(context);

    final scaffold = Scaffold(
      body: BlocBuilder<ticketsBloc, ticketsState>(
        buildWhen: (pre, current) => true,
        builder: (context, state) {
          return const Center(
            child: Text("Hi...Welcome to BLoC"),
          );
        },
      ),
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<ticketsBloc, ticketsState>(
          listenWhen: (pre, current) => pre.error != current.error,
          listener: (context, state) {
            if (state.error.isNotEmpty) {
              print("ERROR: ${state.error}");
            }
          },
        ),
      ],
      child: scaffold,
    );
  }
}
