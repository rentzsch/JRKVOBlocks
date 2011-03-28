//	Copyright (c) 2011 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//	Some rights reserved: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>

typedef void (^JRKVOBlock)(NSDictionary *changes);

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