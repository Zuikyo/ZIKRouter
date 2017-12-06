# 循环依赖

循环依赖是指两个对象互相依赖。

在router内部动态注入依赖时，如果注入的依赖同时依赖于被注入的对象，则必须在protocol中声明。

```swift
protocol Parent {
    //Parent依赖Child
    var child: Child { get set }
}

protocol Child {
    //Child依赖Parent
    var parent: Parent { get set }
}

class ParentObject: Parent {
    var child: Child!
}

class ChildObject: Child {
    var parent: Parent!
}
```

```
class ParentRouter: ZIKServiceRouter<ParentObject, ZIKPerformRouteConfigration> {
    ...    
    override func destination(with configuration: ZIKPerformRouteConfiguration) -> ParentObject? {
        return ParentObject()
    }
    override func prepareDestination(_ destination: ParentObject, configuration: ZIKPerformRouteConfigration) {
        guard destination.child == nil else {
            return
        }
        //只有在外部没有设置child时，才去主动寻找依赖
        let child = Router.makeDestination(to RoutableService<Child>(), preparation { child in
            //设置child的依赖，防止child内部再去寻找parent依赖，导致循环
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
        //只有在外部没有设置parent时，才去主动寻找依赖
        let parent = Router.makeDestination(to RoutableService<Parent>(), preparation { parent in
            //设置parent的依赖，防止parent内部再去寻找child依赖，导致循环
            parent.child = destination
        })
        destination.parent = parent
    }
}
```

这样就能避免循环依赖导致的无限递归问题。