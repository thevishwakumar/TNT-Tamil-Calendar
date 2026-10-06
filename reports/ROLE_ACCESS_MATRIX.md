# ROLE ACCESS MATRIX

## Discovered Roles
Based on the UserRole enum in lib/models/tnt_models.dart, there are exactly two roles implemented in the application:
1. user (Standard Authenticated User)
2. dmin (Super Admin)

There is no trace of simulated roles like "College Admin", "Student", "HOD", etc.

## 1. User Role (Standard)
**Login:** PASS
**Home / Dashboard:** PASS (Can see Analytics, Calendar, Panchangam)
**Navigation:** PASS
**Data Visibility:** 
- Can see all public calendar data (Festivals, Muhurthams, Special Days)
- Can see own personal events.
- Cannot see other users' personal events.
**CRUD Permissions:**
- Can Create/Read/Update/Delete own PersonalEvents.
- Can Save/Unsave public items.
- Can Toggle Reminders.
- Cannot Modify master database (Festivals/Muhurthams).
**Unauthorized Pages:** AdminDashboardScreen and all sub-routes block this role correctly via AuthStateManager.

## 2. Admin Role (Super Admin)
**Login:** PASS
**Home / Admin Dashboard:** PASS
**Navigation:** PASS (Has access to standard view AND admin view)
**Data Visibility:**
- Can view platform analytics.
- Can view user profiles list.
**CRUD Permissions:**
- Can theoretically manage operational schedules.
- Cannot see raw passwords or decrypted sensitive user events.
**Unauthorized Pages:** None.
