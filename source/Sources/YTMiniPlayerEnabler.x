#import "uYouPlus.h"

// YTMiniPlayerEnabler: https://github.com/level3tjg/YTMiniplayerEnabler/
%hook YTWatchMiniBarViewController
- (void)updateMiniBarPlayerStateFromRenderer {
    if (IS_ENABLED(@"ytMiniPlayer_enabled")) {}
    else { return %orig; }
}
%end