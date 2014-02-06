//
//  KidProfileViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "ProfileCreateViewController.h"
#import "ProfileData.h"
#import "ProfileDataStore.h"
#import "ProfileImageStore.h"

@interface ProfileCreateViewController ()
{
    UIDatePicker *_datePicker;
    UIImagePickerController *_imagePicker;
}

@end

@implementation ProfileCreateViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(cancelAction)];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(createNewProfile)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UITapGestureRecognizer *selectGender = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(genderSelection:)];
    [_maleImageView addGestureRecognizer:selectGender];
    [_femaleImageView addGestureRecognizer:selectGender];
    
    UITapGestureRecognizer *selectPhoto = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(getPicture:)];
    [_profileImageView addGestureRecognizer:selectPhoto];
    
    
    // Initiate imagePicker controller for photo selection
    _imagePicker = [[UIImagePickerController alloc]init];
    _imagePicker.delegate = self;
    
    // Setup Date picker
    _datePicker = [[UIDatePicker alloc]init];
    [_datePicker setDatePickerMode:UIDatePickerModeDate];
    [_datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
    
    // Add date picker to birthday textfield
    _birthdayTextField.inputView = _datePicker;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancelAction
{
    // Remove profile upon cancel button clicked
    [[ProfileDataStore sharedStore]removeItem:_profile];
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (void)createNewProfile
{
    // Set values for each property
    _profile.name = _nameTextField.text;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSDate *birthDate = [dateFormatter dateFromString:_birthdayTextField.text];
    _profile.birthDate = [birthDate timeIntervalSince1970];

    [[ProfileDataStore sharedStore]saveChanges];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)genderSelection:(UITapGestureRecognizer *)sender
{
    if(sender.view.tag==0) {
        _profile.gender = @"Male";
        NSLog(@"Male");
    }
    else {
        _profile.gender = @"Female";
        NSLog(@"Female");
    }
}

- (void)getPicture:(UITapGestureRecognizer *)sender
{
    NSLog(@"get pic");
    [self.navigationController setToolbarHidden:NO animated:YES];
    UIImage *galleryImage = [UIImage imageNamed:@"929-film-1.png"];
    UIBarButtonItem *cameraItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                               target:self
                                                                               action:@selector(pickFromCamera)];
    
    UIBarButtonItem *flexibleSpaceItem1 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                       target:self
                                                                                       action:nil];
    
    UIBarButtonItem *galleryItem = [[UIBarButtonItem alloc]initWithImage:galleryImage style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(pickFromGallery)];
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(hideToolBar)];
    
    [self.navigationController.toolbar setItems:@[cameraItem,flexibleSpaceItem1, galleryItem,flexibleSpaceItem1, doneItem] animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get picked image from info dictionary
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [_profile setThumbnailDataFromImage:image];
    
    // Create a CFUUID object - it knows how to create unique identifier strings
    CFUUIDRef newUniqueID = CFUUIDCreate (kCFAllocatorDefault);
    
    // Create a string from unique identifier
    CFStringRef newUniqueIDString =
    CFUUIDCreateString (kCFAllocatorDefault, newUniqueID);
    
    // Use that unique ID to set our item's imageKey
    NSString *key = (__bridge NSString *)newUniqueIDString;
    
    [_profile setImageKey:key];
    
    
    // Store image in the BNRImageStore with this key
    [[ProfileImageStore sharedStore] setImage:image
                                   forKey:[_profile imageKey]];
    
    CFRelease(newUniqueIDString);
    CFRelease(newUniqueID);
    
    // Put that image onto the screen in our image view    
    
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = _profileImageView.frame.size.width/_profileImageView.frame.size.height;
    
    if(imgRatio!=maxRatio){
        if(imgRatio < maxRatio){
            imgRatio = _profileImageView.frame.size.height / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = _profileImageView.frame.size.height;
        }
        else{
            imgRatio = _profileImageView.frame.size.width / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = _profileImageView.frame.size.width;
        }
    }
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //imageSize = UIImagePNGRepresentation(img);
    
    _profileImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_profileImageView setImage:img];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pickFromCamera
{
    [_imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (void)pickFromGallery
{
    [_imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:_imagePicker animated:YES completion:nil];
}

-(void)hideToolBar
{
    [self.navigationController setToolbarHidden:YES animated:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)changeDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    _birthdayTextField.text = [dateFormatter stringFromDate:_datePicker.date];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_nameTextField resignFirstResponder];
    [_birthdayTextField resignFirstResponder];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

@end
