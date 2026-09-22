import SwiftUI

struct BulkContactExportOptionsView: View {
    let listName: String
    let contactCount: Int
    let onCSV: () -> Void
    let onSalesforce: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ExportDestinationRow(
                        title: "CSV File",
                        subtitle: "Share a spreadsheet containing the current list.",
                        systemImage: "tablecells",
                        tint: .green,
                        action: onCSV
                    )
                    ExportDestinationRow(
                        title: "Salesforce",
                        subtitle: "Connect, map fields, and send records to Salesforce.",
                        systemImage: "cloud.fill",
                        tint: .blue,
                        action: onSalesforce
                    )
                } header: {
                    Text("Export \(contactCount) \(listName.lowercased())")
                }
            }
            .navigationTitle("Export Contacts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ExportDestinationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(tint, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}

struct SalesforceExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var client = SalesforceClient()

    let records: [SalesforceExportRecord]
    let listName: String

    @State private var clientID = UserDefaults.standard.string(forKey: "salesforce.clientID") ?? ""
    @State private var environment = SalesforceEnvironment(
        rawValue: UserDefaults.standard.string(forKey: "salesforce.environment") ?? ""
    ) ?? .developer
    @State private var customDomain = UserDefaults.standard.string(forKey: "salesforce.customDomain") ?? ""
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var showingSetupHelp = false
    @State private var connectionAlertTitle = ""
    @State private var connectionAlertMessage = ""
    @State private var showingConnectionAlert = false

    init(records: [SalesforceExportRecord], listName: String) {
        self.records = records
        self.listName = listName
    }

    var body: some View {
        NavigationStack {
            Form {
                SalesforceConnectionSection(
                    clientID: $clientID,
                    environment: $environment,
                    customDomain: $customDomain,
                    isConnected: client.isConnected,
                    organizationName: client.organizationName,
                    isWorking: isWorking,
                    onConnect: connect,
                    onDisconnect: disconnect,
                    onHelp: { showingSetupHelp = true }
                )

                if client.isConnected {
                    Section {
                        Button {
                            export()
                        } label: {
                            HStack {
                                Spacer()
                                if isWorking { ProgressView() }
                                else { Text("Export \(records.count) to Salesforce Contacts") }
                                Spacer()
                            }
                        }
                        .disabled(isWorking || records.isEmpty)
                    } footer: {
                        Text("The current \(listName.lowercased()) list will be added to Salesforce Contacts using last name and phone. A failed record won’t stop the remaining records.")
                    }
                }

                if let statusMessage {
                    Section("Result") { Text(statusMessage) }
                }
            }
            .navigationTitle("Salesforce Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(isPresented: $showingSetupHelp) { SalesforceSetupHelpView() }
            .alert(connectionAlertTitle, isPresented: $showingConnectionAlert) {
                Button("OK") {}
            } message: {
                Text(connectionAlertMessage)
            }
        }
    }

    private func connect() {
        isWorking = true
        statusMessage = nil
        Task {
            do {
                try await client.connect(clientID: clientID, environment: environment, customDomain: customDomain)
                showConnectionAlert(
                    title: "Salesforce Connected",
                    message: "You can now export the current list to Salesforce Contacts."
                )
            } catch {
                statusMessage = error.localizedDescription
                showConnectionAlert(title: "Connection Failed", message: error.localizedDescription)
            }
            isWorking = false
        }
    }

    private func disconnect() {
        client.disconnect()
        statusMessage = nil
    }

    private func showConnectionAlert(title: String, message: String) {
        connectionAlertTitle = title
        connectionAlertMessage = message
        showingConnectionAlert = true
    }

    private func export() {
        isWorking = true
        statusMessage = nil
        Task {
            do {
                let result = try await client.export(
                    records: records,
                    clientID: clientID,
                    environment: environment,
                    customDomain: customDomain
                )
                statusMessage = result.failedMessages.isEmpty
                    ? "Successfully exported \(result.succeeded) records."
                    : "Exported \(result.succeeded) records. \(result.failedMessages.count) failed: \(result.failedMessages.prefix(3).joined(separator: " "))"
            } catch {
                statusMessage = error.localizedDescription
            }
            isWorking = false
        }
    }

}

private struct SalesforceConnectionSection: View {
    @Binding var clientID: String
    @Binding var environment: SalesforceEnvironment
    @Binding var customDomain: String
    let isConnected: Bool
    let organizationName: String?
    let isWorking: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onHelp: () -> Void

    var body: some View {
        Section {
            Picker("Environment", selection: $environment) {
                ForEach(SalesforceEnvironment.allCases) { Text($0.title).tag($0) }
            }
            .disabled(isConnected)
            if environment == .developer {
                TextField("My Domain URL", text: $customDomain)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .disabled(isConnected)
            }
            TextField("Consumer Key", text: $clientID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(isConnected)
            if isConnected {
                Label(organizationName ?? "Connected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button("Disconnect", role: .destructive, action: onDisconnect)
            } else {
                Button(action: onConnect) {
                    if isWorking { ProgressView() } else { Text("Connect to Salesforce") }
                }
                .disabled(
                    isWorking ||
                    clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    (environment == .developer && customDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
            }
            Button("How do I get a Consumer Key?", action: onHelp)
        } header: {
            Text("Connection")
        } footer: {
            Text("Developer Edition uses your org’s My Domain URL. Your password never enters d2d CRM, and the refresh token is stored in the iOS Keychain.")
        }
    }
}

private struct SalesforceSetupHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("In Salesforce Setup") {
                    Text("1. Open External Client App Manager and create an External Client App.")
                    Text("2. Enable OAuth and add this callback URL:\n\(SalesforceClient.callbackURL)")
                    Text("3. Add the API and Refresh Token OAuth scopes.")
                    Text("4. Require PKCE. Turn off the client-secret requirement for the web server and refresh-token flows.")
                    Text("5. Copy the Consumer Key into d2d CRM. No Consumer Secret is needed.")
                }
                Section("Sandbox Testing") {
                    Text("Choose Sandbox on the connection screen and sign in with a Salesforce Developer sandbox account. Your External Client App must exist in that sandbox.")
                }
                Section("Developer Edition") {
                    Text("Choose Developer Edition / My Domain and paste the URL shown in your browser after signing in, ending in .salesforce.com. Developer Edition organizations do not use test.salesforce.com.")
                }
            }
            .navigationTitle("One-Time Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
