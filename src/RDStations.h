#import <Foundation/Foundation.h>
// Station list: built-in presets (plain HTTP MP3 streams that still answer) plus the user's own.
// A station is {name, sub, url, group}.
@interface RDStations : NSObject
+ (NSArray *)groups;                 // ordered group titles
+ (NSArray *)stationsInGroup:(NSString *)g;
+ (NSArray *)custom; + (void)setCustom:(NSArray *)a;
+ (NSArray *)all;
+ (NSString *)lastURL; + (void)setLastURL:(NSString *)u;
@end
