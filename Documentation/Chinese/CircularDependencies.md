# 循环依赖

循环依赖是指两个对象互相依赖。

在 router 内部动态注入依赖时，如果注入的依赖同时依赖于被注入的对象，则必须在 protocol 中声明。

```swift
protocol Parent {
    //Parent 依赖 Child
    var child: Child { get set }
}

protocol Child {
    //Child 依赖 Parent
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
        //只有在外部没有设置 child 时，才去主动寻找依赖
        let child = Router.makeDestination(to RoutableService<Child>(), preparation { child in
            //设置 child 的依赖，防止 child 内部再去寻找 parent 依赖，导致循环
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
        //只有在外部没有设置 parent 时，才去主动寻找依赖
        let parent = Router.makeDestination(to RoutableService<Parent>(), preparation { parent in
            //设置 parent 的依赖，防止 parent 内部再去寻找 child 依赖，导致循环
            parent.child = destination
        })
        destination.parent = parent
    }
}
```

这样就能避免循环依赖导致的无限递归问题。

---
#### 下一节：[模块化和解耦](ModuleAdapter.md)