import SwiftUI

struct SongSearchField: View {
    let title: String
    let identifier: String
    @Binding var text: String
    var onSearch: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(PracticeTheme.muted)
                .accessibilityHidden(true)

            TextField(title, text: $text, prompt: Text(title).foregroundStyle(PracticeTheme.muted))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit(submit)
                .accessibilityIdentifier(identifier)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(PracticeTheme.muted)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }

            if onSearch != nil, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: submit) {
                    Text("Search")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("submit-youtube-search")
            }
        }
        .padding(.horizontal, 15)
        .frame(minHeight: 52)
        .background(PracticeTheme.paper, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(PracticeTheme.line, lineWidth: 1)
        }
    }

    private func submit() {
        onSearch?()
        isFocused = false
    }
}
