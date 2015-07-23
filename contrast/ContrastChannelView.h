//
//  ContrastChannelView.h
//  contrast
//
//  Created by Johan Halin on 6.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CONTRAST_COLOR_OUTLINE [UIColor colorWithRed:(253.0 / 255.0) green:(225.0 / 255.0) blue:(209.0 / 255.0) alpha:1.0]
#define CONTRAST_COLOR_FULL    [UIColor colorWithRed:(253.0 / 255.0) green:(225.0 / 255.0) blue:(209.0 / 255.0) alpha:0.75]
#define CONTRAST_COLOR_SILENT  [UIColor colorWithRed:(253.0 / 255.0) green:(225.0 / 255.0) blue:(209.0 / 255.0) alpha:0.25]
#define CONTRAST_COLOR_CYAN    [UIColor colorWithRed:(0 / 255.0) green:(158.0 / 255.0) blue:(226.0 / 255.0) alpha:1.0]
#define CONTRAST_COLOR_MAGENTA [UIColor colorWithRed:(229.0 / 255.0) green:(0 / 255.0) blue:(126.0 / 255.0) alpha:0.75]

@protocol ContrastChannelViewDelegate;

@interface ContrastChannelView : UIView

@property (nonatomic) BOOL silent;

- (instancetype)initWithCenter:(CGPoint)center delegate:(id<ContrastChannelViewDelegate>)delegate;

@end

@protocol ContrastChannelViewDelegate <NSObject>

@required
- (void)channelView:(ContrastChannelView *)channelView updatedWithPosition:(CGPoint)position scale:(CGFloat)scale rotation:(CGFloat)rotation;
- (void)channelViewReceivedTap:(ContrastChannelView *)channelView;
- (void)channelViewReceivedDoubleTap:(ContrastChannelView *)channelView;

@end
