//
//  DropboxModel.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import "DropboxModel.h"
#import "DiaryData.h"
#import "DiaryDataStore.h"
#import "TempDiaryData.h"
#import "CloudData.h"
#import "LocationDataStore.h"
#import "LocationData.h"
#import "UIImage+Resize.h"

@implementation DropboxModel
{
    DBFilesystem *filesystem;
    NSString *folder;
}

+ (DropboxModel *)shareModel
{
    static DropboxModel *shareModel = nil;
    if(!shareModel)
        shareModel = [[super allocWithZone:nil] init];
    
    return shareModel;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self shareModel];
}

- (id)init
{
    self = [super init];
    if(self) {
        folder = @"Diary";
    }
    return self;
}

- (void)linkToDropBox:(LinkHandler)linkComplete fromController:(UIViewController *)controller
{
    DBAccount  *account = [DBAccountManager sharedManager].linkedAccount;
    if (!account || !account.linked) {
        NSLog(@"No account linked\n");
        [[DBAccountManager sharedManager] linkFromController:controller];
        linkComplete(NO);
    } else {
        NSLog(@"There's already DB account linked");
        if ([DBFilesystem sharedFilesystem]) {
            NSLog(@"There's already DB filesystem linked");
            linkComplete(YES);
        }
        else {
            NSLog(@"Connect to filesystem");
            [self setupFileSystemAndStore:linkComplete];
        }
    }
}

- (void)setupFileSystemAndStore:(LinkHandler)completeSetUp
{
    filesystem = [[DBFilesystem alloc] initWithAccount:[DBAccountManager sharedManager].linkedAccount];
    [DBFilesystem setSharedFilesystem:filesystem];
    completeSetUp(YES);
}

- (void)uploadDiaryToFilesystem:(DiaryData *)diary mediaData:(NSData *)data mediaType:(SourceType)type complete:(UploadBlock)uploadComplete
{
    if([self checkFile:diary.diaryKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Duplicate File"
                                                           message:@"You already have this diary on cloud"
                                                          delegate:self cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil, nil];
            [alert show];
        });
        uploadComplete(NO);
    } else {
        [self checkDiaryFolder:^{
            
            // Get diary location
            LocationData *diaryLocation = [[[LocationDataStore sharedStore]allItems]objectForKey:diary.diaryKey];
            NSDictionary *location;
            if (diaryLocation) {
                location = [[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%f",diaryLocation.latitude],@"latitude",[NSString stringWithFormat:@"%f",diaryLocation.longitude],@"longitude", nil];
            }

            NSString *uploadFilePath;
            NSString *media;
            
            // Create and upload video thumbnail
            NSString *thumbPath = [NSString stringWithFormat:@"%@/%@-thumbnail.png",folder,diary.diaryKey];
            DBPath *newThumbPath = [[DBPath root] childPath:thumbPath];
            DBFile *newThumb = [[DBFilesystem sharedFilesystem] createFile:newThumbPath error:nil];
            
            // Upload photo
            if (type == kSourceTypePhoto) {
                // Create upload path for photo
                uploadFilePath = [NSString stringWithFormat:@"%@/%@.png",folder,diary.diaryKey];
                media = @"photo";
                UIImage *image = [diary.diaryImage resizeImageToSize:CGSizeMake(50, 50)];
                [newThumb writeData:UIImagePNGRepresentation(image) error:nil];

            }
            // Upload video
            else {
                // Create upload path for video
                uploadFilePath = [NSString stringWithFormat:@"%@/%@.mov",folder,diary.diaryKey];
                media = @"video";
                [newThumb writeData:diary.diaryVideoThumbData error:nil];
            }
            

            [self uploadMediaToPath:uploadFilePath mediaData:data complete:^(BOOL success) {
                // Create json dictionary
                NSString *diaryDate = [NSString stringWithFormat:@"%f",diary.dateCreated];
                NSDictionary *diaryDict = [[NSDictionary alloc]initWithObjectsAndKeys:
                                           diary.subject,                                       @"diarySubject",
                                           diary.diaryText,                                     @"diaryText",
                                           diaryDate,                                           @"dateInterval",
                                           location,                                       @"diaryLocationCoordinate",
                                           diary.location,                                      @"diaryLocationName" ,
                                           media,                                               @"mediaType",
                                           nil];
                NSData *diaryData = [NSJSONSerialization dataWithJSONObject:diaryDict options:NSJSONWritingPrettyPrinted error:nil];
                
                // Upload diary JSON to DBFilesystem
                NSString *uploadJsonPath = [NSString stringWithFormat:@"%@/%@.json",folder,diary.diaryKey];
                DBPath *newJsonPath = [[DBPath root] childPath:uploadJsonPath];
                DBFile *jsonFile = [[DBFilesystem sharedFilesystem] createFile:newJsonPath error:nil];
                [jsonFile writeData:diaryData error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Alert for upload complete
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Upload Done"
                                                                   message:@"You have successfully uploaded diary"
                                                                  delegate:self cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil, nil];
                    [alert show];
                });
                // Check diary now has uploaded to dropbox
                diary.cloudRelationship.dropbox = YES;
                
                uploadComplete(YES);

            }];
        }];
    }
}

