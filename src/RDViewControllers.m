#import "RDViewControllers.h"
#import "RDStations.h"
#import "RDPlayer.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

static UIColor *tint(CGFloat a) { return [UIColor colorWithRed:0.20 green:0.36 blue:0.59 alpha:a]; }   // the icon blue
static UIImage *glyph(BOOL play) {   // drawn, not typed: the ▶ character renders as an emoji on iOS 5
    CGFloat sz = 28; UIGraphicsBeginImageContextWithOptions(CGSizeMake(sz, sz), NO, 0); CGContextRef c = UIGraphicsGetCurrentContext();
    [tint(1) setFill];
    if (play) { CGContextMoveToPoint(c, 6, 3); CGContextAddLineToPoint(c, 26, 14); CGContextAddLineToPoint(c, 6, 25); CGContextClosePath(c); CGContextFillPath(c); }
    else CGContextFillRect(c, CGRectMake(5, 5, 18, 18));
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}

#pragma mark - Dial ruler
@implementation RDDialView
- (id)initWithStations:(NSArray *)s pointsPerMHz:(CGFloat)p {
    lo = 87.5; hi = 108.1; ppm = p; stations = [s retain];
    if ((self = [super initWithFrame:CGRectMake(0, 0, (hi - lo) * ppm, 74)])) { self.backgroundColor = [UIColor clearColor]; self.opaque = NO; }
    return self;
}
- (void)dealloc { [stations release]; [super dealloc]; }
- (CGFloat)xForFrequency:(double)f { return (f - lo) * ppm; }
- (double)frequencyForX:(CGFloat)x { return lo + x / ppm; }
- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext(); CGFloat base = 44;
    [[UIColor colorWithWhite:0.45 alpha:1] setStroke]; CGContextSetLineWidth(c, 1);
    for (double f = lo; f <= hi + 0.001; f += 0.1) {
        CGFloat x = floorf([self xForFrequency:f]) + 0.5; if (x < rect.origin.x - 2 || x > CGRectGetMaxX(rect) + 2) continue;
        int tenth = (int)floor(f * 10 + 0.5); CGFloat h = tenth % 10 == 0 ? 14 : tenth % 5 == 0 ? 9 : 5;
        CGContextMoveToPoint(c, x, base); CGContextAddLineToPoint(c, x, base - h); CGContextStrokePath(c);
        if (tenth % 10 == 0) { NSString *t = [NSString stringWithFormat:@"%d", tenth / 10]; [[UIColor colorWithWhite:0.25 alpha:1] set]; [t drawAtPoint:CGPointMake(x - 8, base + 3) withFont:[UIFont boldSystemFontOfSize:10]]; }
    }
    CGContextMoveToPoint(c, rect.origin.x, base + 0.5); CGContextAddLineToPoint(c, CGRectGetMaxX(rect), base + 0.5); CGContextStrokePath(c);
    [tint(1) setStroke]; CGContextSetLineWidth(c, 2); NSUInteger i = 0;
    for (NSDictionary *s in stations) {
        CGFloat x = [self xForFrequency:[[s objectForKey:@"freq"] doubleValue]]; if (x < rect.origin.x - 60 || x > CGRectGetMaxX(rect) + 60) { i++; continue; }
        CGContextMoveToPoint(c, x, base); CGContextAddLineToPoint(c, x, base - 20); CGContextStrokePath(c);
        NSString *call = [[[s objectForKey:@"name"] componentsSeparatedByString:@" "] objectAtIndex:0]; UIFont *f = [UIFont boldSystemFontOfSize:9]; CGSize sz = [call sizeWithFont:f];
        [tint(1) set]; [call drawAtPoint:CGPointMake(x - sz.width / 2, (i % 2 == 0) ? 2 : 12) withFont:f]; i++;   // alternate rows so neighbours don't collide
    }
}
@end

