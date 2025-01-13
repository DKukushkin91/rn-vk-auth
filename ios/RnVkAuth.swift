//
//  RnVkAuth.swift
//  rn-vk-auth
//
//  Created by Кукушкин Дмитрий Сергеевич on 10.01.2025.
//

import Foundation
import VKID
import React

@objc public class RnVkAuthImpl : NSObject {
  var vkid: VKID?
  var viewController: UIViewController?
  var session: UserSession?
  var responseSender: RCTResponseSenderBlock?

  private func handleSuccess(
    resolve: @escaping RCTPromiseResolveBlock,
    result: Any
  ) {
    let resultObject: [String: Any] = [
      "success": true,
      "result": result
    ]
    
    resolve(resultObject)
  }
  
  private func handleError(
    reject: @escaping RCTPromiseRejectBlock,
    code: String,
    message: String,
    error: NSError? = nil
  ) {
    let errorObject: [String: Any] = [
      "success": false,
      "error": message,
      "code": code
    ]
    
    if let jsonData = try? JSONSerialization.data(withJSONObject: errorObject, options: []),
       let jsonString = String(data: jsonData, encoding: .utf8) {
      reject(code, jsonString, error)
    } else {
      reject(code, message, nil)
    }
  }
  
  private func accessTokenToDictionary(accessToken: AccessToken) -> [String: Any]? {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      do {
          let data = try encoder.encode(accessToken)
          let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
          return dictionary
      } catch {
          print("Error encoding AccessToken to dictionary: \(error)")
          return nil
      }
  }

  private func mapAuthorizationCode(code: AuthorizationCode) -> [String: Any] {
    return [
      "code": code.code,
      "codeVerifier": code.codeVerifier ?? nil,
      "deviceId": code.deviceId,
      "redirectURI": code.redirectURI,
    ]
  }
  
  @objc public func initialize(
    _ params: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) -> Void {
    guard let clientId = params["clientId"] as? String,
          let clientSecret = params["clientSecret"] as? String
    else {
      self.handleError(
        reject: reject,
        code: "VKID_INIT_PARAMS_ERROR",
        message: "Invalid parameters"
      )
      return
    }

    let loggingEnabled = params["loggingEnabled"] as? Bool

    do {
      self.vkid = try VKID(
            config: Configuration(
                appCredentials: AppCredentials(
                    clientId: clientId,
                    clientSecret: clientSecret
                ),
                loggingEnabled: loggingEnabled ?? false
            )
        )
      
      self.handleSuccess(
        resolve: resolve,
        result: "VKID initialized success"
      )
    } catch {
      self.handleError(
        reject: reject,
        code: "VKID_INIT_ERROR",
        message: "Failed to initialize VKID: \(error)"
      )
    }
  }
  
  @objc public func toggleOneTapBottomSheet(
    _ params: NSDictionary,
    fetchApi: @escaping RCTResponseSenderBlock,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) -> Void {
    self.responseSender = fetchApi
    
    guard let serviceName = params["serviceName"] as? String,
          let cornerRadius = params["cornerRadius"] as? NSNumber,
          let autoDismissOnSuccess = params["autoDismissOnSuccess"] as? Bool,
          let scope = params["scope"] as? [String]
        else {
            self.handleError(
              reject: reject,
              code: "ONE_TAP_BOTTOM_SHEET",
              message: "Invalid parameters"
            )
            return
        }
    
    let scopeSet = Set(scope)
    let authConfiguration = AuthConfiguration(
        flow: .confidentialClientFlow(
            codeExchanger: self
        ),
        scope: Scope(scopeSet)
    )
    
    let oneTapSheet = OneTapBottomSheet(
        serviceName: serviceName,
        targetActionText: .signIn,
        oneTapButton: .init(
            height: .medium(.h44),
            cornerRadius: CGFloat(cornerRadius.intValue)
        ),
        authConfiguration: authConfiguration,
        theme: .matchingColorScheme(.system),
        autoDismissOnSuccess: autoDismissOnSuccess
    ) { authResult in
        do {
          self.session = try authResult.get()
          
          guard let session = self.session else {
            self.handleError(
              reject: reject,
              code: "ONE_TAP_BOTTOM_SHEET",
              message: "Failed get session"
            )
            return
          }
          
          print("SESSION", session)
          
          if let accessTokenDict = self.accessTokenToDictionary(accessToken: session.accessToken) {
            if let expirationDate = accessTokenDict["expirationDate"] as? String,
               let scopeDict = accessTokenDict["scope"] as? [String: Any],
               let scope = scopeDict["value"] as? [String],
               let userIdDict = accessTokenDict["userId"] as? [String: Any],
               let userId = userIdDict["value"] as? NSNumber,
               let accessToken = accessTokenDict["value"] as? String {
              
              guard let responseSender = self.responseSender else { return }
              
              self.handleSuccess(
                resolve: resolve,
                result: [
                  "expirationDate": expirationDate,
                  "scope": scope,
                  "userId": userId,
                  "accessToken": accessToken
                ]
              )
            } else {
              self.handleError(
                reject: reject,
                code: "ONE_TAP_BOTTOM_SHEET",
                message: "Failed to extract data"
              )
            }
          } else {
            self.handleError(
              reject: reject,
              code: "ONE_TAP_BOTTOM_SHEET",
              message: "Failed to encode access token"
            )
          }
        } catch AuthError.cancelled {
          self.handleError(
            reject: reject,
            code: "ONE_TAP_BOTTOM_SHEET",
            message: "Auth cancelled by user"
          )
        } catch {
          self.handleError(
            reject: reject,
            code: "ONE_TAP_BOTTOM_SHEET",
            message: "Auth failed with error: \(error)"
          )
        }
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let vkid = self.vkid else {
              reject("E_INIT_ERROR", "VKID instance is not initialized", nil)
              return
            }
      
      self.viewController = vkid.ui(for: oneTapSheet).uiViewController()
      
      guard let windowScene = UIApplication.shared.connectedScenes
        .first(where: {$0.activationState == .foregroundActive}) as? UIWindowScene,
            let rootViewController = windowScene.windows
        .first(where: {$0.isKeyWindow})?.rootViewController,
            let viewController = self.viewController
      else {
        self.handleError(
          reject: reject,
          code: "ONE_TAP_BOTTOM_SHEET_UI",
          message: "Unable to present the UI"
        )
        return
      }

      rootViewController.present(viewController, animated: true)
    }
  }
  
  @objc public func logout(
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard let session = self.session else {
      self.handleError(
        reject: reject,
        code: "VK_SESSION",
        message: "Not active session"
      )
      return
    }
    
    session.logout { result in
      self.handleSuccess(
        resolve: resolve,
        result: "VKID logout success"
      )
    }
    
    self.session = nil
    self.vkid = nil
  }
}

extension RnVkAuthImpl: AuthCodeHandler {
    public func exchange(
        _ code: AuthorizationCode,
        finishFlow: @escaping () -> Void
    ) {
      guard let responseSender = self.responseSender else { return }
      
      let authCode = self.mapAuthorizationCode(code: code)
      
      responseSender([authCode]);
      self.responseSender = nil;
      finishFlow()
    }
}
