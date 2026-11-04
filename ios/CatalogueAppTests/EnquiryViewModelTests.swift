import CatalogueDomain
import Foundation
import Testing
@testable import CatalogueApp

@Test
@MainActor
func enquiryViewModelStartsEditingWithoutVisibleErrors() {
    let repository = FakeEnquiryRepository(outcomes: [])
    let viewModel = makeEnquiryViewModel(repository: repository)

    #expect(viewModel.state == .editing)
    #expect(viewModel.fieldErrors.isEmpty)
    #expect(viewModel.hasAttemptedSubmit == false)
    #expect(viewModel.canSubmit)
}

@Test
@MainActor
func enquirySubmitShowsRequiredErrorsWithoutCallingTheUseCase() async {
    let repository = FakeEnquiryRepository(outcomes: [])
    let viewModel = makeEnquiryViewModel(repository: repository)

    #expect(viewModel.fieldErrors.isEmpty)

    await viewModel.submit()

    #expect(viewModel.state == .editing)
    #expect(viewModel.hasAttemptedSubmit)
    #expect(viewModel.fieldErrors["name"] == "Enter your name.")
    #expect(viewModel.fieldErrors["email"] == "Enter a valid email address of 254 characters or fewer.")
    #expect(viewModel.fieldErrors["message"] == "Enter a message.")
    #expect(viewModel.fieldErrors["phone"] == nil)
    #expect(await repository.submissionCount() == 0)
}

@Test
@MainActor
func enquiryShowsOnlyTouchedFieldErrorsBeforeSubmit() {
    let repository = FakeEnquiryRepository(outcomes: [])
    let viewModel = makeEnquiryViewModel(repository: repository)

    viewModel.markTouched(.name)

    #expect(viewModel.fieldErrors == ["name": "Enter your name."])
}

@Test
@MainActor
func validEnquirySubmitsOnceAndSuccessClearsFormData() async {
    let receipt = EnquiryReceipt(id: "receipt-42")
    let repository = FakeEnquiryRepository(outcomes: [.suspended])
    let viewModel = makeEnquiryViewModel(repository: repository, productID: 42)
    fillValidEnquiry(viewModel)

    #expect(viewModel.state == .editing)

    let submission = Task {
        await viewModel.submit()
    }
    await repository.waitForSubmissionCount(1)

    #expect(viewModel.state == .submitting)
    #expect(viewModel.canSubmit == false)

    await viewModel.submit()
    #expect(await repository.submissionCount() == 1)

    #expect(await repository.completeSuspendedSubmission(with: receipt))
    await submission.value

    let received = await repository.recordedSubmissions()
    #expect(received == [
        Enquiry(
            productId: 42,
            name: "Ada Lovelace",
            email: "ada@example.test",
            phone: nil,
            message: "I have a question."
        ),
    ])
    #expect(viewModel.state == .succeeded(receipt))
    #expect(viewModel.canSubmit)
    #expect(viewModel.name.isEmpty)
    #expect(viewModel.email.isEmpty)
    #expect(viewModel.phone.isEmpty)
    #expect(viewModel.message.isEmpty)
}

@Test
@MainActor
func serverValidationErrorsMapToFieldsAndPreserveFormValues() async {
    let error = AppError.validation(
        fields: [
            "email": "Email has already been used.",
            "message": "Please revise your message.",
        ]
    )
    let repository = FakeEnquiryRepository(outcomes: [.failure(error)])
    let viewModel = makeEnquiryViewModel(repository: repository)
    fillValidEnquiry(viewModel)

    await viewModel.submit()

    #expect(viewModel.state == .failed(error))
    #expect(viewModel.fieldErrors == [
        "email": "Email has already been used.",
        "message": "Please revise your message.",
    ])
    #expect(viewModel.failureMessage == nil)
    #expect(viewModel.name == "  Ada Lovelace  ")
    #expect(viewModel.email == "ada@example.test")
    #expect(viewModel.phone.isEmpty)
    #expect(viewModel.message == "  I have a question.  ")
    #expect(viewModel.canSubmit)
    #expect(await repository.submissionCount() == 1)
}

@Test
@MainActor
func enquiryFailureMessagesAreUserFriendly() async {
    let failures: [(AppError, String)] = [
        (.rateLimited, "Too many enquiries, please try again in a minute"),
        (.unreachable, "Unable to connect. The backend may not be running."),
        (.serverUnavailable, AppError.serverUnavailable.message),
        (.unexpected, AppError.unexpected.message),
    ]

    for (error, expectedMessage) in failures {
        let repository = FakeEnquiryRepository(outcomes: [.failure(error)])
        let viewModel = makeEnquiryViewModel(repository: repository)
        fillValidEnquiry(viewModel)

        await viewModel.submit()

        #expect(viewModel.state == .failed(error))
        #expect(viewModel.failureMessage == expectedMessage)
        #expect(viewModel.name == "  Ada Lovelace  ")
    }
}

@Test
@MainActor
func unexpectedEnquiryErrorsBecomeUnexpectedAppErrors() async {
    let repository = FakeEnquiryRepository(outcomes: [.unexpected])
    let viewModel = makeEnquiryViewModel(repository: repository)
    fillValidEnquiry(viewModel)

    await viewModel.submit()

    #expect(viewModel.state == .failed(.unexpected))
    #expect(viewModel.failureMessage == AppError.unexpected.message)
}

