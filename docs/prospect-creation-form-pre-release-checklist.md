# Prospect Creation Form

## Pre-Release Checklist (MapKit Address Resolution)

### Happy-Path Creation

- Create a new Prospect with a valid, real address
- Prospect saves successfully
- No UI delay or freeze after tapping Finish
- Latitude and longitude are populated
- Prospect appears immediately in the list

### Address Autocomplete Flow

- Type an address and select a suggestion from autocomplete
- Address field updates with resolved address
- Autocomplete results clear after selection
- Prospect saves with correct coordinates

### Failure Path Handling (No Results)

- Enter a clearly invalid address (e.g. 99999999 NotARealStreet)
- Prospect still saves successfully
