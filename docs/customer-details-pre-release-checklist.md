# Pre-Release Checklist: CustomerDetailsView

## Address Change / Commit Edits Checklist

### 1. Core Functionality
- [ ] Verify that `commitEdits()` correctly updates the customer's:
  - [ ] Full name
  - [ ] Address
  - [ ] Latitude/Longitude after geocoding
- [ ] Confirm that automatic change notes are appended to `customer.notes`.
- [ ] Test the "Save" button behavior:
  - [ ] Enabled only when edits exist
  - [ ] Successfully commits edits to SwiftData model
  - [ ] Geocoding completes before save is finalized
- [ ] Test the "Revert" button:
  - [ ] Resets `tempFullName` and `tempAddress` to original customer values
  - [ ] Dismisses address field focus

### 2. MapKit Geocoding (iOS 26+)
- [ ] Ensure `MKLocalSearch` returns coordinates correctly for valid addresses
- [ ] Confirm `customer.latitude` and `customer.longitude` are updated without optional binding errors
- [ ] Test invalid / ambiguous addresses:
  - [ ] Prints error without crashing
  - [ ] Save still works for name-only edits
  - [ ] No incorrect coordinates are stored

### 3. UI / UX Checks
- [ ] Customer Scorecards:
  - [ ] "Meetings" count updates correctly
  - [ ] "Knocks" count updates correctly
  - [ ] Tapping each card opens the correct sheet with haptic + sound feedback
- [ ] AddressAutocompleteField:
  - [ ] Autocomplete suggestions show correctly
  - [ ] Focus and keyboard behavior works properly
- [ ] Toolbar:
  - [ ] Back button dismisses view
  - [ ] Export / Share buttons visible when no unsaved edits
  - [ ] Save / Revert buttons appear only when edits exist
- [ ] Floating actions:
  - [ ] Delete button triggers confirmation sheet
  - [ ] Notes button opens notes sheet
- [ ] Export to Contacts:
  - [ ] Access requested correctly
  - [ ] Existing contacts update properly
  - [ ] New contacts created with correct fields
  - [ ] Success / failure banners appear with proper animation

### 4. Sheet Navigation
- [ ] Appointments sheet opens and displays upcoming meetings
- [ ] Knocks sheet opens and displays knock history
- [ ] Delete confirmation sheet behaves as expected
- [ ] Notes sheet opens and displays all existing notes

### 5. Haptic / Sound Feedback
- [ ] Confirm all haptic/sound calls trigger as expected:
  - [ ] Scorecards
  - [ ] Toolbar actions
  - [ ] Sheets (delete, notes)
  - [ ] Export prompts

### 6. Miscellaneous
- [ ] `.onAppear()` initializes local temp variables correctly
- [ ] Ensure no compiler warnings, especially after removing optional binding on `.location`
- [ ] Run on multiple iOS devices / simulators for consistency
- [ ] Verify logs (`print`) for geocoding success/failure

### 7. Regression Testing
- [ ] Previous functionality not impacted:
  - [ ] Notes system
  - [ ] Customer list updates
  - [ ] Floating buttons and toolbar remain functional
- [ ] Test editing only name, only address, and both together
