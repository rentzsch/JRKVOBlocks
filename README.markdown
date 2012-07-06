### Description

JRKVOBlocks replaces this:

	- (void)someMethod:(id)someObject {
		self.someProperty = someObject;
		
		[someObject addObserver:self
					 forKeyPath:@"someKey"
						options:0
						context:NULL];
	}

	- (void)observeValueForKeyPath:(NSString*)keyPath
						  ofObject:(id)object
							change:(NSDictionary*)change
						   context:(void*)context
	{
		// Do something.
	}

	- (void)dealloc {
		[self removeObserver:_someProperty forKeyPath:@"someKey"];
		[_someProperty release];
		[super dealloc];
	}

…with this:

	- (void)someMethod:(id)someObject {
		[self jr_observe:someObject keyPath:@"someKey" block:^(JRKVOChange *change){
			// Do something.
		}];
	}

Besides redirecting `-observeValueForKeyPath:ofObject:change:context:` into a simple block callback, it also uses Obj-C associated objects to keep track of the objects you're currently observing and automatically stops observing those when released.

And additional bonus is `JRKVOObserver`, JRKVOBlocks' internal observer class, offers an enhanced `-description` method that reports the observer's thread and call-stack of the location of registration.

This code requires 10.6 or later and uses MRC, so you'll need to [enable `-fno-objc-arc`](http://macindie.com/2011/10/making-legacy-code-sail-on-arc/) if you want to use it in an ARC project.

Let me know if it works on iOS. I think it should…

### JRCallBlockOnObserverThread

JRKVOBlocks also defines a new `NSKeyValueObservingOptions` flag: `JRCallBlockOnObserverThread`. The "problem" is that KVO observers are invoked synchronously on the thread that made the change. That's a pain if you want to observe a worker thread and update your UI based on its progress.

By using the `JRCallBlockOnObserverThread` option your block will be called asynchronously on whatever thread you're on when you register your observation (usually the main thread).