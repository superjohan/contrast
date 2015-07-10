//
//  ViewController.m
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastViewController.h"
#import "ContrastChannelView.h"
#import "ContrastChannelController.h"

static const NSInteger ContrastMaximumChannelCount = 8;

@interface ContrastViewController () <ContrastChannelViewDelegate>
@property (nonatomic) NSMutableArray<ContrastChannelView *> *channels; // FIXME: maybe this isn't necessary
@property (nonatomic) ContrastChannelController *channelController;
@end

@implementation ContrastViewController

#pragma mark - Private

- (float)_frequencyPositionFromPoint:(CGPoint)point
{
	CGFloat heightRatio = point.y / self.view.bounds.size.height;
	CGFloat widthModifier = ((point.x / self.view.bounds.size.width) / 10.0) - 0.05;
	
	return (1.0f - heightRatio) + widthModifier;
}

- (void)_addChannelAtPoint:(CGPoint)point
{
	if (self.channels.count >= ContrastMaximumChannelCount)
	{
		// TODO: Maybe indicate somehow that more channels cannot be added?
		
		return;
	}
	
	ContrastChannelView *channelView = [[ContrastChannelView alloc] initWithCenter:point delegate:self];
	channelView.alpha = 0;
	channelView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
	[self.view addSubview:channelView];
	[self.channels addObject:channelView];
	[self.channelController addView:channelView];
	[self.channelController updateChannelWithView:channelView frequencyPosition:[self _frequencyPositionFromPoint:point] volume:0.5f effectAmount:0];
	
	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
		channelView.alpha = 1;
		channelView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
	} completion:nil];
}

- (void)_removeChannel:(ContrastChannelView *)channelView
{
	[self.channelController removeView:channelView];

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

- (float)_effectAmountFromRotation:(CGFloat)rotation
{
	if (rotation >= 0)
	{
		float amount = (float)(rotation / (M_PI * 2.0));

		if (amount > 1)
		{
			amount = 1;
		}
		
		return amount;
	}
	else
	{
		return 0;
	}
}

#pragma mark - ContrastChannelViewDelegate

- (void)channelView:(ContrastChannelView *)channelView updatedWithPosition:(CGPoint)position scale:(CGFloat)scale rotation:(CGFloat)rotation
{
	[self.channelController updateChannelWithView:channelView
								frequencyPosition:[self _frequencyPositionFromPoint:position]
										   volume:(scale - 0.5f)
									 effectAmount:[self _effectAmountFromRotation:rotation]];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.channels = [[NSMutableArray alloc] init];
	self.channelController = [[ContrastChannelController alloc] init];
	
	UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_doubleTapRecognized:)];
	doubleTapRecognizer.numberOfTapsRequired = 2;
	[self.view addGestureRecognizer:doubleTapRecognizer];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

@end
