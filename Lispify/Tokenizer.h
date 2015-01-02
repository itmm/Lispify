@import Foundation;

@interface Tokenizer : NSObject

    + (instancetype) tokenizerWithString: (NSString *) source;

    - (unsigned char) current;
    - (unsigned char) next;

@end
