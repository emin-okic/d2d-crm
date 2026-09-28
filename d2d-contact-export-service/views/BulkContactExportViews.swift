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
                        subtitle: "Send all prospects and customers to Salesforce Contacts.",
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
    @State private var showingSetupHelp: Bool
    @State private var connectionAlertTitle = ""
    @State private var connectionAlertMessage = ""
    @State private var showingConnectionAlert = false

    init(records: [SalesforceExportRecord], listName: String) {
        self.records = records
        self.listName = listName

        let hasSeenGuide = UserDefaults.standard.bool(forKey: "salesforce.hasSeenSetupGuide")
        let hasConfiguration = !(UserDefaults.standard.string(forKey: "salesforce.clientID") ?? "").isEmpty
        _showingSetupHelp = State(initialValue: !hasSeenGuide && !hasConfiguration)
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
            .sheet(isPresented: $showingSetupHelp) {
                SalesforceSetupGuideView(
                    clientID: $clientID,
                    environment: $environment,
                    customDomain: $customDomain,
                    onFinish: finishSetupGuide
                )
                .interactiveDismissDisabled()
            }
            .alert(connectionAlertTitle, isPresented: $showingConnectionAlert) {
                Button("OK") {}
            } message: {
                Text(connectionAlertMessage)
            }
        }
    }

    private func finishSetupGuide() {
        UserDefaults.standard.set(true, forKey: "salesforce.hasSeenSetupGuide")
        showingSetupHelp = false
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

private struct SalesforceSetupGuideView: View {
    private enum Step {
        case experience
        case organization
        case externalClientApp
        case credentials
        case ready
    }

    @Binding var clientID: String
    @Binding var environment: SalesforceEnvironment
    @Binding var customDomain: String
    let onFinish: () -> Void

    @State private var step: Step = .experience
    @State private var hasSalesforceOrganization = false

    private let developerSignupURL = URL(string: "https://developer.salesforce.com/signup")

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ProgressView(value: progress)
                    Text("Step \(stepNumber) of \(totalSteps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                stepContent
            }
            .navigationTitle("Connect Salesforce")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                navigationControls
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Set Up Later", action: onFinish)
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .experience:
            Section {
                Label("Let’s get your Salesforce account ready for secure exports.", systemImage: "cloud.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text("Do you already have a Salesforce organization that you can administer?")
                Button("Yes, I have an organization") {
                    hasSalesforceOrganization = true
                    step = .externalClientApp
                }
                Button("No, help me create one") {
                    hasSalesforceOrganization = false
                    step = .organization
                }
            } footer: {
                Text("You need administrator access to create the one-time connection used by d2d CRM.")
            }

        case .organization:
            Section {
                GuideInstructionRow(number: 1, text: "Open Salesforce’s Developer Edition sign-up page.")
                if let developerSignupURL {
                    Link("Open Salesforce Sign Up", destination: developerSignupURL)
                }
                GuideInstructionRow(number: 2, text: "Complete the form and verify the email Salesforce sends you.")
                GuideInstructionRow(number: 3, text: "Create your password, sign in, and keep the Salesforce tab open.")
            } header: {
                Text("Create a free organization")
            } footer: {
                Text("Developer Edition is a free Salesforce organization intended for learning, development, and testing.")
            }

        case .externalClientApp:
            Section {
                GuideInstructionRow(number: 1, text: "Open Setup, search for Apps, then open External Client App Manager.")
                GuideInstructionRow(number: 2, text: "Create a New External Client App. Give it a recognizable name such as d2d CRM and enter your email.")
                GuideInstructionRow(number: 3, text: "Enable OAuth Settings and use this exact callback URL:")
                Text(SalesforceClient.callbackURL)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                GuideInstructionRow(number: 4, text: "Add the Manage user data via APIs (api) and Perform requests at any time (refresh_token, offline_access) scopes.")
                GuideInstructionRow(number: 5, text: "Require PKCE, and turn off the client-secret requirement for the web server and refresh-token flows.")
                GuideInstructionRow(number: 6, text: "Save the app. Open its details, choose Consumer Key and Secret, and copy the Consumer Key.")
            } header: {
                Text("Create the connection in Salesforce")
            } footer: {
                Text("d2d CRM uses PKCE, so you never paste a Consumer Secret into the app.")
            }

        case .credentials:
            Section {
                Picker("Environment", selection: $environment) {
                    ForEach(SalesforceEnvironment.allCases) {
                        Text($0.title).tag($0)
                    }
                }

                if environment == .developer {
                    TextField("My Domain URL", text: $customDomain)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    Text("In Salesforce, open Setup → My Domain and copy the URL ending in .salesforce.com.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Paste Consumer Key", text: $clientID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Choose your Salesforce environment")
            } footer: {
                Text("Use Production for an existing live organization, Sandbox for a testing sandbox, or Developer Edition / My Domain for a free developer organization.")
            }

        case .ready:
            Section {
                Label("You’re ready to connect", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                LabeledContent("Environment", value: environment.title)
                if environment == .developer {
                    LabeledContent("My Domain", value: customDomain)
                }
                LabeledContent("Consumer Key", value: maskedClientID)
            } footer: {
                Text("Next, tap Connect to Salesforce. Salesforce will open a secure sign-in page where you approve access. Your password never enters d2d CRM.")
            }
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 12) {
            if step != .experience {
                Button("Back", action: goBack)
                    .buttonStyle(.bordered)
            }
            Spacer()
            if step != .experience {
                Button(step == .ready ? "Continue to Connect" : "Continue", action: goForward)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canContinue)
            }
        }
        .padding()
        .background(.bar)
    }

    private var totalSteps: Int { hasSalesforceOrganization ? 4 : 5 }

    private var stepNumber: Int {
        switch step {
        case .experience: 1
        case .organization: 2
        case .externalClientApp: hasSalesforceOrganization ? 2 : 3
        case .credentials: hasSalesforceOrganization ? 3 : 4
        case .ready: totalSteps
        }
    }

    private var progress: Double {
        Double(stepNumber) / Double(totalSteps)
    }

    private var canContinue: Bool {
        guard step == .credentials else { return true }
        let hasClientID = !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDomain = !customDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasClientID && (environment != .developer || hasDomain)
    }

    private var maskedClientID: String {
        let trimmed = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 8 else { return trimmed }
        return "••••••••\(trimmed.suffix(8))"
    }

    private func goBack() {
        switch step {
        case .experience:
            break
        case .organization:
            step = .experience
        case .externalClientApp:
            step = hasSalesforceOrganization ? .experience : .organization
        case .credentials:
            step = .externalClientApp
        case .ready:
            step = .credentials
        }
    }

    private func goForward() {
        switch step {
        case .experience:
            break
        case .organization:
            step = .externalClientApp
        case .externalClientApp:
            step = .credentials
        case .credentials:
            step = .ready
        case .ready:
            onFinish()
        }
    }
}

private struct GuideInstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
