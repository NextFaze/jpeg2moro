//
//  JPEG2moroCache.m
//  jpeg2moro
//
//  Created by Andrew on 22/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import "JPEG2moroCache.h"

@implementation JPEG2moroCache

@synthesize cacheSize;

- (id)init {
	if(self = [super init]) {
		cacheDict = [[NSMutableDictionary alloc] init];
		cacheList = [[NSMutableArray alloc] init];
		cacheSize = JPEG2moroCacheSize;
		
		// empty cache on memory warnings
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(memoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[cacheDict release];
	[cacheList release];
	
	[super dealloc];
}

#pragma mark -

- (void)setImage:(JPEG2moro *)jpeg forKey:(NSString *)name {
	if(jpeg == nil || name == nil) return;
	
	@synchronized(self) {
		[cacheDict setValue:jpeg forKey:name];
		[cacheList removeObject:name];
		[cacheList addObject:name];
		
		// remove images from the cache until we are under the cacheSize.
		// removes least recently used images first
		while([cacheList count] > cacheSize) {
			NSString *oldname = [cacheList objectAtIndex:0];
			[cacheList removeObjectAtIndex:0];
			[cacheDict removeObjectForKey:oldname];
		}
	}
}

- (JPEG2moro *)imageForKey:(NSString *)name {
	JPEG2moro *jpeg = nil;
	
	if(name == nil) return nil;
	
	@synchronized(self) {
		jpeg = [cacheDict valueForKey:name];

		if(jpeg) {
			// update list so that recently accessed images are at the end
			[cacheList removeObject:name];
			[cacheList addObject:name];
		}
	}
	return jpeg;
}

// clear the cache
- (void)removeAllObjects {
	@synchronized(self) {
		[cacheDict removeAllObjects];
		[cacheList removeAllObjects];
	}
}

- (int)count {
	return [cacheList count];
}

- (void)memoryWarning {
	LOG(@"memory warning received, emptying cache");
	[self removeAllObjects];
}

@end
