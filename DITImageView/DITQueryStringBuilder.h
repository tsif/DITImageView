/*
 * DTQueryStringBuilder.h
 */

#import <Foundation/Foundation.h>

@interface DITQueryStringBuilder : NSObject

@property(nonatomic, strong) NSString *queryString;

- (id)initWithDictionary:(NSDictionary*)dictionary;
- (id)initWithName:(id)name andValue:(id)value;
- (id)init;

- (void)add:(id)name andValue:(id)value;

@end
