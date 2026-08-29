//
//  ProspectRankingControllerTests.swift
//  d2d-studioTests
//
//  Created by Codex on 8/29/26.
//

import XCTest
@testable import d2d_studio

final class ProspectRankingControllerTests: XCTestCase {

    func testRanksProspectsByMatchingCustomerDemographics() {
        let homeownerCustomer = Customer(fullName: "Closed Owner", address: "100 Main St")
        homeownerCustomer.demographicHomeownership = "Owner"
        homeownerCustomer.demographicHouseholdType = "Family with kids"
        homeownerCustomer.demographicIndustry = "Construction"

        let renterCustomer = Customer(fullName: "Closed Renter", address: "200 Main St")
        renterCustomer.demographicHomeownership = "Renter"

        let strongMatch = Prospect(fullName: "Strong Match", address: "101 Main St", orderIndex: 2)
        strongMatch.demographicHomeownership = "Owner"
        strongMatch.demographicHouseholdType = "Family with kids"
        strongMatch.demographicIndustry = "Construction"

        let weakMatch = Prospect(fullName: "Weak Match", address: "201 Main St", orderIndex: 0)
        weakMatch.demographicHomeownership = "Renter"

        let noMatch = Prospect(fullName: "No Match", address: "301 Main St", orderIndex: 1)
        noMatch.demographicHomeownership = "Unknown"

        let ranked = ProspectRankingController(customers: [homeownerCustomer, renterCustomer])
            .rankedProspects([weakMatch, noMatch, strongMatch])

        XCTAssertEqual(ranked.map(\.fullName), ["Strong Match", "Weak Match", "No Match"])
    }

    func testFallsBackToOrderIndexWhenScoresTie() {
        let customer = Customer(fullName: "Closed Customer", address: "100 Main St")
        customer.demographicHomeownership = "Owner"

        let first = Prospect(fullName: "First", address: "101 Main St", orderIndex: 0)
        let second = Prospect(fullName: "Second", address: "102 Main St", orderIndex: 1)

        let ranked = ProspectRankingController(customers: [customer])
            .rankedProspects([second, first])

        XCTAssertEqual(ranked.map(\.fullName), ["First", "Second"])
    }
}
