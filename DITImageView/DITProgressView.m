/*
 * DITProgressView.m
 */


#import "DITProgressView.h"

#define kProgressBarHeight   15.0f
#define kProgressBarWidth	175.0f

@interface DITProgressView() {
    float progress ;
	UIColor *innerColor ;
	UIColor *outerColor ;
    UIColor *emptyColor ;
}

@end

@implementation DITProgressView

@synthesize innerColor ;
@synthesize outerColor ;
@synthesize emptyColor ;
@synthesize progress ;

#pragma mark - LIFECYCLE

- (id)init {
	return [self initWithFrame: CGRectZero] ;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame: frame] ;
	if (self)
	{
		self.backgroundColor = [UIColor clearColor] ;
		self.innerColor = [UIColor grayColor] ;
		self.outerColor = [UIColor grayColor] ;
		self.emptyColor = [UIColor clearColor] ;
		if (frame.size.width == 0.0f)
			frame.size.width = kProgressBarWidth ;
	}
	return self ;
}

#pragma mark - PROPERTIES

- (void)setProgress:(float)theProgress {
	/* make sure the user does not try to set the progress outside of the bounds */
	if (theProgress > 1.0f)
		theProgress = 1.0f ;
	if (theProgress < 0.0f)
		theProgress = 0.0f ;
	
	progress = theProgress ;
	[self setNeedsDisplay] ;
}

- (void)setFrame:(CGRect)frame {
	// we set the height ourselves since it is fixed
	frame.size.height = kProgressBarHeight ;
	[super setFrame: frame] ;
}

- (void)setBounds:(CGRect)bounds {
	// we set the height ourselves since it is fixed
	bounds.size.height = kProgressBarHeight ;
	[super setBounds: bounds] ;
}

#pragma mark == DRAWING ==

- (void)drawRect:(CGRect)rect {
    
	CGContextRef context = UIGraphicsGetCurrentContext() ;
	
	/* save the context */
	CGContextSaveGState(context) ;
	
	/* allow antialiasing */
	CGContextSetAllowsAntialiasing(context, TRUE) ;
	
	/* we first draw the outter rounded rectangle */
	rect = CGRectInset(rect, 1.0f, 1.0f) ;
	CGFloat radius = 0.5f * rect.size.height ;
    
	[outerColor setStroke] ;
	CGContextSetLineWidth(context, 0.5f) ;
	
	CGContextBeginPath(context) ;
	CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMidY(rect)) ;
	CGContextAddArcToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetMidX(rect), CGRectGetMinY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect), CGRectGetMaxX(rect), CGRectGetMidY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect), CGRectGetMidX(rect), CGRectGetMaxY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect), CGRectGetMinX(rect), CGRectGetMidY(rect), radius) ;
	CGContextClosePath(context) ;
	CGContextDrawPath(context, kCGPathStroke) ;
    
    /* draw the empty rounded rectangle (shown for the "unfilled" portions of the progress */
    rect = CGRectInset(rect, 3.0f, 3.0f) ;
	radius = 0.5f * rect.size.height ;
	
	[emptyColor setFill] ;
	
	CGContextBeginPath(context) ;
	CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMidY(rect)) ;
	CGContextAddArcToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetMidX(rect), CGRectGetMinY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect), CGRectGetMaxX(rect), CGRectGetMidY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect), CGRectGetMidX(rect), CGRectGetMaxY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect), CGRectGetMinX(rect), CGRectGetMidY(rect), radius) ;
	CGContextClosePath(context) ;
	CGContextFillPath(context) ;
    
	/* draw the inside moving filled rounded rectangle */
	radius = 0.5f * rect.size.height ;
	
	/* make sure the filled rounded rectangle is not smaller than 2 times the radius */
	rect.size.width *= progress ;
	if (rect.size.width < 2 * radius)
		rect.size.width = 2 * radius ;
	
	[innerColor setFill] ;
	
	CGContextBeginPath(context) ;
	CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMidY(rect)) ;
	CGContextAddArcToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetMidX(rect), CGRectGetMinY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect), CGRectGetMaxX(rect), CGRectGetMidY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect), CGRectGetMidX(rect), CGRectGetMaxY(rect), radius) ;
	CGContextAddArcToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect), CGRectGetMinX(rect), CGRectGetMidY(rect), radius) ;
	CGContextClosePath(context) ;
	CGContextFillPath(context) ;
	
	/* restore the context */
	CGContextRestoreGState(context) ;
}

#pragma mark - CLEANUP CREW

- (void)dealloc {
}

@end
