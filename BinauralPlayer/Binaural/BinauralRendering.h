//
//  BinauralRendering.h
//  BinauralPlayer
//
//  Created by kyungryun Choi on 2018. 6. 1..
//  Copyright © 2018년 kyungryun Choi. All rights reserved.
//

#ifndef BinauralRendering_h
#define BinauralRendering_h
#import <AVFoundation/AVFoundation.h>
#import <STA_Framework/STA_Framework.h>
#import <STA_Framework/STAMutableAudioMixInputParameters.h>
@import AudioToolbox;

@interface BinauralRendering : NSObject{
    STALibrary *lib;
    int16_t input[4096];
    int16_t outL[4096];
    int16_t outR[4096];
}
- (void)initDictionary;
- (void)setAudio : (NSURL *) URL;
- (void)setDictionary: (int) angle elev:(int)elev frameNumber:(int)frameNumber;
- (void)rendering;

@end

#endif /* BinauralRendering_h */
