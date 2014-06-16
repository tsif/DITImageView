DITImageView
============

UIView subclass that allows you to assign an image url property. Supports caching, visible progress and default image

Usage:

DITImageView *imageView  = [[DITImageView alloc] initWithFrame:(CGRect){{0.0f, 0.0f}, {150.0f, 150.0f}}];
imageView.customProgress = YES; // show image download progress with a progress bar
imageView.url            = @"http://i.imgur.com/1YQ4cy3.jpg";

The same as above applies if you have a DITImageView as an outlet in you storyboard or xib.
