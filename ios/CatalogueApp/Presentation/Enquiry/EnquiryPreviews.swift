import CatalogueDomain
import SwiftUI

private enum EnquiryPreviewScenario: Sendable {
    case empty
    case filled
    case fieldErrors
    case submitting
    case failure
    case success
}

private struct EnquiryPreviewHost: View {
    @State private var viewModel: EnquiryViewModel
    private let scenario: EnquiryPreviewScenario

    init(scenario: EnquiryPreviewScenario) {
        self.scenario = scenario
        let repository = EnquiryPreviewRepository(scenario: scenario)
        _viewModel = State(
            initialValue: EnquiryViewModel(
                product: EnquiryProduct(id: 1, title: "Everyday Canvas Backpack"),
                submitEnquiry: SubmitEnquiryUseCase(repository: repository)
            )
        )
    }

    var body: some View {
        EnquiryView(viewModel: viewModel)
            .task {
                await prepareScenario()
            }
    }

    private func prepareScenario() async {
        switch scenario {
        case .empty:
            break
        case .filled:
            fillForm()
        case .fieldErrors:
            await viewModel.submit()
        case .submitting, .failure, .success:
            fillForm()
            await viewModel.submit()
        }
    }

    private func fillForm() {
        viewModel.name = "Ada Lovelace"
        viewModel.email = "ada@example.test"
        viewModel.phone = "+1 555 010-1234"
        viewModel.message = "I have a question about the backpack."
    }
}

private struct EnquiryPreviewRepository: EnquiryRepository {
    let scenario: EnquiryPreviewScenario

    func submit(_ enquiry: Enquiry) async throws -> EnquiryReceipt {
        switch scenario {
        case .failure:
            throw AppError.unreachable
        case .submitting:
            try await Task.sleep(for: .seconds(3_600))
            return EnquiryReceipt(id: "preview")
        case .empty, .filled, .fieldErrors, .success:
            return EnquiryReceipt(id: "preview")
        }
    }
}

#Preview("Empty enquiry") {
    EnquiryPreviewHost(scenario: .empty)
}

#Preview("Filled enquiry") {
    EnquiryPreviewHost(scenario: .filled)
}

#Preview("Field errors") {
    EnquiryPreviewHost(scenario: .fieldErrors)
}

#Preview("Submitting enquiry") {
    EnquiryPreviewHost(scenario: .submitting)
}

#Preview("Failure banner") {
    EnquiryPreviewHost(scenario: .failure)
}

#Preview("Thank you") {
    EnquiryPreviewHost(scenario: .success)
}
