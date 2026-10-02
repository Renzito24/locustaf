# Registro de Refactorización

Este archivo mantiene un registro de todos los archivos que han sido refactorizados, limpiados o modularesizados bajo las reglas estrictas de mantener la lógica de negocio intacta y asegurar la cobertura de tests antes de modificar.

## Archivos Refactorizados

- **`lib/features/companies/presentation/screens/companies_screen.dart`**
  - **Acción:** Modularizado para extraer métricas y lista a widgets separados.
  - **Tests:** Se aseguraron los tests correspondientes.
  
- **`lib/features/medical_documents/presentation/widgets/medical_document_detail_dialog.dart`**
  - **Acción:** Refactorizado para mejorar legibilidad y reducir longitud.

- **`lib/features/workplaces/presentation/screens/workplace_form_screen.dart`**
  - **Acción:** Reducido de >500 líneas. Se extrajeron los campos del formulario en secciones lógicas (`workplace_form_sections.dart`).
  - **Tests:** Se creó `test/features/workplaces/presentation/screens/workplace_form_screen_test.dart` antes de la refactorización para garantizar cero cambios en el comportamiento.

- **`lib/features/authentication/presentation/screens/login_screen.dart`**
  - **Acción:** Refactorizado. Se extrajeron los campos del formulario en componentes más pequeños (`login_form_fields.dart`).
  - **Tests:** Se creó `test/features/authentication/presentation/screens/login_screen_test.dart` y se comprobó el correcto funcionamiento tras el refactor.

- **`lib/features/companies/presentation/screens/onboarding_screen.dart`**
  - **Acción:** Refactorizado. Se dividió el largo formulario en pequeños componentes extraídos en `onboarding_form_sections.dart`.
  - **Tests:** Se creó `test/features/companies/presentation/screens/onboarding_screen_test.dart` y se comprobó que todas las pruebas pasaran exitosamente tras el refactor.

## Próximos Candidatos (Pendientes)
3. `lib/features/companies/presentation/widgets/superadmin_settings_panel.dart`
4. `lib/features/dashboard/presentation/screens/employee_home_screen.dart`
5. `lib/features/reports/presentation/screens/reports_screen.dart`
6. `lib/features/employees/presentation/widgets/employee_form.dart`
7. `lib/features/profile/presentation/screens/profile_screen.dart`
8. `lib/features/employees/presentation/widgets/employee_card.dart`
9. `lib/features/workplaces/presentation/screens/workplaces_screen.dart`
10. `lib/features/workplaces/presentation/widgets/workplace_map_picker.dart`
11. `lib/features/medical_documents/presentation/widgets/medical_document_form.dart`
12. `lib/features/reports/presentation/screens/employee_reports_screen.dart`
13. `lib/features/history/presentation/screens/history_screen.dart`
14. `lib/features/companies/presentation/widgets/company_card.dart`
15. `lib/features/companies/presentation/widgets/company_form.dart`
16. `lib/features/attendance/presentation/widgets/admin_attendance_view.dart`
17. `lib/features/medical_documents/presentation/screens/medical_documents_screen.dart`
18. `lib/features/incidences/presentation/screens/incidences_screen.dart`
19. `lib/core/theme/app_theme.dart`
20. `lib/features/medical_documents/presentation/providers/medical_documents_provider.dart`
21. `lib/features/attendance/presentation/providers/attendance_notifier.dart`
22. `lib/core/services/report_exporter.dart`
