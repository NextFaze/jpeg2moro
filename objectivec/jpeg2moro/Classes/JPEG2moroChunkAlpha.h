//
//  JPEG2moroChunkAlpha.h
//  jpeg2moro
//
//  Created by Andrew on 20/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JPEG2moroChunk.h"

@interface JPEG2moroChunkAlpha : JPEG2moroChunk {

}

- (int)bitDepth;
- (NSData *)compressedData;

@end
