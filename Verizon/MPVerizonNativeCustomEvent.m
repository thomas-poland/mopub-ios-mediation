#import "MPVerizonNativeCustomEvent.h"
#import "MPNativeAdError.h"
#import "MPLogging.h"
#import "VASNativeAdAdapter.h"
#import "VASAdapterVersion.h"
#import "VerizonBidCache.h"
#import "VerizonAdapterConfiguration.h"
#import <VerizonAdsNativePlacement/VerizonAdsNativePlacement.h>
#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>

@interface MPVerizonNativeCustomEvent() <VASNativeAdFactoryDelegate, VASNativeAdDelegate>
@property (nonatomic, strong) VASNativeAdFactory *nativeAdFactory;
@property (nonatomic, strong) MPNativeAd *mpNativeAd;
@property (nonatomic, assign) BOOL didTrackClick;
@end

#pragma mark - MPVerizonNativeCustomEvent

@implementation MPVerizonNativeCustomEvent

- (id)init
{
    if ([[UIDevice currentDevice] systemVersion].floatValue < 8.0)
    {
        return nil;
    }
    return self = [super init];
}

-(void)dealloc
{
    MPLogTrace(@"Deallocating %@.", self);
}

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info
{
    MPLogDebug(@"Requesting VAS native with event info %@.", info);

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
                                                  code:MoPubVASAdapterErrorInvalidConfig
                                                   who:kMoPubVASAdapterErrorWho
                                           description:[NSString stringWithFormat:@"Invalid configuration while initializing [%@]", NSStringFromClass([self class])]
                                            underlying:nil];
        MPLogError(@"%@", [error localizedDescription]);
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    if (![VASAds sharedInstance].initialized &&
        ![VASStandardEdition initializeWithSiteId:siteId])
     {
        NSError *error = [VASErrorInfo errorWithDomain:kMoPubVASAdapterErrorDomain
                                                  code:MoPubVASAdapterErrorNotInitialized
                                                   who:kMoPubVASAdapterErrorWho
                                           description:[NSString stringWithFormat:@"VAS adapter not properly intialized yet."]
                                            underlying:nil];
        MPLogError(@"%@", [error localizedDescription]);
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    [VASAds sharedInstance].locationEnabled = [MoPub sharedInstance].locationUpdatesEnabled;
    
    VASRequestMetadataBuilder *metaDataBuilder = [[VASRequestMetadataBuilder alloc] init];
    [metaDataBuilder setAppMediator:VerizonAdapterConfiguration.appMediator];
    self.nativeAdFactory = [[VASNativeAdFactory alloc] initWithPlacementId:placementId adTypes:@[@"inline"] vasAds:[VASAds sharedInstance] delegate:self];
    [self.nativeAdFactory setRequestMetadata:metaDataBuilder.build];
    
    // NOTE: The factory delegate assignment to self is temporary until the VASNativeAdAdapter is created and reassigns it
    VASBid *bid = [VerizonBidCache.sharedInstance bidForPlacementId:placementId];
    if (bid)
    {
        [self.nativeAdFactory loadBid:bid nativeAdDelegate:self];
    } else {
        [self.nativeAdFactory load:self];
    }
}

- (NSString *)version
{
    return kVASAdapterVersion;
}

#pragma mark - VASInlineAdFactoryDelegate

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory cacheLoadedNumRequested:(NSUInteger)numRequested numReceived:(NSUInteger)numReceived
{
    MPLogDebug(@"VAS native factory cache loaded with requested: %lu", (unsigned long)numRequested);
}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSUInteger)cacheSize
{
    MPLogDebug(@"VAS native factory cache updated with size: %lu", (unsigned long)cacheSize);
}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory didFailWithError:(nullable VASErrorInfo *)errorInfo
{
    MPLogWarn(@"VAS native factory load failed with error %@.", errorInfo.description);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:errorInfo];
    });
}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory didLoadNativeAd:(nonnull VASNativeAd *)nativeAd
{
    MPLogDebug(@"VAS native factory did load %@, creativeId %@.", nativeAd, nativeAd.creativeInfo.creativeId);
    dispatch_async(dispatch_get_main_queue(), ^{
        VASNativeAdAdapter *adapter = [[VASNativeAdAdapter alloc] initWithVASNativeAd:nativeAd];
        nativeAd.delegate = adapter; // reassign the ad delegate to the adapter
        self.mpNativeAd = [[MPNativeAd alloc] initWithAdAdapter:adapter];
        [self.delegate nativeCustomEvent:self didLoadAd:self.mpNativeAd];
    });
}

#pragma mark - VASNativeAdDelegate

- (void)nativeAdClickedWithComponentBundle:(nonnull id<VASNativeComponentBundle>)nativeComponentBundle
{
    MPLogDebug(@"VAS native ad clicked - %@.", nativeComponentBundle);
}

- (void)nativeAdDidClose:(nonnull VASNativeAd *)nativeAd
{
    MPLogDebug(@"VAS native ad closed - %@.", nativeAd);
}

- (void)nativeAdDidFail:(nonnull VASNativeAd *)nativeAd withError:(nonnull VASErrorInfo *)errorInfo
{
    MPLogWarn(@"VAS native ad failed with error %@.", errorInfo.description);
}

- (void)nativeAdDidLeaveApplication:(nonnull VASNativeAd *)nativeAd
{
    MPLogDebug(@"VAS native ad did leave application - %@.", nativeAd);
}

- (void)nativeAdEvent:(nonnull VASNativeAd *)nativeAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments
{
    MPLogTrace(@"VAS native ad event - %@, source %@, eventId %@, args %@.", nativeAd, source, eventId, arguments);
}

- (nullable UIViewController *)nativeAdPresentingViewController
{
    MPLogTrace(@"VAS native ad presenting VC requested.");
    return nil;
}

@end

@implementation MillennialNativeCustomEvent
@end
