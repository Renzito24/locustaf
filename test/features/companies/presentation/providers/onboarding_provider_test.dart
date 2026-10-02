import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/authentication/data/services/auth_service.dart';
import 'package:app_locustaf/features/companies/presentation/providers/onboarding_provider.dart';

class MockUser implements User {
  @override
  final String uid = 'admin_uid_123';
  @override
  final String? email = 'admin@example.com';
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthService implements AuthService {
  User? _currentUser;
  
  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  @override
  User? get currentUser => _currentUser;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late ProviderContainer container;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(fakeFirestore);
    mockAuthService = MockAuthService();
    mockUser = MockUser();

    mockAuthService.setCurrentUser(mockUser);

    container = ProviderContainer(
      overrides: [
        firestoreServiceProvider.overrideWithValue(firestoreService),
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingNotifier', () {
    test('initial state is not loading and no error', () {
      final state = container.read(onboardingProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('createCompanyAndAdmin fails if no current user', () async {
      mockAuthService.setCurrentUser(null);

      final notifier = container.read(onboardingProvider.notifier);

      final profile = UserModel(
        id: '',
        email: 'admin@example.com',
        nombre: 'Admin',
        apellido: 'Test',
        dni: '12345678',
        rol: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final company = CompanyModel(
        id: '',
        nombreComercial: 'Test Company',
        razonSocial: 'Test Company SA',
        cuit: '20123456789',
        plan: CompanyPlan.mensual,
        createdAt: DateTime.now(),
        createdBy: '',
      );

      await notifier.createCompanyAndAdmin(profile: profile, company: company);

      final state = container.read(onboardingProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, 'No hay sesión activa.');
    });

    test('createCompanyAndAdmin creates company and user documents correctly', () async {
      final notifier = container.read(onboardingProvider.notifier);

      final profile = UserModel(
        id: '',
        email: 'admin@example.com',
        nombre: 'Admin',
        apellido: 'Test',
        dni: '12345678',
        rol: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final company = CompanyModel(
        id: '',
        nombreComercial: 'Test Company',
        razonSocial: 'Test Company SA',
        cuit: '20123456789',
        plan: CompanyPlan.mensual,
        createdAt: DateTime.now(),
        createdBy: '',
      );

      await notifier.createCompanyAndAdmin(profile: profile, company: company);

      final state = container.read(onboardingProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);

      // Verify company was created
      final companiesSnapshot = await fakeFirestore.collection('companies').get();
      expect(companiesSnapshot.docs.length, 1);
      final companyDoc = companiesSnapshot.docs.first;
      expect(companyDoc.data()['nombreComercial'], 'Test Company');
      expect(companyDoc.data()['createdBy'], 'admin_uid_123');

      // Verify user was created
      final userDoc = await fakeFirestore.collection('users').doc('admin_uid_123').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['nombre'], 'Admin');
      expect(userDoc.data()?['rol'], 'admin');
      expect(userDoc.data()?['companyId'], companyDoc.id);
      expect(userDoc.data()?['acceptedPoliciesAt'], isNotNull);
    });
  });
}
