//
//  ImageViewController.h
//  jpeg2moro
//
//  Created by Andrew on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageViewController : UIViewController {
	UILabel *labelFile;
	UIImageView *imageView;
	int imageNumber;
	NSString *imageName;
}

@property (nonatomic, retain) IBOutlet UILabel *labelFile;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, copy) NSString *imageName;

- (id)initWithImageName:(NSString *)imageName;
- (IBAction)reloadImage:(id)sender;

@end
