#import <UIKit/UIKit.h>
// The tuner: frequency readout, a draggable FM dial with the band's stations at their real frequencies, play/stop, volume.
@interface RDDialView : UIView { NSArray *stations, *labels; double lo, hi; CGFloat ppm; }
- (id)initWithStations:(NSArray *)s pointsPerMHz:(CGFloat)p;
- (CGFloat)xForFrequency:(double)f; - (double)frequencyForX:(CGFloat)x;
@end
@interface RDMetalView : UIView { CGRect dialWindow; } @property (nonatomic, assign) CGRect dialWindow; @end   // brushed-metal face with a recessed glass window
@interface RDTunerView : UIView <UIScrollViewDelegate> { UILabel *freq, *name, *song, *status; UIButton *button; UIActivityIndicatorView *spinner; UISegmentedControl *bandSeg; UIScrollView *dialScroll; RDDialView *dial; RDMetalView *glass; NSString *band; BOOL settling, purged; }
- (void)refresh;
- (void)showStation:(NSDictionary *)s animated:(BOOL)a;   // move the dial to a station (switches band if needed)
- (void)purgeArt; - (void)restoreArt;   // drop the dial and metal bitmaps while playing in the background; draw them again on the way back
@end
@interface RDStationsViewController : UITableViewController <UIActionSheetDelegate> { RDTunerView *tuner; BOOL stale; NSString *shown; }
@end
@interface RDAddViewController : UITableViewController <UITextFieldDelegate> { UITextField *nameField, *urlField; }
@end
