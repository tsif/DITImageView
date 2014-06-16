/*
 * DITDiskCacheManager.m
 */


#import "DITDiskCacheManager.h"
#import "DITNetworkManager.h"

static DITDiskCacheManager *_defaultManager = NULL;

@interface DITDiskCacheManager() { 
}

- (NSString *)_getUniquePathForUrlString:(NSString *)string;

@end

@implementation DITDiskCacheManager

#pragma mark - LIFE CYCLE

/* Access to singleton */
+ (DITDiskCacheManager*)defaultManager {    
    
	@synchronized (self) {
		if (_defaultManager == nil) {
			_defaultManager = [[DITDiskCacheManager alloc] init];
            
		}
	}
    return _defaultManager;
}

- (id)init {
    
    self = [super init];
    if (self) {
        if([DITNetworkManager defaultManager].hasNetwork == YES) {
        }
    }    
    
    return self;
}

#pragma mark - PATH & URLS

- (NSString *)_getUniquePathForUrlString:(NSString *)string {

    NSString *returnedFirstString  = [string stringByReplacingOccurrencesOfString:@"http://" withString:@""];    
    NSString *returnedSecondString = [returnedFirstString stringByReplacingOccurrencesOfString:@"." withString:@""]; 
    NSString *returnedThirdString  = [returnedSecondString stringByReplacingOccurrencesOfString:@"/" withString:@""]; 
    
    /* Generate a unique path to a resource representing the image you want */
    NSString *filename             = returnedThirdString;
    NSString *uniquePath           = [NSTemporaryDirectory() stringByAppendingPathComponent: filename];
    
    return uniquePath;
}

#pragma mark - DISK CACHING

- (void)clearCache {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:NSTemporaryDirectory() error:&error];
    for (NSString *file in cacheFiles) {
        error = nil;
        [fileManager removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:file] error:&error];
        /* handle error */
    }
}

- (BOOL)isImageInCache:(NSString *)imageURLString {
    
    if([imageURLString isEqualToString:@""]) {
        return NO;    
    }
    
    NSString *uniquePath = [self _getUniquePathForUrlString:imageURLString];
    
    /* Check for a cached version */
    if([[NSFileManager defaultManager] fileExistsAtPath: uniquePath]) {
        return YES;
    }
    return NO;
}

- (void)cacheImage:(NSString *)imageURLString withImage:(UIImage *)image {

    NSString *uniquePath = [self _getUniquePathForUrlString:imageURLString];
    
    /* Check for file existence */
    if(![[NSFileManager defaultManager] fileExistsAtPath: uniquePath]) {        
        // Is it PNG or JPG/JPEG?
        // Running the image representation function writes the data from the image to a file
        if([imageURLString rangeOfString: @".png" options: NSCaseInsensitiveSearch].location != NSNotFound) {
            [UIImagePNGRepresentation(image) writeToFile: uniquePath atomically: YES];
        } else if([imageURLString rangeOfString: @".jpg" options: NSCaseInsensitiveSearch].location != NSNotFound || 
                  [imageURLString rangeOfString: @".jpeg" options: NSCaseInsensitiveSearch].location != NSNotFound) {
            [UIImageJPEGRepresentation(image, 100) writeToFile: uniquePath atomically: YES];
        } else if([imageURLString rangeOfString: @".gif" options: NSCaseInsensitiveSearch].location != NSNotFound) {
            [UIImagePNGRepresentation(image) writeToFile: uniquePath atomically: YES];
        }
    }
}

- (UIImage *)getCachedImage:(NSString *)imageURLString {

    NSString *uniquePath = [self _getUniquePathForUrlString:imageURLString];
    UIImage *image       = nil;

    /* Check for a cached version */
    if([[NSFileManager defaultManager] fileExistsAtPath: uniquePath]) {        
               
        if(image == nil) {
            /* this is the cached image */
            image = [UIImage imageWithContentsOfFile: uniquePath];        
        }        
    } else {
        /* get a new one */        
        image = [UIImage imageWithContentsOfFile: uniquePath];
        [self cacheImage:imageURLString withImage:image];
    }

    return image;
}

@end
