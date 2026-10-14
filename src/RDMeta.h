#import <Foundation/Foundation.h>
// Reads the "now playing" title from an Icecast or Shoutcast stream the old-fashioned way: a second request with
// Icy-MetaData: 1, read up to the first metadata block, parse StreamTitle, hang up. Repeated every 30 s while playing.
@interface RDMeta : NSObject { NSURLConnection *conn; NSMutableData *buf; NSInteger metaint; NSString *url; void (^onTitle)(NSString *); NSTimer *timer; }
- (void)startForURL:(NSString *)u onTitle:(void (^)(NSString *))block;
- (void)stop;
@end
