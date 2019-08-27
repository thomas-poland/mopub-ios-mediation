#import "VASNativeAdAdapter.h"
#import "MPNativeAdConstants.h"
#import "MPLogging.h"

NSString * const kVASDisclaimerKey = @"vasdisclaimer";
NSString * const kVASVideoViewKey = @"vasvideoview";

static NSString * const kTitleCompId        = @"title";
static NSString * const kBodyCompId         = @"body";
static NSString * const kCTACompId          = @"callToAction";
static NSString * const kRatingCompId       = @"rating";
static NSString * const kDisclaimerCompId   = @"disclaimer";
static NSString * const kMainImageCompId    = @"mainImage";
static NSString * const kIconImageCompId    = @"iconImage";
static NSString * const kVideoCompId        = @"video";

@interface VASNativeAdAdapter()
@property (nonatomic, strong) NSString *siteId;
@property (nonatomic, strong) VASNativeAd *vasNativeAd;
@property (nonatomic, strong) NSDictionary<NSString *, id> *vasAdProperties;
@end

@implementation VASNativeAdAdapter

- (instancetype)initWithVASNativeAd:(VASNativeAd *)vasNativeAd siteId:(NSString *)siteId
{
    if (self = [super init])
    {
        _siteId = siteId;
        _vasNativeAd = vasNativeAd;
        
        // MoPub Native Properties
        NSMutableDictionary<NSString *, id> *properties = [NSMutableDictionary dictionary];
        
        VASTextView *titleView = [vasNativeAd text:kTitleCompId];
        if (titleView.text) {
            properties[kAdTitleKey] = titleView.text;
        }
        
        VASTextView *bodyView = [vasNativeAd text:kBodyCompId];
        if (bodyView.text) {
            properties[kAdTextKey] = bodyView.text;
        }
        
        VASTextView *ctaView = [vasNativeAd text:kCTACompId];
        if (ctaView.text) {
            properties[kAdCTATextKey] = ctaView.text;
        }
        
        VASTextView *ratingView = [vasNativeAd text:kRatingCompId];
        if (ratingView.text) {
            properties[kAdStarRatingKey] = @(ratingView.text.integerValue);
        }
        
        VASDisplayMediaView *mainImageView = [vasNativeAd displayMedia:kMainImageCompId];
        if (mainImageView) {
            properties[kAdMainMediaViewKey] = mainImageView;
        }
        
        VASDisplayMediaView *iconImageView = [vasNativeAd displayMedia:kIconImageCompId];
        if (iconImageView) {
            properties[kAdIconImageViewKey] = iconImageView;
        }
        
        // Verizon Native Properties
        
        VASDisplayMediaView *videoView = [vasNativeAd displayMedia:kVideoCompId];
        if (videoView) {
            properties[kVASVideoViewKey] = videoView;
        }
        
        VASTextView *disclaimerView = [vasNativeAd text:kDisclaimerCompId];
        if (disclaimerView.text) {
            properties[kVASDisclaimerKey] = disclaimerView.text;
        }
        
        _vasAdProperties = properties;
    }
    return self;
}

-(void)dealloc
{
    MPLogTrace(@"Deallocating %@.", self);
}

#pragma mark - MPNativeAdAdapter

- (NSDictionary *)properties
{
    return self.vasAdProperties;
}

- (NSURL *)defaultActionURL
{
    return nil;
}

- (UIView *)mainMediaView
{
    return self.vasAdProperties[kAdMainMediaViewKey];
}

- (UIView *)iconMediaView
{
    return self.vasAdProperties[kAdIconImageViewKey];
}

#pragma mark - Impression and Click Tracking

- (void)willAttachToView:(UIView *)view
{
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], self.siteId);
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], self.siteId);
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], self.siteId);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], self.siteId);
    
    [self.delegate nativeAdWillLogImpression:self];
    [self.vasNativeAd fireImpression];
}

#pragma mark - VASNativeAdDelegate

- (void)nativeAdClickedWithComponentBundle:(nonnull id<VASNativeComponentBundle>)nativeComponentBundle
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            if ([self.delegate respondsToSelector:@selector(nativeAdDidClick:)]) {
                MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.siteId);
                [strongSelf.delegate nativeAdDidClick:strongSelf];
            }
            
            [strongSelf.delegate nativeAdWillPresentModalForAdapter:self];
        }
    });
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
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            [strongSelf.delegate nativeAdWillLeaveApplicationFromAdapter:strongSelf];
        }
    });
}

- (void)nativeAdEvent:(nonnull VASNativeAd *)nativeAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments
{
    MPLogTrace(@"VAS nativeAdEvent: %@, source: %@, eventId: %@, arguments: %@", nativeAd, source, eventId, arguments);
}

- (nullable UIViewController *)nativeAdPresentingViewController
{
    MPLogTrace(@"VAS native ad presenting VC requested.");
    return [self.delegate viewControllerForPresentingModalView];
}

@end
