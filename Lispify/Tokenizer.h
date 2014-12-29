@import Foundation;

@interface Tokenizer : NSObject

    + (instancetype) tokenizerWithString: (NSString *) source;

    - (char) current;
    - (char) next;

@end
