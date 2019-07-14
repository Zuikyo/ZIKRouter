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
        register(RoutableViewModule<___VARIABLE_moduleProtocolName___>())
    }
    
    override class func defaultRouteConfiguration() -> ViewRouteConfig {
        let config = ViewMakeableConfiguration<___VARIABLE_protocolName___, (/*arguments*/) -> ___VARIABLE_protocolName___?>({ _ in return nil })
        
        config.__prepareDestination = { destination in
            // Prepare destination
        }
        
        config.makeDestinationWith = { [unowned config] (arguments) in
            config.makeDestination = { () in
                // Instantiate destination. Return nil if configuration is invalid.
                let destination: ___VARIABLE_destinationClass___? = /*___VARIABLE_destinationClass___()*/
                return destination
            }
            if let destination = config.makeDestination?() {
                config.__prepareDestination?(destination)
                config.makedDestination = destination
                return destination
            }
            return nil
        }
        return config
    }
    
    override func destination(with configuration: ViewRouteConfig) -> ___VARIABLE_destinationClass___? {
        if let config = configuration as? ViewMakeableConfiguration<___VARIABLE_protocolName___, (/*arguments*/) -> ___VARIABLE_protocolName___?>,
            let makeDestination = config.makeDestination {
            return makeDestination() as? ___VARIABLE_destinationClass___ ?? nil
        }
        // Instantiate destination with configuration. Return nil if configuration is invalid.
        let destination: ___VARIABLE_destinationClass___? = /*___VARIABLE_destinationClass___()*/
        return destination
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

extension RoutableViewModule where Protocol == ___VARIABLE_moduleProtocolName___ {
    init() { self.init(declaredTypeName: "___VARIABLE_moduleProtocolName___") }
}

extension ViewMakeableConfiguration: ___VARIABLE_moduleProtocolName___ where Destination == ___VARIABLE_protocolName___, Constructor == (/*arguments*/) -> ___VARIABLE_protocolName___? {
    
}
