//
//  JPEG2moro.h
//  jpeg2moro
//
//  Created by Andrew Williams on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JPEG2moro : NSObject {
	UIImage *image;
	NSData *alpha;  // this needs to be retained, not sure why?
}

+ (JPEG2moro *)imageNamed:(NSString *)name;
+ (JPEG2moro *)imageWithContentsOfFile:(NSString *)filename;
+ (JPEG2moro *)imageWithData:(NSData *)data;

- (id)initWithData:(NSData *)data;

- (UIImage *)image;

@end
