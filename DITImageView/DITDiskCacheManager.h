/*
 * DITDiskCacheManager.h
 */


#import <Foundation/Foundation.h>

@interface DITDiskCacheManager : NSObject {
    
}

/* Singleton access */
+ (DITDiskCacheManager *)defaultManager;

- (void)cacheImage:(NSString*)imageURLString withImage:(UIImage*)image;
- (UIImage*)getCachedImage:(NSString*)imageURLString;
- (BOOL)isImageInCache:(NSString*)imageURLString;
- (void)clearCache;

@end
