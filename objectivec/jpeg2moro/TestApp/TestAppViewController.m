//
//  TestAppViewController.m
//  jpeg2moro
//
//  Created by Andrew on 18/11/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

#import "TestAppViewController.h"
#import "JPEG2moro.h"

@implementation TestAppViewController

@synthesize imageView, labelFile;
@synthesize imageList, imageNames;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// find all jpeg images, add to list
- (void)findImages {
	NSString *path = [[NSBundle mainBundle] bundlePath];
	NSMutableArray *list = [NSMutableArray array];
	NSMutableArray *names = [NSMutableArray array];
	NSError *error = nil;
	NSArray *contents = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:&error];
	NSArray *images = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"]];
	
	for(NSString *imgName in images) {
		LOG(@"found image: %@", imgName);
		JPEG2moro *img = [JPEG2moro imageNamed:imgName];
		[list addObject:[img image]];
		[names addObject:imgName];
	}
	LOG(@"image list contains %d images", [list count]);

	self.imageList = list;
	self.imageNames = names;
}

- (void)setImage {
	if([imageList count] <= imageNumber) return;
	
	UIImage *img = [imageList objectAtIndex:imageNumber];
	NSString *name = [imageNames objectAtIndex:imageNumber];
	LOG(@"displaying image: %@", name);
	CGSize vsize = self.view.frame.size;
	int width = vsize.width - 40;
	int height = img.size.height * width / img.size.width;
	
	imageView.frame = CGRectMake(20, 20, width, height);
	imageView.center = CGPointMake(vsize.width / 2, vsize.height / 2);
	imageView.image = img;
	labelFile.text = name;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	[self findImages];
	imageNumber = 0;
	
	[self setImage];
}

// touch anywhere to change image
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event  {
	if([imageList count] == 0) return;
	imageNumber = (imageNumber + 1) % [imageList count];
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
	self.imageList = nil;
	self.labelFile = nil;
	self.imageView = nil;
	self.imageNames = nil;
}


- (void)dealloc {
	[self viewDidUnload];
    [super dealloc];
}


@end
