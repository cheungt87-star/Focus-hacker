import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
            Text("FocusHacker")
                .font(.fhDisplay)
                .foregroundStyle(Color.fhTextPrimary)
            Text("Foundation scaffold is active. Feature work starts in EPIC 2.")
                .font(.fhBody)
                .foregroundStyle(Color.fhTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(DesignSpacing.spacing6)
        .background(Color.fhBgApp)
    }
}

#Preview {
    RootView(dependencies: .live)
}
