/*
 * DTQueryStringBuilder.m
 */

#import "DITQueryStringBuilder.h"

@interface DITQueryStringBuilder() {
    
    NSMutableDictionary *_dictionary;
}

- (NSString*)_escapeObject:(id)object;

@end

@implementation DITQueryStringBuilder

#pragma mark - LIFECYCLE

- (id)initWithDictionary:(NSDictionary*)dictionary {
    
    self = [super init];
    if (self) {
        _dictionary = [dictionary mutableCopy];
    }
    return self;
}

- (id)initWithName:(id)name andValue:(id)value {
    
    self = [super init];
    if (self) {
        _dictionary = [[NSMutableDictionary alloc] init];
        [_dictionary setObject:[self _escapeObject:value] forKey:[self _escapeObject:name]];
    }
    return self;
}

- (id)init {
    
    self = [super init];
    if (self) {
        _dictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - BUILDER

- (void)add:(id)name andValue:(id)value {
    
    [_dictionary setObject:[self _escapeObject:value] forKey:[self _escapeObject:name]];
}

- (NSString*)queryString {
    
    NSMutableString *result = nil;
    NSArray         *keys   = [_dictionary allKeys];
    
    if ([keys count] > 0) {
        
        for (NSString *key in keys) {
            
            NSString *value = [_dictionary objectForKey:key];
            
            result == nil
                ? result = [[NSMutableString alloc] init]
                : [result appendFormat:@"&"];
            
            if (nil != key && nil != value) {
                [result appendFormat:@"%@=%@", key, value];
            } else if (nil != key) {
                [result appendFormat:@"%@", key];
            }
        }
    }
    return result;
}

#pragma mark - PRIVATE

- (NSString*)_escapeObject:(id)object {

    NSString *s = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                NULL,
                                                (__bridge CFStringRef)[NSString stringWithFormat: @"%@", object],
                                                NULL,
                                                CFSTR("!*'();:@&=+$,/?%#[]"),
                                                kCFStringEncodingUTF8));
    
    return s;
}

#pragma mark - CLEANUP CREW

- (void)dealloc {
}

@end
