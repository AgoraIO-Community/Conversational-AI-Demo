//
//  LoginRequestModel.swift
//  AgoraEntScenarios
//
//  Created by qinhui on 2024/11/26.
//

import Foundation
import Common

class LoginCommonModel: AUINetworkModel {
    override init() {
        super.init()
        host = AppContext.shared.baseServerUrl
    }
    
    public override func parse(data: Data?) throws -> Any? {
        var dic: Any? = nil
        do {
            try dic = super.parse(data: data)
        } catch let err {
            throw err
        }
        guard let dic = dic as? [String: Any] else {
            throw AUICommonError.networkParseFail.toNSError()
        }
        
        let message = dic["message"] as? String ?? ""
        if message == "unauthorized" {
            self.tokenExpired()
            throw AUICommonError.httpError(401, message).toNSError()
        }
        return dic["data"]
    }
}

class SSOUserInfoModel: LoginCommonModel {
    override init() {
        super.init()
        method = .get
        interfaceName = "/v1/convoai/sso/userInfo"
    }
    
    func getToken() -> String {
        guard UserCenter.shared.isLogin(),
              let token = UserCenter.user?.token else {
            return ""
        }
        return token
    }
    
    override func getHeaders() -> [String : String] {
        var headers = super.getHeaders()
        headers["Authorization"] = "Bearer " + self.getToken()
        return headers
    }
}
