import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/authentication/domain/repositories/auth_repository.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/authentication/presentation/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeUser implements User {
  @override
  String get uid => 'user123';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  @override
  User? get user => FakeUser();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  bool loginCalled = false;
  bool shouldThrow = false;

  @override
  Future<UserCredential> login(String email, String password) async {
    loginCalled = true;
    if (shouldThrow) {
      throw Exception('Login failed');
    }
    return FakeUserCredential();
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirestoreService implements FirestoreService {
  @override
  Future<Map<String, dynamic>?> getDocument({required String path, required String documentId}) async {
    if (path == 'users' && documentId == 'user123') {
      return {'isActive': true, 'isDeleted': false};
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeFirestoreService fakeFirestoreService;
  late GoRouter router;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeFirestoreService = FakeFirestoreService();

    router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
  });

  Widget createTestWidget() {
    // Definimos el tamaño de la pantalla para evitar overflow en headless tests
    TestWidgetsFlutterBinding.ensureInitialized();
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        firestoreServiceProvider.overrideWithValue(fakeFirestoreService),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('LoginScreen Tests', () {
    testWidgets('renders login form correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('shows validation errors when fields are empty', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese su correo electrónico'), findsOneWidget);
      expect(find.text('Ingrese su contraseña'), findsOneWidget);
      expect(fakeAuthRepository.loginCalled, isFalse);
    });

    testWidgets('shows validation error for invalid email', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese un correo electrónico válido'), findsOneWidget);
      expect(fakeAuthRepository.loginCalled, isFalse);
    });

    testWidgets('successful login navigates to dashboard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.loginCalled, isTrue);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('failed login shows error message', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      fakeAuthRepository.shouldThrow = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle(); // Wait for state update

      expect(fakeAuthRepository.loginCalled, isTrue);
      expect(find.textContaining('Se produjo un problema inesperado. Intentá nuevamente.'), findsOneWidget);
    });
  });
}