#pragma mark - Tuner panel
@implementation RDTunerView
- (id)initWithFrame:(CGRect)fr {
    if ((self = [super initWithFrame:fr])) {
        self.backgroundColor = [UIColor clearColor];
        UIView *glass = [[[UIView alloc] initWithFrame:CGRectMake(9, 10, fr.size.width - 18, fr.size.height - 14)] autorelease];
        glass.backgroundColor = [UIColor whiteColor]; glass.layer.cornerRadius = 10; glass.layer.borderWidth = 1; glass.layer.borderColor = [UIColor colorWithWhite:0.67 alpha:1].CGColor; glass.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:glass]; CGFloat w = glass.bounds.size.width;
        freq = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, w - 100, 34)]; freq.font = [UIFont boldSystemFontOfSize:30]; freq.textColor = tint(1); freq.backgroundColor = [UIColor clearColor]; [glass addSubview:freq];
        name = [[UILabel alloc] initWithFrame:CGRectMake(12, 42, w - 100, 18)]; name.font = [UIFont boldSystemFontOfSize:14]; name.textColor = [UIColor blackColor]; name.backgroundColor = [UIColor clearColor]; [glass addSubview:name];
        song = [[UILabel alloc] initWithFrame:CGRectMake(12, 60, w - 100, 32)]; song.font = [UIFont systemFontOfSize:12]; song.textColor = [UIColor colorWithWhite:0.4 alpha:1]; song.backgroundColor = [UIColor clearColor]; song.numberOfLines = 2; [glass addSubview:song];
        button = [[UIButton buttonWithType:UIButtonTypeCustom] retain]; button.frame = CGRectMake(w - 80, 12, 66, 66); button.layer.cornerRadius = 33; button.layer.borderWidth = 2; button.layer.borderColor = tint(1).CGColor; button.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
        [button addTarget:[RDPlayer shared] action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside]; [glass addSubview:button];
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]; spinner.center = button.center; spinner.hidesWhenStopped = YES; [glass addSubview:spinner];
        // the dial
        dialScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 96, w, 74)]; dialScroll.showsHorizontalScrollIndicator = NO; dialScroll.delegate = self; dialScroll.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1]; dialScroll.decelerationRate = UIScrollViewDecelerationRateFast; dialScroll.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [glass addSubview:dialScroll];
        UIView *needle = [[[UIView alloc] initWithFrame:CGRectMake(w / 2 - 1, 96, 2, 74)] autorelease]; needle.backgroundColor = [UIColor colorWithRed:0.95 green:0.2 blue:0.15 alpha:1]; needle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin; [glass addSubview:needle];
        UIView *cap = [[[UIView alloc] initWithFrame:CGRectMake(w / 2 - 5, 92, 10, 6)] autorelease]; cap.backgroundColor = needle.backgroundColor; cap.autoresizingMask = needle.autoresizingMask; [glass addSubview:cap];
        bandSeg = [[UISegmentedControl alloc] initWithItems:[RDStations bands]]; bandSeg.frame = CGRectMake(12, 178, w - 24, 28); bandSeg.segmentedControlStyle = UISegmentedControlStyleBar; bandSeg.tintColor = tint(1); bandSeg.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [bandSeg addTarget:self action:@selector(bandChanged) forControlEvents:UIControlEventValueChanged]; [glass addSubview:bandSeg];
        status = [[UILabel alloc] initWithFrame:CGRectMake(12, 212, w - 24, 14)]; status.font = [UIFont systemFontOfSize:10]; status.textColor = [UIColor colorWithWhite:0.45 alpha:1]; status.backgroundColor = [UIColor clearColor]; status.textAlignment = UITextAlignmentCenter; [glass addSubview:status];
        MPVolumeView *vol = [[[MPVolumeView alloc] initWithFrame:CGRectMake(12, glass.bounds.size.height - 32, w - 24, 24)] autorelease]; vol.autoresizingMask = UIViewAutoresizingFlexibleWidth; [glass addSubview:vol];
        NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:@"rd_band"]; band = [([[RDStations bands] containsObject:saved] ? saved : @"Bay Area") copy];
        bandSeg.selectedSegmentIndex = [[RDStations bands] indexOfObject:band]; [self loadBand];
        [self refresh];
    }
    return self;
}
- (void)dealloc { [freq release]; [name release]; [song release]; [status release]; [button release]; [spinner release]; [bandSeg release]; [dialScroll release]; [dial release]; [band release]; [super dealloc]; }
- (void)loadBand {
    [dial removeFromSuperview]; [dial release];
    dial = [[RDDialView alloc] initWithStations:[RDStations stationsInBand:band] pointsPerMHz:110];
    [dialScroll addSubview:dial]; dialScroll.contentSize = dial.bounds.size; CGFloat half = dialScroll.bounds.size.width / 2;
    dialScroll.contentInset = UIEdgeInsetsMake(0, half, 0, half);   // so the first and last frequency can sit under the needle
    NSDictionary *cur = [[RDPlayer shared] station];
    NSArray *list = [RDStations stationsInBand:band]; NSDictionary *target = [[cur objectForKey:@"band"] isEqualToString:band] ? cur : ([list count] ? [list objectAtIndex:0] : nil);
    settling = YES; dialScroll.contentOffset = CGPointMake(target ? [dial xForFrequency:[[target objectForKey:@"freq"] doubleValue]] - half : -half, 0); settling = NO;
    [self updateReadout];
}
- (void)bandChanged { [band release]; band = [[[RDStations bands] objectAtIndex:bandSeg.selectedSegmentIndex] copy]; [[NSUserDefaults standardUserDefaults] setObject:band forKey:@"rd_band"]; [self loadBand]; }
- (double)centerFrequency { return [dial frequencyForX:dialScroll.contentOffset.x + dialScroll.bounds.size.width / 2]; }
- (NSDictionary *)nearestStation {
    double f = [self centerFrequency]; NSDictionary *best = nil; double bd = 1e9;
    for (NSDictionary *s in [RDStations stationsInBand:band]) { double d = fabs([[s objectForKey:@"freq"] doubleValue] - f); if (d < bd) { bd = d; best = s; } }
    return best;
}
- (void)updateReadout {
    RDPlayer *p = [RDPlayer shared]; NSDictionary *cur = [p station];
    if (settling || !dialScroll.dragging) { if (cur && ![[cur objectForKey:@"band"] isEqualToString:band] && [p state] != RDStopped) { freq.text = [[cur objectForKey:@"freq"] doubleValue] > 0 ? [NSString stringWithFormat:@"%.1f FM", [[cur objectForKey:@"freq"] doubleValue]] : @"WEB"; return; } }
    freq.text = [NSString stringWithFormat:@"%.1f FM", [self centerFrequency]];
}
- (void)scrollViewDidScroll:(UIScrollView *)sv { if (!settling) [self updateReadout]; }
- (void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)d { if (!d) [self snap]; }
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv { [self snap]; }
- (void)snap {   // settle the needle on the nearest station and play it
    NSDictionary *s = [self nearestStation]; if (!s) return;
    settling = YES; [dialScroll setContentOffset:CGPointMake([dial xForFrequency:[[s objectForKey:@"freq"] doubleValue]] - dialScroll.bounds.size.width / 2, 0) animated:YES];
    [self performSelector:@selector(settled) withObject:nil afterDelay:0.35];
    RDPlayer *p = [RDPlayer shared]; if (![[[p station] objectForKey:@"url"] isEqualToString:[s objectForKey:@"url"]] || [p state] == RDStopped || [p state] == RDFailed) [p play:s];
}
- (void)settled { settling = NO; [self updateReadout]; }
- (void)showStation:(NSDictionary *)s animated:(BOOL)a {
    NSString *b = [s objectForKey:@"band"]; if (![b length]) { [self updateReadout]; return; }
    if (![b isEqualToString:band]) { [band release]; band = [b copy]; bandSeg.selectedSegmentIndex = [[RDStations bands] indexOfObject:band]; [self loadBand]; return; }
    settling = YES; [dialScroll setContentOffset:CGPointMake([dial xForFrequency:[[s objectForKey:@"freq"] doubleValue]] - dialScroll.bounds.size.width / 2, 0) animated:a];
    [self performSelector:@selector(settled) withObject:nil afterDelay:a ? 0.35 : 0];
}
- (void)refresh {
    RDPlayer *p = [RDPlayer shared]; NSDictionary *s = [p station]; RDState st = [p state];
    name.text = s ? [s objectForKey:@"name"] : @"Tune the dial or pick a station";
    song.text = st == RDFailed ? ([p error] ?: @"Couldn't connect.") : ([p nowPlaying] ?: (s ? [s objectForKey:@"sub"] : @""));
    song.textColor = st == RDFailed ? [UIColor colorWithRed:0.75 green:0.1 blue:0.1 alpha:1] : [UIColor colorWithWhite:0.4 alpha:1];
    NSString *sleep = [p sleepEnd] ? [NSString stringWithFormat:@"  ·  sleeps in %ld min", (long)ceil([[p sleepEnd] timeIntervalSinceNow] / 60)] : @"";
    status.text = [NSString stringWithFormat:@"%@%@", st == RDPlaying ? @"Live" : st == RDConnecting ? @"Connecting..." : @"Stopped", sleep];
    BOOL on = st == RDPlaying || st == RDConnecting;
    [button setImage:glyph(!on) forState:UIControlStateNormal]; button.hidden = st == RDConnecting;
    if (st == RDConnecting) [spinner startAnimating]; else [spinner stopAnimating];
    [self updateReadout];
}
@end

