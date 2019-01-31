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

public struct SwitchableView {
    public let routableProtocol: Any.Type
    public let typeName: String
    public init<Protocol>(_ routableEntry: RoutableView<Protocol>) {
        routableProtocol = Protocol.self
        typeName = routableEntry.typeName
    }
}

public struct SwitchableViewModule {
    public let routableProtocol: Any.Type
    public let typeName: String
    public init<Protocol>(_ routableEntry: RoutableViewModule<Protocol>) {
        routableProtocol = Protocol.self
        typeName = routableEntry.typeName
    }
}
