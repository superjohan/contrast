//
//  ContrastChannel.h
//  contrast
//
//  Created by Johan Halin on 9.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

@interface ContrastChannel : NSObject <AEAudioPlayable>

- (instancetype)initWithSampleRate:(float)sampleRate;

@end
