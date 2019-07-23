///
///  @file
///  @brief Implementation for VASNativeCustomEvent
///
///  @copyright Copyright © 2019 Verizon. All rights reserved.
///

#import "VASNativeCustomEvent.h"
#import "VASNativeAdAdapter.h"
#import "MPNativeAdError.h"
#import "MPLogging.h"
#import "VASAdapterVersion.h"

static NSString *const kMoPubVASAdapterAdUnit = @"adUnitID";
static NSString *const kMoPubVASAdapterDCN = @"dcn";

@interface VASNativeCustomEvent() <VASNativeAdDelegate>

@property (nonatomic, strong) VASNativeAd *nativeAd;

@end

@implementation VASNativeCustomEvent

- (id)init {
    if (self = [super init]) {
        if([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
            MPLogInfo(@"VAS adapter version: %@", kVASAdapterVersion);
            VASSDK *vasSDK = [VASSDK sharedInstance];
            if(![vasSDK isInitialized]) {
                VASAppSettings *appSettings = [[VASAppSettings alloc] init];
                [vasSDK initializeWithSettings:appSettings withUserSettings:nil];
            }
        }
    }
    return self;
}

-(void) dealloc {
    self.nativeAd.delegate = nil;
}

-(void)requestAdWithCustomEventInfo:(NSDictionary *)info {
    __strong __typeof__(self.delegate) delegate = self.delegate;
    VASSDK *vasSDK = [VASSDK sharedInstance];
    
    if (![vasSDK isInitialized]) {
        NSError *error = [NSError errorWithDomain:VASSDKErrorDomain
                                             code:VASSDKErrorNotInitialized
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"VAS adapter not properly intialized yet."]
                                                    }];
        MPLogError(@"%@", [error localizedDescription]);
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    MPLogDebug(@"Requesting VAS native ad with event info %@.", info);

    NSString *placementId = info[kMoPubVASAdapterAdUnit];
    if (!placementId) {
        NSError *error = [NSError errorWithDomain:VASSDKErrorDomain
                                             code:VASSDKErrorServerResponseNoContent
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"VAS received no placement ID. Request failed."]
                                                    }];
        MPLogError(@"%@", [error localizedDescription]);
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    [vasSDK appSettings].mediator = kVASAdapterVersion;
    if (info[kMoPubVASAdapterDCN]) {
        vasSDK.appSettings.siteId = info[kMoPubVASAdapterDCN];
    } else {
        vasSDK.appSettings.siteId = nil;
    }
    
    self.nativeAd = [[VASNativeAd alloc] initWithPlacementId:placementId supportedTypes:@[VASNativeAdTypeInline]];
    self.nativeAd.delegate = self;
    [self.nativeAd load:nil];
}

-(VASCreativeInfo*)creativeInfo
{
    return self.nativeAd.creativeInfo;
}

-(NSString*)version
{
    return kVASAdapterVersion;
}

#pragma mark - VASNativeAdDelegate

- (UIViewController *)viewControllerForPresentingModalView {
    return [UIApplication sharedApplication].delegate.window.rootViewController;
}

- (void)nativeAdRequestDidSucceed:(VASNativeAd *)ad {
    MPLogDebug(@"VAS native ad loaded, creative ID %@", self.creativeInfo.creativeId);
    VASNativeAdAdapter *adapter = [[VASNativeAdAdapter alloc] initWithVASNativeAd:self.nativeAd];
    MPNativeAd *mpNativeAd = [[MPNativeAd alloc] initWithAdAdapter:adapter];
    [self.delegate nativeCustomEvent:self didLoadAd:mpNativeAd];
}

- (void)nativeAd:(VASNativeAd *)ad requestDidFailWithError:(NSError *)error {
    MPLogWarn(@"VAS native ad did fail loading with error: %@.", error);
    [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:MPNativeAdNSErrorForNoInventory()];
}

@end
