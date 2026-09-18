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

    @Test
    func insertsSecondaryAddressBeforeCityAndRegion() {
        let result = SearchCompleterViewModel.appendingSecondaryAddress(
            "Unit 5",
            to: "10320 Norfolk Dr, Omaha, NE 68114"
        )

        #expect(result == "10320 Norfolk Dr Unit 5, Omaha, NE 68114")
    }
}
