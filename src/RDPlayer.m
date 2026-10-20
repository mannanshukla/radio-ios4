#import "RDPlayer.h"
#import "RDStations.h"
#import <MediaPlayer/MediaPlayer.h>
NSString *const RDPlayerChanged = @"RDPlayerChanged";
static void *kStatus = &kStatus, *kMeta = &kMeta;

@implementation RDPlayer
+ (RDPlayer *)shared { static RDPlayer *p = nil; if (!p) p = [[RDPlayer alloc] init]; return p; }
- (id)init {
    if ((self = [super init])) {
        AVAudioSession *s = [AVAudioSession sharedInstance]; [s setCategory:AVAudioSessionCategoryPlayback error:nil]; s.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failed:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ended:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}
- (void)changed { [[NSNotificationCenter defaultCenter] postNotificationName:RDPlayerChanged object:self]; [self pushNowPlaying]; }
- (void)pushNowPlaying {   // lock screen and multitasking bar, iOS 5+; silently skipped on 4.3
    Class c = NSClassFromString(@"MPNowPlayingInfoCenter"); if (!c || !station) return;
    id center = [c performSelector:@selector(defaultCenter)];
    NSDictionary *info = state == RDStopped ? nil : [NSDictionary dictionaryWithObjectsAndKeys:[station objectForKey:@"name"], MPMediaItemPropertyArtist, (title ?: [station objectForKey:@"sub"]), MPMediaItemPropertyTitle, nil];
    [center performSelector:@selector(setNowPlayingInfo:) withObject:info];
}
- (void)teardown {
    if (item) { [item removeObserver:self forKeyPath:@"status"]; [item removeObserver:self forKeyPath:@"timedMetadata"]; [item release]; item = nil; }
    [player pause]; [player release]; player = nil;
}
- (void)play:(NSDictionary *)s {
    [self teardown]; [station release]; station = [s retain]; [title release]; title = nil; [error release]; error = nil;
    [RDStations setLastURL:[s objectForKey:@"url"]];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    NSURL *u = [NSURL URLWithString:[s objectForKey:@"url"]];
    if (!u) { state = RDFailed; error = [@"That isn't a stream address." copy]; [self changed]; return; }
    item = [[AVPlayerItem alloc] initWithURL:u];
    [item addObserver:self forKeyPath:@"status" options:0 context:kStatus];
    [item addObserver:self forKeyPath:@"timedMetadata" options:NSKeyValueObservingOptionNew context:kMeta];
    player = [[AVPlayer alloc] initWithPlayerItem:item]; [player play];
    state = RDConnecting; [self changed];
    if (!meta) meta = [[RDMeta alloc] init];
    [meta startForURL:[s objectForKey:@"url"] onTitle:^(NSString *t) { if (![t isEqualToString:title]) { [title release]; title = [t copy]; [self changed]; } }];
}
- (void)stop { [meta stop]; [self teardown]; state = RDStopped; [title release]; title = nil; [self changed]; }
- (void)toggle {
    if (state == RDPlaying || state == RDConnecting) { [self stop]; return; }
    NSDictionary *s = station ?: [RDStations lastStation];
    if (!s) s = [[RDStations all] objectAtIndex:0];
    [self play:s];
}
- (void)observeValueForKeyPath:(NSString *)k ofObject:(id)o change:(NSDictionary *)c context:(void *)ctx {
    if (o != item) return;
    if (ctx == kStatus) {
        if (item.status == AVPlayerItemStatusReadyToPlay) { state = RDPlaying; [self changed]; }
        else if (item.status == AVPlayerItemStatusFailed) { state = RDFailed; [error release]; error = [([item.error localizedDescription] ?: @"The stream wouldn't start.") copy]; [meta stop]; [self teardown]; [self changed]; }
    } else if (ctx == kMeta) {
        NSString *t = nil;   // Icecast "StreamTitle" arrives as timed metadata; take the first string value
        for (AVMetadataItem *m in item.timedMetadata) { if ([m.value isKindOfClass:[NSString class]] && [(NSString *)m.value length]) { t = (NSString *)m.value; if ([m.commonKey isEqualToString:AVMetadataCommonKeyTitle]) break; } }
        if (t && ![t isEqualToString:title]) { [title release]; title = [t copy]; [self changed]; }
    }
}
- (void)failed:(NSNotification *)n { if (n.object != item) return; state = RDFailed; [error release]; error = [@"Lost the stream. Tap to reconnect." copy]; [meta stop]; [self teardown]; [self changed]; }
- (void)ended:(NSNotification *)n { if (n.object != item) return; [self failed:n]; }
- (RDState)state { return state; }
- (NSDictionary *)station { return station; }
- (NSString *)nowPlaying { return title; }
- (NSString *)error { return error; }
- (NSDate *)sleepEnd { return sleepEnd; }
- (void)setSleepMinutes:(NSInteger)m {
    [sleepTimer invalidate]; [sleepTimer release]; sleepTimer = nil; [sleepEnd release]; sleepEnd = nil;
    if (m > 0) { sleepEnd = [[NSDate dateWithTimeIntervalSinceNow:m * 60] retain]; sleepTimer = [[NSTimer scheduledTimerWithTimeInterval:m * 60 target:self selector:@selector(sleepFired) userInfo:nil repeats:NO] retain]; }
    [self changed];
}
- (void)sleepFired { [sleepTimer release]; sleepTimer = nil; [sleepEnd release]; sleepEnd = nil; [self stop]; }
// phone calls, alarms: pause and come back
- (void)beginInterruption { if (state == RDPlaying || state == RDConnecting) { interrupted = YES; [player pause]; [meta stop]; } }   // play: starts the title polling again
- (void)endInterruptionWithFlags:(NSUInteger)f { if (interrupted) { interrupted = NO; [[AVAudioSession sharedInstance] setActive:YES error:nil]; if (station) [self play:station]; } }
@end
