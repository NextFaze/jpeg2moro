//
//  TestAppViewController.h
//  jpeg2moro
//
//  Created by Andrew on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TestAppViewController : UIViewController {
	NSArray *imageList, *imageNames;
	UILabel *labelFile;
	UIImageView *imageView;
	int imageNumber;
}

@property (nonatomic, retain) IBOutlet UILabel *labelFile;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;

@property (nonatomic, retain) NSArray *imageList, *imageNames;

@end
