# LOCUSTAF - Technical Specification

# Module: Employees (CRUD)

Version: 1.0

Status: Approved

Author: LOCUSTAF Architecture

---

# 1. Objective

Implement the complete Employees module of LOCUSTAF.

This module is responsible for managing all employees of the system.

An employee is represented internally by UserModel with:

UserRole.empleado

There is NO EmployeeModel.

---

# 2. Current Project State

The project already contains:

✔ Flutter Web
✔ Firebase Authentication
✔ Cloud Firestore
✔ Riverpod
✔ GoRouter
✔ DashboardLayout
✔ Sidebar navigation
✔ FirestoreService
✔ AuthService
✔ UserModel
✔ WorkplaceModel
✔ AttendanceModel
✔ MedicalDocumentModel

The architecture is considered stable.

No architectural refactoring is allowed.

---

# 3. Architecture Rules (MANDATORY)

The project follows Feature First Architecture.

Each feature must contain only:

data/
domain/
presentation/

No additional layers are allowed.

Example:

features/
    employees/
        data/
        domain/
        presentation/

---

# 4. Responsibilities

Presentation

Contains:

Screens

Widgets

Riverpod Providers

UI State

No Firebase code.

No Firestore code.

No business logic.

---

Domain

Contains:

Repositories (interfaces)

Business contracts

No implementation.

No Firebase imports.

---

Data

Contains:

Repositories implementations

Services

Models

Firebase communication

Firestore communication

---

Core

Contains only reusable infrastructure.

Examples:

FirestoreService

Router

Theme

Constants

Validators

Extensions

Never place feature-specific logic inside core.

---

# 5. Existing Components

The following components already exist and MUST be reused.

FirebaseAuth

FirestoreService

AuthService

DashboardLayout

GoRouter

RoutePaths

Riverpod

UserModel

No duplicate implementations are allowed.

---

# 6. Employee Definition

Employees are users.

Employee == UserModel

role == UserRole.empleado

Do NOT create:

EmployeeModel

EmployeeEntity

EmployeeDTO

Any duplicate model.

---

# 7. Firestore Collection

Collection:

users

Document ID:

Firebase UID

Fields:

id

nombre

apellido

email

dni

telefono

rol

isActive

lugarDeTrabajoId

createdAt

updatedAt

The structure must match UserModel exactly.

---

# 8. Module Goal

The Employees module must allow administrators to:

View employees

Create employees

Edit employees

Disable employees

Enable employees

Search employees

Filter active/inactive employees

Future deletion should be logical (soft delete).

Never physical delete.

---

# 9. General Restrictions

DO NOT:

Modify Auth Guard

Modify Router

Modify DashboardLayout

Modify Sidebar

Modify FirestoreService unless strictly necessary

Create duplicate services

Create duplicate repositories

Break Feature First architecture

Change UserModel

Create EmployeeModel

Move folders

Rename public classes

Introduce new packages without justification

---

END OF PART 1

---

# 10. Functional Requirements

The Employees module must implement the following use cases.

## UC-01 - List Employees

The administrator can view all employees.

Requirements:

- Read employees from Firestore.
- Display only users where:
  role == empleado
- Sort alphabetically by last name.
- Show loading state.
- Show empty state.
- Show error state.

---

## UC-02 - Create Employee

The administrator can create a new employee.

Required fields:

- Nombre
- Apellido
- DNI
- Email
- Password
- Teléfono (optional)
- Workplace
- Active

Flow:

1. Validate form.
2. Create Authentication account.
3. Obtain Firebase UID.
4. Create Firestore document.
5. Refresh employee list.
6. Show success feedback.

The process must be atomic whenever possible.

---

## UC-03 - Edit Employee

The administrator can edit:

- Nombre
- Apellido
- DNI
- Teléfono
- Workplace
- Active status

Email cannot be edited in MVP.

Password cannot be edited here.

---

## UC-04 - Enable / Disable Employee

Employees must never be physically deleted.

Instead:

isActive = false

or

isActive = true

All queries must respect this value.

---

## UC-05 - Search Employees

The administrator can search by:

- Nombre
- Apellido
- DNI
- Email

