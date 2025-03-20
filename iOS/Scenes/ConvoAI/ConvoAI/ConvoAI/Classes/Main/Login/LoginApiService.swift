//
//  LoginApiService.swift
//  AgoraEntScenarios
//
//  Created by qinhui on 2024/11/26.
//

import Foundation
import Common

struct SSOUserInfoResponse: Codable {
    let accountUid: String
    let accountType: String
    let email: String
    let companyId: Int
    let profileId: Int
    let displayName: String
    let companyName: String
    let companyCountry: String
}

class LoginApiService: NSObject {
    static func getUserInfo(callback: ((Error?)->Void)?) {
        let userInfoModel = SSOUserInfoModel()
        userInfoModel.request { error, res in
            if let err = error {
                callback?(err)
                return
            }
            
            guard let res = res else {
                callback?(NSError.init(domain: "user info is empty", code: -1))
                return
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: res, options: []) {
                do {
                    let userInfo = try JSONDecoder().decode(SSOUserInfoResponse.self, from: jsonData)
                    let model = LoginModel()
                    model.token = UserCenter.user?.token ?? ""
                    model.uid = userInfo.accountUid
                    AppContext.loginManager()?.updateUserInfo(userInfo: model)
                    callback?(nil)
                } catch {
                    callback?(NSError.init(domain: "Failed to decode JSON", code: -1))
                    print("Failed to decode JSON: \(error)")
                }
            } else {
                callback?(NSError.init(domain: "Failed to convert Any to Data", code: -1))
            }
        }
    }
}
