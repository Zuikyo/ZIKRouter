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
        register(RoutableService<___VARIABLE_protocolName___>())
    }
    
    override func destination(with configuration: PerformRouteConfig) -> ___VARIABLE_destinationClass___? {
        // Instantiate destination with configuration. Return nil if configuration is invalid.
        let destination: ___VARIABLE_destinationClass___? = /*___VARIABLE_destinationClass___()*/
        return destination
    }
    
    override func prepareDestination(_ destination: ___VARIABLE_destinationClass___, configuration: PerformRouteConfig) {
        // Prepare destination
    }
    
}

extension ___VARIABLE_destinationClass___: ZIKRoutableService {
    
}

extension RoutableService where Protocol == ___VARIABLE_protocolName___ {
    init() { self.init(declaredTypeName: "___VARIABLE_protocolName___") }
}
