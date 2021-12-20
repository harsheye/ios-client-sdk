//
//  ObjCDVCClient.swift
//  DevCycle
//
//

import Foundation

@objc(DVCClient)
public class ObjCDVCClient: NSObject {
    
    var client: DVCClient?
    
    @objc public var eventQueue: [ObjCDVCEvent] = []
    
    init(builder: ObjCClientBuilder, onIntialized: ((Error?) -> Void)?) throws {
        guard let environmentKey = builder.environmentKey,
              let objcUser = builder.user,
              let user = objcUser.user
        else {
            if (builder.environmentKey == nil) {
                print("Environment key missing")
                throw ObjCClientErrors.MissingEnvironmentKey
            } else if (builder.user == nil) {
                print("User missing")
                throw ObjCClientErrors.MissingUser
            } else if (builder.user != nil && builder.user?.user == nil) {
                print("User is invalid")
                throw ObjCClientErrors.InvalidUser
            }
            return
        }
        guard let client = try? DVCClient.builder()
                .environmentKey(environmentKey)
                .user(user)
                .build(onInitialized: onIntialized)
        else {
            print("Error creating client")
            throw ObjCClientErrors.InvalidClient
        }
        self.client = client
    }
    
    @objc public func initialize(_ block: ((Error?) -> Void)?) {
        guard let client = self.client else {
            print("Client wasn't created properly")
            return
        }
        client.initialize { err in
            block?(err)
        }
    }
    
    @objc(DVCClientBuilder)
    public class ObjCClientBuilder: NSObject {
        @objc public var environmentKey: String?
        @objc public var user: ObjCDVCUser?
    }
    
    @objc(build:block:onInitialized:) public static func build(block: ((ObjCClientBuilder) -> Void), onInitialized: ((Error?) -> Void)?) throws -> ObjCDVCClient {
        let builder = ObjCClientBuilder()
        block(builder)
        let client = try ObjCDVCClient(builder: builder, onIntialized: onInitialized)
        return client
    }
    
    @objc public func track(_ event: ObjCDVCEvent) {
        self.eventQueue.append(event)
    }
}
