#import "Header.h"

// Tweak's bundle for Localizations support - @PoomSmart - https://github.com/PoomSmart/YouPiP/commit/aea2473f64c75d73cab713e1e2d5d0a77675024f
NSBundle *uYouPlusBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
 	dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"uYouPlus" ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/Application Support/uYouPlus.bundle")];
    });
    return bundle;
}
NSBundle *tweakBundle = uYouPlusBundle();

//
static BOOL IsEnabled(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}
static BOOL isDarkMode() {
    return ([[NSUserDefaults standardUserDefaults] integerForKey:@"page_style"] == 1);
}
static BOOL oledDarkTheme() {
    return ([[NSUserDefaults standardUserDefaults] integerForKey:@"appTheme"] == 1);
}
static BOOL oldDarkTheme() {
    return ([[NSUserDefaults standardUserDefaults] integerForKey:@"appTheme"] == 2);
}

//
# pragma mark - uYou's patches
// Workaround for qnblackcat/uYouPlus#10
%hook UIViewController
- (UITraitCollection *)traitCollection {
    @try {
        return %orig;
    } @catch(NSException *e) {
        return [UITraitCollection currentTraitCollection];
    }
}
%end

// Prevent uYou player bar from showing when not playing downloaded media
%hook PlayerManager
- (void)pause {
    if (isnan([self progress]))
        return;
    %orig;
}
%end

// Workaround for issue #54
%hook YTMainAppVideoPlayerOverlayViewController
- (void)updateRelatedVideos {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"relatedVideosAtTheEndOfYTVideos"] == NO) {}
    else { return %orig; }
}
%end

// iOS 16 uYou crash fix - @level3tjg: https://github.com/qnblackcat/uYouPlus/pull/224
%group iOS16
%hook OBPrivacyLinkButton
%new
- (instancetype)initWithCaption:(NSString *)caption
                     buttonText:(NSString *)buttonText
                          image:(UIImage *)image
                      imageSize:(CGSize)imageSize
                   useLargeIcon:(BOOL)useLargeIcon {
  return [self initWithCaption:caption
                    buttonText:buttonText
                         image:image
                     imageSize:imageSize
                  useLargeIcon:useLargeIcon
               displayLanguage:[NSLocale currentLocale].languageCode];
}
%end
%end

%hook YTAppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    BOOL didFinishLaunching = %orig;

    if (IsEnabled(@"flex_enabled")) {
        [[%c(FLEXManager) performSelector:@selector(sharedManager)] performSelector:@selector(showExplorer)];
    }

    return didFinishLaunching;
}
- (void)appWillResignActive:(id)arg1 {
    %orig;
    if (IsEnabled(@"flex_enabled")) {
        [[%c(FLEXManager) performSelector:@selector(sharedManager)] performSelector:@selector(showExplorer)];
    }
}
%end

# pragma mark - YouTube's patches
// Workaround for MiRO92/uYou-for-YouTube#12, qnblackcat/uYouPlus#263
%hook YTDataUtils
+ (NSMutableDictionary *)spamSignalsDictionary {
    return nil;
}
%end

%hook YTHotConfig
- (BOOL)disableAfmaIdfaCollection { return NO; }
%end

// https://github.com/PoomSmart/YouTube-X/blob/1e62b68e9027fcb849a75f54a402a530385f2a51/Tweak.x#L27
// %hook YTAdsInnerTubeContextDecorator
// - (void)decorateContext:(id)context {}
// %end

