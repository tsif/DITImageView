/*
 * DITURLConnection.m
 */


#import "DITURLConnection.h"

@implementation DITURLConnection

#pragma mark - LIFE CYCLE 

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate {
	self = [super initWithRequest:request delegate:delegate];
	if(self) {
        /* At init time we create a dictionary to hold arbitrary key values */
		_metaData = [[NSMutableDictionary alloc] init];
	}
	return self;
}

/* override NSObject's desription to call po in gdb and make debugging easier */
- (NSString *)description {
	return [NSString stringWithFormat:@"%@ with %d metadata ", [super description], [_metaData count]];
}


#pragma mark - PROPERTIES SETTER

- (void)setMetaObject:(id) anObject forKey:(NSString *)aKey {
    
    /* Add or replace a meta info property */
	if( (nil != anObject) &&  (nil != aKey) ){
		[_metaData setObject:anObject forKey:aKey];
	}	
}

- (id) metaObjectForKey:(NSString *)aKey {
    
	id result = nil;
    
	if(aKey) {
		result = [_metaData objectForKey:aKey];
	}
	return result;	
}

- (void) removeMetaObjectForKey:(NSString *)aKey {
    
	if (nil != aKey){
		[_metaData removeObjectForKey:aKey];
	}	
}

#pragma mark - CLEANUP CREW

- (void) dealloc {
}

@end
