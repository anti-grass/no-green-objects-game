#import <Cocoa/Cocoa.h>

@interface GameView : NSView
@property (nonatomic, strong) NSMutableArray *circles;
@property (nonatomic) int greenCirclesLeft;
@end

@implementation GameView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _circles = [NSMutableArray array];
        [self generateCircles];
    }
    return self;
}

- (void)generateCircles {
    _greenCirclesLeft = 0;
    [_circles removeAllObjects];
    for (int i = 0; i < 20; i++) {
        NSRect circle = NSMakeRect(arc4random_uniform(self.bounds.size.width - 50),
                                   arc4random_uniform(self.bounds.size.height - 50),
                                   50, 50);
        
        // Define the valid green color
        NSColor *validGreen = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        
        // Randomly decide if the circle is valid green or another color
        NSColor *color;
        if (arc4random_uniform(4) == 0) { // 25% chance of being valid green
            color = validGreen;
            _greenCirclesLeft++;
        } else {
            // Generate a non-green-like color
            do {
                color = [NSColor colorWithCalibratedRed:arc4random_uniform(256)/255.0
                                                  green:arc4random_uniform(128)/255.0 // Restrict green channel to avoid close shades
                                                   blue:arc4random_uniform(256)/255.0
                                                  alpha:1.0];
            } while ([self isColorCloseToGreen:color]);
        }
        
        [_circles addObject:@{@"rect": [NSValue valueWithRect:circle], @"color": color}];
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    for (NSDictionary *circleData in _circles) {
        NSColor *color = circleData[@"color"];
        NSRect circle = [circleData[@"rect"] rectValue];
        [color setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:circle];
        [path fill];
    }
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint clickPoint = [self convertPoint:event.locationInWindow fromView:nil];
    for (NSInteger i = _circles.count - 1; i >= 0; i--) {
        NSDictionary *circleData = _circles[i];
        NSRect circle = [circleData[@"rect"] rectValue];
        if (NSPointInRect(clickPoint, circle)) {
            NSColor *color = circleData[@"color"];
            
            // Check if the clicked color is the valid green
            if ([self isExactGreenColor:color]) {
                _greenCirclesLeft--;
                [_circles removeObjectAtIndex:i];
                if (_greenCirclesLeft == 0) {
                    [self showWinAlert];
                }
            } else {
                [self showErrorAlert];
                [self generateCircles];
            }
            break;
        }
    }
    [self setNeedsDisplay:YES];
}

- (void)showWinAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"You Win!"];
    [alert addButtonWithTitle:@"Play Again"];
    [alert addButtonWithTitle:@"Quit"];
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [self generateCircles];
    } else {
        [NSApp terminate:self];
    }
}

- (void)showErrorAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Oops! You clicked the wrong circle."];
    [alert addButtonWithTitle:@"Try Again"];
    [alert runModal];
}

- (BOOL)isExactGreenColor:(NSColor *)color {
    CGFloat red, green, blue, alpha;
    [[color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&red green:&green blue:&blue alpha:&alpha];
    
    // Compare against the exact green RGB values
    return (red == 0.0 && green == 1.0 && blue == 0.0);
}

- (BOOL)isColorCloseToGreen:(NSColor *)color {
    CGFloat red, green, blue, alpha;
    [[color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&red green:&green blue:&blue alpha:&alpha];
    
    // A color is "close to green" if its green component is significantly higher than red and blue
    return (green > 0.6 && green > red + 0.2 && green > blue + 0.2);
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        NSRect frame = NSMakeRect(0, 0, 800, 600);
        NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;
        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
        [window setTitle:@"Find the Exact Green Circle"];
        [window makeKeyAndOrderFront:nil];

        GameView *view = [[GameView alloc] initWithFrame:frame];
        [window setContentView:view];
        [app run];
    }
    return 0;
}
