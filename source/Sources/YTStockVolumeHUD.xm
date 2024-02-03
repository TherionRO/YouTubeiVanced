#import "uYouPlus.h"

%group YTStockVolumeHUD // https://github.com/lilacvibes/YTStockVolumeHUD
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

%ctor {
    if (IS_ENABLED(@"stockVolumeHUD_enabled")) {
        %init(YTStockVolumeHUD);
    }
}