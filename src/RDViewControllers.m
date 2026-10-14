#import "RDViewControllers.h"
#import "RDStations.h"
#import "RDPlayer.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

static UIColor *amber(CGFloat a) { return [UIColor colorWithRed:1.0 green:0.72 blue:0.15 alpha:a]; }
static UIImage *glyph(BOOL play) {   // drawn, not typed: the ▶ character renders as an emoji on iOS 5
    CGFloat sz = 28; UIGraphicsBeginImageContextWithOptions(CGSizeMake(sz, sz), NO, 0); CGContextRef c = UIGraphicsGetCurrentContext();
    [amber(1) setFill];
    if (play) { CGContextMoveToPoint(c, 6, 3); CGContextAddLineToPoint(c, 26, 14); CGContextAddLineToPoint(c, 6, 25); CGContextClosePath(c); CGContextFillPath(c); }
    else CGContextFillRect(c, CGRectMake(5, 5, 18, 18));
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}
static UIFont *displayFont(CGFloat sz) { return [UIFont fontWithName:@"CourierNewPS-BoldMT" size:sz] ?: [UIFont boldSystemFontOfSize:sz]; }

#pragma mark - Now playing panel (looks like the dial display on a tuner)
@implementation RDNowPlayingView
- (id)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.backgroundColor = [UIColor blackColor];
        UIView *glass = [[[UIView alloc] initWithFrame:CGRectMake(10, 10, f.size.width - 20, f.size.height - 20)] autorelease];
        glass.backgroundColor = [UIColor colorWithRed:0.07 green:0.06 blue:0.03 alpha:1]; glass.layer.cornerRadius = 8; glass.layer.borderWidth = 1; glass.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1].CGColor; glass.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:glass];
        CGFloat w = glass.bounds.size.width;
        name = [[UILabel alloc] initWithFrame:CGRectMake(14, 10, w - 110, 24)]; name.font = displayFont(20); name.textColor = amber(1); name.backgroundColor = [UIColor clearColor]; name.adjustsFontSizeToFitWidth = YES; name.minimumFontSize = 12; [glass addSubview:name];
        song = [[UILabel alloc] initWithFrame:CGRectMake(14, 36, w - 110, 40)]; song.font = [UIFont boldSystemFontOfSize:14]; song.textColor = [UIColor whiteColor]; song.backgroundColor = [UIColor clearColor]; song.numberOfLines = 2; [glass addSubview:song];
        status = [[UILabel alloc] initWithFrame:CGRectMake(14, 78, w - 110, 16)]; status.font = [UIFont systemFontOfSize:11]; status.textColor = [UIColor colorWithWhite:0.6 alpha:1]; status.backgroundColor = [UIColor clearColor]; [glass addSubview:status];
        button = [[UIButton buttonWithType:UIButtonTypeCustom] retain]; button.frame = CGRectMake(w - 86, 16, 72, 72); button.layer.cornerRadius = 36; button.layer.borderWidth = 2; button.layer.borderColor = amber(1).CGColor; button.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
        
        [button addTarget:[RDPlayer shared] action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside]; [glass addSubview:button];
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]; spinner.center = button.center; spinner.hidesWhenStopped = YES; [glass addSubview:spinner];
        MPVolumeView *vol = [[[MPVolumeView alloc] initWithFrame:CGRectMake(14, glass.bounds.size.height - 34, w - 28, 24)] autorelease]; vol.autoresizingMask = UIViewAutoresizingFlexibleWidth; [glass addSubview:vol];
        [self refresh];
    }
    return self;
}
- (void)dealloc { [name release]; [song release]; [status release]; [button release]; [spinner release]; [super dealloc]; }
- (void)refresh {
    RDPlayer *p = [RDPlayer shared]; NSDictionary *s = [p station]; RDState st = [p state];
    name.text = s ? [s objectForKey:@"name"] : @"RADIO";
    song.text = st == RDFailed ? ([p error] ?: @"Couldn't connect.") : ([p nowPlaying] ?: (s ? [s objectForKey:@"sub"] : @"Pick a station below."));
    song.textColor = st == RDFailed ? [UIColor colorWithRed:1 green:0.5 blue:0.5 alpha:1] : [UIColor whiteColor];
    NSString *sleep = [p sleepEnd] ? [NSString stringWithFormat:@"  ·  sleeps in %ld min", (long)ceil([[p sleepEnd] timeIntervalSinceNow] / 60)] : @"";
    status.text = [NSString stringWithFormat:@"%@%@", st == RDPlaying ? @"Live" : st == RDConnecting ? @"Connecting..." : st == RDFailed ? @"Stopped" : @"Stopped", sleep];
    BOOL on = st == RDPlaying || st == RDConnecting;
    [button setImage:glyph(!on) forState:UIControlStateNormal]; button.hidden = st == RDConnecting;
    if (st == RDConnecting) [spinner startAnimating]; else [spinner stopAnimating];
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
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [now release]; [super dealloc]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    now = [[RDNowPlayingView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 150)]; now.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = now;
    [NSTimer scheduledTimerWithTimeInterval:30 target:now selector:@selector(refresh) userInfo:nil repeats:YES];   // keeps the sleep countdown honest
}
- (BOOL)canBecomeFirstResponder { return YES; }   // headphone clicker and lock screen buttons land here
- (void)viewDidAppear:(BOOL)a {
    [super viewDidAppear:a]; [self becomeFirstResponder]; [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:@"rd_test_play"]) { NSInteger i = [d integerForKey:@"rd_test_play"]; [d removeObjectForKey:@"rd_test_play"]; [d synchronize]; [[RDPlayer shared] play:[[RDStations all] objectAtIndex:i]]; }
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
- (void)step:(NSInteger)by {   // next/previous station from the headphone clicker
    NSArray *all = [RDStations all]; NSDictionary *cur = [[RDPlayer shared] station]; NSInteger i = cur ? [all indexOfObject:cur] : NSNotFound; if (i == NSNotFound) i = 0; else i = (i + by + [all count]) % [all count];
    [[RDPlayer shared] play:[all objectAtIndex:i]];
}
- (void)playerChanged { [now refresh]; [self.tableView reloadData]; }
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
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { NSInteger n = [[RDStations stationsInGroup:[self groupAt:s]] count]; return s == 5 ? n + 1 : n; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return [self groupAt:s]; }
- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s { return s == 5 ? @"Any Icecast or Shoutcast MP3 stream works. Paste the address that ends in .mp3 or the station's stream link." : nil; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSArray *list = [RDStations stationsInGroup:[self groupAt:ip.section]];
    UITableViewCell *c = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil] autorelease];
    if (ip.row >= (NSInteger)[list count]) { c.textLabel.text = @"Add a station..."; c.textLabel.textColor = [UIColor colorWithRed:0.75 green:0.38 blue:0.05 alpha:1]; return c; }
    NSDictionary *s = [list objectAtIndex:ip.row]; c.textLabel.text = [s objectForKey:@"name"]; c.detailTextLabel.text = [s objectForKey:@"sub"]; c.detailTextLabel.textColor = [UIColor grayColor];
    BOOL cur = [[[[RDPlayer shared] station] objectForKey:@"url"] isEqualToString:[s objectForKey:@"url"]];
    c.accessoryType = cur ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone; c.textLabel.textColor = cur ? [UIColor colorWithRed:0.75 green:0.38 blue:0.05 alpha:1] : [UIColor blackColor];
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSArray *list = [RDStations stationsInGroup:[self groupAt:ip.section]];
    if (ip.row >= (NSInteger)[list count]) { [self add]; return; }
    NSDictionary *s = [list objectAtIndex:ip.row]; RDPlayer *p = [RDPlayer shared];
    if ([[[p station] objectForKey:@"url"] isEqualToString:[s objectForKey:@"url"]] && [p state] != RDStopped && [p state] != RDFailed) [p stop]; else [p play:s];
    [tv scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return ip.section == 5 && ip.row < (NSInteger)[[RDStations custom] count]; }
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
    [a addObject:[NSDictionary dictionaryWithObjectsAndKeys:n, @"name", u, @"sub", u, @"url", @"Your stations", nil]]; [RDStations setCustom:a];
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
