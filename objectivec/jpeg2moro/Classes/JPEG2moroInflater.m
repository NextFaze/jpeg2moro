//
//  JPEG2moroInflater.m
//  jpeg2moro
//
//  Created by Andrew Williams on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//
// adapted from zpipe.c zlib example code.

#import "JPEG2moroInflater.h"
#import <zlib.h> 

#define CHUNK 16384

@implementation JPEG2moroInflater

+ (NSError *)errorWithCode:(int)code {
	NSError *err = [NSError errorWithDomain:@"zlibError" code:code userInfo:[NSDictionary dictionary]];
	return err;
}

// Decompress from data source.
// Returns decompressed data on success, nil on error.
// on error sets error object, if provided.

+ (NSData *)inflate:(NSData *)source error:(NSError **)error {
	
    int ret;
    unsigned have;
    z_stream strm;
	unsigned char out_buffer[CHUNK];
	NSMutableData *output = [NSMutableData data];
	
	if(error) *error = nil;

	// sanity checks
	if([source length] == 0) {
		if(error) *error = [self errorWithCode:Z_DATA_ERROR];
		return nil;
	}
	
    /* allocate inflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    ret = inflateInit(&strm);
    if (ret != Z_OK) {
		LOG(@"inflate init error: %d", ret);
		if(error) *error = [self errorWithCode:ret];
        return nil;
	}

	strm.avail_in = [source length];
	strm.next_in = (Bytef *)[source bytes];

	/* run inflate() on input until output buffer not full */
	do {
		strm.avail_out = CHUNK;
		strm.next_out = out_buffer;

		LOG(@"inflating chunk. available in: %d", strm.avail_in);
		ret = inflate(&strm, Z_NO_FLUSH);
		
		assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
		switch (ret) {
			case Z_NEED_DICT:
				ret = Z_DATA_ERROR;     /* and fall through */
			case Z_DATA_ERROR:
			case Z_MEM_ERROR:
				(void)inflateEnd(&strm);
				LOG(@"parser error: %d", ret);
				if(error) *error = [self errorWithCode:ret];
				return nil;
		}
		have = CHUNK - strm.avail_out;
		[output appendBytes:out_buffer length:have];

		LOG(@"have %d bytes output. avail_out = %d", have, strm.avail_out);
		
	} while (strm.avail_out == 0);
	
    /* clean up and return */
    (void)inflateEnd(&strm);

	if(ret != Z_STREAM_END) {
		LOG(@"not at stream end: %d", ret);
		if(error) *error = [self errorWithCode:ret];
		return nil;
	}
	LOG(@"success. deflate output length: %d", [output length]);
	return output;
}

@end
