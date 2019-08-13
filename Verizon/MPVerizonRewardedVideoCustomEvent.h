#import "MPRewardedVideoCustomEvent.h"
#import "MoPub.h"

@class VASCreativeInfo;

@interface MPVerizonRewardedVideoCustomEvent : MPRewardedVideoCustomEvent

@property (nonatomic, readonly, nullable) VASCreativeInfo* creativeInfo;

@end
