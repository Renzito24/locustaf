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

- **`lib/features/companies/presentation/widgets/superadmin_settings_panel.dart`**
  - **Acción:** Refactorizado. Se extrajeron los chips de métricas y la tabla de pagos a `superadmin_settings_components.dart`.
  - **Tests:** Se creó `test/features/companies/presentation/widgets/superadmin_settings_panel_test.dart` comprobando el comportamiento sin mutaciones.

- **`lib/features/dashboard/presentation/screens/employee_home_screen.dart`**
  - **Acción:** Refactorizado. Se extrajeron las tarjetas de métricas y detalles del lugar de trabajo a `employee_home_components.dart`.
  - **Tests:** Tests verificados en `employee_home_screen_test.dart`.

- **`lib/features/reports/presentation/screens/reports_screen.dart`**
  - **Acción:** Refactorizado. Se extrajeron los filtros, cabecera, tabla y tarjetas de métricas a `reports_components.dart`.
  - **Tests:** Se verificó usando `reports_screen_test.dart`.

- **`lib/features/employees/presentation/widgets/employee_form.dart`**
  - **Acción:** Refactorizado. Se extrajeron los campos de contraseñas, dropdowns de roles y lugares de trabajo, junto con estilos de inputs, a `employee_form_components.dart`.
  - **Tests:** Comprobados en `employee_form_dni_test.dart`.

- **`lib/features/profile/presentation/screens/profile_screen.dart`**
  - **Acción:** Refactorizado. Se extrajeron las secciones de UI (editar, tarjetas de información, seguridad) a `profile_components.dart`.
  - **Tests:** Se creó `test/features/profile/presentation/screens/profile_screen_test.dart` y se comprobó el correcto funcionamiento tras el refactor.

- **`lib/core/theme/app_theme.dart`**
  - **Acción:** Refactorizado. Se extrajeron los decoradores visuales a `app_theme_decorations.dart` y los widgets a `app_theme_components.dart`.
  - **Tests:** Se creó `test/core/theme/app_theme_test.dart` antes del refactor para garantizar cero cambios en el comportamiento.

- **`lib/features/workplaces/presentation/widgets/workplace_map_picker.dart`**
  - **Acción:** Refactorizado. Se dividió la pantalla en varios subcomponentes en `workplace_map_picker_components.dart`.
  - **Tests:** Se verificó usando `test/features/workplaces/presentation/widgets/workplace_map_picker_test.dart`.

- **`lib/features/employees/presentation/widgets/employee_card.dart`**
  - **Acción:** Refactorizado. Se extrajeron los elementos del UI como avatares, detalles, el menú de acciones y diálogos a `employee_card_components.dart`. Además se solucionó un problema de `RenderFlex overflow` oculto en tests al abrir los PopupMenuItem.
  - **Tests:** Se creó `test/features/employees/presentation/widgets/employee_card_test.dart` y se comprobó su funcionamiento.

- **`lib/features/workplaces/presentation/screens/workplaces_screen.dart`**
  - **Acción:** Refactorizado. Se extrajeron los chips de filtrado, la tarjeta `WorkplaceCard` y los diálogos a `workplaces_screen_components.dart`.
  - **Tests:** Se creó `test/features/workplaces/presentation/screens/workplaces_screen_test.dart` y se comprobó el funcionamiento antes y después del refactor.

- **`lib/features/medical_documents/presentation/widgets/medical_document_form.dart`**
  - **Acción:** Refactorizado. Se extrajeron los inputs, el file picker y los date pickers a `medical_document_form_components.dart`.
  - **Tests:** Se arregló y ejecutó el test `test/features/medical_documents/presentation/widgets/medical_document_form_test.dart` antes y después de la refactorización.

- **`lib/features/reports/presentation/screens/employee_reports_screen.dart`**
  - **Acción:** Refactorizado. Se extrajeron la barra de filtros y la sección de exportación a `employee_reports_components.dart`.
  - **Tests:** Se verificó el funcionamiento con `employee_reports_screen_test.dart` antes y después de la refactorización.

- **`lib/features/history/presentation/screens/history_screen.dart`**
  - **Acción:** Refactorizado. Se extrajeron componentes como tarjetas de indicadores, botón de cargar más y tablas de datos a `history_components.dart`.
  - **Tests:** Se creó `test/features/history/presentation/screens/history_screen_test.dart` y se comprobó el funcionamiento antes y después del refactor.

## Próximos Candidatos (Pendientes)
14. `lib/features/companies/presentation/widgets/company_card.dart`
15. `lib/features/companies/presentation/widgets/company_form.dart`
16. `lib/features/attendance/presentation/widgets/admin_attendance_view.dart`
17. `lib/features/medical_documents/presentation/screens/medical_documents_screen.dart`
18. `lib/features/incidences/presentation/screens/incidences_screen.dart`
19. `lib/features/medical_documents/presentation/providers/medical_documents_provider.dart`
20. `lib/features/attendance/presentation/providers/attendance_notifier.dart`
21. `lib/core/services/report_exporter.dart`
