//
//  AuthService.swift
//  Kare
//
//  Real accounts, through Firebase Auth. Two doors in (Sign in with Apple,
//  email and password), one door out (log out) and one door that closes the
//  account for good (delete), which Guideline 5.1.1(v) requires the moment an
//  app lets people create one.
//
//  The rest of the app keeps reading `OnboardingKeys.hasAccount`; this file is
//  the only thing that sets it to true, and only after Firebase says yes.
//

import Foundation
import AuthenticationServices
import UIKit
import CryptoKit
import Security
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@MainActor
enum AuthService {

    // MARK: State

    static var isAvailable: Bool { FirebaseApp.app() != nil }

    static var currentUID: String? {
        guard isAvailable else { return nil }
        return Auth.auth().currentUser?.uid
    }

    static var currentDisplayName: String? {
        guard isAvailable else { return nil }
        return Auth.auth().currentUser?.displayName
    }

    static var isAppleAccount: Bool {
        guard isAvailable else { return false }
        return Auth.auth().currentUser?.providerData.contains { $0.providerID == "apple.com" } ?? false
    }

    /// Called at launch. A device that says "signed in" while Firebase has no
    /// user (an old build's local-only sign-in, a revoked session) goes back
    /// to being a guest, so nothing is ever posted under an unverified name.
    static func reconcile() {
        guard isAvailable else { return }
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: OnboardingKeys.hasAccount), Auth.auth().currentUser == nil {
            defaults.set(false, forKey: OnboardingKeys.hasAccount)
        }
    }

    // MARK: Sign in with Apple

    /// The raw nonce for the request in flight. Apple gets its hash, Firebase
    /// gets the raw value, and that pairing is what stops a replayed token.
    private static var pendingNonce: String?

    /// Fills in an Apple ID request. Use from `SignInWithAppleButton`.
    static func prepare(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonce()
        pendingNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Signs in to Firebase with the Apple credential. Returns the best name
    /// we have: the one Apple just gave (first sign-in only) or the one saved
    /// on the account.
    @discardableResult
    static func signIn(with apple: ASAuthorizationAppleIDCredential) async throws -> String {
        guard isAvailable else { throw AuthFailure.unavailable }
        guard let nonce = pendingNonce,
              let tokenData = apple.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthFailure.appleTokenMissing
        }
        pendingNonce = nil
        let credential = OAuthProvider.appleCredential(withIDToken: token,
                                                       rawNonce: nonce,
                                                       fullName: apple.fullName)
        let result = try await run { try await Auth.auth().signIn(with: credential) }

        let given = [apple.fullName?.givenName, apple.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")
        if !given.isEmpty, result.user.displayName?.isEmpty ?? true {
            try? await setDisplayName(given)
        }
        return given.isEmpty ? (result.user.displayName ?? "") : given
    }

    // MARK: Email

    static func signUp(name: String, email: String, password: String) async throws {
        guard isAvailable else { throw AuthFailure.unavailable }
        _ = try await run { try await Auth.auth().createUser(withEmail: email, password: password) }
        try? await setDisplayName(name)
    }

    /// Returns the name saved on the account, or the part of the email before
    /// the @ when there is none.
    static func logIn(email: String, password: String) async throws -> String {
        guard isAvailable else { throw AuthFailure.unavailable }
        let result = try await run { try await Auth.auth().signIn(withEmail: email, password: password) }
        if let name = result.user.displayName, !name.isEmpty { return name }
        return (email.split(separator: "@").first.map(String.init) ?? "").capitalized
    }

    static func sendPasswordReset(to email: String) async throws {
        guard isAvailable else { throw AuthFailure.unavailable }
        try await run { try await Auth.auth().sendPasswordReset(withEmail: email) }
    }

    static func setDisplayName(_ name: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        let change = user.createProfileChangeRequest()
        change.displayName = name
        try await change.commitChanges()
    }

    // MARK: Leaving

    static func signOut() {
        guard isAvailable else { return }
        try? Auth.auth().signOut()
    }

    /// Deletes the account and everything it wrote.
    ///
    /// Firebase only deletes an account that signed in recently, so this asks
    /// again first: Apple users go through the Apple sheet (which also gives
    /// the code needed to revoke Kare's access to their Apple ID, as Apple
    /// asks), email users type their password.
    static func deleteAccount(password: String?) async throws {
        guard isAvailable, let user = Auth.auth().currentUser else { throw AuthFailure.notSignedIn }

        if isAppleAccount {
            let apple = try await AppleReauth.request()
            guard let nonce = pendingNonce,
                  let tokenData = apple.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                throw AuthFailure.appleTokenMissing
            }
            pendingNonce = nil
            let credential = OAuthProvider.appleCredential(withIDToken: token, rawNonce: nonce,
                                                           fullName: apple.fullName)
            _ = try await run { try await user.reauthenticate(with: credential) }
            if let codeData = apple.authorizationCode,
               let code = String(data: codeData, encoding: .utf8) {
                try? await Auth.auth().revokeToken(withAuthorizationCode: code)
            }
        } else if let email = user.email, let password {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            _ = try await run { try await user.reauthenticate(with: credential) }
        }

        // Their reviews go with them. Done before the account, while the
        // security rules can still see who owns them.
        await ReviewService.deleteAll(byUID: user.uid)
        try await run { try await user.delete() }
    }

    // MARK: Helpers

    /// Runs a Firebase call and turns its error into one we can show.
    @discardableResult
    private static func run<T>(_ body: () async throws -> T) async throws -> T {
        do { return try await body() } catch { throw AuthFailure(error) }
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    fileprivate static func prepareForReauth(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonce()
        pendingNonce = nonce
        request.requestedScopes = []
        request.nonce = sha256(nonce)
    }
}

