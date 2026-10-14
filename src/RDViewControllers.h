#import <UIKit/UIKit.h>
@interface RDNowPlayingView : UIView { UILabel *name, *song, *status; UIButton *button; UIActivityIndicatorView *spinner; }
- (void)refresh;
@end
@interface RDStationsViewController : UITableViewController <UIActionSheetDelegate> { RDNowPlayingView *now; }
@end
@interface RDAddViewController : UITableViewController <UITextFieldDelegate> { UITextField *nameField, *urlField; }
@end
