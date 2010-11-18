//
//  JPEG2moroInflater.h
//  jpeg2moro
//
//  Created by Andrew Williams on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JPEG2moroInflater : NSObject {

}

+ (NSData *)inflate:(NSData *)source error:(NSError **)error;

@end
