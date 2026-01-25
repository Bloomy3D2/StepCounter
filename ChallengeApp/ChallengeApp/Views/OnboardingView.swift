//
//  OnboardingView.swift
//  ChallengeApp
//
//  Экран онбординга (3 экрана со свайпами)
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPage1(currentPage: $currentPage)
                    .tag(0)
                
                OnboardingPage2(currentPage: $currentPage)
                    .tag(1)
                
                OnboardingPage3(currentPage: $currentPage, appState: appState)
                    .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

// MARK: - Page 1: Суть
struct OnboardingPage1: View {
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Text("onboarding.short_challenges".localized)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("onboarding.on_discipline".localized)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("onboarding.money_motivates".localized)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("onboarding.next".localized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Page 2: Как это работает
struct OnboardingPage2: View {
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("onboarding.how_it_works".localized)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 24) {
                    OnboardingStep(number: 1, icon: "person.badge.plus", text: "onboarding.step_join".localized)
                    OnboardingStep(number: 2, icon: "creditcard.fill", text: "onboarding.step_pay".localized)
                    OnboardingStep(number: 3, icon: "checkmark.circle.fill", text: "onboarding.step_complete".localized)
                    OnboardingStep(number: 4, icon: "xmark.circle.fill", text: "onboarding.step_fail".localized)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 2
                }
            }) {
                Text("onboarding.next".localized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

struct OnboardingStep: View {
    let number: Int
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("\(number)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 32, height: 50)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Page 3: Честность
struct OnboardingPage3: View {
    @Binding var currentPage: Int
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 32) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                VStack(spacing: 24) {
                    Text("onboarding.not_for_everyone".localized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("onboarding.no_excuses".localized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    appState.completeOnboarding()
                }) {
                    Text("onboarding.start".localized)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    appState.completeOnboarding()
                }) {
                    Text("onboarding.skip".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}
