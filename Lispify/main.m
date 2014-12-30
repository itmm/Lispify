@import Foundation;
@import Quartz;
@import CoreText;

#import "Pair.h"
#import "Tokenizer.h"

static Pair *parsePair(Tokenizer *tokenizer) {
    if ([tokenizer current] != 0 && [tokenizer current] <= ' ') [tokenizer next];
    if ([tokenizer current] == 0) { NSLog(@"pair not closed"); return nil; }
    if ([tokenizer current] == ')') { [tokenizer next]; return nil; }
    id car;
    id cdr;
    BOOL hidden = NO;
    
    if ([tokenizer current] == '~') {
        hidden = YES;
        [tokenizer next];
    }
    
    if ([tokenizer current] == '(') {
        [tokenizer next]; car = parsePair(tokenizer);
    } else {
        NSMutableString *value = [NSMutableString new];
        while ([tokenizer current] > ' ' && [tokenizer current] != ')') {
            [value appendString: [NSString stringWithFormat: @"%c", [tokenizer current]]];
            [tokenizer next];
        }
        car = [NSString stringWithString: value];
    }
    cdr = parsePair(tokenizer);
    return [Pair pairWithCar: car cdr: cdr hidden: hidden];
}

static Pair *parse(NSString *source) {
    Tokenizer *tokenizer = [Tokenizer tokenizerWithString: source];
    if ([tokenizer current] == '(') {
        [tokenizer next];
        return parsePair(tokenizer);
    }
    NSLog(@"no pair starting with '%c'", [tokenizer current]);
    return nil;
}

static NSInteger maxX = 0;
static NSInteger maxY = 0;

static BOOL contains(Pair *pair, NSInteger x, NSInteger y) {
    if (pair.x == x && pair.y == y) return YES;
    if ([pair.car isKindOfClass: Pair.class]) {
        if (contains(pair.car, x, y)) return YES;
    }
    if ([pair.cdr isKindOfClass: Pair.class]) {
        if (contains(pair.cdr, x, y)) return YES;
    }
    return NO;
}

static BOOL distribute(Pair *pair, Pair *ref) {
    static NSInteger x = 0;
    static NSInteger y = 0;
    
    if (ref && contains(ref, x, y)) return NO;
    
    pair.x = x;
    pair.y = y;
    if (x > maxX) maxX = x;
    if (y > maxY) maxY = y;
    
    if ([pair.car isKindOfClass: Pair.class]) {
        ++y;
        NSInteger oldX = x;
        if (!distribute(pair.car, ref)) { --y; return NO; }
        x = oldX;
        --y;
    }
    if ([pair.cdr isKindOfClass: Pair.class]) {
        NSInteger nextX = x + 1;
        for (;;) {
            x = nextX;
            if (distribute(pair.cdr, ref ?: pair)) break;
            ++nextX;
        }
    }
    
    return YES;
}

static NSMutableData *data = nil;

static size_t consumer_put(void *info, const void *buffer, size_t count) {
    NSMutableData *data = (__bridge NSMutableData *)(info);
    [data appendBytes: buffer length: count];
    return count;
}

static NSString *outPath = nil;

static void consumer_release(void *info) {
    NSMutableData *data = (__bridge NSMutableData *)(info);
    [data writeToFile: outPath atomically: YES];
    NSLog(@"done consuming");
}

static const CGFloat kLineWidth = 2;
static const CGFloat kRectWidth = 100;
static const CGFloat kBoxWidth = 2 * kRectWidth - kLineWidth;
static const CGFloat kSeparatorWidth = 100;
static const CGFloat kBoxHeight = kRectWidth;
static const CGFloat kSeparatorHeight = 100;

static CTFontRef font = NULL;
static NSColor *drawColor = nil;

static void drawTextInRect(CGContextRef ctx, CGRect frame, id obj) {
    if (!obj) {
        CGRect inner = CGRectInset(frame, 20, 20);
        CGContextMoveToPoint(ctx, inner.origin.x, inner.origin.y);
        CGContextAddLineToPoint(ctx, inner.origin.x + inner.size.width, inner.origin.y + inner.size.height);
        CGContextStrokePath(ctx);
    } else {
        NSString *value = [obj description];
        NSAttributedString *attributedValue = [[NSAttributedString alloc] initWithString:value attributes:@{ (NSString *) kCTFontAttributeName: (__bridge NSFont *) font, (NSString *)kCTForegroundColorAttributeName: (__bridge id) drawColor.CGColor}];
        CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef) attributedValue);
        
        CGRect textFrame = CTLineGetBoundsWithOptions(line, 0);
        CGPoint textOrigin = CGPointMake(frame.origin.x + (frame.size.width - textFrame.size.width)/2 - textFrame.origin.x, frame.origin.y + (frame.size.height - textFrame.size.height)/2 - textFrame.origin.y);
        CGContextSetTextPosition(ctx, textOrigin.x, textOrigin.y);
        CTLineDraw(line, ctx);
        CFRelease(line);
    }
}

