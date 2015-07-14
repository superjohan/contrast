//
//  ContrastChannel.m
//  contrast
//
//  Created by Johan Halin on 9.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastChannel.h"
#import "ContrastChannelView.h"

#define PI2   6.28318530717f // pi * 2
#define PI2_I 0.15915494309f // 1 / (pi * 2)
#define I_64K 0.000015259f // 1 / 65535

static const float ContrastChannelFrequencyMinimum = 40.0f;
static const float ContrastChannelFrequencyMaximum = 3000.0f;
static const int ContrastMaxTickCount = 64;
static const int ContrastPhaseCount = 6;
static const int ContrastPhases[ContrastPhaseCount] = { 0, 16, 8, 4, 2, -1 };
static const int ContrastSineTableSize = 16384;
static const int ContrastNoiseTableSize = 32768;

@interface ContrastChannel ()
@property (nonatomic) AEAudioUnitFilter *reverbEffect;
@end

@implementation ContrastChannel
{
	float sampleRate;
	float invertedSampleRate;
	float angle;
	float previousActive;
	float previousVolume;
	float previousPan;
	float previousFrequency;
	float *sineTable;
	float *noiseTable;
	int tickLength;
	int tickCounter;
	int tickCount;
	int phase;
	int noiseCounter;
	BOOL silent;
	BOOL isPreviousRandomSoundActive;
}

#pragma mark - AEAudioPlayable

static inline float getFrequencyFromPosition(float frequencyPosition)
{
	return ContrastChannelFrequencyMinimum + ((ContrastChannelFrequencyMaximum - ContrastChannelFrequencyMinimum) * convertToNonLinear(frequencyPosition));
}

static inline float convertToNonLinear(float value)
{
	return (value * value); // *shrug* you're not my dad
}

static inline void processTick(ContrastChannel *this, BOOL active)
{
	this->tickCounter++;
	if (this->tickCounter > this->tickLength)
	{
		this->tickCounter = 0;
		
		if (active)
		{
			this->tickCount++;
			
			int phaseCount = ContrastPhases[this->phase];
			BOOL isInitialPhase = (phaseCount == 0);
			BOOL isBelowHalfPhase = (this->tickCount % phaseCount) < (phaseCount / 2);

			BOOL eligibleForRandomizedSound = (phaseCount == -1) && arc4random_uniform(2) == 0;
			BOOL shouldTriggerRandomizedSound = this->tickCount % 2 == 0 || (this->tickCount % 1 == 0 && this->isPreviousRandomSoundActive);
			BOOL isRandomizedSoundActive = eligibleForRandomizedSound && shouldTriggerRandomizedSound;
			this->isPreviousRandomSoundActive = isRandomizedSoundActive;

			BOOL shouldPlaySound = isInitialPhase || isBelowHalfPhase || isRandomizedSoundActive;
			
			if (shouldPlaySound)
			{
				this->silent = NO;
				
				dispatch_async(dispatch_get_main_queue(), ^{
					if (this->_view != nil) {
						this->_view.silent = NO;
					}
				});
			}
			else
			{
				this->silent = YES;
				
				dispatch_async(dispatch_get_main_queue(), ^{
					if (this->_view != nil) {
						this->_view.silent = YES;
					}
				});
			}
			
			if (this->tickCount >= ContrastMaxTickCount)
			{
				this->tickCount = 0;
			}
		}
	}
}

