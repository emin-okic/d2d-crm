import SwiftUI
import UIKit

enum EmailMergeField: String, CaseIterable, Identifiable {
    case name
    case address
    case email

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .name:
            "Contact Name"
        case .address:
            "Contact Address"
        case .email:
            "Contact Email"
        }
    }

    var token: String {
        "{{\(rawValue)}}"
    }

    var systemImage: String {
        switch self {
        case .name:
            "person"
        case .address:
            "house"
        case .email:
            "envelope"
        }
    }

    func matches(_ query: String) -> Bool {
        query.isEmpty
            || rawValue.localizedCaseInsensitiveContains(query)
            || String(localized: title).localizedCaseInsensitiveContains(query)
    }
}

struct EmailMergeFieldEditor: View {
    @Binding var text: String
    let minimumHeight: CGFloat

    @State private var selectedRange = NSRange(location: 0, length: 0)

    private var activeTokenRange: NSRange? {
        let nsText = text as NSString
        let caretLocation = min(selectedRange.location, nsText.length)
        let prefixRange = NSRange(location: 0, length: caretLocation)
        let openingRange = nsText.range(
            of: "{{",
            options: .backwards,
            range: prefixRange
        )

        guard openingRange.location != NSNotFound else { return nil }

        let queryLocation = NSMaxRange(openingRange)
        let queryRange = NSRange(
            location: queryLocation,
            length: caretLocation - queryLocation
        )
        let query = nsText.substring(with: queryRange)

        guard !query.contains("}}"),
              !query.contains(where: { $0.isWhitespace }) else {
            return nil
        }

        return NSRange(
            location: openingRange.location,
            length: caretLocation - openingRange.location
        )
    }

    private var filteredFields: [EmailMergeField] {
        guard let activeTokenRange else { return [] }

        let nsText = text as NSString
        let queryLocation = activeTokenRange.location + 2
        let queryRange = NSRange(
            location: queryLocation,
            length: NSMaxRange(activeTokenRange) - queryLocation
        )
        let query = nsText.substring(with: queryRange)

        return EmailMergeField.allCases.filter { $0.matches(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Email Body")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    ForEach(EmailMergeField.allCases) { field in
                        Button {
                            insert(field)
                        } label: {
                            Label(field.title, systemImage: field.systemImage)
                        }
                    }
                } label: {
                    Label("Insert Field", systemImage: "text.badge.plus")
                        .font(.subheadline.weight(.semibold))
                }
                .accessibilityHint("Inserts a contact field at the cursor.")
            }

            MergeFieldTextView(
                text: $text,
                selectedRange: $selectedRange
            )
            .frame(minHeight: minimumHeight)
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            if !filteredFields.isEmpty {
                EmailMergeFieldSuggestions(fields: filteredFields, insert: insert)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Text("Insert a field above, or type {{ to see suggestions. Fields are filled from either a customer or prospect when the email is sent.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .animation(.snappy(duration: 0.2), value: filteredFields)
    }

    private func insert(_ field: EmailMergeField) {
        let nsText = text as NSString
        let replacementRange: NSRange

        if let activeTokenRange {
            replacementRange = activeTokenRange
        } else {
            let location = min(selectedRange.location, nsText.length)
            let length = min(selectedRange.length, nsText.length - location)
            replacementRange = NSRange(location: location, length: length)
        }

        text = nsText.replacingCharacters(in: replacementRange, with: field.token)
        selectedRange = NSRange(
            location: replacementRange.location + (field.token as NSString).length,
            length: 0
        )
    }
}

private struct MergeFieldTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, selectedRange: $selectedRange)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.isScrollEnabled = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.autocorrectionType = .no
        textView.accessibilityLabel = String(localized: "Email Body")
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.isSynchronizingFromSwiftUI = true
        defer { context.coordinator.isSynchronizingFromSwiftUI = false }

        if textView.text != text {
            textView.text = text
        }

        let textLength = (textView.text as NSString).length
        let location = min(selectedRange.location, textLength)
        let length = min(selectedRange.length, textLength - location)
        let safeRange = NSRange(location: location, length: length)

        if textView.selectedRange != safeRange {
            textView.selectedRange = safeRange
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var text: String
        @Binding private var selectedRange: NSRange

        var isSynchronizingFromSwiftUI = false

        init(text: Binding<String>, selectedRange: Binding<NSRange>) {
            _text = text
            _selectedRange = selectedRange
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isSynchronizingFromSwiftUI else { return }
            text = textView.text
            selectedRange = textView.selectedRange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isSynchronizingFromSwiftUI else { return }
            selectedRange = textView.selectedRange
        }
    }
}

private struct EmailMergeFieldSuggestions: View {
    let fields: [EmailMergeField]
    let insert: (EmailMergeField) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Contact fields")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            ForEach(fields) { field in
                Button {
                    insert(field)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: field.systemImage)
                            .frame(width: 20)
                            .foregroundStyle(.tint)

                        Text(field.title)

                        Spacer()

                        Text(field.token)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if field.id != fields.last?.id {
                    Divider()
                        .padding(.leading, 42)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator.opacity(0.35), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}