// Hide YouTube annoying banner in Home page? - @MiRO92 - YTNoShorts: https://github.com/MiRO92/YTNoShorts
%hook YTAsyncCollectionView
- (id)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = %orig;
    if ([cell isKindOfClass:NSClassFromString(@"_ASCollectionViewCell")]) {
        _ASCollectionViewCell *cell = %orig;
        if ([cell respondsToSelector:@selector(node)]) {
            if ([[[cell node] accessibilityIdentifier] isEqualToString:@"statement_banner.view"]) { [self removeShortsAndFeaturesAdsAtIndexPath:indexPath]; }
            if ([[[cell node] accessibilityIdentifier] isEqualToString:@"compact.view"]) { [self removeShortsAndFeaturesAdsAtIndexPath:indexPath]; }
            // if ([[[cell node] accessibilityIdentifier] isEqualToString:@"id.ui.video_metadata_carousel"]) { [self removeShortsAndFeaturesAdsAtIndexPath:indexPath]; }
        }
    }
    return %orig;
}
%new
- (void)removeShortsAndFeaturesAdsAtIndexPath:(NSIndexPath *)indexPath {
        [self deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
}
%end

# pragma mark - Tweaks
// IAmYouTube - https://github.com/PoomSmart/IAmYouTube/
%hook YTVersionUtils
+ (NSString *)appName { return YT_NAME; }
+ (NSString *)appID { return YT_BUNDLE_ID; }
%end

%hook GCKBUtils
+ (NSString *)appIdentifier { return YT_BUNDLE_ID; }
%end

%hook GPCDeviceInfo
+ (NSString *)bundleId { return YT_BUNDLE_ID; }
%end

%hook OGLBundle
+ (NSString *)shortAppName { return YT_NAME; }
%end

%hook GVROverlayView
+ (NSString *)appName { return YT_NAME; }
%end

%hook OGLPhenotypeFlagServiceImpl
- (NSString *)bundleId { return YT_BUNDLE_ID; }
%end

%hook APMAEU
+ (BOOL)isFAS { return YES; }
%end

%hook GULAppEnvironmentUtil
+ (BOOL)isFromAppStore { return YES; }
%end

%hook SSOConfiguration
- (id)initWithClientID:(id)clientID supportedAccountServices:(id)supportedAccountServices {
    self = %orig;
    [self setValue:YT_NAME forKey:@"_shortAppName"];
    [self setValue:YT_BUNDLE_ID forKey:@"_applicationIdentifier"];
    return self;
}
%end

%hook NSBundle
- (NSString *)bundleIdentifier {
    NSArray *address = [NSThread callStackReturnAddresses];
    Dl_info info = {0};
    if (dladdr((void *)[address[2] longLongValue], &info) == 0)
        return %orig;
    NSString *path = [NSString stringWithUTF8String:info.dli_fname];
    if ([path hasPrefix:NSBundle.mainBundle.bundlePath])
        return YT_BUNDLE_ID;
    return %orig;
}
- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([key isEqualToString:@"CFBundleIdentifier"])
        return YT_BUNDLE_ID;
    if ([key isEqualToString:@"CFBundleDisplayName"] || [key isEqualToString:@"CFBundleName"])
        return YT_NAME;
    return %orig;
}
// Fix Google Sign in by @PoomSmart and @level3tjg (qnblackcat/uYouPlus#684)
- (NSDictionary *)infoDictionary {
    NSMutableDictionary *info = %orig.mutableCopy;
    NSString *altBundleIdentifier = info[@"ALTBundleIdentifier"];
    if (altBundleIdentifier) info[@"CFBundleIdentifier"] = altBundleIdentifier;
    return info;
}
%end

// YTMiniPlayerEnabler: https://github.com/level3tjg/YTMiniplayerEnabler/
%hook YTWatchMiniBarViewController
- (void)updateMiniBarPlayerStateFromRenderer {
    if (IsEnabled(@"ytMiniPlayer_enabled")) {}
    else { return %orig; }
}
%end

// YTNoHoverCards: https://github.com/level3tjg/YTNoHoverCards
%hook YTCreatorEndscreenView
- (void)setHidden:(BOOL)hidden {
    if (IsEnabled(@"hideHoverCards_enabled"))
        hidden = YES;
    %orig;
}
%end
 
