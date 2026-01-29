# Contact Manager Controller – Pre-Release Checklist

Before release, verify that the suggested neighbor logic behaves correctly under both ideal and failure conditions. This change preserves existing behavior while swapping the underlying geocoding mechanism, so validation focuses on confidence, edge cases, and regressions rather than new functionality.

## Force the failure paths (this is the big one
First, confirm that failure paths are handled safely when MapKit cannot resolve an address. Using a clearly invalid or fabricated customer address, ensure the neighbor suggestion process exits cleanly without crashing or looping indefinitely. The offset recursion should stop after reaching the configured maximum attempts, and no suggested prospect should be produced. This validates that the guard logic and fallback behavior remain equivalent to the prior CLGeocoder-based implementation.

### How To Test
Use a clearly fake address, e.g.:

```
99999999 NotARealStreet
```

Or temporarily add a customer with:

```
1 Xyzxyzxyz Rd
```

### Expected behavior
- No crash
- No infinite loop
- tryOffset walks offsets up to maxAttempts
- suggestedProspect ends up nil

This proves your guard let coordinate = … logic still mirrors the old CLGeocoder behavior.

## Validate the “already exists” filter still works
Next, validate that duplicate prevention still works as expected. When an existing prospect already occupies a neighboring address, the controller should correctly skip that address and continue searching until it finds a valid, unused neighbor. The suggested result should never duplicate an address already present in the prospects list, confirming that address normalization and comparison logic remain intact after the MapKit transition.

### How to test

Add a Prospect at:

```
123 Main St
```

Add a Customer at:

```
122 Main St
```

### Expected behavior
- App skips 123 Main St
- Suggests 124 Main St or higher
- No duplicate suggestions

Confirm the MapKit search swap didn’t alter address string matching behavior.

## Rotation sanity check (index advancement)
Then, verify correct rotation across multiple customers. With several customers available as suggestion sources, repeatedly entering and exiting the Prospects view should yield neighbor suggestions derived from different customers over time. The internal index used to track suggestion sources should advance reliably, avoiding repeated suggestions from the same customer and ensuring that async continuations resume exactly once per attempt.

### How to test
- Add 3+ customers
- Switch away from Prospects → back to Prospects multiple times

### Expected behavior
- Suggested neighbors rotate between customer sources
- No “stuck” suggestion
- No repeating the same base address every time

Confirm async + continuation still resumes exactly once.

## Inject a deterministic test closure (best dev-only test)
Additionally, confirm deterministic behavior using the injected geocoding closure. By temporarily providing a test closure that returns a fixed address and coordinate, ensure that a suggested neighbor appears immediately, the UI updates correctly, and no MapKit calls are executed. This confirms that the controller logic is decoupled from the geocoding implementation and remains fully testable.

### How to test
You already built the perfect test seam:

```
var geocodeNeighborClosure: ...
```

Set temp debug code like this:

```
controller.geocodeNeighborClosure = { address, _, completion in
    completion(
        "999 Test St",
        CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
    )
}
```

### Expected behavior
- Suggested neighbor appears instantly
- No MapKit call at all
- UI still updates correctly

This proves nothing else depends on CLGeocoder / MKLocalSearch internals.

## Performance + UX sanity check
Finally, perform a light performance and UX sanity check. Because MKLocalSearch is heavier than the previous geocoder, verify that suggestions appear without noticeable delay, the UI remains responsive, and repeated navigation does not result in stacked or redundant search requests. If behavior feels indistinguishable from before, the change is safe to ship.

### What to watch
- Noticeable delay before suggestion appears?
- UI freeze? (shouldn’t happen — you’re async + MainActor-safe)
- Repeated switching causing stacking requests?
