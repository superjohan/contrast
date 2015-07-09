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

- (instancetype)init
{
	if ((self = [super init]))
	{
		_audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]];
		_audioController.preferredBufferDuration = 0.025;
		
		NSMutableArray *channels = [NSMutableArray array];
		for (NSInteger i = 0; i < ContrastChannelAmount; i++)
		{
			ContrastChannel *channel = [[ContrastChannel alloc] initWithSampleRate:_audioController.audioDescription.mSampleRate];
			[channels addObject:channel];
		}
		
		[_audioController addChannels:channels];
		
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