//YTCastConfirm: https://github.com/JamieBerghmans/YTCastConfirm
%hook MDXPlaybackRouteButtonController
- (void)didPressButton:(id)arg1 {
    if (IsEnabled(@"castConfirm_enabled")) {
        NSBundle *tweakBundle = uYouPlusBundle();
        YTAlertView *alertView = [%c(YTAlertView) confirmationDialogWithAction:^{
            %orig;
        } actionTitle:LOC(@"MSG_YES")];
        alertView.title = LOC(@"CASTING");
        alertView.subtitle = LOC(@"MSG_ARE_YOU_SURE");
        [alertView show];
	} else {
    return %orig;
    }
}
%end

// Hide search ads by @PoomSmart - https://github.com/PoomSmart/YouTube-X
// %hook YTIElementRenderer
// - (NSData *)elementData {
//     if (self.hasCompatibilityOptions && self.compatibilityOptions.hasAdLoggingData)
//         return nil;
//     return %orig;
// }
// %end

// %hook YTSectionListViewController
// - (void)loadWithModel:(YTISectionListRenderer *)model {
//     NSMutableArray <YTISectionListSupportedRenderers *> *contentsArray = model.contentsArray;
//     NSIndexSet *removeIndexes = [contentsArray indexesOfObjectsPassingTest:^BOOL(YTISectionListSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
//         YTIItemSectionRenderer *sectionRenderer = renderers.itemSectionRenderer;
//         YTIItemSectionSupportedRenderers *firstObject = [sectionRenderer.contentsArray firstObject];
//         return firstObject.hasPromotedVideoRenderer || firstObject.hasCompactPromotedVideoRenderer || firstObject.hasPromotedVideoInlineMutedRenderer;
//     }];
//     [contentsArray removeObjectsAtIndexes:removeIndexes];
//     %orig;
// }
// %end

// YTClassicVideoQuality: https://github.com/PoomSmart/YTClassicVideoQuality
%hook YTVideoQualitySwitchControllerFactory
- (id)videoQualitySwitchControllerWithParentResponder:(id)responder {
    Class originalClass = %c(YTVideoQualitySwitchOriginalController);
    return originalClass ? [[originalClass alloc] initWithParentResponder:responder] : %orig;
}
%end

// A/B flags
%hook YTColdConfig 
- (BOOL)respectDeviceCaptionSetting { return NO; } // YouRememberCaption: https://poomsmart.github.io/repo/depictions/youremembercaption.html
- (BOOL)isLandscapeEngagementPanelSwipeRightToDismissEnabled { return YES; } // Swipe right to dismiss the right panel in fullscreen mode
%end

// NOYTPremium - https://github.com/PoomSmart/NoYTPremium/
%hook YTCommerceEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTInterstitialPromoEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTPromosheetEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTPromoThrottleController
- (BOOL)canShowThrottledPromo { return NO; }
- (BOOL)canShowThrottledPromoWithFrequencyCap:(id)arg1 { return NO; }
- (BOOL)canShowThrottledPromoWithFrequencyCaps:(id)arg1 { return NO; }
%end

%hook YTIShowFullscreenInterstitialCommand
- (BOOL)shouldThrottleInterstitial { return YES; }
%end

%hook YTSurveyController
- (void)showSurveyWithRenderer:(id)arg1 surveyParentResponder:(id)arg2 {}
%end

// YTNoPaidPromo: https://github.com/PoomSmart/YTNoPaidPromo
%hook YTMainAppVideoPlayerOverlayViewController
- (void)setPaidContentWithPlayerData:(id)data {
    if (IsEnabled(@"hidePaidPromotionCard_enabled")) {}
    else { return %orig; }
}
- (void)playerOverlayProvider:(YTPlayerOverlayProvider *)provider didInsertPlayerOverlay:(YTPlayerOverlay *)overlay {
    if ([[overlay overlayIdentifier] isEqualToString:@"player_overlay_paid_content"] && IsEnabled(@"hidePaidPromotionCard_enabled")) return;
    %orig;
}
%end

