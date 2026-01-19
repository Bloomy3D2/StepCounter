//
//  LoadingStateView.swift
//  StepCounter
//
//  Компоненты для отображения состояний загрузки
//

import SwiftUI

/// Универсальный View для отображения состояния загрузки
struct LoadingStateView<Content: View, LoadingView: View, ErrorView: View>: View {
    let state: LoadingState<Any>
    let content: () -> Content
    let loadingView: () -> LoadingView
    let errorView: (Error) -> ErrorView
    
    init(
        state: LoadingState<Any>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder loadingView: @escaping () -> LoadingView = { DefaultLoadingView() },
        @ViewBuilder errorView: @escaping (Error) -> ErrorView = { DefaultErrorView(error: $0) }
    ) {
        self.state = state
        self.content = content
        self.loadingView = loadingView
        self.errorView = errorView
    }
    
    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            loadingView()
        case .loaded:
            content()
        case .error(let error):
            errorView(error)
        }
    }
}

/// Стандартный View для загрузки
struct DefaultLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Загрузка данных...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

/// Стандартный View для ошибки
struct DefaultErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Ошибка загрузки")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            if let loadingError = error as? LoadingError,
               let message = loadingError.errorDescription {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else {
                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

/// Компактный индикатор загрузки
struct CompactLoadingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Загрузка...")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}

/// Компактное сообщение об ошибке
struct CompactErrorView: View {
    let error: Error
    let onRetry: (() -> Void)?
    
    init(error: Error, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Повторить")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private var errorMessage: String {
        if let loadingError = error as? LoadingError {
            return loadingError.errorDescription ?? "Ошибка загрузки"
        }
        return error.localizedDescription
    }
}

/// Модификатор для отображения состояния загрузки
extension View {
    func loadingState<T>(
        _ state: LoadingState<T>,
        loading: @escaping () -> some View = { DefaultLoadingView() },
        error: @escaping (Error) -> some View = { DefaultErrorView(error: $0) }
    ) -> some View {
        Group {
            switch state {
            case .idle:
                self
            case .loading:
                loading()
            case .loaded:
                self
            case .error(let err):
                error(err)
            }
        }
    }
}
