//
//  Switchable.swift
//  ZRouter
//
//  Created by zuik on 2017/11/10.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

public struct SwitchableService {
    public let routableProtocol: Any.Type
    public let typeName: String
    public init<Protocol>(_ routableEntry: RoutableService<Protocol>) {
        routableProtocol = Protocol.self
        typeName = routableEntry.typeName
    }
}

public struct SwitchableServiceModule {
    public let routableProtocol: Any.Type
    public let typeName: String
    public init<Protocol>(_ routableEntry: RoutableServiceModule<Protocol>) {
        routableProtocol = Protocol.self
        typeName = routableEntry.typeName
    }
}
