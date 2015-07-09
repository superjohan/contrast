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

- (instancetype)initWithCenter:(CGPoint)center delegate:(id<ContrastChannelViewDelegate>)delegate;

@end

@protocol ContrastChannelViewDelegate <NSObject>

@required
- (void)channelView:(ContrastChannelView *)channelView updatedWithPosition:(CGPoint)position scale:(CGFloat)scale rotation:(CGFloat)rotation;

@end
