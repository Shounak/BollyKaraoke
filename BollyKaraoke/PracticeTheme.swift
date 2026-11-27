import SwiftUI

enum PracticeTheme {
    static let background = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let paper = Color(red: 1, green: 0.99, blue: 0.97)
    static let ink = Color(red: 0.17, green: 0.12, blue: 0.10)
    static let muted = Color(red: 0.42, green: 0.35, blue: 0.31)
    static let accent = Color(red: 0.60, green: 0.24, blue: 0.17)
    static let blush = Color(red: 0.98, green: 0.89, blue: 0.84)
    static let line = Color(red: 0.90, green: 0.84, blue: 0.79)
    static let green = Color(red: 0.22, green: 0.41, blue: 0.32)
}

struct RecordArtwork: View {
    var center = 0.5

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let diameter = size.height * 1.15
            ZStack {
                LinearGradient(
                    colors: [PracticeTheme.blush, Color(red: 0.97, green: 0.76, blue: 0.62)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<4) { ring in
                    let width = diameter * (1.13 + Double(ring) * 0.20)
                    Circle()
                        .strokeBorder(PracticeTheme.accent.opacity(0.13), lineWidth: 1)
                        .frame(width: width, height: width)
                        .position(x: size.width * center, y: size.height * 0.53)
                }

                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.47, green: 0.19, blue: 0.16), PracticeTheme.ink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    ForEach(0..<7) { ring in
                        let width = diameter * (0.94 - Double(ring) * 0.075)
                        Circle()
                            .strokeBorder(.white.opacity(ring.isMultiple(of: 2) ? 0.12 : 0.06), lineWidth: 1)
                            .frame(width: width, height: width)
                    }
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 1, green: 0.83, blue: 0.68), Color(red: 0.90, green: 0.55, blue: 0.40)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: diameter * 0.31, height: diameter * 0.31)
                    Image(systemName: "waveform")
                        .font(.system(size: diameter * 0.115, weight: .semibold))
                        .foregroundStyle(PracticeTheme.ink)
                }
                .frame(width: diameter, height: diameter)
                .position(x: size.width * center, y: size.height * 0.53)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

func trackTime(_ seconds: TimeInterval) -> String {
    let whole = Int(max(0, seconds))
    return String(format: "%d:%02d", whole / 60, whole % 60)
}
