//	Copyright (c) 2011 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//	Some rights reserved: http://opensource.org/licenses/mit-license.php

#import "JRKVOBlocks.h"
#include <objc/runtime.h>
#include <pthread.h>

@interface JRKVOObserverController : NSObject {
#ifndef NOIVARS
  @protected
    NSMutableArray *observers;
#endif
}
@property(retain) NSMutableArray *observers;
@end

//-----------------------------------------------------------------------------------------

@interface JRKVOObserver : NSObject {
#ifndef NOIVARS
  @protected
    id observedObject;
    NSString *keyPath;
    JRKVOBlock block;
    NSString *callStackSymbols;
    BOOL keyPathWasNil;
#endif
}
@property(assign) id observedObject;
@property(retain) NSString *keyPath;
@property(copy)   JRKVOBlock block;
@property(retain) NSString *callStackSymbols;
@property(assign) BOOL keyPathWasNil;

- (void)invalidate;
@end

//-----------------------------------------------------------------------------------------

@implementation NSObject (JRKVOExtensions)

- (void)jr_observe:(id)object_
           keyPath:(NSString*)keyPath_
             block:(JRKVOBlock)block_
{
    [self jr_observe:object_ keyPath:keyPath_ options:0 block:block_];
}

static char controllerKey;

- (void)jr_observe:(id)object_
           keyPath:(NSString*)keyPath_
           options:(NSKeyValueObservingOptions)options_
             block:(JRKVOBlock)block_
{
    NSParameterAssert(object_);
    NSParameterAssert(keyPath_ && [keyPath_ length]);
    NSParameterAssert(block_);
    
    @synchronized(self) {
        JRKVOObserverController *controller = objc_getAssociatedObject(self, &controllerKey);
        if (!controller) {
            controller = [[JRKVOObserverController alloc] init]; // autorelease scope is too broad
            objc_setAssociatedObject(self, &controllerKey, controller, OBJC_ASSOCIATION_RETAIN);
            [controller release];
        }
        
        JRKVOObserver *observer = [[[JRKVOObserver alloc] init] autorelease];
        observer.observedObject = object_;
        observer.keyPath = keyPath_;
        observer.block = block_;
        //observer.callStackSymbols = [[NSThread callStackSymbols] description];
        [controller.observers addObject:observer];
        
        [object_ addObserver:observer
                  forKeyPath:keyPath_
                     options:options_
                     context:NULL];
    }
}

- (void)jr_stopObserving {
    [self jr_stopObserving:nil keyPath:nil];
}

- (void)jr_stopObserving:(id)object_ {
    [self jr_stopObserving:object_ keyPath:nil];
}

- (void)jr_stopObserving:(id)object_ keyPath:(NSString*)keyPath_ {
    @synchronized(self) {
        JRKVOObserverController *controller = objc_getAssociatedObject(self, &controllerKey);
        NSMutableArray *observersToRemove = [NSMutableArray array];
        if (object_) {
            if (keyPath_) {
                for (JRKVOObserver *observer in controller.observers) {
                    if (observer.observedObject == object_ && [observer.keyPath isEqualToString:keyPath_]) {
                        [observersToRemove addObject:observer];
                    }
                }
            } else {
                for (JRKVOObserver *observer in controller.observers) {
                    if (observer.observedObject == object_) {
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
@synthesize observers;

- (id)init {
    self = [super init];
    if (self) {
        observers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [observers makeObjectsPerformSelector:@selector(invalidate)];
    [observers release];
    [super dealloc];
}

@end

//-----------------------------------------------------------------------------------------

@implementation JRKVOObserver
@synthesize observedObject;
@synthesize keyPath;
@synthesize block;
@synthesize callStackSymbols;
@synthesize keyPathWasNil;

- (void)invalidate {
    [observedObject removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString*)keyPath_
                      ofObject:(id)object_
                        change:(NSDictionary*)change_
                       context:(void*)context_
{
    if (keyPathWasNil && [observedObject valueForKeyPath:keyPath]) {
        [observedObject removeObserver:self
                            forKeyPath:[[keyPath componentsSeparatedByString:@"."] objectAtIndex:0]];
        [observedObject addObserver:self
                  forKeyPath:keyPath
                     options:0 // FIXME
                     context:NULL];
        keyPathWasNil = NO;
    }
    JRKVOChange *changeObj = [[[JRKVOChange alloc] init] autorelease];
    changeObj.observedObject = object_;
    changeObj.keyPath = keyPath_;
    changeObj.change = change_;
    self.block(changeObj);
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@<%p> observedObject:%@<%p> keyPath:%@ callStackSymbols:%@",
            [self className],
            self,
            [observedObject className],
            observedObject,
            keyPath,
            callStackSymbols];
}

- (void)dealloc {
    [keyPath release];
    [block release];
    [callStackSymbols release];
    [super dealloc];
}

@end

//-----------------------------------------------------------------------------------------

@implementation JRKVOChange
@synthesize observedObject;
@synthesize keyPath;
@synthesize change;

- (void)dealloc {
    [observedObject release];
    [keyPath release];
    [change release];
    [super dealloc];
}

@end
