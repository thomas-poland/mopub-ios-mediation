#import "MPStaticNativeAdRenderer+MPVerizonNativeCustomEvent.h"
#import "MPNativeAdRendererConfiguration.h"
#import <VerizonAdsSupport/VerizonAdsSupport.h>

// TODO: MoPub must add MPVerizonNativeCustomEvent to MPStaticNativeAdRenderer because their MPStaticNativeAdRenderer class is discovered and used even if we provide our own custom MPNativeAdRenderer class.

SUPPRESS_CATEGORY_ALSO_IMPLEMENTING_WARNINGS

@implementation MPStaticNativeAdRenderer(MPVerizonNativeCustomEvent)

+ (MPNativeAdRendererConfiguration *)rendererConfigurationWithRendererSettings:(id<MPNativeAdRendererSettings>)rendererSettings
{
    MPNativeAdRendererConfiguration *config = [[MPNativeAdRendererConfiguration alloc] init];
    config.rendererClass = [self class];
    config.rendererSettings = rendererSettings;
    config.supportedCustomEvents = @[@"MPMoPubNativeCustomEvent", @"FacebookNativeCustomEvent", @"MillennialNativeCustomEvent", @"MPVerizonNativeCustomEvent"];
    
    return config;
}

@end

RESTORE_CATEGORY_ALSO_IMPLEMENTING_WARNINGS
