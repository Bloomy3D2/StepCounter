//
//  LoadingState.swift
//  StepCounter
//
//  Универсальное состояние загрузки для улучшения UX
//

import Foundation

/// Универсальное состояние загрузки данных
enum LoadingState<T> {
    case idle           // Начальное состояние, данные не загружаются
    case loading        // Данные загружаются
    case loaded(T)      // Данные успешно загружены
    case error(Error)   // Произошла ошибка при загрузке
    
    /// Проверка, загружаются ли данные
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    /// Проверка, загружены ли данные
    var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
    
    /// Проверка, есть ли ошибка
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    /// Получить загруженные данные
    var value: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }
    
    /// Получить ошибку
    var error: Error? {
        if case .error(let err) = self {
            return err
        }
        return nil
    }
    
    /// Сообщение об ошибке для пользователя
    var errorMessage: String? {
        guard let error = error else { return nil }
        
        // Обрабатываем различные типы ошибок
        if let localizedError = error as? LocalizedError {
            return localizedError.errorDescription ?? localizedError.localizedDescription
        }
        
        return error.localizedDescription
    }
}

/// Расширение для удобной работы с LoadingState в SwiftUI
extension LoadingState {
    /// Выполнить действие с загруженными данными
    func map<U>(_ transform: (T) -> U) -> LoadingState<U> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded(let value):
            return .loaded(transform(value))
        case .error(let error):
            return .error(error)
        }
    }
    
    /// Выполнить асинхронное действие с загруженными данными
    func flatMap<U>(_ transform: (T) -> LoadingState<U>) -> LoadingState<U> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded(let value):
            return transform(value)
        case .error(let error):
            return .error(error)
        }
    }
}

/// Ошибки загрузки данных
enum LoadingError: LocalizedError {
    case networkUnavailable
    case timeout
    case invalidData
    case unauthorized
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Нет подключения к интернету"
        case .timeout:
            return "Превышено время ожидания"
        case .invalidData:
            return "Получены некорректные данные"
        case .unauthorized:
            return "Требуется авторизация"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
