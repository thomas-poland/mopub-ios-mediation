#import "MPVerizonNativeCustomEvent.h"
#import "MPNativeAdError.h"
#import "MPLogging.h"
#import "VASNativeAdAdapter.h"
#import "VerizonBidCache.h"
#import "VerizonAdapterConfiguration.h"
#import <VerizonAdsNativePlacement/VerizonAdsNativePlacement.h>
#import <VerizonAdsStandardEdition/VerizonAdsStandardEdition.h>

@interface MPVerizonNativeCustomEvent() <VASNativeAdFactoryDelegate, VASNativeAdDelegate>
@property (nonatomic, strong) NSString *siteId;
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
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], self.siteId);
    
    MPLogDebug(@"Requesting VAS native with event info %@.", info);
    
    __strong __typeof__(self.delegate) delegate = self.delegate;
    
    self.siteId = info[kMoPubVASAdapterSiteId];
    if (self.siteId.length == 0)
    {
        self.siteId = info[kMoPubMillennialAdapterSiteId];
    }
    
    NSString *placementId = info[kMoPubVASAdapterPlacementId];
    if (placementId.length == 0)
    {
        placementId = info[kMoPubMillennialAdapterPlacementId];
    }
    
    if (self.siteId.length == 0 || placementId.length == 0)
    {
        NSError *error = [VASErrorInfo errorWithDomain:kMoPubVASAdapterErrorDomain
                                                  code:MoPubVASAdapterErrorInvalidConfig
                                                   who:kMoPubVASAdapterErrorWho
                                           description:[NSString stringWithFormat:@"Invalid configuration while initializing [%@]", NSStringFromClass([self class])]
                                            underlying:nil];
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], self.siteId);
        [delegate nativeCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    if (![VASAds sharedInstance].initialized &&
        ![VASStandardEdition initializeWithSiteId:self.siteId])
    {
        NSError *error = [VASErrorInfo errorWithDomain:kMoPubVASAdapterErrorDomain
                                                  code:MoPubVASAdapterErrorNotInitialized
                                                   who:kMoPubVASAdapterErrorWho
                                           description:[NSString stringWithFormat:@"VAS adapter not properly intialized yet."]
                                            underlying:nil];
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], self.siteId);
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
    return VerizonAdapterConfiguration.appMediator;
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
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:errorInfo], self.siteId);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:errorInfo];
    });
}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory didLoadNativeAd:(nonnull VASNativeAd *)nativeAd
{
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], self.siteId);
    dispatch_async(dispatch_get_main_queue(), ^{
        VASNativeAdAdapter *adapter = [[VASNativeAdAdapter alloc] initWithVASNativeAd:nativeAd siteId:self.siteId];
        nativeAd.delegate = adapter; // reassign the ad delegate to the adapter
        self.mpNativeAd = [[MPNativeAd alloc] initWithAdAdapter:adapter];
        [self.delegate nativeCustomEvent:self didLoadAd:self.mpNativeAd];
    });
}

#pragma mark - VASNativeAdDelegate

- (void)nativeAdClickedWithComponentBundle:(nonnull id<VASNativeComponentBundle>)nativeComponentBundle
{
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.siteId);
}

- (void)nativeAdDidClose:(nonnull VASNativeAd *)nativeAd
{
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], self.siteId);
}

- (void)nativeAdDidFail:(nonnull VASNativeAd *)nativeAd withError:(nonnull VASErrorInfo *)errorInfo
{
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:errorInfo], self.siteId);
}

- (void)nativeAdDidLeaveApplication:(nonnull VASNativeAd *)nativeAd
{
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], self.siteId);
}

- (void)nativeAdEvent:(nonnull VASNativeAd *)nativeAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments
{
    MPLogTrace(@"VAS nativeAdEvent: %@, source: %@, eventId: %@, arguments: %@", nativeAd, source, eventId, arguments);
}

- (nullable UIViewController *)nativeAdPresentingViewController
{
    MPLogTrace(@"VAS native ad presenting VC requested.");
    return nil;
}

@end

@implementation MillennialNativeCustomEvent
@end