#pragma mark - Stations
@implementation RDStationsViewController
- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.title = @"Radio";
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)] autorelease];
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Sleep" style:UIBarButtonItemStyleBordered target:self action:@selector(sleep)] autorelease];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerChanged) name:RDPlayerChanged object:nil];
    }
    return self;
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [tuner release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    tuner = [[RDTunerView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 268)]; tuner.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = tuner;
    [NSTimer scheduledTimerWithTimeInterval:30 target:tuner selector:@selector(refresh) userInfo:nil repeats:YES];
}
- (BOOL)canBecomeFirstResponder { return YES; }
- (void)viewDidAppear:(BOOL)a {
    [super viewDidAppear:a]; [self becomeFirstResponder]; [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:@"rd_test_play"]) { NSInteger i = [d integerForKey:@"rd_test_play"]; [d removeObjectForKey:@"rd_test_play"]; [d synchronize]; NSDictionary *s = [[RDStations all] objectAtIndex:i]; [[RDPlayer shared] play:s]; [tuner showStation:s animated:NO]; }
    if ([d boolForKey:@"rd_test_sheet"]) { [d removeObjectForKey:@"rd_test_sheet"]; [d synchronize]; [self sleep]; }
    if ([d boolForKey:@"rd_test_add"]) { [d removeObjectForKey:@"rd_test_add"]; [d synchronize]; [self add]; }
}
- (void)remoteControlReceivedWithEvent:(UIEvent *)e {
    RDPlayer *p = [RDPlayer shared];
    switch (e.subtype) {
        case UIEventSubtypeRemoteControlTogglePlayPause: [p toggle]; break;
        case UIEventSubtypeRemoteControlPlay: if ([p state] == RDStopped || [p state] == RDFailed) [p toggle]; break;
        case UIEventSubtypeRemoteControlPause: case UIEventSubtypeRemoteControlStop: if ([p state] != RDStopped) [p stop]; break;
        case UIEventSubtypeRemoteControlNextTrack: [self step:1]; break;
        case UIEventSubtypeRemoteControlPreviousTrack: [self step:-1]; break;
        default: break;
    }
}
- (void)step:(NSInteger)by {
    NSArray *all = [RDStations all]; NSDictionary *cur = [[RDPlayer shared] station]; NSInteger i = cur ? [all indexOfObject:cur] : NSNotFound; if (i == NSNotFound) i = 0; else i = (i + by + [all count]) % [all count];
    NSDictionary *s = [all objectAtIndex:i]; [[RDPlayer shared] play:s]; [tuner showStation:s animated:YES];
}
- (void)playerChanged { [tuner refresh]; [self.tableView reloadData]; }
- (void)add { RDAddViewController *v = [[RDAddViewController alloc] init]; UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:v]; n.navigationBar.tintColor = self.navigationController.navigationBar.tintColor; [self presentModalViewController:n animated:YES]; [n release]; [v release]; }
- (void)sleep {
    UIActionSheet *a = [[UIActionSheet alloc] initWithTitle:@"Stop playing in" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:[[RDPlayer shared] sleepEnd] ? @"Turn off sleep timer" : nil otherButtonTitles:@"15 minutes", @"30 minutes", @"1 hour", @"2 hours", nil];
    [a showInView:self.view]; [a release];
}
- (void)actionSheet:(UIActionSheet *)a clickedButtonAtIndex:(NSInteger)i {
    if (i == a.cancelButtonIndex) return;
    if (a.destructiveButtonIndex >= 0 && i == a.destructiveButtonIndex) { [[RDPlayer shared] setSleepMinutes:0]; return; }
    NSInteger idx = i - a.firstOtherButtonIndex; NSInteger mins[] = {15, 30, 60, 120}; if (idx >= 0 && idx < 4) [[RDPlayer shared] setSleepMinutes:mins[idx]];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return [[RDStations groups] count]; }
