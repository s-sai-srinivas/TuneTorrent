import SwiftUI

// MARK: - GlassCard (Liquid Glass like iOS 18)
struct GlassCard<Content: View>: View {
    let content: Content
    var tint: Color? = nil
    init(tint: Color? = nil, @ViewBuilder content: () -> Content) { self.tint = tint; self.content = content() }
    var body: some View {
        content
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.glassStroke, lineWidth: 0.8)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .fill(Theme.glassGradient).opacity(0.45)
                    }
            }
            .shadow(color: Theme.glassShadow, radius: 16, y: 8)
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }
}

// MARK: - LiquidGlassButton
struct LiquidGlassButton: View {
    let title: String; let systemImage: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing:6){ Image(systemName: systemImage).font(.caption.weight(.semibold)); Text(title).font(.caption.weight(.semibold)) }
                .padding(.horizontal,12).padding(.vertical,8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay{ Capsule().stroke(Theme.glassStroke, lineWidth:0.7) }
                .shadow(color: Theme.glassShadow, radius: 8, y: 4)
        }.tint(Theme.accent)
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    let icon: String; let title: String; let subtitle: String; var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            ZStack{
                Circle().fill(.ultraThinMaterial).frame(width:84,height:84).overlay(Circle().stroke(Theme.glassStroke,lineWidth:1))
                Image(systemName: icon).font(.system(size: 36, weight: .light)).foregroundStyle(.secondary)
            }
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 24)
            if let a = action { LiquidGlassButton(title: "Add", systemImage: "plus", action: a) }
        }.padding(32)
    }
}

// MARK: - StorageBar (glassy capsule)
struct StorageBar: View {
    var breakdown: StorageBreakdown
    var body: some View {
        GeometryReader { geo in
            let total = max(breakdown.totalUsed, 1)
            HStack(spacing: 3) {
                Capsule().fill(Theme.accentGradient).frame(width: geo.size.width * CGFloat(breakdown.music) / CGFloat(total))
                Capsule().fill(LinearGradient(colors:[.purple,.pink], startPoint:.leading, endPoint:.trailing)).frame(width: geo.size.width * CGFloat(breakdown.video) / CGFloat(total))
                Capsule().fill(LinearGradient(colors:[.orange,.yellow], startPoint:.leading, endPoint:.trailing)).frame(width: geo.size.width * CGFloat(breakdown.torrents) / CGFloat(total))
                Capsule().fill(Color.secondary.opacity(0.18)).frame(width: geo.size.width * CGFloat(breakdown.other) / CGFloat(total))
            }
        }.frame(height: 10).clipShape(Capsule()).overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 0.5))
    }
}

// MARK: - GlassTabBar Modifier
struct GlassTabBackground: ViewModifier {
    func body(content: Content) -> some View { content.background(.ultraThinMaterial).overlay(Rectangle().frame(height:0.5).foregroundStyle(Color.white.opacity(0.5)), alignment:.top) }
}