%hook YTInlineMutedPlaybackPlayerOverlayViewController
- (void)setPaidContentWithPlayerData:(id)data {
    if (IsEnabled(@"hidePaidPromotionCard_enabled")) {}
    else { return %orig; }
}
%end

// YTReExplore: https://github.com/PoomSmart/YTReExplore/
%group gReExplore
static void replaceTab(YTIGuideResponse *response) {
    NSMutableArray <YTIGuideResponseSupportedRenderers *> *renderers = [response itemsArray];
    for (YTIGuideResponseSupportedRenderers *guideRenderers in renderers) {
        YTIPivotBarRenderer *pivotBarRenderer = [guideRenderers pivotBarRenderer];
        NSMutableArray <YTIPivotBarSupportedRenderers *> *items = [pivotBarRenderer itemsArray];
        NSUInteger shortIndex = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
            return [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:@"FEshorts"];
        }];
        if (shortIndex != NSNotFound) {
            [items removeObjectAtIndex:shortIndex];
            NSUInteger exploreIndex = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
                return [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:[%c(YTIBrowseRequest) browseIDForExploreTab]];
            }];
            if (exploreIndex == NSNotFound) {
                YTIPivotBarSupportedRenderers *exploreTab = [%c(YTIPivotBarRenderer) pivotSupportedRenderersWithBrowseId:[%c(YTIBrowseRequest) browseIDForExploreTab] title:@"Explore" iconType:292];
                [items insertObject:exploreTab atIndex:1];
            }
            break;
        }
    }
}
%hook YTGuideServiceCoordinator
- (void)handleResponse:(YTIGuideResponse *)response withCompletion:(id)completion {
    replaceTab(response);
    %orig(response, completion);
}
- (void)handleResponse:(YTIGuideResponse *)response error:(id)error completion:(id)completion {
    replaceTab(response);
    %orig(response, error, completion);
}
%end
%end

// BigYTMiniPlayer: https://github.com/Galactic-Dev/BigYTMiniPlayer
%group Main
%hook YTWatchMiniBarView
- (void)setWatchMiniPlayerLayout:(int)arg1 {
    %orig(1);
}
- (int)watchMiniPlayerLayout {
    return 1;
}
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - self.frame.size.width), self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}
%end

%hook YTMainAppVideoPlayerOverlayView
- (BOOL)isUserInteractionEnabled {
    if([[self _viewControllerForAncestor].parentViewController.parentViewController isKindOfClass:%c(YTWatchMiniBarViewController)]) {
        return NO;
    }
        return %orig;
}
%end
%end

// YTSpeed - https://github.com/Lyvendia/YTSpeed
%hook YTVarispeedSwitchController
- (id)init {
	id result = %orig;

	const int size = 12;
	float speeds[] = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0};
	id varispeedSwitchControllerOptions[size];

	for (int i = 0; i < size; ++i) {
		id title = [NSString stringWithFormat:@"%.2fx", speeds[i]];
		varispeedSwitchControllerOptions[i] = [[%c(YTVarispeedSwitchControllerOption) alloc] initWithTitle:title rate:speeds[i]];
	}

	NSUInteger count = sizeof(varispeedSwitchControllerOptions) / sizeof(id);
	NSArray *varispeedArray = [NSArray arrayWithObjects:varispeedSwitchControllerOptions count:count];
	MSHookIvar<NSArray *>(self, "_options") = varispeedArray;

	return result;
}
%end

%hook MLHAMQueuePlayer
- (void)setRate:(float)rate {
    MSHookIvar<float>(self, "_rate") = rate;
	MSHookIvar<float>(self, "_preferredRate") = rate;

	id player = MSHookIvar<HAMPlayerInternal *>(self, "_player");
	[player setRate: rate];

	id stickySettings = MSHookIvar<MLPlayerStickySettings *>(self, "_stickySettings");
	[stickySettings setRate: rate];

	[self.playerEventCenter broadcastRateChange: rate];

	YTSingleVideoController *singleVideoController = self.delegate;
	[singleVideoController playerRateDidChange: rate];
}
%end 