- (NSString *)groupAt:(NSInteger)s { return [[RDStations groups] objectAtIndex:s]; }
- (BOOL)isCustom:(NSInteger)s { return s == (NSInteger)[[RDStations groups] count] - 1; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { NSInteger n = [[RDStations stationsInGroup:[self groupAt:s]] count]; return [self isCustom:s] ? n + 1 : n; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return [self groupAt:s]; }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s { return [self isCustom:s] ? @"Any Icecast or Shoutcast MP3 or AAC stream works. Paste the address that ends in .mp3 or the station's stream link." : nil; }
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip { return 50; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSArray *list = [RDStations stationsInGroup:[self groupAt:ip.section]];
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil] autorelease];
    c.detailTextLabel.textColor = [UIColor grayColor];
    if (ip.row >= (NSInteger)[list count]) { c.textLabel.text = @"Add a station..."; c.textLabel.textColor = tint(1); return c; }
    NSDictionary *s = [list objectAtIndex:ip.row]; c.textLabel.text = [s objectForKey:@"name"]; c.detailTextLabel.text = [s objectForKey:@"sub"];
    BOOL cur = [[[[RDPlayer shared] station] objectForKey:@"url"] isEqualToString:[s objectForKey:@"url"]];
    c.accessoryType = cur ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone; c.textLabel.textColor = cur ? tint(1) : [UIColor blackColor];
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSArray *list = [RDStations stationsInGroup:[self groupAt:ip.section]];
    if (ip.row >= (NSInteger)[list count]) { [self add]; return; }
    NSDictionary *s = [list objectAtIndex:ip.row]; RDPlayer *p = [RDPlayer shared];
    if ([[[p station] objectForKey:@"url"] isEqualToString:[s objectForKey:@"url"]] && [p state] != RDStopped && [p state] != RDFailed) [p stop]; else { [p play:s]; [tuner showStation:s animated:YES]; }
    [tv scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return [self isCustom:ip.section] && ip.row < (NSInteger)[[RDStations custom] count]; }
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)st forRowAtIndexPath:(NSIndexPath *)ip {
    if (st != UITableViewCellEditingStyleDelete) return;
    NSMutableArray *a = [NSMutableArray arrayWithArray:[RDStations custom]]; [a removeObjectAtIndex:ip.row]; [RDStations setCustom:a]; [tv reloadData];
}
@end

