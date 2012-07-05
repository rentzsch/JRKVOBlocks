//	Copyright (c) 2011 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//	Some rights reserved: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>

@interface JRKVOChange : NSObject {
#ifndef NOIVARS
  @protected
    id            _observedObject;
    NSString      *_keyPath;
    NSDictionary  *_change;
#endif
}
@property(retain)  id            observedObject;
@property(retain)  NSString      *keyPath;
@property(retain)  NSDictionary  *change;
@end

typedef void (^JRKVOBlock)(JRKVOChange *change);

@interface NSObject (JRKVOExtensions)

- (void)jr_observe:(id)object
           keyPath:(NSString*)keyPath
             block:(JRKVOBlock)block;

- (void)jr_observe:(id)object
           keyPath:(NSString*)keyPath
           options:(NSKeyValueObservingOptions)options
             block:(JRKVOBlock)block;

- (void)jr_stopObserving;

- (void)jr_stopObserving:(id)object;

- (void)jr_stopObserving:(id)object
                 keyPath:(NSString*)keyPath;

@end