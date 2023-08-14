//
//  EventEmitter.swift
//  DevCycle
//

public typealias VariableSet = [String: Variable]

public typealias ErrorHandlerCallback = (Error) -> Void
public typealias InitializedHandlerCallback = (Bool) -> Void
public typealias ConfigUpdatedHandlerCallback = (VariableSet) -> Void
public typealias VariableUpdatedHandlerCallback = (String, Variable) -> Void
public typealias VariableEvaluatedHandlerCallback = (String, DVCVariable<Any>) -> Void
public typealias FeatureUpdatedHandlerCallback = (String, Feature) -> Void

public class BaseHandler<T>: Equatable {
    public static func == (lhs: BaseHandler, rhs: BaseHandler) -> Bool {
        return lhs === rhs
    }
    
    let callback: T
    
    public init(_ handler: T) {
        self.callback = handler
    }
}

public typealias ErrorEventHandler = BaseHandler<ErrorHandlerCallback>
public typealias InitializedEventHandler = BaseHandler<InitializedHandlerCallback>
public typealias ConfigUpdatedEventHandler = BaseHandler<ConfigUpdatedHandlerCallback>
public typealias VariableUpdatedHandler = BaseHandler<VariableUpdatedHandlerCallback>
public typealias VariableEvaluatedHandler = BaseHandler<VariableEvaluatedHandlerCallback>
public typealias FeatureUpdatedHandler = BaseHandler<FeatureUpdatedHandlerCallback>

enum EventHandlers {
    case error(ErrorEventHandler)
    case initialized(InitializedEventHandler)
    case configUpdated(ConfigUpdatedEventHandler)
    case variableUpdated(String?, VariableUpdatedHandler)
    case variableEvaluated(String?, VariableEvaluatedHandler)
    case featureUpdated(String?, FeatureUpdatedHandler)
}

enum EventEmitValues {
    case error(Error)
    case initialized(Bool)
    case configUpdated(VariableSet)
    case variableUpdated(String, Variable)
    case variableEvaluated(String, DVCVariable<Any>)
    case featureUpdated(String, Feature)
}

class EventEmitter {
    var errorHandlers: [ErrorEventHandler] = []
    var initHandlers: [InitializedEventHandler] = []
    var configUpdatedHandlers: [ConfigUpdatedEventHandler] = []
    var variableUpdatedHandlers: [String : [VariableUpdatedHandler]] = [:]
    var allVariableUpdatedHandlers: [VariableUpdatedHandler] = []
    var variableEvaluatedHandlers: [String : [VariableEvaluatedHandler]] = [:]
    var allVariableEvaluatedHandlers: [VariableEvaluatedHandler] = []
    var featureUpdatedHandlers: [String : [FeatureUpdatedHandler]] = [:]
    var allFeatureUpdatedHandlers: [FeatureUpdatedHandler] = []

    func subscribe(_ handler: EventHandlers) {
        switch handler {
        case .error(let handler):
            self.errorHandlers.append(handler)
        case .initialized(let handler):
            self.initHandlers.append(handler)
        case .configUpdated(let handler):
            self.configUpdatedHandlers.append(handler)
        case .variableUpdated(let key, let handler):
            if let key = key {
                subscribeByKey(key, handler: handler, handlersByKey: &self.variableUpdatedHandlers)
            } else {
                self.allVariableUpdatedHandlers.append(handler)
            }
        case .variableEvaluated(let key, let handler):
            if let key = key {
                subscribeByKey(key, handler: handler, handlersByKey: &self.variableEvaluatedHandlers)
            } else {
                self.allVariableEvaluatedHandlers.append(handler)
            }
        case .featureUpdated(let key, let handler):
            if let key = key {
                subscribeByKey(key, handler: handler, handlersByKey: &self.featureUpdatedHandlers)
            } else {
                self.allFeatureUpdatedHandlers.append(handler)
            }
        }
    }
    
    private func subscribeByKey<T>(_ key: String, handler: T, handlersByKey: inout [String: [T]]) {
        if var handlers = handlersByKey[key] {
            handlers.append(handler)
        } else {
            handlersByKey[key] = [handler]
        }
    }
    
    func unsubscribe(_ handler: EventHandlers) {
        switch handler {
        case .error(let handler):
            unsubscribeHandler(handler, handlers: &self.errorHandlers)
        case .initialized(let handler):
            unsubscribeHandler(handler, handlers: &self.initHandlers)
        case .configUpdated(let handler):
            unsubscribeHandler(handler, handlers: &self.configUpdatedHandlers)
        case .variableUpdated(let key, let handler):
            if let key = key {
                unsubscribeHandlerByKey(key, handler: handler, handlersByKey: &self.variableUpdatedHandlers)
            } else {
                unsubscribeHandler(handler, handlers: &self.allVariableUpdatedHandlers)
            }
        case .variableEvaluated(let key, let handler):
            if let key = key {
                unsubscribeHandlerByKey(key, handler: handler, handlersByKey: &self.variableEvaluatedHandlers)
            } else {
                unsubscribeHandler(handler, handlers: &self.allVariableEvaluatedHandlers)
            }
        case .featureUpdated(let key, let handler):
            if let key = key {
                unsubscribeHandlerByKey(key, handler: handler, handlersByKey: &self.featureUpdatedHandlers)
            } else {
                unsubscribeHandler(handler, handlers: &self.allVariableEvaluatedHandlers)
            }
        }
    }
    
    private func unsubscribeHandlerByKey<T: Equatable>(_ key: String, handler: T, handlersByKey: inout [String: [T]]) {
        if var handlers = handlersByKey[key] {
            unsubscribeHandler(handler, handlers: &handlers)
        }
    }
    
    private func unsubscribeHandler<T: Equatable>(_ handler: T, handlers: inout [T]) {
        if let index = handlers.firstIndex(where: { $0 == handler }) {
            handlers.remove(at: index)
        }
    }
    
    func emit(_ emitValues: EventEmitValues) {
        switch emitValues {
        case .error(let err):
            self.errorHandlers.forEach { handler in handler.callback(err) }
        case .initialized(let initialized):
            self.initHandlers.forEach { handler in handler.callback(initialized) }
        case .configUpdated(let variableSet):
            self.configUpdatedHandlers.forEach { handler in handler.callback(variableSet) }
        case .variableUpdated(let key, let variable):
            if let handlers = self.variableUpdatedHandlers[key] {
                handlers.forEach { handler in handler.callback(key, variable) }
            }
        case .variableEvaluated(let key, let variable):
            if let handlers = self.variableEvaluatedHandlers[key] {
                handlers.forEach { handler in handler.callback(key, variable) }
            }
            allVariableEvaluatedHandlers.forEach { handler in handler.callback(key, variable) }
        case .featureUpdated(let key, let feature):
            if let handlers = self.featureUpdatedHandlers[key] {
                handlers.forEach { handler in handler.callback(key, feature) }
            }
            allFeatureUpdatedHandlers.forEach { handler in handler.callback(key, feature) }
        }
    }
    
//    private func emitValuesByKey<T: BaseHandler<Any>, V>(_ key: String, variable: V, handlersByKey: [String : [T]]) {
//        if let handlers = handlersByKey[key] {
//            handlers.forEach { handler in handler.callback(key, variable) }
//        }
//    }
}
