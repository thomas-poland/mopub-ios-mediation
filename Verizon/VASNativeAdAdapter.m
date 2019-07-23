#import "VASNativeAdAdapter.h"
#import "MPNativeAdConstants.h"

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
@property (nonatomic, strong) VASNativeAd *vasNativeAd;
@property (nonatomic, strong) NSDictionary<NSString *, id> *vasAdProperties;
@end

@implementation VASNativeAdAdapter

- (instancetype)initWithVASNativeAd:(VASNativeAd *)vasNativeAd
{
    if (self = [super init])
    {
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
    [self.delegate nativeAdWillLogImpression:self];
    [self.vasNativeAd fireImpression];
}

#pragma mark - VASNativeAdDelegate

- (void)nativeAdClickedWithComponentBundle:(nonnull id<VASNativeComponentBundle>)nativeComponentBundle
{
    MPLogDebug(@"VAS native ad clicked - %@.", nativeComponentBundle);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate nativeAdDidClick:self];
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate nativeAdWillLeaveApplicationFromAdapter:self];
    });
}

- (void)nativeAdEvent:(nonnull VASNativeAd *)nativeAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments
{
    MPLogTrace(@"VAS native ad event - %@, source %@, eventId %@, args %@.", nativeAd, source, eventId, arguments);
}

- (nullable UIViewController *)nativeAdPresentingViewController
{
    MPLogTrace(@"VAS native ad presenting VC requested.");
    return [self.delegate viewControllerForPresentingModalView];
}

@end