- (void)uploadMediaToPath:(NSString *)uploadFilePath mediaData:(NSData *)data complete:(UploadBlock)uploadComplete
{
    // Upload vidoe or photo
    DBPath *newFilePath = [[DBPath root] childPath:uploadFilePath];
    __weak DBFile *newFile = [[DBFilesystem sharedFilesystem] createFile:newFilePath error:nil];
    
    NSLog(@"observer %@",_observer);
    dispatch_async(dispatch_get_main_queue(), ^{
        [newFile addObserver:self block:^{
            NSLog(@"File upload progress %f",newFile.status.progress);
            if (newFile.status.state==DBFileStateUploading)
                NSLog(@"Uploading");
            else if (newFile.status.state==DBFileStateIdle)
                NSLog(@"Idle");
            
            if (newFile.status.progress==1) {
                [newFile removeObserver:_observer];
                uploadComplete(YES);
            }
        }];
    });
    [newFile writeData:data error:nil];

}

- (void)checkDiaryFolder:(void(^)(void))completeFolderCheck
{
    BOOL hasDiaryFolder = NO;
    NSArray *fileInfoArray = [[DBFilesystem sharedFilesystem]listFolder:[DBPath root] error:nil];
    for (DBFileInfo *fileInfo in fileInfoArray) {
        if (fileInfo.isFolder) {
            if ([fileInfo.path.name isEqualToString:folder])
                hasDiaryFolder = YES;
        }
    }
    if(!hasDiaryFolder) {
        [self createFolder:completeFolderCheck];
    } else {
        completeFolderCheck();
    }
}

- (void)createFolder:(void(^)(void))completeFolderCreate
{
    NSLog(@"Creating new folder");
    DBPath *newFolderPath = [[DBPath root] childPath:folder];
    NSLog(@"folder path %@", newFolderPath);
    DBError *error;
    if ([[DBFilesystem sharedFilesystem] createFolder:newFolderPath error:&error]) {
        NSLog(@"Create folder succeed");
        completeFolderCreate();
    }
    else {
        NSLog(@"Create folder failed with error :%@",error);
    }
}

- (void)downloadDiaryFromFilesystem:(NSString *)key  mediaType:(SourceType)type complete:(DownloadBlock)downloadComplete
{
    NSString *downloadFilePath;
    
    if (type==kSourceTypePhoto)
        downloadFilePath = [NSString stringWithFormat:@"%@/%@.png",folder,key];
    else
        downloadFilePath = [NSString stringWithFormat:@"%@/%@.mov",folder,key];
    
    DBPath *existingPath = [[DBPath root] childPath:downloadFilePath];
    DBFile *file = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
    NSData *diaryMediaData = [file readData:nil];
    
    downloadComplete(diaryMediaData);
}

- (BOOL)checkFile:(NSString *)key
{
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.png",folder,key];
    DBPath *existingPath = [[DBPath root] childPath:filePath];
    DBFile *file = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
    if (file) {
        return YES;
    } else {
        return NO;
    }
}

