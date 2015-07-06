//
//  ViewController.m
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastViewController.h"
#import "ContrastChannelView.h"

static const NSInteger ContrastMaximumChannelCount = 8;

@interface ContrastViewController ()
@property (nonatomic) NSMutableArray<ContrastChannelView *> *channels;
@end

@implementation ContrastViewController

#pragma mark - Private

- (void)_addChannelAtPoint:(CGPoint)point
{
	if (self.channels.count >= ContrastMaximumChannelCount)
	{
		// TODO: Maybe indicate somehow that more channels cannot be added?
		
		return;
	}
	
	ContrastChannelView *channelView = [[ContrastChannelView alloc] initWithCenter:point];
	channelView.alpha = 0;
	channelView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
	[self.view addSubview:channelView];
	[self.channels addObject:channelView];
	
	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
		channelView.alpha = 1;
		channelView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
	} completion:nil];
}

- (void)_removeChannel:(ContrastChannelView *)channelView
{
	[UIView animateWithDuration:(UINavigationControllerHideShowBarDuration * 2.0) delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
		channelView.alpha = 0;
		channelView.transform = CGAffineTransformRotate(channelView.transform, M_PI_4);
		channelView.transform = CGAffineTransformScale(channelView.transform, 0.1, 0.1);
	} completion:^(BOOL finished) {
		[self.channels removeObject:channelView];
		[channelView removeFromSuperview];
	}];
}

- (void)_doubleTapRecognized:(UITapGestureRecognizer *)tapRecognizer
{
	CGPoint location = [tapRecognizer locationInView:self.view];
	UIView *view = [self.view hitTest:location withEvent:nil];
	
	if (view == self.view)
	{
		[self _addChannelAtPoint:location];
	}
	else
	{
		UIView *baseView = [self _baseViewFromView:view];
		
		if ([baseView isKindOfClass:[ContrastChannelView class]])
		{
			[self _removeChannel:(ContrastChannelView *)baseView];
		}
	}
}

- (UIView *)_baseViewFromView:(UIView *)view
{
	if (view == self.view)
	{
		return nil;
	}
	
	UIView *currentView = view;
	
	while (currentView.superview != self.view)
	{
		currentView = currentView.superview;
	}
	
	return currentView;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.channels = [[NSMutableArray alloc] init];
	
	UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_doubleTapRecognized:)];
	doubleTapRecognizer.numberOfTapsRequired = 2;
	[self.view addGestureRecognizer:doubleTapRecognizer];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

@end
