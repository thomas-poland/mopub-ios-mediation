#import "MPVerizonRewardedVideoCustomEvent.h"
#import "MPVerizonInterstitialCustomEvent.h"
#import "MPLogging.h"
#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>
#import <VerizonAdsInterstitialPlacement/VASInterstitialAd.h>
#import <VerizonAdsInterstitialPlacement/VASInterstitialAdFactory.h>
#import "VASAdapterVersion.h"
#import "MPVerizonErrors.h"
#import "VerizonAdapterConfiguration.h"

static NSString *const kMoPubVASAdapterAdUnit = @"adUnitID";
static NSString *const kMoPubVASAdapterDCN = @"dcn";
static NSString *const kMoPubVASAdapterVideoCompleteEventId = @"onVideoComplete";

@interface MPVerizonRewardedVideoCustomEvent () <VASInterstitialAdDelegate, VASInterstitialAdFactoryDelegate>
@property (nonatomic, assign) BOOL didTrackClick;
@property (nonatomic, assign) BOOL adReady;
@property (nonatomic, strong, nullable) VASInterstitialAdFactory *interstitialAdFactory;
@property (nonatomic, strong, nullable) VASInterstitialAd *interstitialAd;
@property (nonatomic, assign) BOOL isVideoCompletionEventCalled;
@end

@implementation MPVerizonRewardedVideoCustomEvent

- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO;
}

- (id)init
{
    if (self = [super init])
    {
        if ([[UIDevice currentDevice] systemVersion].floatValue < 8.0) {
            self = nil; // No support below minimum OS.
        }
    }
    return self;
}

- (void)requestRewardedVideoWithCustomEventInfo:(NSDictionary<NSString *, id> *)info {
    
    MPLogDebug(@"Requesting VAS rewarded video with event info %@.", info);

    self.adReady = NO;
    self.isVideoCompletionEventCalled = NO;

    __strong __typeof__(self.delegate) delegate = self.delegate;
    
    NSString *siteId = info[kMoPubVASAdapterSiteId];
    if (siteId.length == 0)
    {
        siteId = info[kMoPubMillennialAdapterSiteId];
    }
    NSString *placementId = info[kMoPubVASAdapterPlacementId];
    if (placementId.length == 0)
    {
        placementId = info[kMoPubMillennialAdapterPlacementId];
    }
    if (siteId.length == 0 || placementId.length == 0)
    {
        NSError *error = [VASErrorInfo errorWithDomain:kMoPubVASAdapterErrorDomain
                                                  code:VASCoreErrorAdFetchFailure
                                                   who:kMoPubVASAdapterErrorWho
                                           description:[NSString stringWithFormat:@"Error occurred while fetching content for requestor [%@]", NSStringFromClass([self class])]
                                            underlying:nil];
        MPLogError(@"%@", [error localizedDescription]);
        [delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
        return;
    }
    
    if (![VASAds sharedInstance].initialized &&
        ![VASStandardEdition initializeWithSiteId:siteId])
    {
        NSError *error = [VASErrorInfo errorWithDomain:kMoPubVASAdapterErrorDomain
                                                  code:VASCoreErrorAdFetchFailure
                                                   who:kMoPubVASAdapterErrorWho
                                           description:[NSString stringWithFormat:@"VAS adapter not properly intialized yet."]
                                            underlying:nil];
        MPLogError(@"%@", [error localizedDescription]);
        [delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
        return;
    }
    
    [VASAds sharedInstance].locationEnabled = [MoPub sharedInstance].locationUpdatesEnabled;
    
    VASRequestMetadataBuilder *metaDataBuilder = [[VASRequestMetadataBuilder alloc] init];
    [metaDataBuilder setAppMediator:VerizonAdapterConfiguration.appMediator];
    self.interstitialAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:placementId vasAds:[VASAds sharedInstance] delegate:self];
    [self.interstitialAdFactory setRequestMetadata:metaDataBuilder.build];
    
    [self.interstitialAdFactory load:self];
    
}

- (BOOL)hasAdAvailable
{
    return self.adReady;
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController
{
    [self.interstitialAd setImmersiveEnabled:YES];
    [self.interstitialAd showFromViewController:viewController];
}

- (void)handleCustomEventInvalidated
{
    [self.interstitialAd destroy];
    self.interstitialAd = nil;
    self.delegate = nil;
}

- (void)handleAdPlayedForCustomEventNetwork
{
    // If we no longer have an ad available, report back up to the application that this ad expired.
    if (![self hasAdAvailable]) {
        [self.delegate rewardedVideoDidExpireForCustomEvent:self];
    }
}

-(VASCreativeInfo*)creativeInfo
{
    return self.interstitialAd.creativeInfo;
}

-(NSString*)version
{
    return kVASAdapterVersion;
}


- (void)interstitialAdClicked:(nonnull VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate rewardedVideoDidReceiveTapEventForCustomEvent:self];
    });
    
}

- (void)interstitialAdDidClose:(nonnull VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
        [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
        self.interstitialAd = nil;
        self.delegate = nil;
    });

}

- (void)interstitialAdDidFail:(nonnull VASInterstitialAd *)interstitialAd withError:(nonnull VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate rewardedVideoDidFailToPlayForCustomEvent:self error:errorInfo];
    });
}

- (void)interstitialAdDidLeaveApplication:(nonnull VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate rewardedVideoWillLeaveApplicationForCustomEvent:self];
    });
}

- (void)interstitialAdDidShow:(nonnull VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate rewardedVideoWillAppearForCustomEvent:self];
        [self.delegate rewardedVideoDidAppearForCustomEvent:self];
    });

}

- (void)interstitialAdEvent:(nonnull VASInterstitialAd *)interstitialAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nullable NSDictionary<NSString *,id> *)arguments
{
    
    if ([eventId isEqualToString:kMoPubVASAdapterVideoCompleteEventId]
        && !self.isVideoCompletionEventCalled
        ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MPRewardedVideoReward *reward = [[MPRewardedVideoReward alloc] initWithCurrencyAmount:@1];
            [self.delegate rewardedVideoShouldRewardUserForCustomEvent:self reward:reward];
            self.isVideoCompletionEventCalled = YES;
        });
    }
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested numReceived:(NSInteger)numReceived
{
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSInteger)cacheSize
{
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory didFailWithError:(nonnull VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:errorInfo];
    });

}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory didLoadInterstitialAd:(nonnull VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = interstitialAd;
        self.adReady = YES;
        [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
    });
}

@end
