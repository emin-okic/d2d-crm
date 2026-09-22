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
    ) ?? .sandbox
    @State private var objectType: SalesforceObjectType
    @State private var fields: [SalesforceField] = []
    @State private var mappings: [SalesforceFieldMapping] = SalesforceSourceField.allCases.map {
        SalesforceFieldMapping(source: $0, destinationName: nil)
    }
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var showingSetupHelp = false
    @State private var connectionAlertTitle = ""
    @State private var connectionAlertMessage = ""
    @State private var showingConnectionAlert = false

    init(records: [SalesforceExportRecord], listName: String) {
        self.records = records
        self.listName = listName
        _objectType = State(initialValue: listName == "Prospects" ? .lead : .contact)
    }

    var body: some View {
        NavigationStack {
            Form {
                SalesforceConnectionSection(
                    clientID: $clientID,
                    environment: $environment,
                    isConnected: client.isConnected,
                    organizationName: client.organizationName,
                    isWorking: isWorking,
                    onConnect: connect,
                    onDisconnect: disconnect,
                    onHelp: { showingSetupHelp = true }
                )

                if client.isConnected {
                    SalesforceMappingSection(
                        objectType: $objectType,
                        fields: fields,
                        mappings: $mappings,
                        isLoading: isWorking
                    )

                    Section {
                        Button {
                            export()
                        } label: {
                            HStack {
                                Spacer()
                                if isWorking { ProgressView() }
                                else { Text("Export \(records.count) Records") }
                                Spacer()
                            }
                        }
                        .disabled(isWorking || records.isEmpty || fields.isEmpty)
                    } footer: {
                        Text("Salesforce permissions and validation rules still apply. A failed record won’t stop the remaining records.")
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
            .task {
                guard client.isConnected, fields.isEmpty, !clientID.isEmpty else { return }
                loadFields()
            }
            .onChange(of: objectType) { _, _ in
                guard client.isConnected else { return }
                loadFields()
            }
        }
    }

    private func connect() {
        isWorking = true
        statusMessage = nil
        Task {
            do {
                try await client.connect(clientID: clientID, environment: environment)
                try await refreshFields()
                showConnectionAlert(
                    title: "Salesforce Connected",
                    message: "Your Salesforce fields are ready to map and export."
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
        fields = []
        statusMessage = nil
    }

    private func showConnectionAlert(title: String, message: String) {
        connectionAlertTitle = title
        connectionAlertMessage = message
        showingConnectionAlert = true
    }

    private func loadFields() {
        isWorking = true
        statusMessage = nil
        Task {
            do { try await refreshFields() }
            catch { statusMessage = error.localizedDescription }
            isWorking = false
        }
    }

    private func refreshFields() async throws {
        fields = try await client.fields(for: objectType, clientID: clientID, environment: environment)
        mappings = SalesforceMappingStore.load(object: objectType) ?? defaultMappings(for: fields)
    }

    private func export() {
        isWorking = true
        statusMessage = nil
        SalesforceMappingStore.save(mappings, object: objectType)
        Task {
            do {
                let result = try await client.export(
                    records: records,
                    object: objectType,
                    mappings: mappings,
                    clientID: clientID,
                    environment: environment
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

    private func defaultMappings(for fields: [SalesforceField]) -> [SalesforceFieldMapping] {
        let available = Set(fields.map(\.name))
        let defaults: [SalesforceSourceField: String] = [
            .firstName: "FirstName", .lastName: "LastName", .email: "Email", .phone: "Phone",
            .address: objectType == .lead ? "Street" : "MailingStreet", .company: "Company",
            .jobTitle: "Title", .industry: "Industry", .latitude: "Latitude", .longitude: "Longitude"
        ]
        return SalesforceSourceField.allCases.map {
            let destination = defaults[$0]
            return SalesforceFieldMapping(source: $0, destinationName: destination.flatMap { available.contains($0) ? $0 : nil })
        }
    }
}

private struct SalesforceConnectionSection: View {
    @Binding var clientID: String
    @Binding var environment: SalesforceEnvironment
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
                .disabled(isWorking || clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Button("How do I get a Consumer Key?", action: onHelp)
        } header: {
            Text("Connection")
        } footer: {
            Text("Your password never enters d2d CRM. Salesforce handles sign-in, and the refresh token is stored in the iOS Keychain.")
        }
    }
}

private struct SalesforceMappingSection: View {
    @Binding var objectType: SalesforceObjectType
    let fields: [SalesforceField]
    @Binding var mappings: [SalesforceFieldMapping]
    let isLoading: Bool

    var body: some View {
        Section("Destination") {
            Picker("Salesforce object", selection: $objectType) {
                ForEach(SalesforceObjectType.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        Section {
            if isLoading && fields.isEmpty {
                ProgressView("Loading Salesforce fields…")
            } else {
                ForEach($mappings) { $mapping in
                    Picker(mapping.source.title, selection: $mapping.destinationName) {
                        Text("Don’t export").tag(String?.none)
                        ForEach(fields) { field in
                            Text(field.isRequired ? "\(field.label) (required)" : field.label)
                                .tag(String?.some(field.name))
                        }
                    }
                }
            }
        } header: {
            Text("Field Mapping")
        } footer: {
            Text("Lead last name and company, or Contact last name, are filled automatically when blank.")
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
            }
            .navigationTitle("One-Time Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private enum SalesforceMappingStore {
    static func load(object: SalesforceObjectType) -> [SalesforceFieldMapping]? {
        guard let data = UserDefaults.standard.data(forKey: key(object)) else { return nil }
        return try? JSONDecoder().decode([SalesforceFieldMapping].self, from: data)
    }

    static func save(_ mappings: [SalesforceFieldMapping], object: SalesforceObjectType) {
        guard let data = try? JSONEncoder().encode(mappings) else { return }
        UserDefaults.standard.set(data, forKey: key(object))
    }

    private static func key(_ object: SalesforceObjectType) -> String { "salesforce.mapping.\(object.rawValue)" }
}
