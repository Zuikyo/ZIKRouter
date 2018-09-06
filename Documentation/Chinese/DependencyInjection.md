# 依赖注入和依赖查找

依赖注入和依赖查找是实现控制反转的方式。

控制反转是将对象依赖的获取从主动变为被动，从对象内部直接引用并获取依赖，变为由外部向对象提供对象所要求的依赖，从而让对象和其依赖解耦。

## 依赖注入

依赖注入是指外部向对象传入依赖。

一个类 A 在接口中体现出内部需要用到的一些依赖(例如内部需要用到类B的实例)，从而让使用者从外部注入这些依赖，而不是在类内部直接引用依赖并创建类 B。依赖可以用 protocol 的方式声明，这样就可以使类 A 和所使用的依赖类 B 进行解耦。

### 初始化注入

初始化注入是指类在初始化方法里添加的一些必需依赖。这些依赖是创建对象的时候必须要用到的。

```swift
protocol Name {
    var firstName: String { get }
    var lastName: String { get }
}

class Person {
    let name: Name
    init(name: Name) {
        self.name = name
    }
}
```

<details><summary>Objective-C示例</summary>

```objectivec
@protocol Name
- (NSString *)firstName;
- (NSString *)lastName;
@end

@interface Person: NSObject
@property (nonatomic, strong) id<Name> name;
- (instancetype)initWithName:(id<Name>)name;
@end
```
</details>

在 router 里，可以用 module config protocol 实现初始化依赖：

```swift
protocol PersonConfig {
    func constructWithName(_ name: Name) -> Void
}
class PersonConfiguration: ZIKPerformRouteConfiguration, PersonConfig {
    var name: Name?
    func constructWithName(name: Name) {
        self.name = name
    }
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! PersonConfiguration
        copy.name = self.name
        return copy
    }
}
class PersonRouter: ZIKServiceRouter<Person, PersonConfiguration> {
    ...    
    override func destination(with configuration: PersonConfiguration) -> Person? {
        guard let name = configuration.name else {
            return nil
        }
        return Person(name: name)
    }
}
```

你可以约定调用者必须调用 config protocol 中以`construct`作为前缀的方法。

```swift
let name: Name = ...
let person = Router.makeDestination(to: RoutableServiceModule<PersonConfig>(), preparation: { moduleConfig in
            moduleConfig.constructWithName(name)
        })
```

<details><summary>Objective-C示例</summary>

```objectivec
@protocol PersonConfig: ZIKServiceModuleRoutable
- (void)constructWithName:(id<Name>)name;
@end

@interface PersonConfiguration: ZIKPerformConfiguration <PersonConfig>
@property (nonatomic, strong) id<Name> name;
- (void)constructWithName:(id<Name>)name;
@end
@implementation PersonConfiguration
- (void)constructWithName:(id<Name>)name {
    self.name = name;
}
- (id)copyWithZone:(nullable NSZone *)zone {
    PersonConfiguration *copy = [super copyWithZone:zone];
    copy.name = self.name;
    return copy;
}
@end

@interface PersonRouter: ZIKServiceRouter<Person *, PersonConfiguration *>
@end
@implementation PersonRouter

- (nullable Person *)destinationWithConfiguration:(PersonConfiguration *)configuration {
    id<Name> name = configuration.name;
    if (name == nil) {
        return nil;
    }
    return [[Person alloc] initWithName:name];
}

@end

```

```objectivec
id<Name> name = ...
Person *person = [ZIKRouterToServiceModule(PersonConfig) 
         makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<PersonConfig> * _Nonnull config) {
            [config constructWithName:name];
        }];
```
</details>

### 属性注入和方法注入

当依赖是可选的，并不是创建对象所必需的，可以用属性注入和方法注入。

属性注入是指外部设置对象的属性。

方法注入是指外部调用对象的方法，从而传入依赖。

```swift
protocol PersonType {
    var wife: Person? { get set }
    func addChild(_ child: Person) -> Void
}
protocol Child {
    var parent: Person { get }
}

class Person: PersonType {
    var wife: Person? = nil
    var childs: Set<Child> = []
    func addChild(_ child: Child) {
        childs.insert(child)
    }
}
```

<details><summary>Objective-C示例</summary>

```objectivec
@protocol PersonType: ZIKServiceRoutable
@property (nonatomic, strong, nullable) Person *wife;
- (void)addChild:(Person *)child;
@end
@protocol Child
@property (nonatomic, strong) Person *parent;
@end

@interface Person: NSObject <PersonType>
@property (nonatomic, strong, nullable) Person *wife;
@property (nonatomic, strong) NSSet<id<Child>> childs;
@end
```
</details>

在 router 里，可以注入一些默认的依赖：

```swift
class PersonRouter: ZIKServiceRouter<Person, ZIKPerformRouteConfiguration> {
    ...    
    override func destination(with configuration: ZIKPerformRouteConfiguration) -> Person? {
        let person = Person()
        //可以直接在router里设置默认值
        //person.wife = ...
        return person
    }
}
```

调用者也可以用`PersonType`动态地注入依赖。

```swift
let wife: Person = ...
let child: Child = ...
let person = Router.makeDestination(to: RoutableService<PersonType>(), preparation: { destination in
            destination.wife = wife
            destination.addChild(child)
        })
```

<details><summary>Objective-C示例</summary>

```objectivec
@interface PersonRouter: ZIKServiceRouter<Person *, ZIKPerformRouteConfiguration *>
@end
@implementation PersonRouter

- (nullable Person *)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    Person *person = [Person new];
    ///[person addChild:...];
    return person;
}

@end

```

```objectivec
Person *wife = ...
Child *child = ...
Person *person = [ZIKRouterToService(PersonType) 
         makeDestinationWithPreparation:^(id<PersonType> destination) {
            destination.wife = wife;
            [destination addChild:child];
        }];
```
</details>

## 依赖查找

依赖查找是指在内部通过某种方式查找依赖。当使用 Router 获取模块的时候，就是在动态地查找依赖。

---
#### 下一节：[循环依赖问题](CircularDependencies.md)