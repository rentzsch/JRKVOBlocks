#import <Foundation/Foundation.h>
#import "JRKVOBlocks.h"

@interface Victim : NSObject {
#ifndef NOIVARS
  @protected
    NSString  *_value;
    BOOL      _threadFired;
#endif
}
@property(retain)  NSString  *value;
@property(assign)  BOOL      threadFired;
@end

//-----------------------------------------------------------------------------------------

@interface Watcher : NSObject
- (void)testKVOWithVictim:(Victim*)victim_;
- (void)testVictimUpdatesValueOnBackgroundThreadWithSyncCallback:(Victim*)victim;
- (void)testVictimUpdatesValueOnBackgroundThreadWithCallbackOnMainThread:(Victim*)victim;
@end

//-----------------------------------------------------------------------------------------

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    {{
        printf("Testing Watcher outliving Victim\n");
        
        Victim *victim = [[Victim alloc] init];
        Watcher *watcher = [[Watcher alloc] init];
        
        [watcher testKVOWithVictim:victim];
        
        [watcher release];
        [victim release];
    }}
    {{
        printf("Testing Victim outliving Watcher\n");
        
        Victim *victim = [[Victim alloc] init];
        Watcher *watcher = [[Watcher alloc] init];
        
        [watcher testKVOWithVictim:victim];
        
        [watcher release];
        
        victim.value = @"siete"; // Make sure nothing fires.
        [victim release];
    }}
    {{
        printf("Testing Victim Updating Value on Background Thread With Sync Callback\n");
        
        Victim *victim = [[Victim alloc] init];
        Watcher *watcher = [[Watcher alloc] init];
        
        [watcher testVictimUpdatesValueOnBackgroundThreadWithSyncCallback:victim];
        
        [watcher release];
        [victim release];
    }}
    {{
        printf("Testing Victim Updating Value on Background Thread With Async Callback on Main Thread\n");
        
        Victim *victim = [[Victim alloc] init];
        Watcher *watcher = [[Watcher alloc] init];
        
        [watcher testVictimUpdatesValueOnBackgroundThreadWithCallbackOnMainThread:victim];
        
        [watcher release];
        [victim release];
    }}
    
    [NSThread sleepForTimeInterval:0.25];
    [pool drain];
    [NSThread sleepForTimeInterval:0.25];
    return 0;
}

//-----------------------------------------------------------------------------------------

@implementation Victim
@synthesize value = _value;
@synthesize threadFired = _threadFired;

- (void)fireThread:(id)ignored {
    self.threadFired = YES;
}

- (void)dealloc {
    [_value release];
    [super dealloc];
}

@end

//-----------------------------------------------------------------------------------------

@implementation Watcher

- (void)testKVOWithVictim:(Victim*)victim {
    __block BOOL triggered = NO;
    victim.value = @"uno";
    
    [self jr_observe:victim keyPath:@"value" block:^(JRKVOChange *change){
        triggered = YES;
    }];
    
    victim.value = @"dos";
	NSAssert(triggered, @"failed to trigger");
    
    [self jr_stopObserving:victim keyPath:@"value"];
    triggered = NO;
    
    victim.value = @"tres";
    NSAssert(!triggered, @"triggered after deregistering");
}

- (void)testVictimUpdatesValueOnBackgroundThreadWithSyncCallback:(Victim*)victim {
    NSConditionLock *lock = [[[NSConditionLock alloc] initWithCondition:0] autorelease];
    [self jr_observe:victim keyPath:@"threadFired" block:^(JRKVOChange *change){
        assert(![NSThread isMainThread]);
        [lock lock];
        [lock unlockWithCondition:1];
    }];
    
    [victim performSelectorInBackground:@selector(fireThread:) withObject:nil];
    [lock lockWhenCondition:1];
    [lock unlock];
}

- (void)testVictimUpdatesValueOnBackgroundThreadWithCallbackOnMainThread:(Victim*)victim {
    __block BOOL callbackFired = NO;
    [self jr_observe:victim
             keyPath:@"threadFired"
             options:JRCallBlockOnObserverThread
               block:^(JRKVOChange *change)
     {
         assert([NSThread isMainThread]);
         callbackFired = YES;
     }];
    
    [victim performSelectorInBackground:@selector(fireThread:) withObject:nil];
    
    while (!callbackFired) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
}

/* Don't need this anymore -- JRKVOBlocks will auto-deregister for you
 - (void)dealloc {
     [self jr_stopObserving];
     [super dealloc];
 }
 */

@end