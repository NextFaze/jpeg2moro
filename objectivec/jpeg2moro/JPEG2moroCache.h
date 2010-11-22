//
//  JPEG2moroCache.h
//  jpeg2moro
//
//  Created by Andrew on 22/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JPEG2moro.h"

#define JPEG2moroCacheSize 100  // default cache size

@interface JPEG2moroCache : NSObject {
	NSMutableDictionary *cacheDict;     // image name -> JPEG2moro object
	NSMutableArray *cacheList;          // list of image names (most recently used last)
	int cacheSize;
}

@property (nonatomic, assign) int cacheSize;

- (void)setImage:(JPEG2moro *)jpeg forKey:(NSString *)name;
- (JPEG2moro *)imageForKey:(NSString *)name;
- (void)removeAllObjects;
- (int)count;

@end
