//
//  ContrastChannel.m
//  contrast
//
//  Created by Johan Halin on 9.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastChannel.h"

@interface ContrastChannel () 
@property (nonatomic) float sampleRate;
@end

@implementation ContrastChannel

#pragma mark - AEAudioPlayable

static OSStatus renderCallback(ContrastChannel *this, AEAudioController *audioController, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
{
	for (NSInteger i = 0; i < frames; i++)
	{
		float sample = arc4random_uniform(100) / 1000.0;
		
		((float *)audio->mBuffers[0].mData)[i] = sample;
		((float *)audio->mBuffers[1].mData)[i] = sample;
	}
	
	return noErr;
}

- (AEAudioControllerRenderCallback)renderCallback
{
	return &renderCallback;
}

#pragma mark - Public

- (instancetype)initWithSampleRate:(float)sampleRate
{
	if ((self = [super init]))
	{
		_sampleRate = sampleRate;
	}
	
	return self;
}

@end
