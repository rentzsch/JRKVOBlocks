//	Copyright (c) 2011 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//	Some rights reserved: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>

@interface JRKVOChange : NSObject {
#ifndef NOIVARS
  @protected
    id observedObject;
    NSString *keyPath;
    NSDictionary *change;
#endif
}
@property(retain) id observedObject;
@property(retain) NSString *keyPath;
@property(retain) NSDictionary *change;
@end

typedef void (^JRKVOBlock)(JRKVOChange *change);

@interface NSObject (JRKVOExtensions)

- (void)jr_observe:(id)object_
           keyPath:(NSString*)keyPath_
             block:(JRKVOBlock)block_;

- (void)jr_observe:(id)object_
           keyPath:(NSString*)keyPath_
           options:(NSKeyValueObservingOptions)options_
             block:(JRKVOBlock)block_;

- (void)jr_stopObserving;

- (void)jr_stopObserving:(id)object_;

- (void)jr_stopObserving:(id)object_
                 keyPath:(NSString*)keyPath_;

@end