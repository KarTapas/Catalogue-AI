import CatalogueDomain
import SwiftUI

struct EnquiryView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: EnquiryField?
    @State private var viewModel: EnquiryViewModel

    #if DEBUG
    private let debugPreviewMode: EnquiryPreviewMode?
    @State private var didRunDebugAction = false
    #endif

    #if DEBUG
    init(
        viewModel: EnquiryViewModel,
        debugPreviewMode: EnquiryPreviewMode? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.debugPreviewMode = debugPreviewMode
    }
    #else
    init(viewModel: EnquiryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    #endif

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .succeeded(let receipt):
                    successView(receipt: receipt)
                case .editing, .submitting, .failed:
                    formView
                }
            }
            .background(Palette.background)
            .navigationTitle("Enquire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if case .succeeded = viewModel.state {
                        EmptyView()
                    } else {
                        Button("Cancel", action: dismissForm)
                            .disabled(viewModel.isSubmitting)
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isSubmitting)
        .task {
            #if DEBUG
            await runDebugActionIfNeeded()
            #endif
        }
        .onChange(of: viewModel.state) { _, state in
            if case .succeeded = state {
                focusedField = nil
            }
        }
    }

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text(verbatim: "About: \(viewModel.product.title)")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if let failureMessage = viewModel.failureMessage {
                    failureBanner(failureMessage)
                }

                FormField(
                    title: "Name (required)",
                    errorMessage: viewModel.fieldErrors[EnquiryField.name.rawValue]
                ) {
                    TextField("Your name", text: $viewModel.name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .name)
                        .onChange(of: viewModel.name) { _, _ in
                            viewModel.markTouched(.name)
                        }
                }
                .disabled(viewModel.isSubmitting)

                FormField(
                    title: "Email (required)",
                    errorMessage: viewModel.fieldErrors[EnquiryField.email.rawValue]
                ) {
                    TextField("you@example.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .email)
                        .onChange(of: viewModel.email) { _, _ in
                            viewModel.markTouched(.email)
                        }
                }
                .disabled(viewModel.isSubmitting)

                FormField(
                    title: "Phone (optional)",
                    errorMessage: viewModel.fieldErrors[EnquiryField.phone.rawValue]
                ) {
                    TextField("Phone number", text: $viewModel.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .phone)
                        .onChange(of: viewModel.phone) { _, _ in
                            viewModel.markTouched(.phone)
                        }
                }
                .disabled(viewModel.isSubmitting)

                FormField(
                    title: "Message (required)",
                    errorMessage: viewModel.fieldErrors[EnquiryField.message.rawValue]
                ) {
                    TextEditor(text: $viewModel.message)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 128)
                        .focused($focusedField, equals: .message)
                        .onChange(of: viewModel.message) { _, _ in
                            viewModel.markTouched(.message)
                        }
                }
                .disabled(viewModel.isSubmitting)

                Text(verbatim: EnquiryText.messageCharacterCount(viewModel.message))
                    .font(Typography.caption)
                    .foregroundStyle(
                        viewModel.message.count > EnquiryText.messageLimit
                            ? Palette.error
                            : Palette.textSecondary
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel(
                        Text(verbatim: EnquiryText.messageCharacterCount(viewModel.message))
                    )
            }
            .padding(Spacing.s16)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(
                title: "Send enquiry",
                isLoading: viewModel.isSubmitting,
                action: submit
            )
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, Spacing.s16)
            .padding(.vertical, Spacing.s12)
            .background(Palette.background)
        }
    }

    private func failureBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.error)
                .accessibilityHidden(true)

            Text(verbatim: message)
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Palette.surface,
            in: RoundedRectangle(cornerRadius: Radius.r12)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: message))
    }

    private func successView(receipt: EnquiryReceipt) -> some View {
        let thankYouMessage = EnquiryText.thankYouMessage(for: viewModel.product.title)

        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text("Thank you")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(verbatim: thankYouMessage)
                    .font(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(title: "Done", action: dismissForm)
                .padding(.horizontal, Spacing.s16)
                .padding(.vertical, Spacing.s12)
                .background(Palette.background)
        }
        .task(id: receipt.id) {
            AccessibilityNotification.Announcement(thankYouMessage).post()
        }
    }

    private func submit() {
        focusedField = nil
        Task {
            await viewModel.submit()
        }
    }

    private func dismissForm() {
        focusedField = nil
        dismiss()
    }

    #if DEBUG
    private func runDebugActionIfNeeded() async {
        guard !didRunDebugAction else {
            return
        }
        didRunDebugAction = true

        switch debugPreviewMode {
        case .submit:
            viewModel.prefillDebugSubmission()
            await viewModel.submit()
        case .errors:
            await viewModel.submit()
        case .form, .none:
            break
        }
    }
    #endif
}