- (void)listUndownloadDiary:(ListAllCloudDiarys)completeDownloadList
{
    NSMutableDictionary *diarysFromCloud = [[NSMutableDictionary alloc]init];
    
    // Get all files from dropbox app folder
    NSString *filePath = [NSString stringWithFormat:@"%@/",folder];
    DBPath *listFilePath = [[DBPath root] childPath:filePath];
    NSArray *listFiles = [filesystem listFolder:listFilePath error:nil];
    
    // Get all diary keys in core data
    NSMutableArray *allDiaryKeys = [[NSMutableArray alloc]init];
    for (DiaryData *d in [[DiaryDataStore sharedStore]allItems]) {
        [allDiaryKeys addObject:d.diaryKey];
    }
    
    // Get all available keys from DB filesystem
    for (DBFileInfo *info in listFiles) {
        
        NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
        NSString *fileExtension = [info.path.name pathExtension];
        
        if ([fileExtension isEqualToString:@"json"]&&![allDiaryKeys containsObject:diaryKey]) {
            DBFile *jsonFile = [filesystem openThumbnail:info.path ofSize:DBThumbSizeXS inFormat:DBThumbFormatPNG error:nil];
            NSData *json = [jsonFile readData:nil];

            TempDiaryData *t = [[TempDiaryData alloc]init];
            t.diaryKey = diaryKey;
            t.diaryData = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingAllowFragments error:nil];
            
            // Get diary thumbnail
            NSString *thumbDataPath = [NSString stringWithFormat:@"%@/%@-thumbnail.png",folder,diaryKey];
            DBPath *thumbPath = [[DBPath root] childPath:thumbDataPath];
            
            DBFile *thumbFile = [[DBFilesystem sharedFilesystem] openFile:thumbPath error:nil];
            NSData *thumbData = [thumbFile readData:nil];
            UIImage *thumb = [UIImage imageWithData:thumbData];
            
            if ([[t.diaryData objectForKey:@"mediaType"] isEqualToString:@"photo"]) {
                
                t.thumbnail = thumb;
                
            } else {
                t.thumbnail = thumb;
            }
            
            [diarysFromCloud setObject:t forKey:diaryKey];
        }
    }
    completeDownloadList(diarysFromCloud);
}

- (void )listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList
{
    NSLog(@"list all diary");
    NSMutableDictionary *diarysFromCloud = [[NSMutableDictionary alloc]init];

    NSString *filePath = [NSString stringWithFormat:@"%@/",folder];
    DBPath *listFilePath = [[DBPath root] childPath:filePath];
    NSArray *listFiles = [filesystem listFolder:listFilePath error:nil];
    NSLog(@"List %@",listFiles);
    // Get all available keys from DB filesystem
    for (DBFileInfo *info in listFiles) {
        
        NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
        NSString *fileExtension = [info.path.name pathExtension];
        
        
        if ([fileExtension isEqualToString:@"png"] && info.thumbExists) {
            
            // Get diary image thumbnail
            DBFile *imageFile = [filesystem openThumbnail:info.path ofSize:DBThumbSizeM inFormat:DBThumbFormatPNG error:nil];
            NSData *diaryImageData = [imageFile readData:nil];
            UIImage *diaryImage = [UIImage imageWithData:diaryImageData];
            
            // Get diary json
            NSString *diaryDataPath = [NSString stringWithFormat:@"%@/%@.json",folder,diaryKey];
            DBPath *existingPath = [[DBPath root] childPath:diaryDataPath];
            DBFile *dataFile = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
            
            TempDiaryData *t = [[TempDiaryData alloc]init];
            t.diaryKey = diaryKey;
            t.thumbnail = diaryImage;
            NSData *json = [dataFile readData:nil];
            t.diaryData = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingAllowFragments error:nil];
            
            [diarysFromCloud setObject:t forKey:diaryKey];
        }
    }
    completeDownloadList(diarysFromCloud);
}

@end
