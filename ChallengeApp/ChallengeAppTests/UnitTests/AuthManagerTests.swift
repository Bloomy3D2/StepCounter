//
//  AuthManagerTests.swift
//  ChallengeAppTests
//
//  Unit тесты для AuthManager
//

import XCTest
@testable import ChallengeApp

@MainActor
final class AuthManagerTests: XCTestCase {
    var sut: AuthManager!
    var mockSupabaseManager: MockSupabaseManager!
    
    override func setUp() {
        super.setUp()
        mockSupabaseManager = MockSupabaseManager()
        sut = AuthManager(supabaseManager: mockSupabaseManager)
    }
    
    override func tearDown() {
        sut = nil
        mockSupabaseManager = nil
        super.tearDown()
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUp_Success() async throws {
        // Given
        let expectedUser = User(
            id: "test-user-id",
            name: "Test User",
            email: "test@example.com",
            balance: 0.0,
            authProvider: .email
        )
        mockSupabaseManager.signUpResult = .success(expectedUser)
        
        // When
        let result = try await sut.signUp(
            email: "test@example.com",
            password: "password123",
            name: "Test User"
        )
        
        // Then
        XCTAssertEqual(result.id, "test-user-id")
        XCTAssertEqual(result.email, "test@example.com")
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertNil(sut.lastError)
    }
    
    func testSignUp_InvalidEmail() async {
        // Given
        mockSupabaseManager.signUpResult = .failure(
            AppError.invalidEmail
        )
        
        // When & Then
        do {
            _ = try await sut.signUp(
                email: "invalid-email",
                password: "password123",
                name: "Test User"
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AppError)
            if let appError = error as? AppError {
                XCTAssertEqual(appError, AppError.invalidEmail)
            }
            XCTAssertFalse(sut.isAuthenticating)
        }
    }
    
    func testSignUp_EmailNotConfirmed() async {
        // Given
        mockSupabaseManager.signUpResult = .failure(
            AppError.emailNotConfirmed
        )
        
        // When & Then
        do {
            _ = try await sut.signUp(
                email: "test@example.com",
                password: "password123",
                name: "Test User"
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AppError)
            if let appError = error as? AppError {
                XCTAssertEqual(appError, AppError.emailNotConfirmed)
            }
        }
    }
    
    // MARK: - Sign In Tests
    
    func testSignIn_Success() async throws {
        // Given
        let expectedUser = User(
            id: "test-user-id",
            email: "test@example.com",
            name: "Test User",
            balance: 100.0,
            level: 1,
            experience: 0,
            authProvider: "EMAIL"
        )
        mockSupabaseManager.signInResult = .success(expectedUser)
        
        // When
        let result = try await sut.signIn(
            email: "test@example.com",
            password: "password123"
        )
        
        // Then
        XCTAssertEqual(result.id, "test-user-id")
        XCTAssertEqual(result.email, "test@example.com")
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertNil(sut.lastError)
    }
    
    func testSignIn_InvalidCredentials() async {
        // Given
        mockSupabaseManager.signInResult = .failure(
            AppError.invalidCredentials
        )
        
        // When & Then
        do {
            _ = try await sut.signIn(
                email: "test@example.com",
                password: "wrong-password"
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AppError)
            if let appError = error as? AppError {
                XCTAssertEqual(appError, AppError.invalidCredentials)
            }
            XCTAssertFalse(sut.isAuthenticating)
            XCTAssertNotNil(sut.lastError)
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_Success() async throws {
        // Given
        mockSupabaseManager.signOutError = nil
        
        // When
        try await sut.signOut()
        
        // Then
        // Проверяем, что ошибок нет
        XCTAssertNil(sut.lastError)
    }
    
    func testSignOut_Error() async {
        // Given
        mockSupabaseManager.signOutError = AppError.authenticationRequired
        
        // When & Then
        do {
            try await sut.signOut()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
}
