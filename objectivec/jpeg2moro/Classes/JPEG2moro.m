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

@interface JPEG2moro (Private)
- (UIImage *)readData:(NSData *)data;
@end

@implementation JPEG2moro

#pragma mark Class methods

+ (JPEG2moro *)imageNamed:(NSString *)name {
	// TODO: caching
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	//NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg" inDirectory:@""];
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
	}
	return self;
}

- (id)initWithData:(NSData *)data {
	if(data == nil) return nil;   // invalid data
	
	if(self = [super init]) {
		image = [self readData:data];
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

// Returns a copy of the given image, adding an alpha channel if it doesn't already have one
- (UIImage *)imageWithAlpha:(UIImage *)img {
    CGImageRef imageRef = img.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB(); //CGImageGetColorSpace(imageRef);

    // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
    CGContextRef offscreenContext = CGBitmapContextCreate(NULL,
                                                          width,
                                                          height,
                                                          8,
                                                          0,
                                                          colorspace,
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    // Draw the image into the context and retrieve the new image, which will now have an alpha layer
    CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(offscreenContext);
    UIImage *imageWithAlpha = [UIImage imageWithCGImage:imageRefWithAlpha];
    
    // Clean up
	CGColorSpaceRelease(colorspace);
    CGContextRelease(offscreenContext);
    CGImageRelease(imageRefWithAlpha);
    
    return imageWithAlpha;
}

- (UIImage *)addAlphaChannel:(NSData *)alpha image:(UIImage *)jpeg depth:(int)alphaDepth {
	size_t bytesPerRow = (jpeg.size.width * alphaDepth + 7) / 8;
	CGImageRef maskImage = nil;
	
	LOG(@"adding alpha channel");
	// add alpha channel to the jpeg image
	jpeg = [self imageWithAlpha:jpeg];
	
	if(alphaDepth == 16) {
		// need to create an image to use as the mask (CGImageMask is limited to 8 bpp)
		// create mask image (monochrome, 16 bit)
		CGBitmapInfo bitmapInfo = kCGBitmapByteOrder16Big; //kCGBitmapFloatComponents;
		CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray(); //CGColorSpaceCreateDeviceRGB();
		CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, [alpha bytes], [alpha length], NULL);
		maskImage = CGImageCreate(jpeg.size.width, jpeg.size.height, 16, 16,
								  bytesPerRow, colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault);
		CGColorSpaceRelease(colorspace);
		CGDataProviderRelease(provider);
	}
	else {
		// can use a mask
		// need to invert the bits in the alpha channel (mask is an inverse alpha).
		NSMutableData *inverse = [NSMutableData dataWithData:alpha];
		unsigned char *bytes = (unsigned char *)[inverse mutableBytes];
		for(unsigned int i = 0; i < [inverse length]; i++) *bytes++ = *bytes ^ 0xff;
		
		CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, [inverse bytes], [inverse length], NULL);		
		maskImage = CGImageMaskCreate(jpeg.size.width, jpeg.size.height, alphaDepth, alphaDepth,
									  bytesPerRow, provider, NULL, true);
		CGDataProviderRelease(provider);
	}

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
	
	// inflate alpha channel data
	NSError *error = nil;
	UIImage *jpeg = [UIImage imageWithData:data];
	NSData *appsegment = [JPEG2moroParser extractAppSegment:data error:&error];

	if(jpeg == nil) {
		// invalid data?
		LOG(@"UIImage could not parse jpeg data, returning nil");
		return nil;
	}
	
	if(error || [appsegment length] == 0) {
		// could not find app segment
		// just return jpeg image data
		LOG(@"app segment not found or error, returning plain jpeg image");
		return jpeg;
	}
	
	unsigned char *appbytes = (unsigned char *)[appsegment bytes];
	int alphaDepth = *(unsigned char *)appbytes;  // first byte is alpha bit depth
	
	LOG(@"alpha channel bit depth: %d", alphaDepth);
	NSData *alphaCompressed = [NSData dataWithBytes:(appbytes + 1) length:[appsegment length] - 1];
	NSData *alpha = [JPEG2moroInflater inflate:alphaCompressed error:&error];
	
	if(alpha == nil || error) {
		LOG(@"error extracting alpha channel, returning plain jpeg image");
		return jpeg;
	}
		
	// read jpeg image, add alpha channel
	UIImage *ret = [self addAlphaChannel:alpha image:jpeg depth:alphaDepth];
	
	// return image with alpha added
	return ret;
}

@end
