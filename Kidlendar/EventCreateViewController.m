//
//  EventCreateViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "EventCreateViewController.h"
#import "EventTitleAndTimeView.h"
#import "GPUImage.h"
#import "CalendarStore.h"
#import "UIImage+Resize.h"
#import "ProfileDataStore.h"
#import "ProfileData.h"

@interface EventCreateViewController ()
{
    EKEvent *event;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    NSDate *minimumDate;
    UIImage *blurBackgroundImage;
    UIImageView *backgroundImageView;
    UIImage *backgroundImage;
    EventTitleAndTimeView *titleAndTimeView;
    GPUImageiOSBlurFilter *blurFilter;
    UICollectionView *profileCollectionView;
}
@end

@implementation EventCreateViewController

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
    
    // Setup blur background
    UIImage *image = [UIImage imageNamed:@"IMG_1725.jpg"];
    backgroundImage = [image resizeImageToSize:self.view.frame.size];
    backgroundImageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    blurFilter = [[GPUImageiOSBlurFilter alloc]init];
    blurBackgroundImage = [blurFilter imageByFilteringImage:backgroundImage];
    backgroundImageView.image = blurBackgroundImage;
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];

    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"MM月dd日 EEEE";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"HH:mm";
    timeFormatter.timeZone = [NSTimeZone systemTimeZone];

    // Setup Date picker
    _datePicker = [[UIDatePicker alloc]init];
    [_datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [_datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
    _datePicker.minuteInterval = 5;
    _datePicker.date = _selectedDate;
    
    // When enter bring up title and time view and keyboard
    titleAndTimeView = [[EventTitleAndTimeView alloc]initWithFrame:CGRectMake(0, 0, 320, 352)];
    titleAndTimeView.titleField.delegate = self;
    titleAndTimeView.nameTextField.delegate = self;
    [titleAndTimeView.titleField becomeFirstResponder];
    [self.view addSubview:titleAndTimeView];
    
    // Setup start time field , default setting is date/time when add button clicked
    titleAndTimeView.startTimeField.inputView = _datePicker;
    titleAndTimeView.startTimeField.dateLabel.text = [dateFormatter stringFromDate:_selectedDate];
    titleAndTimeView.startTimeField.text = [timeFormatter stringFromDate:_selectedDate];
    titleAndTimeView.startTimeField.delegate = self;

    // Setup end time field , default setting is 5min from start time
    titleAndTimeView.endTimeField.inputView = _datePicker;
    titleAndTimeView.endTimeField.dateLabel.text = [dateFormatter stringFromDate:[NSDate dateWithTimeInterval:300 sinceDate:_selectedDate]];
    titleAndTimeView.endTimeField.text = [timeFormatter stringFromDate:[NSDate dateWithTimeInterval:300 sinceDate:_selectedDate]];
    titleAndTimeView.endTimeField.delegate = self;
    
    // Setup Profile table
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    profileCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, 300, 60) collectionViewLayout:layout];
    [profileCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    profileCollectionView.dataSource = self;
    profileCollectionView.delegate = self;
    profileCollectionView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
    
    // Set up save button
    [titleAndTimeView.saveButton addTarget:self action:@selector(createEvent) forControlEvents:UIControlEventTouchDown];
    
    // Initialize new event
    event = [EKEvent eventWithEventStore:[[CalendarStore sharedStore]eventStore]];
    event.timeZone = [NSTimeZone systemTimeZone];
    event.calendar = [[CalendarStore sharedStore]calendar];
    event.startDate = _selectedDate;
    event.endDate = [NSDate dateWithTimeInterval:300 sinceDate:_selectedDate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    ProfileData *p = ProfileDataStore.sharedStore.allItems[indexPath.row];
    cell.backgroundView = [[UIImageView alloc]initWithImage:p.thumbnail];
    
    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Returns number for items in datasource
    return [[[ProfileDataStore sharedStore]allItems]count];
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Put profile's index into event note
    event.notes = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
    ProfileData *p =  [[ProfileDataStore sharedStore]allItems][indexPath.row];
    titleAndTimeView.nameTextField.text = p.name;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(50,50);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 10, 5, 10);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}
#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Tag 0 = title , 1 = startTime , 2 = endTime , 3 = locatoin , 4 = name
    switch (textField.tag) {
        case 1:
            if ([titleAndTimeView.titleField isFirstResponder])
            _datePicker.minimumDate = nil;
            [_datePicker setDate:event.startDate];
            textField.layer.borderColor = [[UIColor greenColor]CGColor];
            textField.layer.borderWidth = 1.0f;
            titleAndTimeView.endTimeField.layer.borderWidth = 0;
            break;
        case 2:
            _datePicker.minimumDate = minimumDate;
            [_datePicker setDate:event.endDate];
            textField.layer.borderColor = [[UIColor redColor]CGColor];
            textField.layer.borderWidth = 1.0f;
            titleAndTimeView.startTimeField.layer.borderWidth = 0;
            break;
        case 4:
            titleAndTimeView.nameTextField.inputAccessoryView = profileCollectionView;
        default:
            break;
    }
    return YES;
}

-(void)changeDate
{
    if (titleAndTimeView.startTimeField.isFirstResponder) {
        titleAndTimeView.startTimeField.dateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
        titleAndTimeView.startTimeField.text = [timeFormatter stringFromDate: _datePicker.date];
        event.startDate = _datePicker.date;
        
        // Minimum end time after start time is selected
        minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:_datePicker.date];
        titleAndTimeView.endTimeField.dateLabel.text = [dateFormatter stringFromDate:minimumDate];
        titleAndTimeView.endTimeField.text = [timeFormatter stringFromDate:minimumDate];
        event.endDate = minimumDate;
    }
    else {
        titleAndTimeView.endTimeField.text = [timeFormatter stringFromDate: _datePicker.date];
        titleAndTimeView.endTimeField.dateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
        event.endDate = _datePicker.date;
    }
}

- (void)createEvent
{
    event.title = titleAndTimeView.titleField.text;
    NSError *err;
    if ([[[CalendarStore sharedStore]eventStore] saveEvent:event span:EKSpanThisEvent commit:YES error:&err])
        NSLog(@"New event created");
    else
        NSLog(@"Create new event fail");
    NSLog(@"Error From calendar : %@", [err description]);
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
