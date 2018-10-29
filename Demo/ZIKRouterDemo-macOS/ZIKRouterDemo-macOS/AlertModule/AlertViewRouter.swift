//
//  AlertViewRouter.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/27.
//Copyright © 2018 duoyi. All rights reserved.
//

import AppKit
import ZRouter
import ZIKRouter.Internal

class AlertViewConfiguration: ViewRouteConfig, AlertViewModuleInput {
    typealias ButtonHandler = () -> Void
    var buttonTitles: [String] = []
    var cancelButtonTitle: String?
    var handlers: [String: ButtonHandler] = [:]
    
    var title: String = ""
    
    var message: String?
    
    func addButton(withTitle title: String, handler: ButtonHandler?) {
        buttonTitles.append(title)
        if let handler = handler {
            handlers[title] = handler
        }
    }
    
    func addCancelButton(withTitle title: String, handler: ButtonHandler?) {
        cancelButtonTitle = title
        buttonTitles.append(title)
        if let handler = handler {
            handlers[title] = handler
        }
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! AlertViewConfiguration
        copy.buttonTitles = buttonTitles
        copy.cancelButtonTitle = cancelButtonTitle
        copy.handlers = handlers
        copy.title = title
        copy.message = message
        return copy
    }
}

class AlertViewRouter: ZIKViewRouter<AlertViewController, AlertViewConfiguration> {
    
    override class func registerRoutableDestination() {
        registerExclusiveView(AlertViewController.self)
        register(RoutableViewModule<AlertViewModuleInput>())
    }
    
    override func destination(with configuration: AlertViewConfiguration) -> AlertViewController? {
        // AlertViewController is never use ,it's just a placeholder
        let destination: AlertViewController? = AlertViewController()
        return destination
    }
    
    override func prepareDestination(_ destination: AlertViewController, configuration: AlertViewConfiguration) {
        // Prepare destination
        
    }
    
    weak var alert: NSAlert?
    
    override func canPerformCustomRoute() -> Bool {
        return alert == nil
    }
    
    override func performCustomRoute(onDestination destination: AlertViewController, fromSource source: Any?, configuration: AlertViewConfiguration) {
        beginPerformRoute()
        
        let alert = NSAlert()
        alert.messageText = configuration.title
        alert.informativeText = configuration.message ?? ""
        
        for title in configuration.buttonTitles {
            if title != configuration.cancelButtonTitle {
                alert.addButton(withTitle: title)
            }
        }
        if let cacnelButtonTitle = configuration.cancelButtonTitle {
            alert.addButton(withTitle: cacnelButtonTitle)
        }
        self.alert = alert
        
        DispatchQueue.main.async {
            
            let result = alert.runModal()
            
            self.endPerformRouteWithSuccess()
            let _ = destination
            
            var handler: AlertViewConfiguration.ButtonHandler?
            switch result {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                let title = alert.buttons[0].title
                handler = configuration.handlers[title]
            case NSApplication.ModalResponse.alertSecondButtonReturn:
                let title = alert.buttons[1].title
                handler = configuration.handlers[title]
            case NSApplication.ModalResponse.alertThirdButtonReturn:
                let title = alert.buttons[2].title
                handler = configuration.handlers[title]
            default:
                handler = nil
            }
            if let handler = handler {
                handler()
            }
        }
        
    }
    
    @objc func handleAlertButtonAction(_ sender: NSButton) {
        let title = sender.title
        if let handler = configuration.handlers[title] {
            handler()
        }
    }
    
    override func canRemoveCustomRoute() -> Bool {
        return alert != nil && NSApplication.shared.modalWindow != nil
    }
    
    override func removeCustomRoute(onDestination destination: AlertViewController, fromSource source: Any?, removeConfiguration: ZIKViewRemoveConfiguration, configuration: AlertViewConfiguration) {
        beginRemoveRoute(fromSource: nil)
        
        NSApplication.shared.stopModal()
        alert = nil
        
        endRemoveRouteWithSuccess(onDestination: destination, fromSource: nil)
    }
    
    override class func supportedRouteTypes() -> ZIKViewRouteTypeMask {
        return [.custom]
    }
    
    override class func defaultRouteConfiguration() -> AlertViewConfiguration {
        let config = AlertViewConfiguration()
        config.routeType = .custom
        return config
    }
 
}



extension AlertViewController: ZIKRoutableView {
    
}

extension RoutableViewModule where Protocol == AlertViewModuleInput {
    init() { self.init(declaredTypeName: "AlertViewModuleInput") }
}
