/*
 * DITImageView.h
 */


#import <QuartzCore/QuartzCore.h>

#import "DITDiskCacheManager.h"
#import "DITImageView.h"
#import "DITNetworkManager.h"
#import "DITProgressView.h"
#import "DITURLConnection.h"

#define kDITIMAGEVIEWTIMEOUTINTERVAL 25.0f
#define kDITIMAGEVIEWTAG             3001
#define kDITIMAGEVIEWSPINNERTAG      10012
#define kDITIMAGEVIEWANIMATIONTIME   0.1f

@interface DITImageView() {    
    
    DITURLConnection  *_connectionptr;
    BOOL              _customProgress;
    NSString          *_url;             // image url
    UIViewContentMode _imageContentMode; // how to layout content
    NSMutableData     *_responseData;    // request response data
}

@property(nonatomic) BOOL dontAssignImage;

- (void)_startSpinner;
- (void)_stopSpinner;
- (void)_setImageInView:(UIImage *)image;
- (UIImage*)image:(UIImage*)sourceImage byScalingAndCroppingForSize:(CGSize)targetSize;

/* retrieve an image either from the online source or a plist */
- (BOOL)_commonRetrieve;

/* grab a saved image */
- (void)_loadFromCache;

/* save an image to the cache via the disk cache manager */
- (void)_saveImageToCache:(UIImage *)image;

- (BOOL)_isJPEGValid:(NSData *)jpeg;
- (void)_assignDefaultImage;

+ (BOOL)validateUrl:(NSString*)candidate;

@end
    
@implementation DITImageView

@synthesize ignoreCache;
@synthesize dontAssignImage;
@synthesize customProgress   = _customProgress;
@synthesize url              = _url;

#pragma mark - LIFECYCLE

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {                
        self.backgroundColor   = [UIColor whiteColor];        
		_imageContentMode      = UIViewContentModeScaleAspectFill;
        _defaultImage          = @"";
        
        dontAssignImage        = NO;
        self.ignoreCache       = NO;
    }
    return self;
}

- (void)_launchImageProcess {
    
	BOOL isInCache = [[DITDiskCacheManager defaultManager] isImageInCache:_url];
    
    if(self.ignoreCache == YES) {
        isInCache = NO;
    }
    
	if(nil == _url) {
		[self _stopSpinner];
		return;
	}
    
	if(isInCache) {
		[self _loadFromCache];
		[self _stopSpinner];		
	} else {
		if([DITNetworkManager defaultManager].hasNetwork && [_url isEqualToString:@""] == NO) {
			[self _commonRetrieve];
		}  else {
			UIImage *image = [UIImage imageNamed:_defaultImage];
			[self _setImageInView:image];
			[self _stopSpinner];					
		}
	}	
}

#pragma mark - ACCESSORS

- (UIImage*)getImage {
    
    UIImageView *imageView = (UIImageView*)[self viewWithTag:kDITIMAGEVIEWTAG];
    return imageView.image;
}

- (void)_assignDefaultImage {
 
    UIImage *image = [UIImage imageNamed:_defaultImage];
    [self _setImageInView:image];
}

#pragma mark - PROPERTY OVERRIDES

- (void)setUrl:(NSString *)url {
    
    BOOL isvaildurl = [DITImageView validateUrl:url];
   
    if(_customProgress == YES) {
        DITProgressView* progressview = (DITProgressView*)[self viewWithTag:kDITIMAGEVIEWSPINNERTAG]; 
        progressview.progress = 0.0f;
        progressview.hidden   = YES;
    }
    
    if(_connectionptr != nil) {
        [_connectionptr cancel];
        _connectionptr = nil;
    }
    
    /* check empty string */
    _url = [url copy];
    if([_url isEqualToString:@""] == YES)  {
       
        return;
    }
    
    /* check if not url (as in bundle) */
    if(isvaildurl == NO) {                       
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,  0ul);
        dispatch_async(queue, ^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self _assignDefaultImage];
            });
        });
        
        return;
    }
    
    BOOL isInCache = [[DITDiskCacheManager defaultManager] isImageInCache:_url];
    if(nil == _url) {
        return;
    }
    
    if(self.ignoreCache == YES) {
        isInCache = NO;
    }
    
    if(isInCache) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(queue, ^{         
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self _loadFromCache];
            });
        });
    } else {
        
        UIImageView *imageView = (UIImageView*)[self viewWithTag:kDITIMAGEVIEWTAG];
        if(nil != imageView) {                             
            imageView.alpha = 0.0f;
        }
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,  0ul);
        dispatch_async(queue, ^{         
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self _startSpinner];
                [self _launchImageProcess];
            });
        });
    }
    return;
}

