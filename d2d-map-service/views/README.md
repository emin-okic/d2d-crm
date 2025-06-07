# Views

This directory contains all SwiftUI views used in the D2D CRM iOS app. These views define what the user sees and interacts with across the app, including login screens, maps, profiles, and prospect management interfaces.

## What Are Views in SwiftUI?

In SwiftUI, a *View* is a declarative description of the UI layout and behavior. Views are the building blocks for composing screens, handling user interaction, and responding to state changes.

---

## Files in This Directory

### `RootView.swift`

**Purpose**: Serves as the main entry point for the app UI after login. Hosts a `TabView` with navigation between:
- Map
- Prospects
- Profile

---

### `LoginView.swift`

**Purpose**: Provides a login interface for existing users.

**Features**:
- Email/password fields
- Validates login against local SwiftData
- Option to open `CreateAccountView`

---

### `CreateAccountView.swift`

**Purpose**: Handles new user account creation.

**Features**:
- Ensures email is unique before creation
- Creates and saves a new `User` to SwiftData
- Automatically logs in the user upon success

---

### `MapSearchView.swift`

**Purpose**: Displays an interactive map with prospect locations.

**Features**:
- Address search via `CLGeocoder`
- Color-coded markers indicating knock frequency
- Tap-based knock logging (“Answered” / “Not Answered”)
- Persists knock events with location and timestamp

---

### `ProspectsView.swift`

**Purpose**: Displays a list of all prospects for the current user.

**Features**:
- Filter by list ("Prospects", "Customers")
- Navigate to edit individual prospects
- Add new prospects via `NewProspectView`

---

### `EditProspectView.swift`

**Purpose**: Allows editing of a single prospect’s details.

**Features**:
- Change name, address, and list type
- View knock history via `KnockingHistoryView`

---

### `NewProspectView.swift`

**Purpose**: Form for adding new prospects manually.

**Features**:
- Captures full name and address
- Saves to SwiftData on submission

---

### `KnockingHistoryView.swift`

**Purpose**: Displays all knock events for a single prospect.

**Features**:
- Grouped by most recent
- Includes timestamp and GPS coordinates
- Color-coded by answered status

---

### `ProfileView.swift`

**Purpose**: Summary of user performance and data.

**Features**:
- Total knock count
- Bar charts for:
  - Knock distribution by list
  - Answered vs. Not Answered
- Logout button to return to login screen

---

## Summary

These views define the app’s entire user interface and interactivity. By composing reusable views and binding them to shared models and controllers, the D2D CRM app creates a smooth and reactive user experience tailored for sales reps in the field.
