# Models

This directory defines the **data structures** that power the D2D CRM iOS app. These models represent the app’s core data: prospects, user accounts, knocks, and geolocation.

## What Are Models in iOS?

In Swift and SwiftData, a *model* represents the structure and behavior of your app's data. These types are responsible for holding state, defining attributes, and interacting with data persistence layers like SwiftData or SQLite.

Models define the *what*, while controllers define the *how*.

---

## Files in This Directory

### `Prospects.swift`

**Purpose**: Represents a single sales lead or household that a door-to-door rep might interact with.

**Key Properties**:
- `fullName`: Name of the prospect
- `address`: Home or business address
- `count`: Number of times this prospect has been knocked
- `list`: Which list this prospect is grouped under (e.g. "Prospects", "Follow-up")
- `userEmail`: Email of the user this record belongs to
- `knockHistory`: An array of associated `Knock` events

**Extras**:
- `sortedKnocks`: A computed property that returns the knock history in descending date order.

---

### `Knock.swift`

**Purpose**: Represents a single door-knocking interaction.

**Key Properties**:
- `date`: When the knock happened
- `status`: Whether the knock was answered or not
- `latitude` / `longitude`: Where the knock took place
- `userEmail`: Email of the rep who performed the knock

---

### `User.swift`

**Purpose**: Represents an account in the D2D CRM system.

**Key Properties**:
- `email`: Email address used for login
- `password`: Stored password (in production, this should be hashed)
- `id`: Unique UUID for this user

---

### `IdentifiablePlace.swift`

**Purpose**: A helper object used to represent mappable locations on the iOS Map view.

**Key Properties**:
- `id`: Unique ID (used by SwiftUI)
- `address`: The original search query
- `location`: The geocoded coordinates
- `count`: The number of interactions or visits at this location

**Extras**:
- `markerColor`: A computed property to determine what color the marker should be based on the number of visits

---

### `ShareSheet.swift`

**Purpose**: A SwiftUI wrapper for `UIActivityViewController`, used for sharing content like reports, referrals, or logs.

**Key Properties**:
- `activityItems`: The list of objects to be shared (text, URLs, etc.)

---

## Summary

These model files form the foundation of your app’s data layer. Combined with controllers and views, they make up a clean and testable architecture that serves the daily needs of door-to-door sales professionals.

By using SwiftData where appropriate and organizing data in a user-first way, the D2D CRM ensures reps have quick, efficient access to the information they need while working in the field.
