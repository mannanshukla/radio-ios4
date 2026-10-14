#import <UIKit/UIKit.h>
#import "RDViewControllers.h"
#import "RDPlayer.h"
@interface RDAppDelegate : NSObject <UIApplicationDelegate> { UIWindow *window; UINavigationController *nav; }
@end
@implementation RDAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    RDStationsViewController *v = [[[RDStationsViewController alloc] init] autorelease];
    nav = [[UINavigationController alloc] initWithRootViewController:v]; nav.navigationBar.barStyle = UIBarStyleBlack;
    [window addSubview:nav.view]; [window makeKeyAndVisible];
    [RDPlayer shared];
    return YES;
}
- (void)dealloc { [nav release]; [window release]; [super dealloc]; }
@end
int main(int argc, char *argv[]) { NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init]; int r = UIApplicationMain(argc, argv, nil, @"RDAppDelegate"); [p release]; return r; }
