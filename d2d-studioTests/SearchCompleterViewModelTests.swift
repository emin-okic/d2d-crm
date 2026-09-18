import Testing
@testable import d2d_studio

struct SearchCompleterViewModelTests {
    @Test(arguments: [
        ("10320 Norfolk Dr Unit 5", "10320 Norfolk Dr", "Unit 5"),
        ("10320 Norfolk Dr Apt. 5B", "10320 Norfolk Dr", "Apt. 5B"),
        ("10320 Norfolk Dr Apartment", "10320 Norfolk Dr", "Apartment"),
        ("10320 Norfolk Dr #5", "10320 Norfolk Dr", "#5"),
        ("10320 Norfolk Dr Suite 200", "10320 Norfolk Dr", "Suite 200"),
        ("10320 Norfolk Dr Ste. 200", "10320 Norfolk Dr", "Ste. 200"),
        ("10320 Norfolk Dr Flat A", "10320 Norfolk Dr", "Flat A"),
        ("10320 Norfolk Dr Room 4", "10320 Norfolk Dr", "Room 4"),
        ("10320 Norfolk Dr Lot 12", "10320 Norfolk Dr", "Lot 12")
    ])
    func parsesSecondaryAddress(
        query: String,
        expectedBaseAddress: String,
        expectedSecondaryAddress: String
    ) {
        let components = SearchCompleterViewModel.addressComponents(from: query)

        #expect(components.baseAddress == expectedBaseAddress)
        #expect(components.secondaryAddress == expectedSecondaryAddress)
    }

    @Test
    func doesNotTreatWordsContainingDesignatorsAsSecondaryAddresses() {
        let query = "10320 Apartment Road"
        let components = SearchCompleterViewModel.addressComponents(from: query)

        #expect(components.baseAddress == query)
        #expect(components.secondaryAddress.isEmpty)
    }

    @Test(arguments: ["Unit 1", "Unit #1", "Apt 1", "Apartment #1", "Suite 1", "Ste. #1"])
    func standardizesEquivalentUnitFormats(_ secondaryAddress: String) {
        let result = SearchCompleterViewModel.appendingSecondaryAddress(
            secondaryAddress,
            to: "1661 Mission St, San Francisco, CA 94103"
        )

        #expect(result == "1661 Mission St Unit 1, San Francisco, CA 94103")
    }

    @Test(arguments: [
        "1661 Mission St Unit 1, San Francisco, CA 94103",
        "1661 Mission St Unit #1, San Francisco, CA 94103",
        "1661 Mission St Apt 1, San Francisco, CA 94103",
        "1661 Mission St Apartment #1, San Francisco, CA 94103"
    ])
    func createsTheSameIdentityForEquivalentUnitFormats(_ address: String) {
        let parts = AddressCanonicalizer.parse(address)

        #expect(parts.base == "1661 Mission St, San Francisco, CA 94103")
        #expect(parts.unit == "1")
        #expect(parts.identityKey == AddressCanonicalizer.parse("1661 Mission St Unit 1, San Francisco, CA 94103").identityKey)
    }

    @Test
    func keepsDifferentUnitsDistinct() {
        #expect(!AddressCanonicalizer.addressesMatch(
            "1661 Mission St Apt 1",
            "1661 Mission St Unit 10"
        ))
    }
}