static OSStatus renderCallback(ContrastChannel *this, AEAudioController *audioController, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
{
	BOOL active = (this->_view != nil);

	float startFrequency = getFrequencyFromPosition(this->_frequencyPosition);
	float previousFrequency = this->previousFrequency;
	BOOL frequencyChanged = (startFrequency != previousFrequency) && active;
	float frequency = startFrequency;
	
	BOOL shouldFadeOut = (active == NO && this->previousActive == YES);
	float startVolume = convertToNonLinear(this->_volume);
	float volume = startVolume;
	float previousVolume = this->previousVolume;
	BOOL volumeChanged = (volume != previousVolume);
	
	float panPosition = this->_panPosition;
	float previousPan = this->previousPan;
	BOOL panChanged = (panPosition != previousPan);
	float pan = panPosition;
	
	BOOL interpolating = frequencyChanged || shouldFadeOut || volumeChanged || panChanged;
	
	NSInteger interpolationMax = frames / 2;

	for (NSInteger i = 0; i < frames; i++)
	{
		processTick(this, active);
		
		float sample;
		
		if (this->silent == NO)
		{
			if (i < interpolationMax)
			{
				float interpolationPosition = (float)i / (float)interpolationMax;
				
				if (frequencyChanged)
				{
					frequency = previousFrequency + ((startFrequency - previousFrequency) * interpolationPosition);
				}
				
				if (shouldFadeOut)
				{
					volume = (startVolume * (1.0f - interpolationPosition));
				}
				else if (volumeChanged)
				{
					volume = previousVolume + ((startVolume - previousVolume) * interpolationPosition);
				}
				
				if (panChanged)
				{
					pan = previousPan + ((panPosition - previousPan) * interpolationPosition);
				}
			}
			else
			{
				interpolating = NO;
			}
			
			if (active || interpolating)
			{
				float angle = this->angle + (PI2 * frequency * this->invertedSampleRate);
				angle = fmodf(angle, PI2);
				int index = (int)(ContrastSineTableSize * (angle * PI2_I));
				float sine = this->sineTable[index];
				this->angle = angle;
				
				float noise = convertToNonLinear(this->noiseTable[this->noiseCounter] * this->_noiseAmount);
				this->noiseCounter++;
				if (this->noiseCounter >= ContrastNoiseTableSize)
				{
					this->noiseCounter = 0;
				}
				
				sample = (sine + noise) * volume;
			}
			else
			{
				sample = 0;
			}
		}
		else
		{
			sample = 0;
		}
		
		sample = clamp(sample, -1.0f, 1.0f);
		
		((float *)audio->mBuffers[0].mData)[i] = (pan >= 0) ? (sample * (1.0f - pan)) : sample;
		((float *)audio->mBuffers[1].mData)[i] = (pan < 0) ? (sample * (1.0f + pan)) : sample;
	}
	
	this->previousActive = active;
	this->previousVolume = startVolume;
	this->previousPan = panPosition;
	this->previousFrequency = frequency;
	
	return noErr;
}

static inline float clamp(float value, float min, float max)
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

static float* generateSineTable(int size)
{
	float *sineTable = malloc(sizeof(float) * size);
	
	for (int i = 0; i < size; i++)
	{
		sineTable[i] = sinf((i / (float)size) * PI2);
	}
	
	return sineTable;
}

static float* generateNoiseTable(int size)
{
	float *noiseTable = malloc(sizeof(float) * size);
	
	for (int i = 0; i < size; i++)
	{
		noiseTable[i] = ((float)(arc4random_uniform(131070) * I_64K) - 1.0f);
	}
	
	return noiseTable;
}

#pragma mark - Properties

- (AEAudioUnitFilter *)reverbEffect
{
	return _reverbEffect;
}

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

- (void)setReverbAmount:(float)reverbAmount
{
	@synchronized(self)
	{
		_reverbAmount = clamp(reverbAmount, 0, 1);

		NSInteger amount = self.reverbAmount * 100;
		
		AudioUnitSetParameter(self.reverbEffect.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, amount, 0);
	}
}

- (void)setNoiseAmount:(float)noiseAmount
{
	@synchronized(self)
	{
		_noiseAmount = clamp(noiseAmount, 0, 1);
	}
}

- (void)setPanPosition:(float)panPosition
{
	@synchronized(self)
	{
		_panPosition = clamp(panPosition, -1, 1);
	}
}

#pragma mark - Public

- (instancetype)initWithSampleRate:(float)aSampleRate reverbEffect:(AEAudioUnitFilter *)reverbEffect
{
	if ((self = [super init]))
	{
		self->sampleRate = aSampleRate;
		self->invertedSampleRate = 1.0f / aSampleRate;
		self->angle = 0;
		self->_frequencyPosition = 0.5f;
		self->_volume = 0.5f;
		self->previousActive = NO;
		self->previousVolume = 0.25f; // ugh.. this has to be set so that a volume change isn't triggered on start, and this is obviously the converted volume value :/
		self->_noiseAmount = 0;
		self->tickLength = aSampleRate * 0.05f;
		self->phase = 0;
		self->sineTable = generateSineTable(ContrastSineTableSize);
		self->noiseTable = generateNoiseTable(ContrastNoiseTableSize);
		
		AudioUnitSetParameter(reverbEffect.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, 0, 0);
		AudioUnitSetParameter(reverbEffect.audioUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, 3.0, 0);
		AudioUnitSetParameter(reverbEffect.audioUnit, kReverb2Param_DecayTimeAtNyquist, kAudioUnitScope_Global, 0, 3.0, 0);
		
		_reverbEffect = reverbEffect;
	}
	
	return self;
}

- (void)incrementPhase
{
	@synchronized(self)
	{
		self->phase++;
		
		if (self->phase >= ContrastPhaseCount)
		{
			self->phase = 0;
			self->tickCount = 0;
		}
	}
}

- (void)resetToDefaults
{
	self->phase = 0;
}

- (void)dealloc
{
	free(self->sineTable);
	free(self->noiseTable);
}

@end
