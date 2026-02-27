import SwiftUI

// MARK: - Puck Theme

/// Centralized theme constants inspired by Puck, the Faerie Dragon from Dota 2.
/// Ethereal blues, mystical purples, and arcane glows.
enum PuckTheme {
    
    // MARK: - Core Colors
    
    /// Puck's signature ethereal cyan — Illusory Orb
    static let orb = Color(red: 0.35, green: 0.78, blue: 1.0)
    
    /// Puck's arcane purple — Dream Coil
    static let coil = Color(red: 0.55, green: 0.4, blue: 1.0)
    
    /// Faerie dust pink accent
    static let faerie = Color(red: 0.75, green: 0.45, blue: 0.95)
    
    /// Ethereal Jaunt shimmer — bright highlight
    static let shimmer = Color(red: 0.6, green: 0.9, blue: 1.0)
    
    /// Deep void background tint
    static let void = Color(red: 0.06, green: 0.06, blue: 0.12)
    
    /// Muted surface for cards
    static let surface = Color.white.opacity(0.04)
    
    /// Slightly elevated surface
    static let surfaceElevated = Color.white.opacity(0.06)
    
    // MARK: - Gradients
    
    /// Primary gradient: Illusory Orb → Dream Coil
    static let primaryGradient = LinearGradient(
        colors: [orb, coil],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Vertical variant
    static let primaryGradientVertical = LinearGradient(
        colors: [orb, coil],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Faerie shimmer gradient for special accents
    static let faerieGradient = LinearGradient(
        colors: [shimmer, orb, coil, faerie],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle background gradient for the window
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.07, blue: 0.14),
            Color(red: 0.05, green: 0.05, blue: 0.10)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Header glow gradient
    static let headerGlow = RadialGradient(
        colors: [orb.opacity(0.08), .clear],
        center: .topLeading,
        startRadius: 0,
        endRadius: 300
    )
    
    // MARK: - Glow Shadows
    
    static func orbGlow(radius: CGFloat = 8) -> some View {
        Color.clear
            .shadow(color: orb.opacity(0.3), radius: radius)
    }
    
    static func coilGlow(radius: CGFloat = 8) -> some View {
        Color.clear
            .shadow(color: coil.opacity(0.3), radius: radius)
    }
    
    // MARK: - Card Style
    
    static let cardRadius: CGFloat = 10
    static let cardPadding: CGFloat = 12
}

// MARK: - Puck Card Modifier

struct PuckCard: ViewModifier {
    var isHovered: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(PuckTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(isHovered ? 0.9 : 0.7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PuckTheme.cardRadius)
                    .stroke(
                        PuckTheme.orb.opacity(isHovered ? 0.2 : 0.08),
                        lineWidth: 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: PuckTheme.cardRadius))
    }
}

// MARK: - Puck Section Header Modifier

struct PuckSectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(PuckTheme.primaryGradient)
    }
}

extension View {
    func puckCard(isHovered: Bool = false) -> some View {
        modifier(PuckCard(isHovered: isHovered))
    }
    
    func puckSectionHeader() -> some View {
        modifier(PuckSectionHeader())
    }
}
