import Testing
@testable import d2d_studio

@MainActor
struct SalesforceExportModelTests {
    @Test func prospectBecomesMappableSalesforceRecord() throws {
        let prospect = Prospect(fullName: "Taylor Morgan", address: "123 Main St", count: 4)
        prospect.contactEmail = "taylor@example.com"
        prospect.contactPhone = "555-0100"
        prospect.demographicCompanyName = "Acme Solar"
        prospect.latitude = 41.5868

        let record = try #require(SalesforceExportModelFactory.prospects([prospect]).first)

        #expect(record.id == prospect.uuid)
        #expect(record.value(for: .firstName) == "Taylor")
        #expect(record.value(for: .lastName) == "Morgan")
        #expect(record.value(for: .email) == "taylor@example.com")
        #expect(record.value(for: .company) == "Acme Solar")
        #expect(record.value(for: .knockCount) == "4")
    }

    @Test func singleNameRemainsAValidSalesforceLastName() throws {
        let customer = Customer(fullName: "Prince", address: "", count: 0)

        let record = try #require(SalesforceExportModelFactory.customers([customer]).first)

        #expect(record.value(for: .firstName) == nil)
        #expect(record.value(for: .lastName) == "Prince")
    }

    @Test func blankValuesAreOmittedFromPayloadInputs() throws {
        let customer = Customer(fullName: "Jamie Doe", address: "", count: 0)

        let record = try #require(SalesforceExportModelFactory.customers([customer]).first)

        #expect(record.value(for: .address) == nil)
        #expect(record.value(for: .email) == nil)
    }
}
