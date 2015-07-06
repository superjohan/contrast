//
//  ContrastChannelView.m
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastChannelView.h"

static const CGFloat ContrastChannelViewInitialSize = 100;

@interface ContrastChannelView ()
@property (nonatomic) CGPoint startCenter;
@property (nonatomic) UIView *innerView;
@end

@implementation ContrastChannelView

#pragma mark - Private

- (void)_panRecognized:(UIPanGestureRecognizer *)panRecognizer
{
	CGPoint translation = [panRecognizer translationInView:self.superview];
	self.center = CGPointMake(self.startCenter.x + translation.x, self.startCenter.y + translation.y);
	
	if (panRecognizer.state == UIGestureRecognizerStateEnded ||
		panRecognizer.state == UIGestureRecognizerStateCancelled ||
		panRecognizer.state == UIGestureRecognizerStateFailed)
	{
		self.startCenter = self.center;
	}
}

#pragma mark - Public

- (instancetype)initWithCenter:(CGPoint)center
{
	CGRect frame = CGRectMake(center.x - (ContrastChannelViewInitialSize / 2.0),
							  center.y - (ContrastChannelViewInitialSize / 2.0),
							  ContrastChannelViewInitialSize,
							  ContrastChannelViewInitialSize);
	
	if ((self = [super initWithFrame:frame]))
	{
		_startCenter = center;
		
		self.backgroundColor = [UIColor whiteColor];
		
		CGFloat padding = 2.0;
		_innerView = [[UIView alloc] initWithFrame:CGRectMake(padding, padding, frame.size.width - (padding * 2.0), frame.size.height - (padding * 2.0))];
		_innerView.backgroundColor = [UIColor blackColor];
		[self addSubview:_innerView];
		
		UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panRecognized:)];
		[self addGestureRecognizer:panRecognizer];
	}
	
	return self;
}

#pragma mark - UIView

- (void)touchesBegan:(nonnull NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	[self.superview bringSubviewToFront:self];
}

@end
