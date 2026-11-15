import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_repository.dart';
import 'data/book_repository.dart';
import 'data/listing_repository.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';

class BookSwapApp extends StatelessWidget {
  const BookSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories (data layer). Tests replace these with fakes.
        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
        Provider<ListingRepository>(create: (_) => FirestoreListingRepository()),
        Provider<BookRepository>(create: (_) => FunctionsBookRepository()),
        // App-wide view model. Page-level view models are created in their pages.
        ChangeNotifierProvider<AuthViewModel>(
          create: (c) => AuthViewModel(c.read<AuthRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'BookSwap',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF0B6B57), useMaterial3: true),
        home: const AuthGate(),
      ),
    );
  }
}

/// Shows login, "verify your email", or the app, depending on the auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    if (user == null) return const LoginPage();
    if (!user.emailVerified) return const VerifyEmailPage();
    return const HomePage();
  }
}