%hook YTPlayerViewController
%property (nonatomic, assign) float playbackRate;
- (void)singleVideo:(id)video playbackRateDidChange:(float)rate {
	%orig;
}
%end

# pragma mark - uYouPlus
// Video Player Options
// Skips content warning before playing *some videos - @PoomSmart
%hook YTPlayabilityResolutionUserActionUIController
- (void)showConfirmAlert { [self confirmAlertDidPressConfirm]; }
%end

// Disable snap to chapter
%hook YTSegmentableInlinePlayerBarView
- (void)didMoveToWindow {
    %orig;
    if (IsEnabled(@"snapToChapter_enabled")) {
        self.enableSnapToChapter = NO;
    }
}
%end

// Disable Pinch to zoom
%hook YTColdConfig
- (BOOL)videoZoomFreeZoomEnabledGlobalConfig {
    return IsEnabled(@"pinchToZoom_enabled") ? NO : %orig;
}
%end

// YTStockVolumeHUD - https://github.com/lilacvibes/YTStockVolumeHUD
%group gStockVolumeHUD
%hook YTVolumeBarView
- (void)volumeChanged:(id)arg1 {
	%orig(nil);
}
%end

%hook UIApplication 
- (void)setSystemVolumeHUDEnabled:(BOOL)arg1 forAudioCategory:(id)arg2 {
	%orig(true, arg2);
}
%end
%end

%hook YTDoubleTapToSeekController
- (void)enableDoubleTapToSeek:(BOOL)arg1 {
    return IsEnabled(@"doubleTapToSeek_disabled") ? %orig(NO) : %orig;
}
%end

// Video Controls Overlay Options
// Hide CC / Autoplay switch
%hook YTMainAppControlsOverlayView
- (void)setClosedCaptionsOrSubtitlesButtonAvailable:(BOOL)arg1 { // hide CC button
    return IsEnabled(@"hideCC_enabled") ? %orig(NO) : %orig;
}
- (void)setAutoplaySwitchButtonRenderer:(id)arg1 { // hide Autoplay
    if (IsEnabled(@"hideAutoplaySwitch_enabled")) {}
    else { return %orig; }
}
%end

// Hide HUD Messages
%hook YTHUDMessageView
- (id)initWithMessage:(id)arg1 dismissHandler:(id)arg2 {
    return IsEnabled(@"hideHUD_enabled") ? nil : %orig;
}
%end

// Hide Watermark
%hook YTAnnotationsViewController
- (void)loadFeaturedChannelWatermark {
    if (IsEnabled(@"hideChannelWatermark_enabled")) {}
    else { return %orig; }
}
%end

// Hide Next & Previous button
%group gHidePreviousAndNextButton
%hook YTColdConfig
- (BOOL)removeNextPaddleForSingletonVideos { return YES; }
- (BOOL)removePreviousPaddleForSingletonVideos { return YES; }
%end
%end

// Replace Next & Previous button with Fast forward & Rewind button
%group gReplacePreviousAndNextButton
%hook YTColdConfig
- (BOOL)replaceNextPaddleWithFastForwardButtonForSingletonVods { return YES; }
- (BOOL)replacePreviousPaddleWithRewindButtonForSingletonVods { return YES; }
%end
%end

// Bring back the red progress bar - Broken?!
%hook YTInlinePlayerBarContainerView
- (id)quietProgressBarColor {
    return IsEnabled(@"redProgressBar_enabled") ? [UIColor redColor] : %orig;
}
%end

// Disable the right panel in fullscreen mode
%hook YTColdConfig
- (BOOL)isLandscapeEngagementPanelEnabled {
    return IsEnabled(@"hideRightPanel_enabled") ? NO : %orig;
}
%end

