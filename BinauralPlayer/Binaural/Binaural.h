//
//  Binaural.h
//  BinauralPlayer
//
//  Created by kyungryun Choi on 2018. 6. 1..
//  Copyright © 2018년 kyungryun Choi. All rights reserved.
//

#ifndef Binaural_h
#define Binaural_h
#import "BinauralRendering.h"
#define CHANNEL_LEFT 0
#define CHANNEL_RIGHT 1
#define NUM_CHANNELS 2

@interface Binaural : NSObject{
}
- (void)setBinaural:(NSURL*)url audioAsset:(AVAssetTrack*)audioAsset;
- (void)modeBinaural;
- (void)setMode;
- (void)setAngle : (int) angle;
- (void)setElev : (int) elev;
- (void)renderingBinaural;
- (void)recordingBinaural;
- (void)setFrames : (Float64) frames;
- (STAMutableAudioMixInputParameters *)getAudioParameter;
- (void)setWriting;

@end

#endif /* Binaural_h */
