//
//  JPEG2moroChunkAlpha.m
//  jpeg2moro
//
//  Created by Andrew on 20/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import "JPEG2moroChunkAlpha.h"


@implementation JPEG2moroChunkAlpha

- (int)bitDepth {
	unsigned char *bytes = (unsigned char *)[data bytes];
	int alphaDepth = *(unsigned char *)bytes;  // first byte is alpha bit depth
	return alphaDepth;
}

- (NSData *)compressedData {
	NSData *alphaCompressed = [NSData dataWithBytes:([data bytes] + 1) length:[data length] - 1];
	return alphaCompressed;
}

@end