// Shorts Controls Overlay Options
%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if ((IsEnabled(@"hideBuySuperThanks_enabled")) && ([self.accessibilityIdentifier isEqualToString:@"id.elements.components.suggested_action"])) { 
        self.hidden = YES; 
    }
}
%end

%hook YTReelWatchRootViewController
- (void)setPausedStateCarouselView {
    if (IsEnabled(@"hideSubcriptions_enabled")) {}
    else { return %orig; }
}
%end

%hook YTShortsStartupCoordinator
- (id)evaluateResumeToShorts { 
    return IsEnabled(@"disableResumeToShorts") ? nil : %orig;
}
%end

// Theme Options
// Old dark theme (gray)
%group gOldDarkTheme
%hook YTColdConfig
- (BOOL)uiSystemsClientGlobalConfigUseDarkerPaletteBgColorForNative { return NO; }
- (BOOL)uiSystemsClientGlobalConfigUseDarkerPaletteTextColorForNative { return NO; }
- (BOOL)enableCinematicContainerOnClient { return NO; }
%end

%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if ([self.accessibilityIdentifier isEqualToString:@"id.elements.components.comment_composer"]) { self.backgroundColor = [UIColor clearColor]; }
    if ([self.accessibilityIdentifier isEqualToString:@"id.elements.components.video_list_entry"]) { self.backgroundColor = [UIColor clearColor]; }
}
%end

%hook ASCollectionView
- (void)didMoveToWindow {
    %orig;
    self.superview.backgroundColor = [UIColor colorWithRed:0.129 green:0.129 blue:0.129 alpha:1.0];
}
%end

%hook YTFullscreenEngagementOverlayView
- (void)didMoveToWindow {
    %orig;
    self.subviews[0].backgroundColor = [UIColor clearColor];
}
%end

%hook YTRelatedVideosView
- (void)didMoveToWindow {
    %orig;
    self.subviews[0].backgroundColor = [UIColor clearColor];
}
%end
%end

// OLED dark mode by BandarHL
UIColor* raisedColor = [UIColor colorWithRed:0.035 green:0.035 blue:0.035 alpha:1.0];
%group gOLED
%hook YTCommonColorPalette
- (UIColor *)brandBackgroundSolid {
    return self.pageStyle == 1 ? [UIColor blackColor] : %orig;
}
- (UIColor *)brandBackgroundPrimary {
    return self.pageStyle == 1 ? [UIColor blackColor] : %orig;
}
- (UIColor *)brandBackgroundSecondary {
    return self.pageStyle == 1 ? [[UIColor blackColor] colorWithAlphaComponent:0.9] : %orig;
}
- (UIColor *)raisedBackground {
    return self.pageStyle == 1 ? [UIColor blackColor] : %orig;
}
- (UIColor *)staticBrandBlack {
    return self.pageStyle == 1 ? [UIColor blackColor] : %orig;
}
- (UIColor *)generalBackgroundA {
    return self.pageStyle == 1 ? [UIColor blackColor] : %orig;
}
%end

%hook YTInnerTubeCollectionViewController
- (UIColor *)backgroundColor:(NSInteger)pageStyle {
    return pageStyle == 1 ? [UIColor blackColor] : %orig;
}
%end

// Explore
%hook ASScrollView 
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode()) {
        self.backgroundColor = [UIColor clearColor];
    }
}
%end

// Your videos
%hook ASCollectionView
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode() && [self.nextResponder isKindOfClass:%c(_ASDisplayView)]) {
        self.superview.backgroundColor = [UIColor blackColor];
    }
}
%end

// Sub menu?
%hook ELMView
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode()) {
        self.subviews[0].backgroundColor = [UIColor clearColor];
    }
}
%end

// iSponsorBlock
%hook SponsorBlockSettingsController
- (void)viewDidLoad {
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        %orig;
        self.tableView.backgroundColor = [UIColor blackColor];
    } else { return %orig; }
}
%end

