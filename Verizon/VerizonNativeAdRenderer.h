#import "MPStaticNativeAdRenderer.h"

@interface VerizonNativeAdRenderer : NSObject <MPNativeAdRendererSettings>

+ (MPNativeAdRendererConfiguration *)rendererConfigurationWithRendererSettings:(id<MPNativeAdRendererSettings>)rendererSettings;

@end
