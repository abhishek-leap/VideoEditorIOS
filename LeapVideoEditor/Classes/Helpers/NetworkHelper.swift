//
//  NetworkHelper.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 09/10/22.
//

import Foundation
import Alamofire

class NetworkHelper {
    
    static let session: Session = {
        let monitor = ClosureEventMonitor()
        monitor.requestDidCompleteTaskWithError = { request, _, _ in
            debugPrint(request)
            let urlRequest = request.request!
            if let httpBody = urlRequest.httpBody, let str = String(data: httpBody, encoding: .utf8) {
                debugPrint("BODY: \(str)")
            }
            debugPrint("HEADERS: \(urlRequest.allHTTPHeaderFields!)")
        }
        return Session(eventMonitors: [monitor])
    }()
    
    static func request<Element: Decodable>(url: String, method: HTTPMethod, param: [String: Any] = [:], headers: HTTPHeaders = [:], parameterEncoding: ParameterEncoding? = nil, _ responseType: Element.Type = Element.self) async -> DataResponse<Element, AFError> {
        let encoding: ParameterEncoding
        if let parameterEncoding = parameterEncoding {
            encoding = parameterEncoding
        } else {
            if method == .patch || method == .put || method == .post {
                encoding = JSONEncoding.default
            } else { encoding = URLEncoding.default }
        }
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        return await session.request(url, method: method, parameters: param, encoding: encoding, headers: headers).serializingDecodable(Element.self).response
    }
}
