//
//  JPEG2moroCacheTestCase.m
//  jpeg2moro
//
//  Created by Andrew Williams on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//
//  Link to Google Toolbox For Mac (IPhone Unit Test): 
//					http://code.google.com/p/google-toolbox-for-mac/wiki/iPhoneUnitTesting
//  Link to OCUnit:	http://www.sente.ch/s/?p=276&lang=en
//  Link to OCMock:	http://www.mulle-kybernetik.com/software/OCMock/


#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import <OCMock/OCMConstraint.h>
#import "GTMSenTestCase.h"
#import <zlib.h>

#import "JPEG2moro.h"
#import "JPEG2moroCache.h"

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

@interface JPEG2moroCacheTestCase : GTMTestCase {
	//id mock; // Mock object used in tests	
}
@end

@implementation JPEG2moroCacheTestCase

#if TARGET_IPHONE_SIMULATOR     // Only run when the target is simulator

- (void) setUp {
	//mock = [OCMockObject mockForClass:[NSString class]];  // create your mock objects here
	// Create shared data structures here
}

- (void) tearDown {
    // Release data structures here.
}

- (NSString *)fixturePath:(NSString *)filename {
	return [NSString stringWithFormat:@"%s/Tests/fixtures/%@", TOSTRING(SOURCE_ROOT), filename];
}
- (NSData *)fixtureData:(NSString *)filename {
	return [NSData dataWithContentsOfFile:[self fixturePath:filename]];
}

// test inflation of compressed data matches expected uncompressed data
- (void)testSetImage {
	NSString *name = @"image1.jpg";
	JPEG2moro *img = [[JPEG2moro alloc] init];
	STAssertNotNil(img, NULL);

	// create cache
	JPEG2moroCache *cache = [[JPEG2moroCache alloc] init];
	
	// add image to cache
	[cache setImage:img forKey:name];
	STAssertEquals([cache count], 1, NULL);	
	STAssertNotNil([cache imageForKey:name], NULL);

	// try adding it again
	[cache setImage:img forKey:name];
	STAssertEquals([cache count], 1, NULL);	
}

- (void)testSetImageWithLimit {
	NSString *name1 = @"image1.jpg";
	NSString *name2 = @"image2.jpg";
	NSString *name3 = @"image3.jpg";
	JPEG2moro *img1 = [[JPEG2moro alloc] init];
	JPEG2moro *img2 = [[JPEG2moro alloc] init];
	JPEG2moro *img3 = [[JPEG2moro alloc] init];
	
	// create cache
	JPEG2moroCache *cache = [[JPEG2moroCache alloc] init];
	cache.cacheSize = 2;  // max size 2 images
	
	[cache setImage:img1 forKey:name1];
	[cache setImage:img2 forKey:name2];
	[cache setImage:img3 forKey:name3];
	
	STAssertEquals([cache count], 2, NULL);
	STAssertNil([cache imageForKey:name1], NULL);  // first image should have been removed
	
	[cache imageForKey:name2];  // access 2nd image
	[cache setImage:img1 forKey:name1];  // add a new image
	
	STAssertNil([cache imageForKey:name3], NULL);  // third image should have been removed (accessed less recently than 1st and 2nd)
}

#endif

@end
