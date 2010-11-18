//
//  JPEG2moroTestCase.m
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

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

@interface JPEG2moroTestCase : GTMTestCase {
	//id mock; // Mock object used in tests	
}
@end

@implementation JPEG2moroTestCase

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
- (void)testImageWithContentsOfFile {
	JPEG2moro *img = [JPEG2moro imageWithContentsOfFile:[self fixturePath:@"meditate-alpha-1.jpg"]];	
	STAssertNotNil(img, NULL);
}

#endif

@end
