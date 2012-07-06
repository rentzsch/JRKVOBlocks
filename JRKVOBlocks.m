// JRKVOBlocks.m semver:1.1.0
//   Copyright (c) 2011-2012 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/MIT
//   https://github.com/rentzsch/JRKVOBlocks

#import "JRKVOBlocks.h"
#include <objc/runtime.h>

@interface JRKVOObserverController : NSObject {
#ifndef NOIVARS
  @protected
    NSMutableArray  *_observers;
#endif
}
@property(retain)  NSMutableArray  *observers;
@end

//-----------------------------------------------------------------------------------------

@interface JRKVOObserver : NSObject {
#ifndef NOIVARS
  @protected
    id          _observedObject;
    NSString    *_keyPath;
    JRKVOBlock  _block;
    NSArray     *_observerCallstack;
    NSThread    *_observerThread;
#endif
}
@property(assign)  id          observedObject;
@property(retain)  NSString    *keyPath;
@property(copy)    JRKVOBlock  block;
@property(retain)  NSArray     *observerCallstack;
@property(retain)  NSThread    *observerThread;

- (void)invalidate;
@end

//-----------------------------------------------------------------------------------------

@implementation NSObject (JRKVOExtensions)

- (void)jr_observe:(id)object
           keyPath:(NSString*)keyPath
             block:(JRKVOBlock)block
{
    [self jr_observe:object keyPath:keyPath options:0 block:block];
}

static char controllerKey;

- (void)jr_observe:(id)object
           keyPath:(NSString*)keyPath
           options:(NSKeyValueObservingOptions)options
             block:(JRKVOBlock)block
{
    NSParameterAssert(object);
    NSParameterAssert(self != object); // Common mistake -- use self.
    NSParameterAssert(keyPath && [keyPath length]);
    NSParameterAssert(block);
    
    @synchronized(self) {
        JRKVOObserverController *controller = objc_getAssociatedObject(self, &controllerKey);
        if (!controller) {
            controller = [[JRKVOObserverController alloc] init]; // autorelease scope is too broad
            objc_setAssociatedObject(self, &controllerKey, controller, OBJC_ASSOCIATION_RETAIN);
            [controller release];
        }
        
        JRKVOObserver *observer = [[[JRKVOObserver alloc] init] autorelease];
        observer.observedObject = object;
        observer.keyPath = keyPath;
        observer.block = block;
#ifdef JRKVOBlocks_DontRecordCallstack
        observer.observerCallstack = [NSThread callStackSymbols];
#endif
        if (options & JRCallBlockOnObserverThread) {
            options &= ~JRCallBlockOnObserverThread;
            observer.observerThread = [NSThread currentThread];
        }
        [controller.observers addObject:observer];
        
        [object addObserver:observer
                  forKeyPath:keyPath
                     options:options
                     context:NULL];
    }
}

- (void)jr_stopObserving {
    [self jr_stopObserving:nil keyPath:nil];
}

- (void)jr_stopObserving:(id)object {
    [self jr_stopObserving:object keyPath:nil];
}

- (void)jr_stopObserving:(id)object keyPath:(NSString*)keyPath {
    @synchronized(self) {
        JRKVOObserverController *controller = objc_getAssociatedObject(self, &controllerKey);
        NSMutableArray *observersToRemove = [NSMutableArray array];
        if (object) {
            if (keyPath) {
                for (JRKVOObserver *observer in controller.observers) {
                    if (observer.observedObject == object && [observer.keyPath isEqualToString:keyPath]) {
                        [observersToRemove addObject:observer];
                    }
                }
            } else {
                for (JRKVOObserver *observer in controller.observers) {
                    if (observer.observedObject == object) {
                        [observersToRemove addObject:observer];
                    }
                }
            }
        } else {
            [observersToRemove addObjectsFromArray:controller.observers];
        }
        [observersToRemove makeObjectsPerformSelector:@selector(invalidate)];
        [controller.observers removeObjectsInArray:observersToRemove];
    }
}

@end

//-----------------------------------------------------------------------------------------

@implementation JRKVOObserverController
@synthesize observers = _observers;

- (id)init {
    self = [super init];
    if (self) {
        _observers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_observers makeObjectsPerformSelector:@selector(invalidate)];
    [_observers release];
    [super dealloc];
}

@end

//-----------------------------------------------------------------------------------------

@implementation JRKVOObserver
@synthesize observedObject = _observedObject;
@synthesize keyPath = _keyPath;
@synthesize block = _block;
@synthesize observerCallstack = _observerCallstack;
@synthesize observerThread = _observerThread;

- (void)invalidate {
    [self.observedObject removeObserver:self forKeyPath:self.keyPath];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    JRKVOChange *changeObj = [[[JRKVOChange alloc] init] autorelease];
    changeObj.observedObject = object;
    changeObj.keyPath = keyPath;
    changeObj.change = change;
    
    if (self.observerThread && ![[NSThread currentThread] isEqual:self.observerThread]) {
        [self performSelector:@selector(callSelfBlockWithChange:)
                     onThread:self.observerThread
                   withObject:changeObj
                waitUntilDone:NO];
    } else {
        self.block(changeObj);
    }
}

- (void)callSelfBlockWithChange:(JRKVOChange*)change {
    NSAssert([[NSThread currentThread] isEqual:self.observerThread], nil);
    self.block(change);
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@<%p> observedObject:%@<%p> keyPath:%@ thread:%@ callstack:%@",
            [self class],
            self,
            [self.observedObject class],
            self.observedObject,
            self.keyPath,
            self.observerThread,
            self.observerCallstack];
}

- (void)dealloc {
    [_keyPath release];
    [_block release];
    [_observerCallstack release];
    [_observerThread release];
    [super dealloc];
}

@end

//-----------------------------------------------------------------------------------------

@implementation JRKVOChange
@synthesize observedObject = _observedObject;
@synthesize keyPath = _keyPath;
@synthesize change = _change;

- (void)dealloc {
    [_observedObject release];
    [_keyPath release];
    [_change release];
    [super dealloc];
}

@end
