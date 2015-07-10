//
//  ContrastChannelController.m
//  contrast
//
//  Created by Johan Halin on 9.7.2015.
//  Copyright © 2015 Aero Deko. All rights reserved.
//

#import "ContrastChannelController.h"
#import "ContrastChannel.h"

#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

static const NSInteger ContrastChannelAmount = 8;

@interface ContrastChannelController ()
@property (nonatomic) AEAudioController *audioController;
@property (nonatomic) NSArray<ContrastChannel *> *channels;
@end

@implementation ContrastChannelController

#pragma mark - Public

- (void)addView:(ContrastChannelView *)channelView
{
	for (ContrastChannel *channel in self.channels)
	{
		if (channel.view == nil)
		{
			channel.view = channelView;
			
			return;
		}
	}
}

- (void)removeView:(ContrastChannelView *)channelView
{
	for (ContrastChannel *channel in self.channels)
	{
		if (channel.view == channelView)
		{
			channel.view = nil;
			
			return;
		}
	}
}

- (void)updateChannelWithView:(ContrastChannelView *)channelView
			frequencyPosition:(float)frequencyPosition
					   volume:(float)volume
				 effectAmount:(float)effectAmount
{
	ContrastChannel *channel = nil;
	
	for (ContrastChannel *chan in self.channels)
	{
		if (chan.view == channelView)
		{
			channel = chan;
			
			break;
		}
	}
	
	channel.frequencyPosition = frequencyPosition;
	channel.volume = volume;
	channel.reverbAmount = effectAmount;
}

- (instancetype)init
{
	if ((self = [super init]))
	{
		_audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]];
		_audioController.preferredBufferDuration = 0.025;
		
		NSMutableArray *channels = [NSMutableArray array];
		for (NSInteger i = 0; i < ContrastChannelAmount; i++)
		{
			AudioComponentDescription reverbComponent = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Effect, kAudioUnitSubType_Reverb2);
			NSError *reverbError = nil;
			AEAudioUnitFilter *reverb = [[AEAudioUnitFilter alloc] initWithComponentDescription:reverbComponent audioController:self.audioController error:&reverbError];
			if (reverb == nil)
			{
				NSLog(@"Error creating reverb: %@", reverbError);
				
				return nil;
			}

			ContrastChannel *channel = [[ContrastChannel alloc] initWithSampleRate:_audioController.audioDescription.mSampleRate reverbEffect:reverb];
			
			[channels addObject:channel];
		}
		
		[_audioController addChannels:channels];

		for (ContrastChannel *channel in channels)
		{
			[_audioController addFilter:channel.reverbEffect toChannel:channel];
		}
		
		_channels = [NSArray arrayWithArray:channels];
		
		NSError *error = nil;
		if ([_audioController start:&error] == NO)
		{
			NSLog(@"%@", error);
			
			return nil;
		}
	}
	
	return self;
}

@end
