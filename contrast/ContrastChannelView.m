//
//  ContrastChannelView.m
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastChannelView.h"

static const CGFloat ContrastChannelViewInitialSize = 150;
static const CGFloat ContrastChannelViewScaleMin = 0.5;
static const CGFloat ContrastChannelViewScaleMax = 1.5;
static const CGFloat ContrastChannelViewAngleMin = 0;
static const CGFloat ContrastChannelViewAngleMax = M_PI * 2.0;

@interface ContrastChannelView () <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) CGFloat minX;
@property (nonatomic, readonly) CGFloat maxX;
@property (nonatomic, readonly) CGFloat minY;
@property (nonatomic, readonly) CGFloat maxY;

@property (nonatomic) CGPoint startCenter;

@property (nonatomic) CGFloat startScale;
@property (nonatomic) CGFloat currentScale;

@property (nonatomic) CGFloat startRotation;
@property (nonatomic) CGFloat currentRotation;

@property (nonatomic) UIView *innerView;
@property (nonatomic) UIView *indicatorView;

@property (nonatomic, weak) id<ContrastChannelViewDelegate> delegate;

@property (nonatomic) BOOL animatingToValidConfiguration;

@end

@implementation ContrastChannelView

#pragma mark - Private

- (CGPoint)_normalizedPosition
{
	CGPoint position = self.center;
	if (position.x < self.minX)
	{
		position.x = self.minX;
	}
	else if (position.x > self.maxX)
	{
		position.x = self.maxX;
	}
	
	if (position.y < self.minY)
	{
		position.y = self.minY;
	}
	else if (position.y > self.maxY)
	{
		position.y = self.maxY;
	}
	
	return position;
}

- (CGFloat)_normalizedScale
{
	if (self.currentScale < ContrastChannelViewScaleMin)
	{
		return ContrastChannelViewScaleMin;
	}
	else if (self.currentScale > ContrastChannelViewScaleMax)
	{
		return ContrastChannelViewScaleMax;
	}
	
	return self.currentScale;
}

- (CGFloat)_normalizedRotation
{
	if (self.currentRotation < ContrastChannelViewAngleMin)
	{
		return ContrastChannelViewAngleMin;
	}
	else if (self.currentRotation > ContrastChannelViewAngleMax)
	{
		return ContrastChannelViewAngleMax;
	}
	
	return self.currentRotation;
}

- (void)_notifyDelegateOfChanges
{
	[self.delegate channelView:self
		   updatedWithPosition:[self _normalizedPosition]
						 scale:[self _normalizedScale]
					  rotation:[self _normalizedRotation]];
}

- (void)_animateToValidConfiguration
{
	if (self.animatingToValidConfiguration == YES)
	{
		return;
	}
		
	self.animatingToValidConfiguration = YES;

	CGPoint center = [self _normalizedPosition];
	CGFloat scale = [self _normalizedScale];
	CGFloat rotation = [self _normalizedRotation];
	
	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:0 animations:^{
		self.center = center;
	
		[self _applyAffineTransformWithScale:scale rotation:rotation];
	} completion:^(BOOL finished) {
		self.animatingToValidConfiguration = NO;
		
		self.startCenter = center;
		self.startScale = scale;
		self.currentScale = scale;
		self.startRotation = rotation;
		self.currentRotation = rotation;
	}];
}

- (CGFloat)_resistanceAdjustedValueFromValue:(CGFloat)value limit:(CGFloat)limit leeway:(CGFloat)leeway
{
	CGFloat resistance = (ABS(limit - value) / ABS(leeway));
	CGFloat resistanceValue = value - (resistance * (leeway / 1.3));

	return resistanceValue;
}

- (void)_panRecognized:(UIPanGestureRecognizer *)panRecognizer
{
	if (self.animatingToValidConfiguration)
	{
		return;
	}

	CGPoint translation = [panRecognizer translationInView:self.superview];
	CGFloat leeway = 10;
	
	CGFloat x = self.startCenter.x + translation.x;
	if (x < self.minX)
	{
		x = [self _resistanceAdjustedValueFromValue:x limit:self.minX leeway:-leeway];
	}
	else if (x > self.maxX)
	{
		x = [self _resistanceAdjustedValueFromValue:x limit:self.maxX leeway:leeway];
	}
	
	CGFloat y = self.startCenter.y + translation.y;
	if (y < self.minY)
	{
		y = [self _resistanceAdjustedValueFromValue:y limit:self.minY leeway:-leeway];
	}
	else if (y > self.maxY)
	{
		y = [self _resistanceAdjustedValueFromValue:y limit:self.maxY leeway:leeway];
	}
	
	self.center = CGPointMake(x, y);
	
	if (panRecognizer.state == UIGestureRecognizerStateEnded ||
		panRecognizer.state == UIGestureRecognizerStateCancelled ||
		panRecognizer.state == UIGestureRecognizerStateFailed)
	{
		[self _animateToValidConfiguration];
	}
	
	[self _notifyDelegateOfChanges];
}