#pragma mark - IMAGE RETRIEVAL AND ASSIGNMENT

- (BOOL)_commonRetrieve {    
	
    if(!_url) {
        return NO;
	}
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url] 
    													   cachePolicy:NSURLRequestReloadIgnoringCacheData
													   timeoutInterval:kDITIMAGEVIEWTIMEOUTINTERVAL];
    
	DITURLConnection *connection = [[DITURLConnection alloc] initWithRequest:request delegate:self];
    [connection setMetaObject:_url forKey:@"url"];
    
    return YES;
}

- (void)_loadFromCache {

    UIImage* image = [[DITDiskCacheManager defaultManager] getCachedImage:_url];
    [self _setImageInView:image];  
}

- (void)_saveImageToCache:(UIImage *)image {    
    [[DITDiskCacheManager defaultManager] cacheImage:_url withImage:image];
}

- (void) _setImageInView:(UIImage *)image {
    
    UIImage *newImage = image;
    
    if(nil == image) {		
		return;
    }
    
    if(self.dontAssignImage == NO) {
        
        UIImageView *imageView = (UIImageView*)[self viewWithTag:kDITIMAGEVIEWTAG];
        if(nil == imageView) {        
            imageView             = [[UIImageView alloc] initWithImage:newImage];
            imageView.alpha       = 0.0f;
            imageView.contentMode = _imageContentMode;
            imageView.tag         = kDITIMAGEVIEWTAG;
            
            [self addSubview:imageView];
            [self sendSubviewToBack:imageView];
            imageView.alpha       = 1.0f;
        } else {          
            
            if(self.ignoreCache == YES) {
                
                [imageView removeFromSuperview];
                
                imageView             = [[UIImageView alloc] initWithImage:newImage];
                imageView.alpha       = 0.0f;
                imageView.contentMode = _imageContentMode;
                imageView.tag         = kDITIMAGEVIEWTAG;
                
                [self addSubview:imageView];
                [self sendSubviewToBack:imageView];
                imageView.alpha       = 1.0f;
                
            } else {
                imageView.image = newImage;
                imageView.alpha = 1.0f;
            }
        }
        imageView.frame = (CGRect){0.0f, 0.0f, self.frame.size.width, self.frame.size.height};
    }
	
    if(self.ignoreCache == YES) {
        [self setNeedsDisplay];
    }
    
    return;
}

#pragma mark - ANIMATION DELEGATE 

- (void)imageViewAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [self setNeedsDisplay];
}

