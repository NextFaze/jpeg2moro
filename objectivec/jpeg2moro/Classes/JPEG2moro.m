//
//  JPEG2moro.m
//  jpeg2moro
//
//  Created by Andrew Williams on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import "JPEG2moro.h"
#import "JPEG2moroInflater.h"
#import "JPEG2moroParser.h"
#import "JPEG2moroChunk.h"
#import "JPEG2moroChunkAlpha.h"

@interface JPEG2moro (Private)
- (void)readData:(NSData *)data;
@end

@implementation JPEG2moro

#pragma mark Class methods

+ (JPEG2moro *)imageNamed:(NSString *)name {
	// TODO: caching
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *path = [NSString stringWithFormat:@"%@/%@", resourcePath, name];
	return [self imageWithContentsOfFile:path];
}

+ (JPEG2moro *)imageWithContentsOfFile:(NSString *)filename {
	return [self imageWithData:[NSData dataWithContentsOfFile:filename]];
}

+ (JPEG2moro *)imageWithData:(NSData *)data {
	return [[JPEG2moro alloc] initWithData:data];
}

#pragma mark Public instance methods

- (id)init {
	if(self = [super init]) {
		image = nil;
		alpha = nil;
	}
	return self;
}

- (id)initWithData:(NSData *)data {	
	if(data == nil) return nil;   // invalid data
	
	if(self = [self init]) {
		[self readData:data];
		if(image == nil) return nil;    // could not read image
	}
	return self;
}

- (void)dealloc {
	[image release];
	[alpha release];
	[super dealloc];
}

- (UIImage *)image {
	return image;
}

#pragma mark Private

// Returns a copy of the given image, adding an alpha channel
- (UIImage *)imageWithAlpha:(UIImage *)img {
    CGImageRef imageRef = img.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
	size_t bytesPerPixel = 4;
    size_t bitsPerComponent = 8;
	size_t bytesPerRow = width * bytesPerPixel;
	size_t imageSize;
	
	// round up bytesPerRow to nearest multiple of 16
	if(bytesPerRow % 16)
		bytesPerRow += 16 - bytesPerRow % 16;
	
	imageSize = bytesPerRow * height;
	
	LOG(@"bytesPerRow: %d, imageSize: %d", bytesPerRow, imageSize);
	
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB(); //CGImageGetColorSpace(imageRef);

	void *data = calloc(imageSize, 1);
	if(data == nil) {
		LOG(@"memory allocation error");
		return nil;
	}
	
    CGContextRef offscreenContext = CGBitmapContextCreate(data,
                                                          width,
                                                          height,
                                                          bitsPerComponent,
                                                          bytesPerRow,
                                                          colorspace,
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    
    // Draw the image into the context and retrieve the new image, which will now have an alpha layer
    CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(offscreenContext);
    UIImage *imageWithAlpha = [UIImage imageWithCGImage:imageRefWithAlpha];
    
    // Clean up
	CGColorSpaceRelease(colorspace);
    CGContextRelease(offscreenContext);
    CGImageRelease(imageRefWithAlpha);
    free(data);
	
    return imageWithAlpha;
}

- (UIImage *)addAlphaChannel:(NSData *)alphaData image:(UIImage *)jpeg depth:(int)alphaDepth {
	size_t width = jpeg.size.width;
	size_t height = jpeg.size.height;
	size_t bytesPerRow = (width * alphaDepth + 7) / 8;
	int pixels = width * height;
	CGImageRef maskImage = nil;
	bool interpolate = true;
	
	LOG(@"image size: (%d,%d)", width, height);
	LOG(@"adding alpha channel. #pixels = %d, alpha length = %d, alpha depth = %d, bytesPerRow = %d", pixels, [alphaData length], alphaDepth, bytesPerRow);
	// add alpha channel to the jpeg image
	jpeg = [self imageWithAlpha:jpeg];
	
	// create mask image (monochrome)
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault; // alphaDepth == 16 ? kCGBitmapByteOrder16Big : kCGBitmapByteOrderDefault;
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray(); //CGColorSpaceCreateDeviceRGB();
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, [alphaData bytes], [alphaData length], NULL);
	
	maskImage = CGImageCreate(width, height, alphaDepth, alphaDepth,
							  bytesPerRow, colorspace, bitmapInfo, provider, NULL, interpolate, kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorspace);
	CGDataProviderRelease(provider);
	
	// combine the jpeg and the mask
	LOG(@"combining image and alpha mask");
	CGImageRef masked = CGImageCreateWithMask([jpeg CGImage], maskImage);
	UIImage *img = [UIImage imageWithCGImage:masked];

	LOG(@"mask applied");
	
	CGImageRelease(maskImage);
	CGImageRelease(masked);
	
	LOG(@"returning image");
	return img;
}

// read jpeg2moro format, return UIImage
- (void)readData:(NSData *)data {
	
	// inflate alpha channel data
	NSError *error = nil;
	UIImage *jpeg = [[UIImage alloc] initWithData:data];

	if(jpeg == nil) {
		// invalid data?
		LOG(@"UIImage could not parse jpeg data, returning nil");
		return;
	}
	
	NSArray *chunks = [JPEG2moroParser extractChunks:data error:&error];
	if(error || [chunks count] == 0) {
		// could not parse chunks
		// just return jpeg image data
		LOG(@"app segment chunks not found or error, returning plain jpeg image");
		image = jpeg;
		alpha = nil;
		return;
	}

	// find alpha chunk

	NSData *alphaCompressed = nil;
	int alphaDepth;
	
	for(JPEG2moroChunk *chunk in chunks) {
		if([chunk.name isEqualToString:@"ALPH"]) {
			JPEG2moroChunkAlpha *alphaChunk = (JPEG2moroChunkAlpha *)chunk;
			alphaDepth = [alphaChunk bitDepth];
			alphaCompressed = [alphaChunk compressedData];
			break;
		}
	}

	if(alphaCompressed == nil) {
		LOG(@"could not find alpha chunk, returning plain jpeg image");
		image = jpeg;
		return;
	}
	
	LOG(@"alpha channel bit depth: %d", alphaDepth);
	NSData *alphaData = [JPEG2moroInflater inflate:alphaCompressed error:&error];

	if(alphaData == nil || error) {
		LOG(@"error decompressing alpha channel, returning plain jpeg image");
		image = jpeg;
		return;
	}
	
	// read jpeg image, add alpha channel
	UIImage *ret = [self addAlphaChannel:alphaData image:jpeg depth:alphaDepth];
	[jpeg release];
	
	// return image with alpha added
	image = [ret retain];
	alpha = [alphaData retain];  // not sure why we need to retain this, but weirdness & crashing ensues if we don't
}

@end
