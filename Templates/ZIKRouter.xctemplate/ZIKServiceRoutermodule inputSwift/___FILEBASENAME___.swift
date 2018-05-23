//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

import ZRouter
import ZIKRouter.Internal

class ___VARIABLE_configClass___: ZIKPerformRouteConfiguration, ___VARIABLE_protocolName___ {
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ___VARIABLE_configClass___
        // Set values to copy
        return copy
    }
}

class ___VARIABLE_productName___: ZIKServiceRouter<___VARIABLE_destinationClass___, ___VARIABLE_configClass___> {
    
    override class func registerRoutableDestination() {
        registerExclusiveService(___VARIABLE_destinationClass___.self)
        register(RoutableServiceModule<___VARIABLE_protocolName___>())
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
    
}

extension ___VARIABLE_destinationClass___: ZIKRoutableService {
    
}

extension RoutableServiceModule where Protocol == ___VARIABLE_protocolName___ {
    init() { self.init(declaredTypeName: "___VARIABLE_protocolName___") }
}