#pragma mark - URL CONNECTION DELEGATE

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    _responseData = [[NSMutableData alloc] init];
    
    if([connection isKindOfClass:[DITURLConnection class]]) {
        DITURLConnection *conn       = (DITURLConnection*)connection;
        NSNumber         *filesize   = [NSNumber numberWithLongLong:[response expectedContentLength]];
        [conn setMetaObject:filesize forKey:@"filesize"];
    }    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
   
    [_responseData appendData:data];
    
    if([connection isKindOfClass:[DITURLConnection class]]) {
     
        DITURLConnection *connection = (DITURLConnection*)connection;
        NSNumber *filesize           = [connection metaObjectForKey:@"filesize"];
        NSNumber *resourceLength     = [NSNumber numberWithUnsignedInteger:[_responseData length]];
     
        DITProgressView* progressview = (DITProgressView*)[self viewWithTag:kDITIMAGEVIEWSPINNERTAG];
        if(nil != progressview && _customProgress == YES) {
            progressview.progress = [resourceLength floatValue] / [filesize floatValue];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    if(_responseData) {
		_responseData = nil;
	}
    
	connection = nil;
	
	[self _stopSpinner];
    
    /* and set the default image */
    UIImage *image = [UIImage imageNamed:_defaultImage];
    [self _setImageInView:image];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection  {
    
    DITURLConnection *conn = (DITURLConnection*)connection;
    
    /* check if we have received the right file size (buffer not corrupt */
    NSInteger filesize = [[conn metaObjectForKey:@"filesize"] intValue];
    NSInteger datasize = [_responseData length];
    
    unsigned char *ptr = (unsigned char *)[_responseData bytes];	
    
    /* check if the response data are supported image types in our case png and jpeg */
    
    NSLog(@"size: %d", filesize);
    
    if(filesize != datasize) {
        [self _setImageInView:[UIImage imageNamed:_defaultImage]];
        
    } else if(ptr) {
        
		if(((ptr[0] == 0x89) && (ptr[1] == 0x50)) ||  /* check if it's a png header */
           ((ptr[0] == 0xFF) && (ptr[1] == 0xD8)) ||  /* check if it's a jpeg header */
           ((ptr[0] == 0x47) && (ptr[1] == 0x49))) {  /* check if it's a gif header */
            UIImage *image = [[UIImage alloc] initWithData:_responseData];
            [self _setImageInView:image];
            [self _saveImageToCache:image];
            
        } else {
			[self _setImageInView:[UIImage imageNamed:_defaultImage]];
		}
	}   
    
	connection = nil;
    
    if(_responseData) {
		_responseData = nil;
	}
    
    [self _stopSpinner];
}

#pragma mark - UTILITIES

- (BOOL)_isJPEGValid:(NSData *)jpeg {
    
    if ([jpeg length] < 4) {
        return NO;
    }
    
    const char * bytes = (const char *)[jpeg bytes];
    if (bytes[0] != 0xFF || bytes[1] != 0xD8) {
        return NO;
    }
    
    if (bytes[[jpeg length] - 2] != 0xFF || bytes[[jpeg length] - 1] != 0xD9) {
        return NO;
    }
    
    return YES;
}

#pragma mark - SPINNER

- (void)_startSpinner {    
           
    if(self.frame.size.width <= 30.0f) {
        return;
    }
    
    if(_customProgress == YES) {
        
        DITProgressView* progressview = (DITProgressView*)[self viewWithTag:kDITIMAGEVIEWSPINNERTAG];    
        if(nil == progressview) {
            DITProgressView *progressview = [[DITProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width / 1.5f, 10.0f)];
            progressview.tag              = kDITIMAGEVIEWSPINNERTAG;
            progressview.hidden           = YES;
            [progressview setCenter:CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height / 2.0f)];
            [self addSubview:progressview];
            
            progressview.hidden = NO;
        } else {
            progressview.hidden = NO;    
        } 
        
    } else if(self.frame.size.width > 30.0f) {
   
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self viewWithTag:kDITIMAGEVIEWSPINNERTAG];
        if(nil == spinner) {
            spinner                  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.hidesWhenStopped = YES;        
            spinner.frame            = CGRectMake(0.0f, 0.0f, 15.0f, 15.0f);	
            spinner.tag              = kDITIMAGEVIEWSPINNERTAG;
           
            [spinner setCenter:CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height / 2.0f)];
            [self addSubview:spinner];
        }        
        [spinner startAnimating];
    }
}

- (void)_stopSpinner {    
    
    if(self.frame.size.width <= 30.0f) {
        return;
    }
    
    if(_customProgress == YES) {
        DITProgressView* progressview = (DITProgressView*)[self viewWithTag:kDITIMAGEVIEWSPINNERTAG];
        progressview.hidden           = YES;
    } else if(self.frame.size.width > 30.0f) {
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self viewWithTag:kDITIMAGEVIEWSPINNERTAG];
        [spinner stopAnimating];
    }    
}

#pragma mark - UTILITIES

- (UIImage*)image:(UIImage*)sourceImage byScalingAndCroppingForSize:(CGSize)targetSize {
    
    UIImage *newImage      = nil;
    CGSize  imageSize      = sourceImage.size;
    CGFloat width          = imageSize.width;
    CGFloat height         = imageSize.height;
    CGFloat targetWidth    = targetSize.width ;
    CGFloat targetHeight   = targetSize.height;
    CGFloat scaleFactor    = 0.0;
    CGFloat scaledWidth    = targetWidth;
    CGFloat scaledHeight   = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0f, 0.0f);
    
    if(CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor  = targetWidth  / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            /* scale to fit height */
            scaleFactor = widthFactor;
        } else {
            /* scale to fit width */
            scaleFactor = heightFactor;
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        /* center the image */
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    /* pop the context to get back to the default */
    UIGraphicsEndImageContext();
    return newImage;
}

+ (BOOL)validateUrl:(NSString*)candidate {
    
    NSString *urlRegEx   = @".*";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    
    return [urlTest evaluateWithObject:candidate];
    
}

#pragma mark - CLEANUP CREW

- (void)dealloc {
}

@end
