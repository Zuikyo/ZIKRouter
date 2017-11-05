//
//  ViewExtension.swift
//  ZRouter
//
//  Created by zuik on 2017/10/23.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import ZIKRouter

extension UIViewController: NamespaceWrappable { }
public extension TypeWrapperProtocol where WrappedType: UIViewController {
    public var routed: Bool {
        return wrappedValue.zix_routed
    }
}

extension UIView: NamespaceWrappable { }
public extension TypeWrapperProtocol where WrappedType: UIView {
    public var routed: Bool {
        return wrappedValue.zix_routed
    }
}