@Test
@MainActor
func failedEnquiryCanBeRetriedWithoutLosingTypedValues() async {
    let receipt = EnquiryReceipt(id: "retry-receipt")
    let repository = FakeEnquiryRepository(
        outcomes: [.failure(.unreachable), .success(receipt)]
    )
    let viewModel = makeEnquiryViewModel(repository: repository)
    fillValidEnquiry(viewModel)

    await viewModel.submit()
    #expect(viewModel.state == .failed(.unreachable))
    #expect(viewModel.name == "  Ada Lovelace  ")
    #expect(viewModel.email == "ada@example.test")
    #expect(viewModel.message == "  I have a question.  ")

    await viewModel.submit()

    #expect(viewModel.state == .succeeded(receipt))
    #expect(await repository.submissionCount() == 2)
    #expect(await repository.recordedSubmissions() == [
        Enquiry(
            productId: 42,
            name: "Ada Lovelace",
            email: "ada@example.test",
            phone: nil,
            message: "I have a question."
        ),
        Enquiry(
            productId: 42,
            name: "Ada Lovelace",
            email: "ada@example.test",
            phone: nil,
            message: "I have a question."
        ),
    ])
}

@Test
@MainActor
func enquiryCancellationReturnsToEditingAndKeepsValues() async {
    let repository = FakeEnquiryRepository(outcomes: [.cancelled])
    let viewModel = makeEnquiryViewModel(repository: repository)
    fillValidEnquiry(viewModel)

    await viewModel.submit()

    #expect(viewModel.state == .editing)
    #expect(viewModel.name == "  Ada Lovelace  ")
    #expect(viewModel.email == "ada@example.test")
    #expect(viewModel.message == "  I have a question.  ")
    #expect(await repository.submissionCount() == 1)
}

@Test
func enquiryMessageCharacterCountIncludesOverLimitInput() {
    #expect(EnquiryText.messageCharacterCount(String(repeating: "x", count: 0)) == "0 / 2000 characters")
    #expect(EnquiryText.messageCharacterCount(String(repeating: "x", count: 1_999)) == "1999 / 2000 characters")
    #expect(EnquiryText.messageCharacterCount(String(repeating: "x", count: 2_000)) == "2000 / 2000 characters")
    #expect(EnquiryText.messageCharacterCount(String(repeating: "x", count: 2_001)) == "2001 / 2000 characters")
}

@MainActor
private func makeEnquiryViewModel(
    repository: FakeEnquiryRepository,
    productID: Int = 42
) -> EnquiryViewModel {
    EnquiryViewModel(
        product: EnquiryProduct(id: productID, title: "Everyday Backpack"),
        submitEnquiry: SubmitEnquiryUseCase(repository: repository)
    )
}

@MainActor
private func fillValidEnquiry(_ viewModel: EnquiryViewModel) {
    viewModel.name = "  Ada Lovelace  "
    viewModel.email = "ada@example.test"
    viewModel.phone = ""
    viewModel.message = "  I have a question.  "
}

private enum EnquiryOutcome: Sendable {
    case success(EnquiryReceipt)
    case failure(AppError)
    case unexpected
    case cancelled
    case suspended
}

private actor FakeEnquiryRepository: EnquiryRepository {
    private var outcomes: [EnquiryOutcome]
    private var submissions: [Enquiry] = []
    private var suspendedContinuations: [CheckedContinuation<EnquiryReceipt, Error>] = []
    private var submissionWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(outcomes: [EnquiryOutcome]) {
        self.outcomes = outcomes
    }

    func submit(_ enquiry: Enquiry) async throws -> EnquiryReceipt {
        submissions.append(enquiry)
        resumeSubmissionWaiters()

        guard !outcomes.isEmpty else {
            throw UnexpectedEnquiryRepositoryError()
        }

        switch outcomes.removeFirst() {
        case .success(let receipt):
            return receipt
        case .failure(let error):
            throw error
        case .unexpected:
            throw UnexpectedEnquiryRepositoryError()
        case .cancelled:
            throw CancellationError()
        case .suspended:
            return try await withCheckedThrowingContinuation { continuation in
                suspendedContinuations.append(continuation)
            }
        }
    }

    func submissionCount() -> Int {
        submissions.count
    }

    func recordedSubmissions() -> [Enquiry] {
        submissions
    }

    func waitForSubmissionCount(_ count: Int) async {
        guard submissions.count < count else {
            return
        }

        await withCheckedContinuation { continuation in
            submissionWaiters.append((count, continuation))
        }
    }

    func completeSuspendedSubmission(with receipt: EnquiryReceipt) -> Bool {
        guard !suspendedContinuations.isEmpty else {
            return false
        }

        suspendedContinuations.removeFirst().resume(returning: receipt)
        return true
    }

    private func resumeSubmissionWaiters() {
        let readyWaiters = submissionWaiters.filter { submissions.count >= $0.count }
        submissionWaiters.removeAll { submissions.count >= $0.count }
        readyWaiters.forEach { $0.continuation.resume() }
    }
}

private struct UnexpectedEnquiryRepositoryError: Error, Sendable {}
