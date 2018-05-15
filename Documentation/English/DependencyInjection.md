# Dependency Injection and Dependency Lookup

Dependency Injection and Dependency Lookup are two basic ways to provide [Inversion of Control](https://en.wikipedia.org/wiki/Inversion_of_control).

Inversion of Control is a principle which recommends moving unwanted responsibilities out of a class and letting the class focus on core responsibilities, hence providing loose coupling.

## Dependency Injection

[Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection) is where the dependency is injected from outside the class, and class is not worried about details.

### Initializer Injection

Initializer injection is a pattern for passing dependencies to a dependent instance by its initializers. Initializer injection is appropriate if the dependent instance cannot work without the dependencies.

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

<details><summary>Objective-C Sample</summary>

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

In ZIKRouter, use module config protocol to make Initializer Injection:

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

The performer must call `construct` method in config protocol:

```swift
let name: Name = ...
let person = Router.makeDestination(to: RoutableServiceModule<PersonConfig>(), preparation: { moduleConfig in
            moduleConfig.constructWithName(name)
        })
```

<details><summary>Objective-C Sample</summary>

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

### Property Injection and Method Injection

Property injection is a pattern to pass a dependency to a dependent instance via a setter property. 

Method injection is a similar pattern to property injection, but it uses a method to pass dependencies to a dependent instance.

Property injection and method injection are appropriate if the dependency is optional to the dependent instance.

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

<details><summary>Objective-C Sample</summary>

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

You can inject default dependencies in router:

```swift
class PersonRouter: ZIKServiceRouter<Person, ZIKPerformRouteConfiguration> {
    ...    
    override func destination(with configuration: ZIKPerformRouteConfiguration) -> Person? {
        let person = Person()
        //Set default value
        //person.wife = ...
        return person
    }
}
```

The performer can inject dependencies at runtime:

```swift
let wife: Person = ...
let child: Child = ...
let person = Router.makeDestination(to: RoutableService<PersonType>(), preparation: { destination in
            destination.wife = wife
            destination.addChild(child)
        })
```

<details><summary>Objective-C Sample</summary>

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

## Dependency Lookup

Dependency lookup is where class itself looks up for dependency.

Getting router with protocol is Dependency Lookup.

---
#### Next section: [Circular Dependency](CircularDependencies.md)