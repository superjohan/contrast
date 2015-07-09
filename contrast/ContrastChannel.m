//
//  ContrastChannel.m
//  contrast
//
//  Created by Johan Halin on 9.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastChannel.h"

#define PI2 6.28318530717f // pi * 2

static const float ContrastChannelFrequencyMinimum = 100.0f;
static const float ContrastChannelFrequencyMaximum = 2000.0f;

@interface ContrastChannel ()
@end

@implementation ContrastChannel
{
	float sampleRate;
	float invertedSampleRate;
	float angle;
}

#pragma mark - AEAudioPlayable

static float getFrequencyFromPosition(float frequencyPosition)
{
	return ContrastChannelFrequencyMinimum + ((ContrastChannelFrequencyMaximum - ContrastChannelFrequencyMinimum) * frequencyPosition);
}

static float calculateVolume(float volume)
{
	return (volume * volume); // *shrug* you're not my dad
}

static OSStatus renderCallback(ContrastChannel *this, AEAudioController *audioController, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
{
	// TODO: Keep volume and active states in an ivar so that we can interpolate between changes.
	
	float frequency = getFrequencyFromPosition(this->_frequencyPosition);
	BOOL active = (this->_view != nil);
	float volume = calculateVolume(this->_volume);
	
	for (NSInteger i = 0; i < frames; i++)
	{
		float sample;
		
		if (active)
		{
			float angle = this->angle + (PI2 * frequency * this->invertedSampleRate);
			angle = fmodf(angle, PI2);
			this->angle = angle;
			
			sample = sin(angle) * volume;
		}
		else
		{
			sample = 0;
		}
		
		((float *)audio->mBuffers[0].mData)[i] = sample;
		((float *)audio->mBuffers[1].mData)[i] = sample;
	}
	
	return noErr;
}

static float clamp(float value, float min, float max)
{
	if (value < min)
	{
		value = min;
	}
	else if (value > max)
	{
		value = max;
	}
	
	return value;
}

- (AEAudioControllerRenderCallback)renderCallback
{
	return &renderCallback;
}

#pragma mark - Properties

- (void)setFrequencyPosition:(float)frequencyPosition
{
	@synchronized(self)
	{
		_frequencyPosition = clamp(frequencyPosition, 0, 1);
	}
}

- (void)setVolume:(float)volume
{
	@synchronized(self)
	{
		volume = clamp(volume, 0, 1);
		
		// the real volume is 0.1 .. 1. if you want silence, remove the dang channel
		_volume = 0.1f + (0.9f * volume);
	}
}

#pragma mark - Public

- (instancetype)initWithSampleRate:(float)aSampleRate
{
	if ((self = [super init]))
	{
		self->sampleRate = aSampleRate;
		self->invertedSampleRate = 1.0f / aSampleRate;
		self->angle = 0;
		self->_frequencyPosition = 0.5f;
		self->_volume = 0.5;
	}
	
	return self;
}

@end
