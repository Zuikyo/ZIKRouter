//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

import ZRouter
import ZIKRouter.Internal

class ___VARIABLE_productName___: ZIKViewRouter<___VARIABLE_destinationClass___, ViewRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerExclusiveView(___VARIABLE_destinationClass___.self)
    }
    
    override func destination(with configuration: ViewRouteConfig) -> ___VARIABLE_destinationClass___? {
        // Instantiate destination with configuration. Return nil if configuration is invalid.
        let destination: ___VARIABLE_destinationClass___? = /*___VARIABLE_destinationClass___()*/
        return destination
    }
    
    override func prepareDestination(_ destination: ___VARIABLE_destinationClass___, configuration: ViewRouteConfig) {
        // Prepare destination
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