// MARK: - Errors

enum AuthFailure: LocalizedError {
    case unavailable
    case notSignedIn
    case appleTokenMissing
    case cancelled
    case message(String)

    init(_ error: Error) {
        let ns = error as NSError
        guard ns.domain == "FIRAuthErrorDomain", let code = AuthErrorCode(rawValue: ns.code) else {
            self = .message(error.localizedDescription)
            return
        }
        switch code {
        case .emailAlreadyInUse:
            self = .message(String(localized: "That email already has an account. Try logging in."))
        case .invalidEmail:
            self = .message(String(localized: "That email doesn't look right."))
        case .weakPassword:
            self = .message(String(localized: "Pick a longer password, at least 6 characters."))
        case .wrongPassword, .invalidCredential, .userNotFound:
            self = .message(String(localized: "Email or password is wrong."))
        case .networkError:
            self = .message(String(localized: "No connection. Check your internet and try again."))
        case .tooManyRequests:
            self = .message(String(localized: "Too many tries. Wait a minute and try again."))
        case .requiresRecentLogin:
            self = .message(String(localized: "For your safety, log out, log back in, then try again."))
        case .userDisabled:
            self = .message(String(localized: "This account has been turned off."))
        default:
            self = .message(error.localizedDescription)
        }
    }

    var errorDescription: String? {
        switch self {
        case .unavailable: String(localized: "Accounts aren't available right now. Try again later.")
        case .notSignedIn: String(localized: "You're not signed in.")
        case .appleTokenMissing: String(localized: "Couldn't sign in with Apple. Try again.")
        case .cancelled: nil
        case let .message(text): text
        }
    }
}

// MARK: - Apple re-authentication

/// Shows the Apple sheet from code, for the one place there is no button:
/// confirming who you are before the account is deleted.
@MainActor
private final class AppleReauth: NSObject,
                                 @preconcurrency ASAuthorizationControllerDelegate,
                                 @preconcurrency ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    private static var current: AppleReauth?

    static func request() async throws -> ASAuthorizationAppleIDCredential {
        let helper = AppleReauth()
        current = helper
        defer { current = nil }
        return try await withCheckedThrowingContinuation { continuation in
            helper.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            AuthService.prepareForReauth(request)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = helper
            controller.presentationContextProvider = helper
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: AuthFailure.appleTokenMissing)
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        let cancelled = (error as? ASAuthorizationError)?.code == .canceled
        continuation?.resume(throwing: cancelled ? AuthFailure.cancelled : error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
