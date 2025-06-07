# Controllers

This directory contains core controllers responsible for managing data, location, map interactions, and user profile analytics in the **D2D CRM** iOS app.

## What Are Controllers in iOS?

In iOS development, a *controller* is a layer that manages the interaction between the app’s data model and its user interface. Controllers handle logic, data coordination, and responses to user input. In Swift, this often means working with `ObservableObject`, `@Published`, or other SwiftUI-compatible tools to keep views reactive and up to date.

This app follows a modular approach with controllers grouped by responsibility.

---

## Files in This Directory

### `DatabaseController.swift`

**Purpose**: Manages all interaction with the local SQLite database. Responsible for creating tables, inserting records, updating records, and fetching structured data about prospects and their knock history.

**Key Features**:
- Manages two main tables: `prospects` and `knocks`
- Supports both disk and in-memory databases (for testing)
- Connects knock data with prospect records
- Includes scoped filtering by user email

---

### `LocationManager.swift`

**Purpose**: Manages access to the device’s location using CoreLocation. Provides live GPS updates to the app.

**Key Features**:
- Provides a shared singleton for use across views
- Publishes the user’s current coordinates
- Requests appropriate location permissions

---

### `MapController.swift`

**Purpose**: Controls map-related logic, including performing geocoding searches and placing pins (markers) on the map.

**Key Features**:
- Uses `CLGeocoder` to convert addresses into coordinates
- Dynamically adjusts map view region to fit all markers
- Supports searching, adding, and resetting map markers
- Integrates tightly with prospect data for visualizing activity

---

### `ProfileController.swift`

**Purpose**: Provides analytical functions used by the Profile screen for reporting knock statistics.

**Key Features**:
- Calculates total number of knocks
- Breaks down knock counts by prospect list
- Splits answered vs. unanswered knock metrics
- Supports user-specific filtering

---

## Summary

These controllers encapsulate the core business logic of the app — separate from the views. By following this architecture, the codebase remains clean, testable, and easy to maintain.

Controllers like these allow the D2D CRM to offer responsive, real-time experiences to door-to-door reps — giving them the tools they need without wasting time on the doors.
