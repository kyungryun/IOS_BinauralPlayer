//
//  STAMutableAudioMixInputParameters.h
//  
//
//  Created by sonic on 2018. 5. 4..
//

#import <AVFoundation/AVFoundation.h>
typedef void (^myBlockType)(MTAudioProcessingTapRef tap, CMItemCount numberFrames,
                            MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut,
                            CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut);
@interface STAMutableAudioMixInputParameters : AVMutableAudioMixInputParameters
-(void)connectCallbacks;
-(void)setProcessingBlock:(myBlockType)block;
-(void)setAngle:(int)angleValue Elevation:(int)elevalue;
-(int)changeMode;
 @end
