//
//  AppSwiftRouteRegistry.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter
import ZIKRouter

/// Manually register swift routers
@objc class AppSwiftRouteRegistry: NSObject {
    @objc class func manuallyRegisterEachRouter() {
        SwiftSampleViewRouter.registerRoutableDestination()
        SwiftServiceRouter.registerRoutableDestination()
        ZIKInfoViewAdapter.registerRoutableDestination()
        AppBlockRouteRegistry.registerRoutableDestination()
        EasyRouteRegistry.registerRoutableDestination()
    }
}

import ZIKRouter.Internal

class AppBlockRouteRegistry: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        do {
            let route = ZIKServiceRoute<SwiftService, PerformRouteConfig>
                .make(withDestination: SwiftService.self,
                      makeDestination: { (config, router) -> SwiftService? in
                        if let config = config as? ServiceMakeableConfiguration<SwiftServiceInput, (String) -> Void>,
                            let makeDestination = config.makeDestination {
                            return makeDestination() as? SwiftService ?? nil
                        }
                        return SwiftService()
                }).makeDefaultConfiguration({
                    let config = ServiceMakeableConfiguration<SwiftServiceInput, (String) -> Void>({ _ in })
                    config.constructDestination = { [unowned config] (param) in
                        config.makeDestination = { () in
                            return SwiftService()
                        }
                    }
                    return config
                })
            if TEST_BLOCK_ROUTES == 1 {
                route.register(RoutableService<SwiftServiceInput>())
                    .register(RoutableServiceModule<SwiftServiceModuleInput>())
            }
        }
    }
}

typealias RequiredInfoViewInput = UIViewController & ZIKInfoViewProtocol
class ZIKInfoViewAdapter: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        register(adapter: RoutableView<UIViewController & ZIKInfoViewProtocol>(), forAdaptee: RoutableView<ZIKInfoViewProtocol>())
    }
}

extension RoutableView where Protocol == RequiredInfoViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}


func makeSampleViewController(config:ViewRouteConfig) -> SwiftSampleViewController? {
    let sb = UIStoryboard.init(name: "Main", bundle: nil)
    let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
    destination.title = "Swift Sample from easy register"
    return destination
}


class EasyRouteRegistry: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        ZIKAnyViewRouter.register(RoutableView<EasyViewInput>(), forMakingView: SwiftSampleViewController.self, making: makeSampleViewController)
        ZIKDestinationViewRouter<SwiftSampleViewController>.register(RoutableView<EasyViewInput2>(), forMakingView: SwiftSampleViewController.self) { (config) -> EasyViewInput2? in
            let sb = UIStoryboard.init(name: "Main", bundle: nil)
            let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
            destination.title = "Swift Sample from easy register"
            return destination
        }
        
        ZIKAnyViewRouter.register(RoutableViewModule<EasyViewModuleInput>(), forMakingView: SwiftSampleViewController.self) { () -> EasyViewModuleInput in
            let config = AnyViewMakeableConfiguration<EasyViewInput, (String, Int)->EasyViewInput?, (String, Int)->Void>(maker: { _,_ in return nil }, constructor: {_,_ in })
            config.makeDestinationWith = { [unowned config] (title, num) in
                config.makeDestination = { () -> EasyViewInput? in
                    let sb = UIStoryboard.init(name: "Main", bundle: nil)
                    let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
                    destination.title = "Swift Sample from easy register"
                    return destination
                }
                if let destination = config.makeDestination?() {
                    config.__prepareDestination?(destination)
                    config.makedDestination = destination
                    return destination
                }
                return nil
            }
            config.constructDestination = { [unowned config] (title, num) in
                config.makeDestination = {
                    let sb = UIStoryboard.init(name: "Main", bundle: nil)
                    let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
                    destination.title = "Swift Sample from easy register"
                    return destination
                }
            }
            return config
        }
        
        ZIKAnyServiceRouter.register(RoutableService<EasyServiceInput>(), forMakingService: EasyService.self)
        ZIKDestinationServiceRouter<EasyService2>.register(RoutableService<EasyServiceInput2>(), forMakingService: EasyService2.self) { (config) -> EasyService2? in
            return EasyService2(name: "default")
        }
        
        ZIKAnyServiceRouter.register(RoutableServiceModule<EasyServiceModuleInput>(), forMakingService: EasyService2.self) { () -> EasyServiceModuleInput in
            let config = ServiceMakeableConfiguration<EasyServiceInput, (String) -> Void>({_ in})
            config.constructDestination = { [unowned config] name in
                config.makeDestination = {
                    let destination = EasyService2(name: name)
                    return destination
                }
            }
            return config
        }
    }
    
}

protocol EasyViewInput { }
extension RoutableView where Protocol == EasyViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol EasyViewInput2 { }
extension RoutableView where Protocol == EasyViewInput2 {
    init() { self.init(declaredProtocol: Protocol.self) }
}
extension SwiftSampleViewController: EasyViewInput, EasyViewInput2 { }

protocol EasyViewModuleInput {
    var makeDestinationWith: (String, Int) -> EasyViewInput? { get }
    
    var constructDestination: (String, Int) -> Void { get }
    var didMakeDestination:((EasyViewInput) -> Void)? { get set }
    
}
extension RoutableViewModule where Protocol == EasyViewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
extension AnyViewMakeableConfiguration: EasyViewModuleInput where Destination == EasyViewInput, Maker == (String, Int) -> EasyViewInput?, Constructor == (String, Int) -> Void {
    
}


protocol EasyServiceInput { }
extension RoutableService where Protocol == EasyServiceInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol EasyServiceInput2 { }
extension RoutableService where Protocol == EasyServiceInput2 {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol EasyServiceModuleInput {
    var constructDestination: (String) -> Void { get }
    var didMakeDestination:((EasyServiceInput) -> Void)? { get set }
    
}
extension RoutableServiceModule where Protocol == EasyServiceModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
extension ServiceMakeableConfiguration: EasyServiceModuleInput where Destination == EasyServiceInput, Constructor == (String) -> Void {
    
}

class EasyService: NSObject, ZIKRoutableService, EasyServiceInput {
    
}

class EasyService2: NSObject, ZIKRoutableService, EasyServiceInput, EasyServiceInput2 {
    let name: String
    init(name: String) {
        self.name = name
    }
}
