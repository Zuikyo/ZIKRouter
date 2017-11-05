//
//  RoutableDeclarations.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/11/5.
//  Copyright © 2017 zuik. All rights reserved.
//

import Foundation
import ZIKRouter
import ZIKRouterSwift

///If you wan't to use objc protocols bridged from objc code, you have to declare those protocols before use.
///Or you can make those internal functions `perform(forViewProtocol:routeConfig:preparation:)` in Router as public and use them. But it's not safe.
//extension ViewModuleRouter where Module == ZIKCompatibleAlertConfigProtocol {
//    static var route: ViewModuleRoute<ZIKCompatibleAlertConfigProtocol>.Type {
//        return ViewModuleRoute<ZIKCompatibleAlertConfigProtocol>.self
//    }
//}

extension ViewRouter where Destination == ZIKInfoViewProtocol {
    static var route: ViewRoute<ZIKInfoViewProtocol>.Type {
        return ViewRoute<ZIKInfoViewProtocol>.self
    }
}
