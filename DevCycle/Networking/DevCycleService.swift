//
//  DevCycleService.swift
//  DevCycle
//
//  Created by Jason Salaber on 2021-11-30.
//

import Foundation

typealias DataResponse = (data: Data?, urlResponse: URLResponse?, error: Error?)
typealias CompletionHandler = (DataResponse) -> Void

typealias Config = (config: UserConfig?, error: Error?)
typealias ConfigCompletionHandler = (Config) -> Void

typealias PublishEventsCompletionHandler = (DataResponse) -> Void

struct NetworkingConstants {
    static let hostUrl = ".devcycle.com"
    static let sdkUrl = "https://sdk-api"
    static let eventsUrl = "https://events"
    
    struct Version {
        static let v1 = "/v1"
    }
    
    struct UrlPaths {
        static let config = "/sdkConfig"
        static let events = "/events"
    }
}

protocol DevCycleServiceProtocol {
    func getConfig(completion: @escaping ConfigCompletionHandler)
    func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler)
}

class DevCycleService: DevCycleServiceProtocol {
    var session: URLSession
    var config: DVCConfig
    
    var cacheService: CacheServiceProtocol
    
    init(config: DVCConfig, cacheService: CacheServiceProtocol) {
        let sessionConfig = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfig)
        self.config = config
        self.cacheService = cacheService
    }
    
    func getConfig(completion: @escaping ConfigCompletionHandler) {
        cacheService.save(user: config.user)
        let configRequest = createConfigRequest(user: config.user)
        self.makeRequest(request: configRequest) { response in
            guard let config = self.processConfig(response.data) else {
                completion((nil, response.error))
                return
            }
            completion((config, response.error))
        }
    }
    
    func publishEvents(events: [DVCEvent], user: DVCUser, completion: @escaping PublishEventsCompletionHandler) {
        var eventsRequest = createEventsRequest()
        guard let userId = user.userId, let featureVariationMap = self.config.userConfig?.featureVariationMap else {
            return completion((nil, nil, ClientError.MissingUserOrFeatureVariationsMap))
        }

        let eventPayload = self.generateEventPayload(events, userId, featureVariationMap)
        
        let requestBody: [String: Any] = [
            "events": eventPayload,
            "user": user
        ]
        
        eventsRequest.httpMethod = "POST"
        eventsRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        eventsRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        eventsRequest.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
        
        self.makeRequest(request: eventsRequest) { data, response, error in
            if error != nil || data == nil {
                print("Failed to Post Events!")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("statusCode: \(httpResponse.statusCode)")
                return
            }
        }
    }
    
    func makeRequest(request: URLRequest, completion: CompletionHandler?) {
        if let urlString = request.url?.absoluteString {
            print("Making request: " + urlString)
        }
        self.session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion?((data, response, error))
            }
        }.resume()
    }
    
    func createConfigRequest(user: DVCUser) -> URLRequest {
        let userQueryItems: [URLQueryItem] = user.toQueryItems()
        let urlComponents: URLComponents = createRequestUrl("config", userQueryItems)
        let url = urlComponents.url!
        return URLRequest(url: url)
    }
    
    func createEventsRequest() -> URLRequest {
        let urlComponents: URLComponents = createRequestUrl("event", nil)
        let url = urlComponents.url!
        return URLRequest(url: url)
    }
    
    private func createRequestUrl(_ type: String, _ queryItems: [URLQueryItem]?) -> URLComponents {
        var url: String
        switch(type) {
        case "event":
            url = NetworkingConstants.eventsUrl + NetworkingConstants.hostUrl
            url.append("\(NetworkingConstants.Version.v1)")
            url.append("\(NetworkingConstants.UrlPaths.events)")
        default:
            url = NetworkingConstants.sdkUrl + NetworkingConstants.hostUrl
            url.append("\(NetworkingConstants.Version.v1)")
            url.append("\(NetworkingConstants.UrlPaths.config)")
        }
        var urlComponents: URLComponents = URLComponents(string: url)!
        if (queryItems != nil && queryItems?.isEmpty == false) {
            var querySpecificItems: [URLQueryItem] = queryItems ?? []
            querySpecificItems.append(URLQueryItem(name: "envKey", value: config.environmentKey))
            urlComponents.queryItems = querySpecificItems
        } else {
            urlComponents.queryItems = [URLQueryItem(name: "envKey", value: config.environmentKey)]
        }
        return urlComponents
    }
    
    private func generateEventPayload(_ events: [DVCEvent], _ userId: String, _ featureVariables: [String: String]) -> Any {
        var eventsJSON: [Any] = []
        
        for event in events {
            let eventDate: Date = event.date ?? Date()
            let eventToPost: DVCEvent = DVCEvent(type: event.type, target: event.target, clientDate: eventDate, value: event.value, metaData: event.metaData, user_id: userId, date: Date(), featureVars: featureVariables)
            guard let encodedEventData = try? JSONSerialization.data(withJSONObject: eventToPost, options: []) else {
                continue
            }
            
            eventsJSON.append(encodedEventData)
        }
        
        return eventsJSON
    }
}

extension DevCycleService {
    func processConfig(_ responseData: Data?) -> UserConfig? {
        guard let data = responseData else {
            print("No config data")
            return nil
        }
        do {
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String:Any]
            let userConfig = try UserConfig(from: dictionary)
            cacheService.save(config: data)
            return userConfig
        } catch {
            print("Failed to decode config: \(error)")
        }
        return nil
    }
}
