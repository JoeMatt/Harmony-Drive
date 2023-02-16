//
//  DriveService.swift
//  Harmony-Drive
//
//  Created by Riley Testut on 1/25/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

import Harmony

import GoogleAPIClientForREST_Drive
import GoogleAPIClientForRESTCore
import GoogleSignIn
import GoogleSignInSwift
import GTMSessionFetcherCore

let fileQueryFields = "id, mimeType, name, headRevisionId, modifiedTime, appProperties, size"
let appDataFolder = "appDataFolder"

private let kGoogleHTTPErrorDomain = "com.google.HTTPStatus"

public class DriveService: NSObject, Service {
    public static let shared = DriveService()

    public let localizedName = NSLocalizedString("Google Drive", comment: "")
    public let identifier = "com.rileytestut.Harmony.Drive"

    public var clientID: String? {
        didSet {
            if let clientID = clientID {
                let configuration = GIDConfiguration(clientID: clientID)
                GIDSignIn.sharedInstance.configuration = configuration
            } else {
                GIDSignIn.sharedInstance.configuration = nil
            }
        }
    }

    let service = GTLRDriveService()

    private var authorizationCompletionHandlers = [(Result<Account, AuthenticationError>) -> Void]()

    private weak var presentingViewController: UIViewController?

    override private init() {
        super.init()
        service.shouldFetchNextPages = true
    }

    private func updateScopes() {
        var scopes = GIDSignIn.sharedInstance.currentUser?.grantedScopes as? [String] ?? []
        if !scopes.contains(kGTLRAuthScopeDriveAppdata) {
            scopes.append(kGTLRAuthScopeDriveAppdata)
            GIDSignIn.sharedInstance.currentUser?.addScopes(scopes, presenting: presentingViewController!)
        }
    }
}

public extension DriveService {
    func authenticate(withPresentingViewController viewController: UIViewController, completionHandler: @escaping (Result<Account, AuthenticationError>) -> Void) {
        authorizationCompletionHandlers.append(completionHandler)

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController,
                                        hint: nil,
                                        additionalScopes: nil) { signinResultMaybe, errorMaybe in
            self.sign(didSignInFor: signinResultMaybe?.user, withError: errorMaybe)
        }
    }

    func authenticateInBackground(completionHandler: @escaping (Result<Account, AuthenticationError>) -> Void) {
        authorizationCompletionHandlers.append(completionHandler)

        // Must run on main thread.
        DispatchQueue.main.async {
            GIDSignIn.sharedInstance.restorePreviousSignIn { userMaybe, errorMaybe in
                self.sign(didSignInFor: userMaybe, withError: errorMaybe)
            }
        }
    }

    func deauthenticate(completionHandler: @escaping (Result<Void, DeauthenticationError>) -> Void) {
        GIDSignIn.sharedInstance.signOut()
        completionHandler(.success)
    }
}

extension DriveService {
    func process<T>(_ result: Result<T, Error>) throws -> T {
        do {
            do {
                let value = try result.get()
                return value
            } catch let error where error._domain == kGIDSignInErrorDomain {
                switch error._code {
                case GIDSignInError.canceled.rawValue: throw GeneralError.cancelled
                case GIDSignInError.hasNoAuthInKeychain.rawValue: throw AuthenticationError.noSavedCredentials
                default: throw ServiceError(error)
                }
            } catch let error where error._domain == kGTLRErrorObjectDomain || error._domain == kGoogleHTTPErrorDomain {
                switch error._code {
                case 400, 401: throw AuthenticationError.tokenExpired
                case 403: throw ServiceError.rateLimitExceeded
                case 404: throw ServiceError.itemDoesNotExist
                default: throw ServiceError(error)
                }
            } catch {
                throw ServiceError(error)
            }
        } catch let error as HarmonyError {
            throw error
        } catch {
            assertionFailure("Non-HarmonyError thrown from DriveService.process(_:)")
            throw error
        }
    }
}

public extension DriveService // GIDSignInDelegate
{
    func sign(didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        let result: Result<Account, AuthenticationError>

        do {
            let user = try process(Result(user, error))

            service.authorizer = user.fetcherAuthorizer

            let name: String = user.profile?.name ?? ""
            let emailAddress: String = user.profile?.email ?? ""
            let account = Account(name: name, emailAddress: emailAddress)
            result = .success(account)
        } catch {
            result = .failure(AuthenticationError(error))
        }

        // Reset self.authorizationCompletionHandlers _before_ calling all the completion handlers.
        // This stops us from accidentally calling completion handlers twice in some instances.
        let completionHandlers = authorizationCompletionHandlers
        authorizationCompletionHandlers.removeAll()

        completionHandlers.forEach { $0(result) }
    }
}
