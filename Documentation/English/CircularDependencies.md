# Circular Dependency

Circular dependencies are dependencies of instances that depend on each other.

Circular dependency should be declared in protocol.

```swift
protocol Parent {
    //Parent depends on Child
    var child: Child { get set }
}

protocol Child {
    //Child depends on Parent
    var parent: Parent { get set }
}

class ParentObject: Parent {
    var child: Child!
}

class ChildObject: Child {
    var parent: Parent!
}
```

```swift
class ParentRouter: ZIKServiceRouter<ParentObject, ZIKPerformRouteConfigration> {
    ...    
    override func destination(with configuration: ZIKPerformRouteConfiguration) -> ParentObject? {
        return ParentObject()
    }
    override func prepareDestination(_ destination: ParentObject, configuration: ZIKPerformRouteConfigration) {
        guard destination.child == nil else {
            return
        }
        //Only get dependency when the child object was not set
        let child = Router.makeDestination(to RoutableService<Child>(), preparation { child in
            //Set child's dependency to avoid child to search parent again
            child.parent = destination
        })
        destination.child = child
    }
}

class ChildRouter: ZIKServiceRouter<ChildObject, ZIKPerformRouteConfigration> {
    ...    
    override func destination(with configuration: ZIKPerformRouteConfiguration) -> ChildObject? {
        return ChildObject()
    }
    override func prepareDestination(_ destination: ChildObject, configuration: ZIKPerformRouteConfigration) {
        guard destination.parent == nil else {
            return
        }
        //Only get dependency when the parent object was not set
        let parent = Router.makeDestination(to RoutableService<Parent>(), preparation { parent in
            //Set parent's dependency to avoid parent to search child again
            parent.child = destination
        })
        destination.parent = parent
    }
}
```

Then we can resovle circular dependencies.

---
#### Next section: [Module Adapter](ModuleAdapter.md)