%hook SponsorBlockViewController
- (void)viewDidLoad {
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        %orig;
        self.view.backgroundColor = [UIColor blackColor];
    } else { return %orig; }
}
%end

// Search View
%hook YTSearchBarView 
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
%end

// History Search view
%hook YTSearchBoxView 
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;

}
%end

// Comment view
%hook YTCommentView
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
%end

%hook YTCreateCommentAccessoryView
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
%end

%hook YTCreateCommentTextView
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
- (void)setTextColor:(UIColor *)color { // fix black text in #Shorts video's comment
    return isDarkMode() ? %orig([UIColor whiteColor]) : %orig;
}
%end

%hook YTCommentDetailHeaderCell
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode()) {
        self.subviews[2].backgroundColor = [UIColor blackColor];
    }
}
%end

%hook YTFormattedStringLabel  // YT is werid...
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor clearColor]) : %orig;
}
%end

// Live chat comment
%hook YCHLiveChatActionPanelView 
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
%end

%hook YTEmojiTextView
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
%end

%hook YCHLiveChatView
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode()) {
        self.subviews[1].backgroundColor = [UIColor blackColor];
    }
}
%end

%hook YTCollectionView 
- (void)setBackgroundColor:(UIColor *)color { 
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
%end

//
%hook YTBackstageCreateRepostDetailView
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig([UIColor blackColor]) : %orig;
}
%end

// Others
%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode()) {
        if ([self.nextResponder isKindOfClass:%c(ASScrollView)]) { self.backgroundColor = [UIColor clearColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"eml.cvr"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"eml.live_chat_text_message"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"rich_header"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.ui.comment_cell"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.ui.cancel.button"]) { self.superview.backgroundColor = [UIColor clearColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.elements.components.comment_composer"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.elements.components.video_list_entry"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.comment.guidelines_text"]) { self.superview.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.comment.channel_guidelines_bottom_sheet_container"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.comment.channel_guidelines_entry_banner_container"]) { self.backgroundColor = [UIColor blackColor]; }
        if ([self.accessibilityIdentifier isEqualToString:@"id.comment.comment_group_detail_container"]) { self.backgroundColor = [UIColor clearColor]; }
    }
}
%end

// Open link with...
%hook ASWAppSwitchingSheetHeaderView
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig(raisedColor) : %orig;
}
%end

%hook ASWAppSwitchingSheetFooterView
- (void)setBackgroundColor:(UIColor *)color {
    return isDarkMode() ? %orig(raisedColor) : %orig;
}
%end

%hook ASWAppSwitcherCollectionViewCell
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode()) {
        self.backgroundColor = raisedColor;
        self.subviews[1].backgroundColor = raisedColor;
        self.superview.backgroundColor = raisedColor;
    }
}
%end

// Incompatibility with the new YT Dark theme
%hook YTColdConfig
- (BOOL)uiSystemsClientGlobalConfigUseDarkerPaletteBgColorForNative { return NO; }
%end
%end

// OLED keyboard by @ichitaso <3 - http://gist.github.com/ichitaso/935100fd53a26f18a9060f7195a1be0e
%group gOLEDKB 
%hook UIPredictionViewController
- (void)loadView {
    %orig;
    [self.view setBackgroundColor:[UIColor blackColor]];
}
%end

%hook UICandidateViewController
- (void)loadView {
    %orig;
    [self.view setBackgroundColor:[UIColor blackColor]];
}
%end

%hook UIKeyboardDockView
- (void)didMoveToWindow {
    %orig;
    self.backgroundColor = [UIColor blackColor];
}
%end

%hook UIKeyboardLayoutStar 
- (void)didMoveToWindow {
    %orig;
    self.backgroundColor = [UIColor blackColor];
}
%end

%hook UIKBRenderConfig // Prediction text color
- (void)setLightKeyboard:(BOOL)arg1 { %orig(NO); }
%end
%end

