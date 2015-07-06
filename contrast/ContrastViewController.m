//
//  ViewController.m
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastViewController.h"
#import "ContrastChannelView.h"

@interface ContrastViewController ()

@end

@implementation ContrastViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	ContrastChannelView *channelView = [[ContrastChannelView alloc] initWithCenter:CGPointMake(100, 100)];
	[self.view addSubview:channelView];

	ContrastChannelView *channelView2 = [[ContrastChannelView alloc] initWithCenter:CGPointMake(200, 200)];
	[self.view addSubview:channelView2];

	ContrastChannelView *channelView3 = [[ContrastChannelView alloc] initWithCenter:CGPointMake(150, 300)];
	[self.view addSubview:channelView3];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

@end
