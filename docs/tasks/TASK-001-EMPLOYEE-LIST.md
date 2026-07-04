# LOCUSTAF - Development Task

Task ID: TASK-001

Module: Employees

Title:
Implement Employee List

Status:
Ready

Priority:
High

Depends on:
EMPLOYEES_MODULE_SPEC.md

---

# Objective

Implement the employee listing screen.

This task includes only read operations.

No employee creation.

No update.

No delete.

No Authentication changes.

---

# Functional Scope

Implement:

✔ Read employees from Firestore

✔ Display only users with:

UserRole.empleado

✔ Alphabetical ordering

✔ Loading state

✔ Empty state

✔ Error state

✔ Search by:

- Nombre
- Apellido
- DNI
- Email

✔ Filters

- All
- Active
- Inactive

---

# Technical Requirements

Reuse:

FirestoreService

UsersRepository

UsersRepositoryImpl

usersStreamProvider

UserModel

DashboardLayout

Do not duplicate code.

---

# UI Requirements

The screen must integrate with DashboardLayout.

Do NOT create another Scaffold.

Do NOT create another AppBar.

The layout must remain responsive.

---

# Allowed Files

Only modify files required inside:

lib/features/employees/

If absolutely necessary:

lib/core/

Nothing else.

---

# Forbidden

Do not modify:

Authentication

Dashboard

Routing

Sidebar

UserModel

---

# Validation

The implementation must finish with:

flutter analyze

0 issues

---

# Mandatory Report

Return:

Files created

Files modified

Files deleted

Architecture decisions

Known limitations

flutter analyze result

End of report.