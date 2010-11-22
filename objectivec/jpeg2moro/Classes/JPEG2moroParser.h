//
//  JPEG2moroParser.h
//  jpeg2moro
//
//  Created by Andrew on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JPEG2moroChunkAlpha.h"

@interface JPEG2moroParser : NSObject {

}

+ (NSData *)extractAppSegment:(NSData *)jpg error:(NSError **)error;
+ (NSArray *)extractChunks:(NSData *)jpg error:(NSError **)error;
+ (JPEG2moroChunkAlpha *)alphaChunk:(NSData *)jpg error:(NSError **)error;

@end
