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
#import "JPEG2moroCache.h"

@interface JPEG2moro (Private)
- (UIImage *)readData:(NSData *)data;
@end

@implementation JPEG2moro

#pragma mark Class methods

static JPEG2moroCache *cache = nil;

+ (void)initialize {
	cache = [[JPEG2moroCache alloc] init];
}

+ (JPEG2moro *)imageNamed:(NSString *)name {
	JPEG2moro *jpeg = [cache imageForKey:name];
	if(jpeg) {
		LOG(@"returning cached image %@", name);
		return jpeg;
	}

	// not cached, load image	
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *path = [NSString stringWithFormat:@"%@/%@", resourcePath, name];
	jpeg = [self imageWithContentsOfFile:path];
	[cache setImage:jpeg forKey:name];

	return jpeg;
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
	}
	return self;
}

- (id)initWithData:(NSData *)data {	
	if(data == nil) return nil;   // invalid data
	UIImage *img = [self readData:data];
	if(img == nil) return nil;    // could not read image
	
	if(self = [self init]) {
		image = [img retain];
	}
	return self;
}

- (void)dealloc {
	[image release];
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
	CGImageRef maskImage = nil;
	bool interpolate = true;
	
	LOG(@"image size: (%d,%d)", width, height);
	LOG(@"adding alpha channel.  alpha length = %d, alpha depth = %d, bytesPerRow = %d", [alphaData length], alphaDepth, bytesPerRow);
	// add alpha channel to the jpeg image
	jpeg = [self imageWithAlpha:jpeg];
	
	// create mask image (monochrome)
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault; // alphaDepth == 16 ? kCGBitmapByteOrder16Big : kCGBitmapByteOrderDefault;
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray(); //CGColorSpaceCreateDeviceRGB();

	// alphaData is retained by the provider and the CGImage we create
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef) alphaData);
	
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
- (UIImage *)readData:(NSData *)data {
	
	// create a UIImage from the data (no alpha channel)
	NSError *error = nil;
	UIImage *jpeg = [UIImage imageWithData:data];

	if(jpeg == nil) {
		// invalid data?
		LOG(@"UIImage could not parse jpeg data, returning nil");
		return nil;
	}
	
	// find alpha chunk within the data
	JPEG2moroChunkAlpha *alphaChunk = [JPEG2moroParser alphaChunk:data error:&error];
	NSData *alphaCompressed = [alphaChunk compressedData];
	int alphaDepth = [alphaChunk bitDepth];

	if(alphaCompressed == nil) {
		LOG(@"could not find alpha chunk, returning plain jpeg image");
		return jpeg;
	}
	
	// inflate alpha channel data
	NSData *alphaData = [JPEG2moroInflater inflate:alphaCompressed error:&error];
	if(alphaData == nil || error) {
		LOG(@"error decompressing alpha channel, returning plain jpeg image");
		return jpeg;
	}
	
	// add alpha channel to the image
	UIImage *ret = [self addAlphaChannel:alphaData image:jpeg depth:alphaDepth];
	
	// return image with alpha added
	return ret;
}

@end
