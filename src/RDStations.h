#import <Foundation/Foundation.h>
// Station list: built-in presets (plain HTTP MP3 streams that still answer) plus the user's own.
// A station is {name, sub, url, group}.
@interface RDStations : NSObject
+ (NSArray *)groups;                 // ordered group titles
+ (NSArray *)bands;                  // dial regions
+ (NSArray *)stationsInBand:(NSString *)b;   // sorted by frequency; a station is {name, sub, url, group, band, freq}
+ (NSArray *)stationsInGroup:(NSString *)g;
+ (NSArray *)custom; + (void)setCustom:(NSArray *)a;
+ (NSArray *)all;
+ (NSString *)lastURL; + (void)setLastURL:(NSString *)u;
+ (NSDictionary *)lastStation;       // the station behind lastURL, if it still exists
@end