#pragma mark - Add a station
@implementation RDAddViewController
- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.title = @"Add Station";
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)] autorelease];
    }
    return self;
}
- (void)dealloc { [nameField release]; [urlField release]; [super dealloc]; }
- (UITextField *)field:(NSString *)ph { UITextField *f = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 280, 30)]; f.placeholder = ph; f.font = [UIFont systemFontOfSize:16]; f.delegate = self; f.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter; f.clearButtonMode = UITextFieldViewModeWhileEditing; f.autocapitalizationType = UITextAutocapitalizationTypeNone; f.autocorrectionType = UITextAutocorrectionTypeNo; return f; }
- (void)viewDidLoad { [super viewDidLoad]; nameField = [self field:@"Station name"]; nameField.autocapitalizationType = UITextAutocapitalizationTypeWords; urlField = [self field:@"http://stream.example.com/live.mp3"]; urlField.keyboardType = UIKeyboardTypeURL; urlField.returnKeyType = UIReturnKeyDone; }
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; [nameField becomeFirstResponder]; }
- (BOOL)textFieldShouldReturn:(UITextField *)f { if (f == nameField) [urlField becomeFirstResponder]; else [self save]; return YES; }
- (void)cancel { [self dismissModalViewControllerAnimated:YES]; }
- (void)save {
    NSString *n = [nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], *u = [urlField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![u length]) return; if (![u hasPrefix:@"http"]) u = [@"http://" stringByAppendingString:u]; if (![n length]) n = [[NSURL URLWithString:u] host] ?: @"Station";
    NSMutableArray *a = [NSMutableArray arrayWithArray:[RDStations custom]];
    [a addObject:[NSDictionary dictionaryWithObjectsAndKeys:n, @"name", u, @"sub", u, @"url", @"Your stations", @"group", @"", @"band", [NSNumber numberWithDouble:0], @"freq", nil]]; [RDStations setCustom:a];
    [self dismissModalViewControllerAnimated:YES];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 1; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return 2; }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s { return @"Stations publish a stream address, usually an .mp3 or Icecast link. Look for \"listen in your player\" or \"direct stream\" on their site."; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease]; c.selectionStyle = UITableViewCellSelectionStyleNone;
    UITextField *f = ip.row == 0 ? nameField : urlField; f.frame = CGRectMake(10, 7, c.contentView.bounds.size.width - 20, 30); f.autoresizingMask = UIViewAutoresizingFlexibleWidth; [c.contentView addSubview:f]; return c;
}
@end