Searching should happen in memory for MVP.

---

## UC-06 - Filter Employees

Available filters:

All

Active

Inactive

Assigned Workplace

Unassigned

---

# 11. User Interface Requirements

The Employees screen must follow the existing Dashboard design.

The DashboardLayout already provides:

- AppBar
- Sidebar
- Responsive layout

EmployeesScreen must provide only its own content.

No nested Scaffold.

No nested AppBar.

---

# 12. Riverpod Rules

Business logic must never be placed inside widgets.

Widgets only consume providers.

Presentation layer communicates only with providers.

Providers communicate with repositories.

Repositories communicate with services.

Services communicate with Firebase.

The dependency direction must always be:

Presentation
↓

Domain
↓

Data
↓

Core

Never the opposite.

---

# 13. Repository Responsibilities

UsersRepository must expose:

- getUsers()
- createUser()
- updateUser()
- setUserActive()
- getUserById()

Repository implementations must not contain UI logic.

---

# 14. Firestore Rules

Collection:

users

Document ID:

Firebase UID

Never generate random IDs.

Firestore document structure must always match UserModel.

Never store redundant information.

---

# 15. Authentication Rules

Employee creation requires:

Firebase Authentication

+

Firestore

If Authentication fails:

Do not create Firestore document.

If Firestore fails:

The implementation should avoid leaving inconsistent data whenever feasible, and any limitation should be documented in the implementation report.

---

END OF PART 2

---

# 16. Allowed Files

The implementation MAY modify only the following files and any new files that are strictly necessary within the employees feature.

Allowed directories:

lib/features/employees/

The following shared infrastructure may also be modified only if required:

lib/core/services/
lib/core/router/
lib/core/constants/

Only when the modification is directly related to the Employees module.

---

# 17. Protected Files

The following files must NOT be modified without explicit authorization.

Authentication

lib/features/authentication/

Dashboard

lib/features/dashboard/

Routing

lib/core/router/app_router.dart

DashboardLayout

lib/features/dashboard/presentation/widgets/dashboard_layout.dart

Sidebar

lib/features/dashboard/presentation/widgets/sidebar.dart

UserModel

lib/features/authentication/data/models/user_model.dart

FirestoreService

lib/core/services/firestore_service.dart

Unless a real bug is found.

---

# 18. Code Quality Requirements

The implementation must follow:

Single Responsibility Principle

Clean Architecture

Feature First Architecture

Riverpod best practices

Small reusable widgets

No duplicated code

No dead code

No commented code

No unused imports

No magic numbers

Meaningful variable names

Const constructors whenever possible

Use Equatable where appropriate

---

# 19. Performance Requirements

Avoid unnecessary rebuilds.

Avoid unnecessary Firestore reads.

Avoid duplicated streams.

Reuse providers.

Prefer immutable models.

---

# 20. Acceptance Criteria

The module will be considered complete only if:

✓ Project compiles successfully.

✓ flutter analyze reports zero issues.

✓ Existing functionality remains intact.

✓ Login continues working.

✓ Logout continues working.

✓ Dashboard navigation continues working.

✓ Employees list loads correctly.

✓ Employee creation works.

✓ Employee update works.

✓ Employee activation/deactivation works.

✓ Search works.

✓ Filters work.

✓ No architectural violations were introduced.

---

# 21. Mandatory Final Report

After implementation, provide a report containing:

1. Files created

2. Files modified

3. Files deleted

4. Public APIs added

5. Breaking changes

6. Architectural decisions

7. Known limitations

8. Future improvements

9. Validation performed

10. Result of flutter analyze

---

# 22. Implementation Policy

Do not implement features outside the requested scope.

Do not refactor unrelated modules.

Do not rename files unless required.

Do not move folders.

Do not introduce additional dependencies without justification.

When in doubt, preserve the existing architecture.

---

# 23. Definition of Done

The Employees module is considered finished when:

- The implementation satisfies every functional requirement.
- The architecture remains consistent.
- The code compiles.
- Static analysis reports zero issues.
- The implementation report has been delivered.

Only then is the task considered complete.

---

END OF SPECIFICATION

Version: 1.0

Status: APPROVED