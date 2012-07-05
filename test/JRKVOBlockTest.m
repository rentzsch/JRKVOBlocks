#import <Foundation/Foundation.h>
#import "JRKVOBlocks.h"

@interface Victim : NSObject {
#ifndef NOIVARS
  @protected
    NSString *key;
#endif
}
@property(retain) NSString *key;
@end

//-----------------------------------------------------------------------------------------

@interface Watcher : NSObject {
    BOOL triggered;
}
@property(assign) BOOL triggered;
- (void)testWatcherOutlivesVictim;
- (void)testVictimOutlivesWatcher:(Victim*)victim_;
@end

//-----------------------------------------------------------------------------------------

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [[[Watcher alloc] init] testWatcherOutlivesVictim];
    
    Victim *victim = [[[Victim alloc] init] autorelease];
    Watcher *watcher = [[Watcher alloc] init];
    [watcher testVictimOutlivesWatcher:victim];
    [watcher release];
    victim.key = @"siete";
    
    [pool drain];
    return 0;
}

//-----------------------------------------------------------------------------------------

@implementation Victim
@synthesize key;

- (void)dealloc {
    [key release];
    [super dealloc];
}
@end

//-----------------------------------------------------------------------------------------

@implementation Watcher
@synthesize triggered;

- (void)testWatcherOutlivesVictim {
    Victim *victim = [[[Victim alloc] init] autorelease];
    victim.key = @"uno";
    
    __block typeof(self) blockSelf = self;
    [self jr_observe:victim keyPath:@"key" block:^(JRKVOChange *change){
        Watcher *self = blockSelf;
        self.triggered = YES;
    }];
    victim.key = @"dos";
	NSAssert(self.triggered, @"failed to trigger");
    
    [self jr_stopObserving:victim keyPath:@"key"];
    self.triggered = NO;
    victim.key = @"tres";
    NSAssert(!self.triggered, @"triggered after deregistering");
}

- (void)testVictimOutlivesWatcher:(Victim*)victim_ {
    self.triggered = NO;
    victim_.key = @"cuatro";
    NSAssert(!self.triggered, @"triggered without registering");
    
    __block typeof(self) blockSelf = self;
    [self jr_observe:victim_ keyPath:@"key" block:^(JRKVOChange *change){
        Watcher *self = blockSelf;
        self.triggered = YES;
    }];
    self.triggered = NO;
    victim_.key = @"cinco";
    NSAssert(self.triggered, @"failed to trigger");
    
    [self jr_stopObserving:victim_ keyPath:@"key"];
    self.triggered = NO;
    victim_.key = @"seis";
    NSAssert(!self.triggered, @"triggered after deregistering");
}

/* Don't need this anymore -- JRKVOBlocks will auto-deregister for you
 - (void)dealloc {
     [self jr_stopObserving];
     [super dealloc];
 }
 */

@end