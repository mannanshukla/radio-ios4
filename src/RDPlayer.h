#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDMeta.h"
// One AVPlayer for the whole app. Posts RDPlayerChanged whenever state, station, title or the sleep timer changes.
typedef enum { RDStopped = 0, RDConnecting, RDPlaying, RDFailed } RDState;
extern NSString *const RDPlayerChanged;
@interface RDPlayer : NSObject <AVAudioSessionDelegate> { AVPlayer *player; AVPlayerItem *item; NSDictionary *station; RDState state; NSString *title, *error; NSTimer *sleepTimer; NSDate *sleepEnd; BOOL interrupted; RDMeta *meta; }
+ (RDPlayer *)shared;
- (void)play:(NSDictionary *)s;
- (void)stop;
- (void)toggle;                       // stop if playing, otherwise play the current (or last) station
- (RDState)state; - (NSDictionary *)station; - (NSString *)nowPlaying; - (NSString *)error; - (NSDate *)sleepEnd;
- (void)setSleepMinutes:(NSInteger)m; // 0 cancels
@end
