//
//  SourceEditorCommand.m
//  DLInsertImportExtension
//
//  Created by Dennis on 27/9/2016.
//  Copyright © 2016 Dennis. All rights reserved.
//

#import "SourceEditorCommand.h"

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    NSString *selectedPhase = [self selectedPhaseForInvocation:invocation];
    if (selectedPhase == nil) {
        completionHandler(nil);
        return;

    }
    
    // Check if file contains target import statement
    NSString *importStr = [NSString stringWithFormat:@"#import \"%@.h\"\n", selectedPhase];
    
    for (NSString *line in invocation.buffer.lines) {
        if ([line isEqualToString:importStr]) {
            NSLog(@"Import statement already exist on line: %ld", [invocation.buffer.lines indexOfObject:line]);
            completionHandler(nil);
            return;
        }
    }
    
    //find line number to add "#import ".h";
    NSInteger lineToAdd = [self lineNumberOfLastImportStatenent:invocation.buffer.lines];
    if (lineToAdd == NSNotFound) {
        lineToAdd = [self lineNumberForEmptyLine:invocation.buffer.lines];
    }
    if (lineToAdd == NSNotFound) {
        lineToAdd = [self lineNumberForLineAboveClassDefinition:invocation.buffer.lines];
    }
    if (lineToAdd != NSNotFound) {
        [invocation.buffer.lines insertObject:importStr atIndex:lineToAdd+1];
    }
    completionHandler(nil);
}

- (NSString *)selectedPhaseForInvocation:(XCSourceEditorCommandInvocation *)invocation{
    // get current selection
    NSMutableArray *selections = invocation.buffer.selections;
    XCSourceTextRange *selectRange = [selections firstObject];
    
    if (selectRange == nil ) {
        return nil;
    }
    
    // Ignore mutli-line selection,
    if (selectRange.start.line != selectRange.end.line) {
        return nil;
    }
    
    NSString *selectedLine = [invocation.buffer.lines objectAtIndex:selectRange.start.line];
    NSString *selectedPhase = [selectedLine substringWithRange:NSMakeRange(selectRange.start.column, selectRange.end.column - selectRange.start.column + 1)];
    
    NSLog(@"Selected Phase: %@", selectedPhase);
    // selecting nothing
    if ([selectedPhase isEqualToString:@""]) {
        return nil;
    }
    return selectedPhase;
}

- (NSInteger)lineNumberOfLastImportStatenent:(NSMutableArray *)lines {
    NSArray *importLines = [lines filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#import \"[^.]*\\.h\"" options:0 error:nil];
        return [regex matchesInString:evaluatedObject options:0 range:NSMakeRange(0, [(NSString *)evaluatedObject length])].count > 0;
    }]];
    NSLog(@"import lines are: %@", importLines);
    
    NSString *lastImportLine = [importLines lastObject];
    if(lastImportLine){
        return [lines indexOfObject:lastImportLine];
    }
    return NSNotFound;
}

/*
 Find the Array Index for first emplty line below the file's top comments
 and before the @class definition
 */
- (NSInteger)lineNumberForEmptyLine:(NSMutableArray *)lines {
    
    for (NSString *lineContent in lines) {
        if ([lineContent hasPrefix:@"//"]) {
            continue;
        }
        
        if ([lineContent isEqualToString:@"\n"]) {
            return [lines indexOfObject:lineContent];
        }
        
        if ([lineContent hasPrefix:@"@"]) {
            return NSNotFound;
        }
    }
    return NSNotFound;
}

- (NSInteger)lineNumberForLineAboveClassDefinition:(NSMutableArray *)lines {
    for (NSString *lineContent in lines) {
        if ([lineContent hasPrefix:@"//"]) {
            continue;
        }
        if ([lineContent hasPrefix:@"@"]) {
            return [lines indexOfObject:lineContent] - 1 ;
        }
    }
    return NSNotFound;
}


@end
