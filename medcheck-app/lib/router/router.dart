import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pill_reminder_app/models/enums.dart';
import 'package:pill_reminder_app/providers/auth_provider.dart';
import 'package:pill_reminder_app/screens/archived/archived_medications_screen.dart';
import 'package:pill_reminder_app/screens/caregivers/caregiver_home_screen.dart';
import 'package:pill_reminder_app/screens/caregivers/caregivers_screen.dart';
import 'package:pill_reminder_app/screens/caregivers/patient_detail_screen.dart';
import 'package:pill_reminder_app/screens/caregivers/patient_history_screen.dart';
import 'package:pill_reminder_app/screens/caregivers/patient_medication_action_screen.dart';
import 'package:pill_reminder_app/screens/caregivers/patient_medications_screen.dart';
import 'package:pill_reminder_app/widgets/caregivers/pdf_report_viewer.dart';
import 'package:pill_reminder_app/screens/home/home_screen.dart';
import 'package:pill_reminder_app/screens/medications/add_medication_screen.dart';
import 'package:pill_reminder_app/screens/medications/edit_medication_screen.dart';
import 'package:pill_reminder_app/screens/medications/medication_detail_screen.dart';
import 'package:pill_reminder_app/screens/medications/medications_screen.dart';
import 'package:pill_reminder_app/screens/onboarding/onboarding_config_screen.dart';
import 'package:pill_reminder_app/screens/onboarding/onboarding_notifications_screen.dart';
import 'package:pill_reminder_app/screens/onboarding/onboarding_welcome_screen.dart';
import 'package:pill_reminder_app/screens/profile/edit_personal_data_screen.dart';
import 'package:pill_reminder_app/screens/profile/profile_screen.dart';
import 'package:pill_reminder_app/screens/shell/main_shell.dart';
import 'package:pill_reminder_app/screens/splash/splash_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const splashName = 'splash';

  static const home = '/home';
  static const homeName = 'home';

  static const medications = '/medications';
  static const medicationsName = 'medications';

  static const medicationDetail = '/medications/:id';
  static const medicationDetailName = 'medicationDetail';

  static const profile = '/profile';
  static const profileName = 'profile';

  static const addMedication = '/add-medication';
  static const addMedicationName = 'addMedication';

  static const editMedication = '/edit-medication/:id';
  static const editMedicationName = 'editMedication';

  static const archivedMedications = '/archived';
  static const archivedMedicationsName = 'archivedMedications';

  static const archivedDetail = '/archived/:id';
  static const archivedDetailName = 'archivedDetail';

  static const caregivers = '/caregivers';
  static const caregiversName = 'caregivers';

  static const patientDetail = '/patient/:id';
  static const patientDetailName = 'patientDetail';

  static const patientMedications = '/patient/:id/medications';
  static const patientMedicationsName = 'patientMedications';

  static const patientMedicationAction = '/patient/:id/medications/action';
  static const patientMedicationActionName = 'patientMedicationAction';

  static const patientMedicationEdit =
      '/patient/:id/medications/:medicationId/action';
  static const patientMedicationEditName = 'patientMedicationEdit';

  static const patientHistory = '/patient/:id/history';
  static const patientHistoryName = 'patientHistory';

  static const patientReport = '/patient/:id/report';
  static const patientReportName = 'patientReport';

  static const myReport = '/my-report';
  static const myReportName = 'myReport';

  static const editPersonalData = '/edit-personal-data';
  static const editPersonalDataName = 'editPersonalData';

  static const onboardingWelcome = '/onboarding';
  static const onboardingWelcomeName = 'onboardingWelcome';

  static const onboardingNotifications = '/onboarding/notifications';
  static const onboardingNotificationsName = 'onboardingNotifications';

  static const onboardingConfig = '/onboarding/config';
  static const onboardingConfigName = 'onboardingConfig';
}

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.asData?.value?.role;
});

GoRouter createRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const _HomeRouterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.medications,
                name: AppRoutes.medicationsName,
                builder: (context, state) => const MedicationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addMedication,
        name: AppRoutes.addMedicationName,
        builder: (context, state) => const AddMedicationScreen(),
      ),
      GoRoute(
        path: AppRoutes.editMedication,
        name: AppRoutes.editMedicationName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return EditMedicationScreen(medicationId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.medicationDetail,
        name: AppRoutes.medicationDetailName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return MedicationDetailScreen(medicationId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.archivedMedications,
        name: AppRoutes.archivedMedicationsName,
        builder: (context, state) => const ArchivedMedicationsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: AppRoutes.archivedDetailName,
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id'] ?? '0');
              return MedicationDetailScreen(medicationId: id, isArchived: true);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.caregivers,
        name: AppRoutes.caregiversName,
        builder: (context, state) => const CaregiversScreen(),
      ),
      GoRoute(
        path: AppRoutes.patientDetail,
        name: AppRoutes.patientDetailName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return PatientDetailScreen(linkId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.patientMedicationAction,
        name: AppRoutes.patientMedicationActionName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return PatientMedicationActionScreen(linkId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.patientMedicationEdit,
        name: AppRoutes.patientMedicationEditName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          final medicationId = state.pathParameters['medicationId'];
          return PatientMedicationActionScreen(
            linkId: id,
            medicationId: medicationId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.patientMedications,
        name: AppRoutes.patientMedicationsName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return PatientMedicationsScreen(linkId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.patientHistory,
        name: AppRoutes.patientHistoryName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          return PatientHistoryScreen(linkId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.patientReport,
        name: AppRoutes.patientReportName,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id'] ?? '0');
          final patientName = state.uri.queryParameters['patient_name'] ?? '';
          return PdfReportViewer(linkId: id, patientName: patientName);
        },
      ),
      GoRoute(
        path: AppRoutes.myReport,
        name: AppRoutes.myReportName,
        builder: (context, state) {
          final patientName =
              state.uri.queryParameters['patientName'] ?? 'Paciente';
          return PdfReportViewer(patientName: patientName, isOwnReport: true);
        },
      ),
      GoRoute(
        path: AppRoutes.editPersonalData,
        name: AppRoutes.editPersonalDataName,
        builder: (context, state) => const EditPersonalDataScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingWelcome,
        name: AppRoutes.onboardingWelcomeName,
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingNotifications,
        name: AppRoutes.onboardingNotificationsName,
        builder: (context, state) => const OnboardingNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingConfig,
        name: AppRoutes.onboardingConfigName,
        builder: (context, state) => const OnboardingConfigScreen(),
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) => createRouter(ref));

class _HomeRouterScreen extends ConsumerWidget {
  const _HomeRouterScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    if (role == UserRole.caregiver) {
      return const CaregiverHomeScreen();
    }
    return const HomeScreen();
  }
}

// Keep backward compatibility
GoRouter get appRouter =>
    throw UnimplementedError('Use appRouterProvider instead');
