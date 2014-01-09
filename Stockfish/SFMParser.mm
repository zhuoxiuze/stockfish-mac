//
//  SFMParser.m
//  Stockfish
//
//  Created by Daylen Yang on 1/8/14.
//  Copyright (c) 2014 Daylen Yang. All rights reserved.
//

#import "SFMParser.h"
#import "SFMChessGame.h"

#include "../Chess/position.h"

using namespace Chess;

@implementation SFMParser

/*
 * Parses chess games from a PGN string.
 * Input: The full PGN string as read from disk.
 * Output: A mutable array of SFMChessGame objects.
 */
+ (NSMutableArray *)parseGamesFromString:(NSString *)str
{
    NSMutableArray *games = [NSMutableArray new];
    
    NSArray *lines = [str componentsSeparatedByString:@"\n"];
    NSMutableDictionary *tags;
    NSMutableString *moves;
    BOOL readingTags = NO;
    
    for (NSString *line in lines) {
        if ([line length] == 0) {
            continue;
        }
        if ([line characterAtIndex:0] == '[') {
            // This is a tag
            if (!readingTags) {
                readingTags = YES;
                if (tags && moves) {
                    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:[tags copy] andMoves:[moves copy]];
                    [games addObject:game];
                }
                tags = [NSMutableDictionary new];
                moves = [NSMutableString new];
            }
            
            NSArray *tokens = [line componentsSeparatedByString:@"\""];
            NSString *tagName = [tokens[0] substringWithRange:NSMakeRange(1, [tokens[0] length] - 2)];
            tags[tagName] = tokens[1];
        } else {
            // This must be move text
            if (readingTags) {
                readingTags = NO;
            }
            
            [moves appendString:line];
        }
    }
    // Upon reaching the end of the file we need to add the last game
    SFMChessGame *game = [[SFMChessGame alloc] initWithTags:[tags copy] andMoves:[moves copy]];
    [games addObject:game];
    return games;
    
}

/*
 * Parses moves out of a string.
 * Input: A string such as: "1. e4 e5 2. Nf3 Nc6" and so on
 * Output: A tokenized array such as: "["e4", "e5", "Nf3", "Nc6"] and so on
 */
+ (NSArray *)parseMoves:(NSString *)moves
{
    // Strip the period, space, and new line characters
    NSMutableCharacterSet *cSet = [[NSMutableCharacterSet alloc] init];
    [cSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [cSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
    NSArray *allTokens = [moves componentsSeparatedByCharactersInSet:cSet];
    
    // Eliminate all non-move tokens, such as move numbers, annotations, and variations
    int depth = 0;
    NSMutableArray *moveTokens = [NSMutableArray new];
    for (NSString *token in allTokens) {
        if ([token length] == 0) {
            continue;
        }
        if ([token rangeOfString:@"{"].location != NSNotFound ||
            [token rangeOfString:@"("].location != NSNotFound) {
            depth++;
        }
        if ([token rangeOfString:@"}"].location != NSNotFound ||
            [token rangeOfString:@")"].location != NSNotFound) {
            depth--;
        }
        
        if (depth < 0) {
            NSException *e = [NSException exceptionWithName:@"ParseErrorException" reason:@"Depth is negative" userInfo:nil];
            @throw e;
        }
        
        if (depth == 0 && [self isLetter:[token characterAtIndex:0]]) {
            [moveTokens addObject:token];
        }
    }
    
    return [moveTokens copy];
    
}


/*
 * Returns whether the character is a lower or upper-case letter.
 */
+ (BOOL)isLetter:(char)c
{
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}

@end