- (void)_pinchRecognized:(UIPinchGestureRecognizer *)pinchRecognizer
{
	if (self.animatingToValidConfiguration)
	{
		return;
	}

	CGFloat scale = pinchRecognizer.scale;
	CGFloat adjustedScale = self.startScale * scale;

	CGFloat leeway = 0.2;
	
	if (adjustedScale <= ContrastChannelViewScaleMin)
	{
		adjustedScale = [self _resistanceAdjustedValueFromValue:adjustedScale limit:ContrastChannelViewScaleMin leeway:-leeway];
	}
	else if (adjustedScale >= ContrastChannelViewScaleMax)
	{
		adjustedScale = [self _resistanceAdjustedValueFromValue:adjustedScale limit:ContrastChannelViewScaleMax leeway:leeway];
	}
	
	self.currentScale = adjustedScale;
	
	[self _applyAffineTransformWithScale:self.currentScale rotation:self.currentRotation];

	if (pinchRecognizer.state == UIGestureRecognizerStateEnded ||
		pinchRecognizer.state == UIGestureRecognizerStateCancelled ||
		pinchRecognizer.state == UIGestureRecognizerStateFailed)
	{
		[self _animateToValidConfiguration];
	}

	[self _notifyDelegateOfChanges];
}

- (void)_rotationRecognized:(UIRotationGestureRecognizer *)rotationRecognizer
{
	if (self.animatingToValidConfiguration)
	{
		return;
	}
	
	self.currentRotation = self.startRotation + rotationRecognizer.rotation;
	
	CGFloat leeway = 0.5;
	
	if (self.currentRotation < ContrastChannelViewAngleMin)
	{
		self.currentRotation = [self _resistanceAdjustedValueFromValue:self.currentRotation limit:ContrastChannelViewAngleMin leeway:-leeway];
	}
	else if (self.currentRotation > ContrastChannelViewAngleMax)
	{
		self.currentRotation = [self _resistanceAdjustedValueFromValue:self.currentRotation limit:ContrastChannelViewAngleMax leeway:leeway];
	}
	
	[self _applyAffineTransformWithScale:self.currentScale rotation:self.currentRotation];

	if (rotationRecognizer.state == UIGestureRecognizerStateEnded ||
		rotationRecognizer.state == UIGestureRecognizerStateCancelled ||
		rotationRecognizer.state == UIGestureRecognizerStateFailed)
	{
		[self _animateToValidConfiguration];
	}

	[self _notifyDelegateOfChanges];
}

- (void)_tapRecognized:(UITapGestureRecognizer *)tapRecognizer
{
	[self.delegate channelViewReceivedTap:self];
}

- (void)_doubleTapRecognized:(UITapGestureRecognizer *)tapRecognizer
{
	[self.delegate channelViewReceivedDoubleTap:self];
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
	
	CGFloat indicatorBaseHeight = self.innerView.bounds.size.height;
	CGFloat indicatorHeight = (rotation / (M_PI * 2.0)) * indicatorBaseHeight;
	if (indicatorHeight > indicatorBaseHeight)
	{
		indicatorHeight = indicatorBaseHeight;
	}
	else if (indicatorHeight < 0)
	{
		indicatorHeight = 0;
	}
	
	self.indicatorView.frame = CGRectMake(self.indicatorView.frame.origin.x,
										  self.indicatorView.frame.origin.y,
										  self.indicatorView.frame.size.width,
										  indicatorHeight);
}

#pragma mark - Properties

- (CGFloat)minX
{
	return self.superview.bounds.origin.x;
}

- (CGFloat)maxX
{
	return self.superview.bounds.size.width;
}

- (CGFloat)minY
{
	return self.superview.bounds.origin.y;
}

- (CGFloat)maxY
{
	return self.superview.bounds.size.height;
}

- (void)setSilent:(BOOL)silent
{
	_silent = silent;
	
	if (silent)
	{
		self.innerView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
	}
	else
	{
		self.innerView.backgroundColor = [UIColor colorWithWhite:0 alpha:1.0];
	}
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

		CGFloat indicatorWidth = ContrastChannelViewInitialSize / 3.0;
		CGRect indicatorViewFrame = CGRectMake((frame.size.width / 2.0) - (indicatorWidth / 2.0), 0, indicatorWidth, 0);
		_indicatorView = [[UIView alloc] initWithFrame:indicatorViewFrame];
		_indicatorView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
		[_innerView addSubview:_indicatorView];
		
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
		
		UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_doubleTapRecognized:)];
		doubleTapRecognizer.delegate = self;
		doubleTapRecognizer.numberOfTapsRequired = 2;
		[self addGestureRecognizer:doubleTapRecognizer];

		UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapRecognized:)];
		singleTapRecognizer.delegate = self;
		singleTapRecognizer.numberOfTapsRequired = 1;
		[singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
		[self addGestureRecognizer:singleTapRecognizer];
	}
	
	return self;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

#pragma mark - UIView

- (void)touchesBegan:(nonnull NSSet *)touches withEvent:(nullable UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	[self.superview bringSubviewToFront:self];
}

@end
