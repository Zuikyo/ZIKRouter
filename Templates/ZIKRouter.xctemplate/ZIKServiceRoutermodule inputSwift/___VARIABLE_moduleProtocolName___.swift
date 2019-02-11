//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#error("replace /*arguments*/ with type of module config parameters")
protocol ___VARIABLE_moduleProtocolName___: class {
    // Transfer parameters for making destination
    var constructDestination: (_ param: /*arguments*/) -> Void { get }
    // Declare the destination type
    var didMakeDestination: ((___VARIABLE_protocolName___) -> Void)? { get set }
}
