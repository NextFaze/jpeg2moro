//
//  ImageViewController.m
//  jpeg2moro
//
//  Created by Andrew on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import "ImageViewController.h"
#import "JPEG2moro.h"

@implementation ImageViewController

@synthesize imageView, labelFile;
@synthesize imageName;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


- (id)initWithImageName:(NSString *)name {
	if(self = [super init]) {
		self.imageName = name;
	}
	return self;
}

- (void)setImage {

	JPEG2moro *jpeg = [JPEG2moro imageNamed:self.imageName];
	UIImage *img = [jpeg image];
	CGSize vsize = self.view.frame.size;
	int width = vsize.width - 40;
	int height = img.size.height * width / img.size.width;
	
	imageView.frame = CGRectMake(20, 20, width, height);
	imageView.center = CGPointMake(vsize.width / 2, vsize.height / 2);
	imageView.image = img;
	labelFile.text = imageName;
}

- (IBAction)reloadImage:(id)sender {
	[self setImage];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Image";
	
	[self setImage];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.labelFile = nil;
	self.imageView = nil;
}


- (void)dealloc {
	[self viewDidUnload];
    [super dealloc];
}


@end
