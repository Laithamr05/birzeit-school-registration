import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var loc: LocalizationManager
    @State private var showAuth = false
    @State private var startInSignup = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.primaryDark, Theme.primary],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 280, height: 280)
                    .offset(x: -120, y: -80)
                Circle()
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .offset(x: geo.size.width - 140, y: 120)
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 90, y: geo.size.height - 250)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    LanguageToggle()
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)

                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 130, height: 130)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(Theme.primaryGradient)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

                    Text(L.t(.appName))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(L.t(.appHeadline))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        startInSignup = false
                        showAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text(L.t(.login))
                        }
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.primaryDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(Theme.radius)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                    }
                    Button {
                        startInSignup = true
                        showAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text(L.t(.signUp))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(Theme.radius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 26)
            }
        }
        .fullScreenCover(isPresented: $showAuth) {
            AuthView(startInSignup: startInSignup)
        }
    }
}