static CGPoint offsetOfPair(Pair *pair) {
    return CGPointMake(pair.x * (kBoxWidth + kSeparatorWidth) + kLineWidth/2, (maxY - pair.y) * (kBoxHeight + kSeparatorHeight) + kLineWidth/2);
}
static void drawPair(CGContextRef ctx, Pair *pair) {
    CGPoint offset = offsetOfPair(pair);
    CGRect rect = CGRectMake(offset.x, offset.y, kRectWidth - 1, kBoxHeight - 1);
    
    if (!pair.hidden) {
        CGContextSetLineWidth(ctx, kLineWidth);
        CGContextStrokeRect(ctx, rect);
    }

    if ([pair.car isKindOfClass: Pair.class]) {
        if (!pair.hidden) {
            CGFloat x = rect.origin.x + rect.size.width/2;
            CGFloat y_from = rect.origin.y + rect.size.height/2;
            CGFloat y_to = offsetOfPair(pair.car).y + kBoxHeight + kLineWidth;
            CGContextStrokeEllipseInRect(ctx, CGRectMake(x - 10, y_from - 10, 20, 20));
            CGContextMoveToPoint(ctx, x, y_from);
            CGContextAddLineToPoint(ctx, x, y_to);
            CGContextStrokePath(ctx);
            CGContextMoveToPoint(ctx, x - 10, y_to + 20);
            CGContextAddLineToPoint(ctx, x, y_to);
            CGContextAddLineToPoint(ctx, x + 10, y_to + 20);
            CGContextStrokePath(ctx);
        }
        drawPair(ctx, pair.car);
    } else if (!pair.hidden) {
        drawTextInRect(ctx, rect, pair.car);
    }

    rect.origin.x += rect.size.width;
    if (!pair.hidden) {
        CGContextSetLineWidth(ctx, kLineWidth);
        CGContextStrokeRect(ctx, rect);
    }
    
    if ([pair.cdr isKindOfClass: Pair.class]) {
        if (!pair.hidden) {
            CGFloat x_from = offset.x + kRectWidth*3/2;
            CGFloat x_to = offsetOfPair(pair.cdr).x - kLineWidth;
            CGFloat y = offset.y + kBoxHeight/2;
            CGContextStrokeEllipseInRect(ctx, CGRectMake(x_from - 10, y - 10, 20, 20));
            CGContextMoveToPoint(ctx, x_from, y);
            CGContextAddLineToPoint(ctx, x_to, y);
            CGContextStrokePath(ctx);
            CGContextMoveToPoint(ctx, x_to - 20, y - 10);
            CGContextAddLineToPoint(ctx, x_to, y);
            CGContextAddLineToPoint(ctx, x_to - 20, y + 10);
            CGContextStrokePath(ctx);
        }
        drawPair(ctx, pair.cdr);
    } else if (!pair.hidden) {
        drawTextInRect(ctx, rect, pair.cdr);
    }
}

static void render(Pair *root) {
    data = [NSMutableData new];
    CGDataConsumerCallbacks callbacks = { consumer_put, consumer_release };
    CGDataConsumerRef consumer = CGDataConsumerCreate((__bridge void *)(data), &callbacks);
    if (!consumer) { NSLog(@"Can't create consumer"); return; }
    
    CGRect mediaBox = CGRectMake(0, 0, (maxX + 1) * (kBoxWidth + kSeparatorWidth) - kSeparatorWidth + kLineWidth, (maxY + 1) * (kBoxHeight + kSeparatorHeight) - kSeparatorHeight + kLineWidth);
    CGContextRef ctx = CGPDFContextCreate(consumer, &mediaBox, NULL);
    if (!ctx) { NSLog(@"Can't create context"); CGDataConsumerRelease(consumer); return; }
    
    font = CTFontCreateWithName(CFSTR("Helvetica"), 60, NULL);
    CGPDFContextBeginPage(ctx, NULL);
    CGContextSetStrokeColorWithColor(ctx, drawColor.CGColor);
    drawPair(ctx, root);
    CGPDFContextEndPage(ctx);
    
    CFRelease(font); font = NULL;
    CGContextRelease(ctx);
    
    CGDataConsumerRelease(consumer);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) { NSLog(@"wrong number of arguments: %@", @(argc - 1)); exit(EXIT_FAILURE); }
        
        drawColor = [NSColor blackColor];
        outPath = [@"~/Desktop/out.pdf" stringByExpandingTildeInPath];
        
        NSMutableString *source = [NSMutableString new];
        
        BOOL noMoreArgs = NO;
        for (NSInteger i = 1; i < argc; ++i) {
            NSString *argument = [NSString stringWithUTF8String: argv[i]];
            if (!noMoreArgs) {
                if ([argument isEqualToString: @"--"]) { noMoreArgs = YES; continue; }
                if ([argument isEqualToString: @"--color=white"]) { drawColor = [NSColor whiteColor]; continue; }
                if ([argument hasPrefix: @"--out="]) {
                    outPath = [[argument substringFromIndex: 6] stringByExpandingTildeInPath];
                    continue;
                }
            }
            if (source.length) { [source appendString: @" "]; }
            [source appendString: argument];
        }
        
        Pair *root = parse(source);
        if (root) {
            distribute(root, nil);
            render(root);
        }
    }
    return 0;
}
