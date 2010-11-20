//
//  JPEG2moroChunk.h
//  jpeg2moro
//
//  Created by Andrew on 20/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JPEG2moroChunk : NSObject {
	NSString *name;
	NSData *data;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSData *data;

@end
