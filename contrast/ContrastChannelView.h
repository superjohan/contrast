//
//  ContrastChannelView.h
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ContrastChannelViewDelegate;

@interface ContrastChannelView : UIView

@property (nonatomic) BOOL silent;

// TODO: Convert to Swift struct.
+ (UIColor *)outlineColor;
+ (UIColor *)fullColor;
+ (UIColor *)silentColor;
+ (UIColor *)cyanColor;
+ (UIColor *)magentaColor;

- (instancetype)initWithCenter:(CGPoint)center delegate:(id<ContrastChannelViewDelegate>)delegate;

@end

@protocol ContrastChannelViewDelegate <NSObject>

@required
- (void)channelView:(ContrastChannelView *)channelView updatedWithPosition:(CGPoint)position scale:(CGFloat)scale rotation:(CGFloat)rotation;
- (void)channelViewReceivedTap:(ContrastChannelView *)channelView;
- (void)channelViewReceivedDoubleTap:(ContrastChannelView *)channelView;

@end
