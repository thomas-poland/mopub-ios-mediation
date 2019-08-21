#import <Foundation/Foundation.h>
#import <VerizonAdsNativePlacement/VerizonAdsNativePlacement.h>
#import "MoPub.h"

// <MPNativeAdRendering> custom asset properties.
extern NSString * const kVASDisclaimerKey;      // NSString *
extern NSString * const kVASVideoViewKey;       // NSString *

@interface VASNativeAdAdapter : NSObject <MPNativeAdAdapter, VASNativeAdDelegate>

@property (nonatomic, weak) id<MPNativeAdAdapterDelegate> delegate;

- (instancetype)initWithVASNativeAd:(VASNativeAd *)vasNativeAd siteId:(NSString *)siteId;

@end
