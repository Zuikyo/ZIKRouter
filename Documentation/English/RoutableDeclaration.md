# Routable

When registering destination and protocol, you need to declare the destination and protocol as routable. You only need to add some extensions. Routable declaration is for making dynamic routing much safer.

## Routable destination

Add `ZIKRoutableView` extension for destination in view router:

```swift
extension EditorViewController: ZIKRoutableView {

}
```

<details><summary>Objecive-C Sample</summary>

```objectivec
@interface EditorViewController(EditorViewRouter)<ZIKRoutableView>
@end
@implementation EditorViewController(EditorViewRouter)
@end
```

</details>

The routable declaration here is for supporting storyboard. When a segue is performed and the UIViewController is routable, ZIKRouter will search it's view router and prepare it.

## Routable protocol

When you try to get a router with a protocol, the protocol must be routable.

There're several levels to make dynamic routing. In Swift and Objective-C, routable declarations are different.

### Routable in Swift

In Swift, protocol was designated as struct's generic parameter:

```swift
public struct RoutableView<Protocol> {
    //The external can't access to the initializer
    internal init() { }
}
```

Declare that `SwiftEditorViewInput` is routable, and can only be used for view routing:

```swift
extension RoutableView where Protocol == SwiftEditorViewInput {
    //Can access to initializer when generic is SwiftEditorViewInput
    init() { }
}
```

`RoutableView`'s initializer is not public, only explicitly declared protocol can be used to create `RoutableView`, like `RoutableView<SwiftEditorViewInput>()`:

```swift
class TestViewController: UIViewController {
    func showEditor() {
        Router.perform(
            to: RoutableView<SwiftEditorViewInput>(),
            from: self,
            configuring: { $0.routeType = .push }
            )
    }
}
```

If you pass a wrong protocol, such as `RoutableView<UnroutableProtocol>()`, there will be a compile error.

### Routable in Objective-C

Swift is type safe, but it's hard to make type safe in Objective-C for dynamic routing.

#### `ZIKViewRoutable` and `ZIKServiceRoutable`

When a protocol is for view routing, the protocol should inherit from `ZIKViewRoutable`.

```
@protocol EditorViewInput <ZIKViewRoutable>
@property (nonatomic, copy) NSString *editorTitle;
@end
```

When a protocol is for service routing, the protocol should inherit from `ZIKServiceRoutable`.

#### `ZIKViewModuleRoutable` and `ZIKServiceModuleRoutable`

When a protocol is a view module config protocol, the protocol should inherit from `ZIKViewModuleRoutable`.

```
@protocol EditorModuleInput <ZIKViewModuleRoutable>
@property (nonatomic, copy) NSString *editorTitle;
@end
```

When a protocol is a service module config protocol, the protocol should inherit from `ZIKServiceModuleRoutable`.

#### Runtime Checking

When app is launched and in DEBUG mode, ZIKRouter will enumerate all protocols inheriting form `ZIKViewRoutable`,`ZIKServiceRoutable `,`ZIKViewModuleRoutable` and `ZIKServiceModuleRoutable`, to check whether all protocols were registered with a router, and the router's destination or defaultConfiguration conforms to the protocol.

Even for pure swift type, ZIKRouter can check it's conformance with another pure swift protocol type.

Protocols inheriting from `ZIKViewRoutable`,`ZIKServiceRoutable `,`ZIKViewModuleRoutable` and `ZIKServiceModuleRoutable` is also routable in Swift. You don't need to declare them in Swift again.

More details about type checking: [Type Checking](TypeChecking.md).