//
//  ContrastChannelView.m
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastChannelView.h"

static const CGFloat ContrastChannelViewInitialSize = 150;
static const CGFloat ContrastChannelViewMinimumScale = 0.5;
static const CGFloat ContrastChannelViewMaximumScale = 2.0;

@interface ContrastChannelView () <UIGestureRecognizerDelegate>

@property (nonatomic) CGPoint startCenter;

@property (nonatomic) CGFloat startScale;
@property (nonatomic) CGFloat currentScale;

@property (nonatomic) CGFloat startRotation;
@property (nonatomic) CGFloat currentRotation;

@property (nonatomic) UIView *innerView;

@property (nonatomic, weak) id<ContrastChannelViewDelegate> delegate;

@end

@implementation ContrastChannelView

#pragma mark - Private

- (void)_notifyDelegateOfChanges
{
	[self.delegate channelView:self updatedWithPosition:self.center scale:self.currentScale rotation:self.currentRotation];
}

- (void)_panRecognized:(UIPanGestureRecognizer *)panRecognizer
{
	CGPoint translation = [panRecognizer translationInView:self.superview];
	CGRect superviewBounds = self.superview.bounds;
	
	// TODO: Some kind of resistance at the edges would be nice, so that it doesn't just stop.
	
	CGFloat x = self.startCenter.x + translation.x;
	if (x < superviewBounds.origin.x)
	{
		x = superviewBounds.origin.x;
	}
	else if (x > superviewBounds.size.width)
	{
		x = superviewBounds.size.width;
	}
	
	CGFloat y = self.startCenter.y + translation.y;
	if (y < superviewBounds.origin.y)
	{
		y = superviewBounds.origin.y;
	}
	else if (y > superviewBounds.size.height)
	{
		y = superviewBounds.size.height;
	}
	
	self.center = CGPointMake(x, y);
	
	if (panRecognizer.state == UIGestureRecognizerStateEnded ||
		panRecognizer.state == UIGestureRecognizerStateCancelled ||
		panRecognizer.state == UIGestureRecognizerStateFailed)
	{
		self.startCenter = self.center;
	}
	
	[self _notifyDelegateOfChanges];
}

- (void)_pinchRecognized:(UIPinchGestureRecognizer *)pinchRecognizer
{
	CGFloat scale = pinchRecognizer.scale;
	CGFloat adjustedScale = self.startScale * scale;

	// TODO: Some kind of resistance at min/max would be nice, so that it doesn't just stop.

	if (adjustedScale <= ContrastChannelViewMinimumScale)
	{
		adjustedScale = ContrastChannelViewMinimumScale;
	}
	else if (adjustedScale >= ContrastChannelViewMaximumScale)
	{
		adjustedScale = ContrastChannelViewMaximumScale;
	}
	
	self.currentScale = adjustedScale;
	
	[self _applyAffineTransformWithScale:self.currentScale rotation:self.currentRotation];

	if (pinchRecognizer.state == UIGestureRecognizerStateEnded ||
		pinchRecognizer.state == UIGestureRecognizerStateCancelled ||
		pinchRecognizer.state == UIGestureRecognizerStateFailed)
	{
		self.startScale = adjustedScale;
	}

	[self _notifyDelegateOfChanges];
}

- (void)_rotationRecognized:(UIRotationGestureRecognizer *)rotationRecognizer
{
	self.currentRotation = fmod(self.startRotation + rotationRecognizer.rotation, M_PI * 2.0);
	
	[self _applyAffineTransformWithScale:self.currentScale rotation:self.currentRotation];

	if (rotationRecognizer.state == UIGestureRecognizerStateEnded ||
		rotationRecognizer.state == UIGestureRecognizerStateCancelled ||
		rotationRecognizer.state == UIGestureRecognizerStateFailed)
	{
		self.startRotation = self.currentRotation;
	}

	[self _notifyDelegateOfChanges];
}

- (void)_applyAffineTransformWithScale:(CGFloat)scale rotation:(CGFloat)rotation
{
	// The border should always be ~two points, so we scale the inner view dynamically as well.
	CGFloat padding = 2.0;
	CGFloat scaledLength = ContrastChannelViewInitialSize * scale;
	CGFloat innerViewScale = (scaledLength - (padding * 2.0)) / scaledLength;
	self.innerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, innerViewScale, innerViewScale);
	
	CGAffineTransform rotationTransform = CGAffineTransformRotate(CGAffineTransformIdentity, rotation);
	CGAffineTransform scaleTransform = CGAffineTransformScale(rotationTransform, scale, scale);
	self.transform = scaleTransform;
}

#pragma mark - Public

- (instancetype)initWithCenter:(CGPoint)center delegate:(id<ContrastChannelViewDelegate>)delegate;
{
	CGRect frame = CGRectMake(center.x - (ContrastChannelViewInitialSize / 2.0),
							  center.y - (ContrastChannelViewInitialSize / 2.0),
							  ContrastChannelViewInitialSize,
							  ContrastChannelViewInitialSize);
	
	if ((self = [super initWithFrame:frame]))
	{
		_startCenter = center;
		_delegate = delegate;
		
		_startScale = 1.0;
		_currentScale = 1.0;
		
		_startRotation = 0;
		_currentRotation = 0;
		
		self.backgroundColor = [UIColor whiteColor];
		
		_innerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
		_innerView.backgroundColor = [UIColor blackColor];
		[self addSubview:_innerView];

		[self _applyAffineTransformWithScale:_currentScale rotation:_currentRotation];
		
		UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panRecognized:)];
		panRecognizer.delegate = self;
		[self addGestureRecognizer:panRecognizer];
		
		UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(_pinchRecognized:)];
		pinchRecognizer.delegate = self;
		[self addGestureRecognizer:pinchRecognizer];
		
		UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(_rotationRecognized:)];
		rotationRecognizer.delegate = self;
		[self addGestureRecognizer:rotationRecognizer];
	}
	
	return self;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

#pragma mark - UIView

- (void)touchesBegan:(nonnull NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	[self.superview bringSubviewToFront:self];
}

@end
