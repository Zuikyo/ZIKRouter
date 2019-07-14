//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

import ZRouter
import ZIKRouter.Internal

class ___VARIABLE_productName___: ZIKServiceRouter<___VARIABLE_destinationClass___, PerformRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerExclusiveService(___VARIABLE_destinationClass___.self)
        register(RoutableServiceModule<___VARIABLE_moduleProtocolName___>())
    }
    
    override class func defaultRouteConfiguration() -> PerformRouteConfig {
        let config = ServiceMakeableConfiguration<___VARIABLE_protocolName___, (/*arguments*/) -> ___VARIABLE_protocolName___?>({ _ in return nil })
        
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
    
    override func destination(with configuration: PerformRouteConfig) -> ___VARIABLE_destinationClass___? {
        if let config = configuration as? ServiceMakeableConfiguration<___VARIABLE_protocolName___, (/*arguments*/) -> ___VARIABLE_protocolName___?>,
            let makeDestination = config.makeDestination {
            return makeDestination() as? ___VARIABLE_destinationClass___ ?? nil
        }
        // Instantiate destination with configuration. Return nil if configuration is invalid.
        let destination: ___VARIABLE_destinationClass___? = /*___VARIABLE_destinationClass___()*/
        return destination
    }
    
}

extension ___VARIABLE_destinationClass___: ZIKRoutableService {
    
}

extension RoutableServiceModule where Protocol == ___VARIABLE_moduleProtocolName___ {
    init() { self.init(declaredTypeName: "___VARIABLE_moduleProtocolName___") }
}

extension ServiceMakeableConfiguration: ___VARIABLE_moduleProtocolName___ where Destination == ___VARIABLE_protocolName___, Constructor == (/*arguments*/) -> ___VARIABLE_protocolName___? {
    
}
