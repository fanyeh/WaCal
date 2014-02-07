//
//  FileManager.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/5.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileManager : NSObject
{
    NSArray *paths;
    NSString *documentsDirectory;
    NSString *savedImagePath;
    NSData *imageData;
    NSString *fileName;
}
@property (strong,nonatomic) NSString *fileDirectory;
-(id)initWithKey:(NSString *)key;
-(void)saveDiaryImage:(UIImage *)image index:(int)i;
-(UIImage *)loadDiaryImageWithIndex:(int)i;
- (void)saveCollectionImage:(UIImage *)collectionViewImage;
- (UIImage *)loadCollectionImage;

@end
