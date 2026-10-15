#import <UIKit/UIKit.h>
// The tuner: frequency readout, a draggable FM dial with the band's stations at their real frequencies, play/stop, volume.
@interface RDDialView : UIView { NSArray *stations; double lo, hi; CGFloat ppm; }
- (id)initWithStations:(NSArray *)s pointsPerMHz:(CGFloat)p;
- (CGFloat)xForFrequency:(double)f; - (double)frequencyForX:(CGFloat)x;
@end
@interface RDMetalView : UIView { CGRect dialWindow; } @property (nonatomic, assign) CGRect dialWindow; @end   // brushed-metal face with a recessed glass window
@interface RDTunerView : UIView <UIScrollViewDelegate> { UILabel *freq, *name, *song, *status; UIButton *button; UIActivityIndicatorView *spinner; UISegmentedControl *bandSeg; UIScrollView *dialScroll; RDDialView *dial; NSString *band; BOOL settling; }
- (void)refresh;
- (void)showStation:(NSDictionary *)s animated:(BOOL)a;   // move the dial to a station (switches band if needed)
@end
@interface RDStationsViewController : UITableViewController <UIActionSheetDelegate> { RDTunerView *tuner; }
@end
@interface RDAddViewController : UITableViewController <UITextFieldDelegate> { UITextField *nameField, *urlField; }
@end
