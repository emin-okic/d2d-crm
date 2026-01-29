# Contact Manager Controller – Pre-Release Checklist

Before release, verify that the suggested neighbor logic behaves correctly under both ideal and failure conditions. This change preserves existing behavior while swapping the underlying geocoding mechanism, so validation focuses on confidence, edge cases, and regressions rather than new functionality.

First, confirm that failure paths are handled safely when MapKit cannot resolve an address. Using a clearly invalid or fabricated customer address, ensure the neighbor suggestion process exits cleanly without crashing or looping indefinitely. The offset recursion should stop after reaching the configured maximum attempts, and no suggested prospect should be produced. This validates that the guard logic and fallback behavior remain equivalent to the prior CLGeocoder-based implementation.

Next, validate that duplicate prevention still works as expected. When an existing prospect already occupies a neighboring address, the controller should correctly skip that address and continue searching until it finds a valid, unused neighbor. The suggested result should never duplicate an address already present in the prospects list, confirming that address normalization and comparison logic remain intact after the MapKit transition.

Then, verify correct rotation across multiple customers. With several customers available as suggestion sources, repeatedly entering and exiting the Prospects view should yield neighbor suggestions derived from different customers over time. The internal index used to track suggestion sources should advance reliably, avoiding repeated suggestions from the same customer and ensuring that async continuations resume exactly once per attempt.

Additionally, confirm deterministic behavior using the injected geocoding closure. By temporarily providing a test closure that returns a fixed address and coordinate, ensure that a suggested neighbor appears immediately, the UI updates correctly, and no MapKit calls are executed. This confirms that the controller logic is decoupled from the geocoding implementation and remains fully testable.

Finally, perform a light performance and UX sanity check. Because MKLocalSearch is heavier than the previous geocoder, verify that suggestions appear without noticeable delay, the UI remains responsive, and repeated navigation does not result in stacked or redundant search requests. If behavior feels indistinguishable from before, the change is safe to ship.
