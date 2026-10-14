#import "RDStations.h"
static NSDictionary *st(NSString *name, NSString *sub, NSString *url, NSString *group) { return [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", sub, @"sub", url, @"url", group, @"group", nil]; }
static NSArray *presets(void) {
    static NSArray *p = nil;
    if (!p) p = [[NSArray alloc] initWithObjects:
        st(@"KQED 88.5", @"NPR for Northern California", @"http://streams.kqed.org/kqedradio", @"Bay Area"),
        st(@"KCSM 91.1", @"Jazz 91, San Mateo", @"http://ice7.securenetsystems.net/KCSM2", @"Bay Area"),
        st(@"KPFA 94.1", @"Pacifica, Berkeley", @"http://streams.kpfa.org:8000/kpfa_128", @"Bay Area"),
        st(@"KPOO 89.5", @"Community radio, San Francisco", @"http://amber.streamguys.com:5220/xstream", @"Bay Area"),
        st(@"KDFC 90.3", @"Classical California", @"http://18243.live.streamtheworld.com/KDFCFM5_SC", @"Bay Area"),
        st(@"KALX 90.7", @"UC Berkeley", @"http://stream.kalx.berkeley.edu:8000/kalx-128.mp3", @"College radio, West"),
        st(@"KZSU 90.1", @"Stanford", @"http://kzsu-streams.stanford.edu/kzsu-1-128.mp3", @"College radio, West"),
        st(@"KFJC 89.7", @"Foothill College, Los Altos Hills", @"http://netcast.kfjc.org/kfjc-128k-mp3", @"College radio, West"),
        st(@"KSJS 90.5", @"San Jose State", @"http://streaming.ksjs.sjsu.edu:8000/live", @"College radio, West"),
        st(@"KSCU 103.3", @"Santa Clara University", @"http://kscu.streamguys1.com/live", @"College radio, West"),
        st(@"KZSC 88.1", @"UC Santa Cruz", @"https://kzscfms1-geckohost.radioca.st/kzschigh", @"College radio, West"),
        st(@"KDVS 90.3", @"UC Davis", @"https://listen.kdvs.org/stream", @"College radio, West"),
        st(@"KXLU 88.9", @"Loyola Marymount, Los Angeles", @"http://kxlu.streamguys1.com:80/kxlu-hi", @"College radio, West"),
        st(@"KUCI 88.9", @"UC Irvine", @"http://streamer.kuci.org:8000/high", @"College radio, West"),
        st(@"KSPC 88.7", @"Pomona College", @"https://kspc.radioca.st/stream", @"College radio, West"),
        st(@"KCPR 91.3", @"Cal Poly, San Luis Obispo", @"https://ice9.securenetsystems.net/KCPR1", @"College radio, West"),
        st(@"WPRB 103.3", @"Princeton", @"http://wprb.streamguys1.com/live", @"College radio, East"),
        st(@"WRSU 88.7", @"Rutgers", @"https://wrsu-libstrm.radioca.st/stream", @"College radio, East"),
        st(@"WKCR 89.9", @"Columbia", @"http://wkcr.streamguys1.com/live", @"College radio, East"),
        st(@"WNYU 89.1", @"NYU", @"http://cinema.acs.its.nyu.edu:8000/wnyu128.mp3", @"College radio, East"),
        st(@"WFUV 90.7", @"Fordham", @"http://wfuv-onair.streamguys.org/onair-hi", @"College radio, East"),
        st(@"WHRB 95.3", @"Harvard", @"http://stream.whrb.org:8000/whrb-mp3", @"College radio, East"),
        st(@"WMBR 88.1", @"MIT", @"http://wmbr.org:8000/hi", @"College radio, East"),
        st(@"WBRU", @"Brown", @"https://s3.radio.co/s115121de1/listen", @"College radio, East"),
        st(@"WXPN 88.5", @"Penn, Philadelphia", @"http://wxpnhi.xpn.org/xpnhi", @"College radio, East"),
        st(@"WHPK 88.5", @"University of Chicago", @"https://whpk-stream.uchicago.edu/stream", @"College radio, East"),
        st(@"WXYC 89.3", @"UNC Chapel Hill", @"http://audio-mp3.ibiblio.org:8000/wxyc.mp3", @"College radio, East"),
        st(@"WREK 91.1", @"Georgia Tech", @"http://streaming.wrek.org:8000/wrek_live-128kb", @"College radio, East"),
        st(@"Groove Salad", @"Ambient and downtempo", @"http://ice1.somafm.com/groovesalad-128-mp3", @"SomaFM, San Francisco"),
        st(@"Drone Zone", @"Atmospheric space music", @"http://ice1.somafm.com/dronezone-128-mp3", @"SomaFM, San Francisco"),
        st(@"Lush", @"Mellow female vocals", @"http://ice1.somafm.com/lush-128-mp3", @"SomaFM, San Francisco"),
        st(@"Secret Agent", @"Spy jazz and lounge", @"http://ice1.somafm.com/secretagent-128-mp3", @"SomaFM, San Francisco"),
        st(@"Indie Pop Rocks", @"New and classic indie pop", @"http://ice1.somafm.com/indiepop-128-mp3", @"SomaFM, San Francisco"),
        st(@"DEF CON Radio", @"Music for hacking", @"http://ice1.somafm.com/defcon-128-mp3", @"SomaFM, San Francisco"),
        st(@"KEXP 90.3", @"Seattle. Where the music matters", @"http://live-mp3-128.kexp.org/kexp128.mp3", @"Elsewhere"),
        st(@"KCRW 89.9", @"Santa Monica, on air", @"https://streams.kcrw.com/kcrw_mp3", @"Elsewhere"),
        st(@"KCRW Eclectic 24", @"Music all day", @"https://streams.kcrw.com/e24_mp3", @"Elsewhere"),
        st(@"WFMU 91.1", @"Freeform radio from New Jersey", @"http://stream0.wfmu.org/freeform-128k", @"Elsewhere"),
        st(@"KBOO 90.7", @"Community radio, Portland", @"http://live.kboo.fm:8000/high", @"Elsewhere"),
        st(@"Radio Paradise", @"Eclectic, listener supported", @"http://stream.radioparadise.com/mp3-128", @"Elsewhere"),
        nil];
    return p;
}
@implementation RDStations
+ (NSArray *)groups { return [NSArray arrayWithObjects:@"Bay Area", @"College radio, West", @"College radio, East", @"SomaFM, San Francisco", @"Elsewhere", @"Your stations", nil]; }
+ (NSArray *)stationsInGroup:(NSString *)g {
    if ([g isEqualToString:@"Your stations"]) return [self custom];
    NSMutableArray *a = [NSMutableArray array]; for (NSDictionary *s in presets()) if ([[s objectForKey:@"group"] isEqualToString:g]) [a addObject:s]; return a;
}
+ (NSArray *)custom { return [[NSUserDefaults standardUserDefaults] arrayForKey:@"rd_custom"] ?: [NSArray array]; }
+ (void)setCustom:(NSArray *)a { [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"rd_custom"]; [[NSUserDefaults standardUserDefaults] synchronize]; }
+ (NSArray *)all { return [presets() arrayByAddingObjectsFromArray:[self custom]]; }
+ (NSString *)lastURL { return [[NSUserDefaults standardUserDefaults] stringForKey:@"rd_last"]; }
+ (void)setLastURL:(NSString *)u { [[NSUserDefaults standardUserDefaults] setObject:u forKey:@"rd_last"]; [[NSUserDefaults standardUserDefaults] synchronize]; }
@end
