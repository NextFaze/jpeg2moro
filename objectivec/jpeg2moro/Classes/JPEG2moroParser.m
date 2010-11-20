//
//  JPEG2moroParser.m
//  jpeg2moro
//
//  Created by Andrew on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import "JPEG2moroParser.h"
#import "JPEG2moroChunk.h"
#import "JPEG2moroChunkAlpha.h"

#define MARKER_APP10 0xE9
#define MARKER_EOI 0xD9  // end of image
#define MARKER_SOS 0xDA  // start of scan

@implementation JPEG2moroParser

+ (BOOL)standaloneJPEGMarker:(unsigned char)byte {
	return ((byte >= 0xd0 && byte <= 0xd7) || 
			byte == 0xd8 ||
			byte == 0xd9 || 
			byte == 0x01) ? YES : NO;
}

+ (NSArray *)extractChunks:(NSData *)jpg error:(NSError **)error {
	NSData *app10 = [self extractAppSegment:jpg error:error];
	NSMutableArray *chunks = [NSMutableArray array];
	
	if(app10 == nil) { // || error) {
		// error extracting app segment
		LOG(@"error extracting app segment");
		return nil;
	}
	
	// parse chunks
	const unsigned char *data = [app10 bytes];
	const unsigned char *ptr = data;
	
	// (4 bytes)  Length
	// (4 bytes)  Chunk type  (e.g. "ALPH" for alpha channel)
	// (length bytes) Chunk data
	for(;ptr < data + [app10 length];) {
		unsigned long len = NSSwapLong(*(unsigned long *)ptr);
		NSString *name = [NSString stringWithFormat:@"%-4.4s", ptr + 4];
		NSData *data = [NSData dataWithBytes:(ptr + 8) length:len];
		
		LOG(@"chunk name: %@", name);
		LOG(@"chunk length: %ld", len);
		
		Class klass = [name isEqualToString:@"ALPH"] ? [JPEG2moroChunkAlpha class] : [JPEG2moroChunk class];
		JPEG2moroChunk *chunk = [[klass alloc] init];
		chunk.data = data;
		chunk.name = name;
		[chunks addObject:chunk];
		[chunk release];
		
		ptr += len + 8;
	}
	
	return chunks;
}

// extract the app10 segment containing alpha data
// TODO: return error objects
+ (NSData *)extractAppSegment:(NSData *)jpg error:(NSError **)error {

	NSMutableData *segment = [NSMutableData data];
	const unsigned char *data = [jpg bytes];
	const unsigned char *ptr = data;
	
	if(error) *error = nil;
	
	LOG(@"jpeg data length: %d", [jpg length]);
	
	for(; ptr < data + [jpg length] - 1;) {
		unsigned char marker1 = *ptr;
		unsigned char marker2 = *(ptr + 1);
		
		LOG(@"marker: %x%x", marker1, marker2);
		
		if(marker1 != 0xff) {
			LOG(@"parse error. marker byte 1: %x", marker1);
			break;
		}
		if(marker2 == 0xff) {
			// fill byte
			ptr++;
			continue;
		}
		if(marker2 == MARKER_SOS || marker2 == MARKER_EOI) {
			// finished parsing headers
			break;
		}
		
		ptr += 2;
		
		if([self standaloneJPEGMarker:marker2]) continue;
		unsigned short len = NSSwapShort(*(unsigned short *)ptr);  // length of segment
		
		ptr += 2;
		
		LOG(@"segment %x length %d", marker2, len);
		if(marker2 == MARKER_APP10) {
			// found APP10 segment
			[segment appendBytes:ptr length:len - 2];
		}
		ptr += len - 2;
	}
	LOG(@"found %d bytes app segment data", [segment length]);
	return segment;
}

@end