// Miscellaneous
// Disable hints - https://github.com/LillieH001/YouTube-Reborn/blob/v4/
%group gDisableHints
%hook YTSettings
- (BOOL)areHintsDisabled {
	return YES;
}
- (void)setHintsDisabled:(BOOL)arg1 {
    %orig(YES);
}
%end
%hook YTUserDefaults
- (BOOL)areHintsDisabled {
	return YES;
}
- (void)setHintsDisabled:(BOOL)arg1 {
    %orig(YES);
}
%end
%end

// Hide the Chip Bar (Upper Bar) in Home feed
%group gHideChipBar
%hook YTMySubsFilterHeaderView 
- (void)setChipFilterView:(id)arg1 {}
%end

%hook YTHeaderContentComboView
- (void)enableSubheaderBarWithView:(id)arg1 {}
%end

%hook YTHeaderContentComboView
- (void)setFeedHeaderScrollMode:(int)arg1 { %orig(0); }
%end
%end

%group giPhoneLayout
%hook UIDevice
- (long long)userInterfaceIdiom {
    return NO;
} 
%end
%hook UIStatusBarStyleAttributes
- (long long)idiom {
    return YES;
} 
%end
%hook UIKBTree
- (long long)nativeIdiom {
    return YES;
} 
%end
%hook UIKBRenderer
- (long long)assetIdiom {
    return YES;
} 
%end
%end

// YT startup animation
%hook YTColdConfig
- (BOOL)mainAppCoreClientIosEnableStartupAnimation {
    return IsEnabled(@"ytStartupAnimation_enabled") ? YES : NO;
}
%end

# pragma mark - ctor
%ctor {
    // Load uYou first so its functions are available for hooks.
    dlopen([[NSString stringWithFormat:@"%@/Frameworks/uYou.dylib", [[NSBundle mainBundle] bundlePath]] UTF8String], RTLD_LAZY);

    %init;
    if (@available(iOS 16, *)) {
        %init(iOS16);
    }
    if (IsEnabled(@"reExplore_enabled")) {
        %init(gReExplore);
    }
    if (IsEnabled(@"bigYTMiniPlayer_enabled") && (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad)) {
        %init(Main);
    }
    if (IsEnabled(@"hidePreviousAndNextButton_enabled")) {
        %init(gHidePreviousAndNextButton);
    }
    if (IsEnabled(@"replacePreviousAndNextButton_enabled")) {
        %init(gReplacePreviousAndNextButton);
    }
    if (oledDarkTheme()) {
        %init(gOLED);
    }
    if (oldDarkTheme()) {
        %init(gOldDarkTheme)
    }
    if (IsEnabled(@"oledKeyBoard_enabled")) {
        %init(gOLEDKB);
    }
    if (IsEnabled(@"disableHints_enabled")) {
        %init(gDisableHints);
    }
    if (IsEnabled(@"hideChipBar_enabled")) {
        %init(gHideChipBar);
    }
    if (IsEnabled(@"iPhoneLayout_enabled") && (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)) {
        %init(giPhoneLayout);
    }
    if (IsEnabled(@"stockVolumeHUD_enabled")) {
        %init(gStockVolumeHUD);
    }

    // Disable updates
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"automaticallyCheckForUpdates"];
 
    // Disable broken options of uYou
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"disableAgeRestriction"];
    
    // Change the default value of some options
    NSArray *allKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    if (![allKeys containsObject:@"relatedVideosAtTheEndOfYTVideos"]) { 
       [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"relatedVideosAtTheEndOfYTVideos"]; 
    }
    if (![allKeys containsObject:@"shortsProgressBar"]) { 
       [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shortsProgressBar"]; 
    }
    if (![allKeys containsObject:@"RYD-ENABLED"]) { 
       [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RYD-ENABLED"]; 
    }
    if (![allKeys containsObject:@"YouPiPEnabled"]) { 
       [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"YouPiPEnabled"]; 
    }
}
