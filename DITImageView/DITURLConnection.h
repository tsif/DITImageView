/*
 * DITURLConnection.h
 */


#import <Foundation/Foundation.h>

@interface DITURLConnection : NSURLConnection {
    NSMutableDictionary *_metaData;
}

/* add or replace a meta info property */
- (void)setMetaObject:(id) anObject forKey:(NSString *)aKey;

/* Get a meta info property */
- (id)metaObjectForKey:(NSString *)aKey;

/* remove a meta info property */
- (void)removeMetaObjectForKey:(NSString *)aKey;

@end
