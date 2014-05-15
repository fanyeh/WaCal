//
//  NSString+Localization.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/5/15.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "NSString+Localization.h"

@implementation NSString (Localization)

-(NSString *)localizeString:(NSString *) translation_key {
    NSString * s = NSLocalizedString(translation_key, nil);
    if (![[[NSLocale preferredLanguages] objectAtIndex:0] isEqualToString:@"en"] && [s isEqualToString:translation_key]) {
        NSString * path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        NSBundle * languageBundle = [NSBundle bundleWithPath:path];
        s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
    }
    return s;
}
@end
