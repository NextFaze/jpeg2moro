//
//  JPEG2moroInflaterTestCase.m
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

#import "JPEG2moroInflater.h"

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

@interface JPEG2moroInflaterTestCase : GTMTestCase {
	//id mock; // Mock object used in tests	
}
@end

@implementation JPEG2moroInflaterTestCase

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
- (void)testInflateData {
	NSError *error;	
	NSData *source = [self fixtureData:@"compressed.dat"];
	NSData *expected = [self fixtureData:@"uncompressed.dat"];
	
	LOG(@"source data length: %d", [source length]);
	LOG(@"expected decompressed data length: %d", [expected length]);
	STAssertNotNil(source, NULL);
	STAssertNotNil(expected, NULL);
	
	NSData *result = [JPEG2moroInflater inflate:source error:&error];
	LOG(@"result data length: %d", [result length]);
	
	STAssertNil(error, NULL);
	STAssertNotNil(result, NULL);
	STAssertEquals([result length], [expected length], NULL);
	STAssertTrue(!memcmp([result bytes], [expected bytes], [result length]), NULL);
}

// test failure
- (void)testInflateBadData {
	NSError *error = nil;
	NSData *source = [NSData dataWithBytes:"bad" length:3];
	NSData *result = [JPEG2moroInflater inflate:source error:&error];
	
	STAssertNotNil(error, NULL);
	STAssertNil(result, NULL);
	STAssertEquals(error.code, Z_DATA_ERROR, NULL);
}

#endif

@end
