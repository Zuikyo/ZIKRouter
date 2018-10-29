//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

import ZRouter
import ZIKRouter.Internal

class ___VARIABLE_configClass___: ZIKViewRouteConfiguration, ___VARIABLE_protocolName___ {
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ___VARIABLE_configClass___
        // Set values to copy
        return copy
    }
}

class ___VARIABLE_productName___: ZIKViewRouter<___VARIABLE_destinationClass___, ___VARIABLE_configClass___> {
    
    override class func registerRoutableDestination() {
        registerExclusiveView(___VARIABLE_destinationClass___.self)
        register(RoutableViewModule<___VARIABLE_protocolName___>())
    }
    
    override func destination(with configuration: ___VARIABLE_configClass___) -> ___VARIABLE_destinationClass___? {
        // Instantiate destination with configuration. Return nil if configuration is invalid.
        let destination: ___VARIABLE_destinationClass___? = /*___VARIABLE_destinationClass___()*/
        return destination
    }
    
    override func prepareDestination(_ destination: ___VARIABLE_destinationClass___, configuration: ___VARIABLE_configClass___) {
        // Prepare destination
    }
    
    override class func defaultRouteConfiguration() -> ___VARIABLE_configClass___ {
        return ___VARIABLE_configClass___()
    }
    
    /*
    // If the destiantion is UIView / NSView, override and return route types for UIView / NSView
    override class func supportedRouteTypes() -> ZIKViewRouteTypeMask {
        return .viewDefault
    }
    */
}

extension ___VARIABLE_destinationClass___: ZIKRoutableView {
    
}

extension RoutableViewModule where Protocol == ___VARIABLE_protocolName___ {
    init() { self.init(declaredTypeName: "___VARIABLE_protocolName___") }
}
