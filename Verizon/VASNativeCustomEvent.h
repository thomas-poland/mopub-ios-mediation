///
///  @file
///  @brief Definitions for VASNativeCustomEvent
///
///  @copyright Copyright © 2019 Verizon. All rights reserved.
///

#import <Foundation/Foundation.h>

@interface VASNativeCustomEvent : MPNativeCustomEvent

@property (nonatomic, readonly) VASCreativeInfo* creativeInfo;
@property (nonatomic, readonly) NSString* version;

@end
