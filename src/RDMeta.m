#import "RDMeta.h"
@implementation RDMeta
- (void)dealloc { [self stop]; [super dealloc]; }
- (void)startForURL:(NSString *)u onTitle:(void (^)(NSString *))block {
    [self stop]; url = [u copy]; onTitle = [block copy];
    [self poll]; timer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(poll) userInfo:nil repeats:YES] retain];
}
- (void)stop { [timer invalidate]; [timer release]; timer = nil; [conn cancel]; [conn release]; conn = nil; [buf release]; buf = nil; [url release]; url = nil; [onTitle release]; onTitle = nil; }
- (void)poll {
    if (conn || !url) return;
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [r setValue:@"1" forHTTPHeaderField:@"Icy-MetaData"]; [r setValue:@"Radio/1.0 (iPod touch)" forHTTPHeaderField:@"User-Agent"];
    buf = [[NSMutableData alloc] init]; metaint = 0; conn = [[NSURLConnection alloc] initWithRequest:r delegate:self];
}
- (void)connection:(NSURLConnection *)c didReceiveResponse:(NSURLResponse *)resp {
    NSDictionary *h = [(NSHTTPURLResponse *)resp allHeaderFields]; NSString *mi = nil;
    for (NSString *k in h) if ([[k lowercaseString] isEqualToString:@"icy-metaint"]) mi = [h objectForKey:k];
    metaint = [mi integerValue]; if (metaint <= 0 || metaint > 64000) { [self finish]; }   // no metadata on this stream
}
- (void)connection:(NSURLConnection *)c didReceiveData:(NSData *)d {
    [buf appendData:d]; if ((NSInteger)[buf length] < metaint + 1) return;
    const unsigned char *p = [buf bytes]; NSInteger len = p[metaint] * 16; if ((NSInteger)[buf length] < metaint + 1 + len) { if (len == 0) [self finish]; return; }
    NSString *meta = [[[NSString alloc] initWithBytes:p + metaint + 1 length:len encoding:NSUTF8StringEncoding] autorelease] ?: [[[NSString alloc] initWithBytes:p + metaint + 1 length:len encoding:NSISOLatin1StringEncoding] autorelease];
    NSRange a = [meta rangeOfString:@"StreamTitle='"];
    if (a.location != NSNotFound) { NSString *rest = [meta substringFromIndex:a.location + a.length]; NSRange b = [rest rangeOfString:@"';"]; NSString *t = b.location == NSNotFound ? rest : [rest substringToIndex:b.location]; t = [t stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; if ([t length] && onTitle) onTitle(t); }
    [self finish];
}
- (void)connection:(NSURLConnection *)c didFailWithError:(NSError *)e { [self finish]; }
- (void)connectionDidFinishLoading:(NSURLConnection *)c { [self finish]; }
- (void)finish { [conn cancel]; [conn release]; conn = nil; [buf release]; buf = nil; }
@end
