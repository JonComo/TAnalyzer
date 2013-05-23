//
//  TAViewController.m
//  TwitterAnalyzer
//
//  Created by David de Jesus on 5/12/13.
//  Copyright (c) 2013 DKJ. All rights reserved.
//

#import "TAViewController.h"
#import "JCConnection.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <MapKit/MapKit.h>
#import "HeatMap.h"
#import "HeatMapView.h"


@interface TAViewController ()
{
    ACAccountStore *store;
    ACAccount *account;
    
    NSMutableArray *allTweets;
        
    BOOL canSearch;
    IBOutlet MKMapView *mapView;
    IBOutlet UIButton *getButton;
}



@end

@implementation TAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    HeatMap *hm = [[HeatMap alloc] initWithData:[self heatMapData]];
    [mapView addOverlay:hm];
    [mapView setVisibleMapRect:[hm boundingMapRect] animated:YES];
    
    [self twitterAccess:^(BOOL success) {
        canSearch = YES;
    }];
    
    getButton.enabled = NO;
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [self searchFriends];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getUsers:(id)sender {
    [self searchUsers:allTweets];
    
}

- (void)searchFriends
{
    if (!allTweets)
        allTweets = [NSMutableArray array];
    
    [allTweets removeAllObjects];
    SLRequest* twitterRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                   requestMethod:SLRequestMethodGET
                                                             URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friends/ids.json"]
                                                      parameters:nil];
    
    [self performTwitterRequest:twitterRequest complete:^(NSDictionary *response) {

        for (NSString *value in [response valueForKey:@"ids"]) {
            if (value == nil) return;
            [allTweets addObject:value];
            getButton.enabled = YES;
            NSLog(@"%@", value);
        }
        

    }];
}

- (void)searchUsers:(NSArray *)userIDs
{    

//    NSString *user = userIDs.lastObject;
    
    for (NSString *user in userIDs) {
        SLRequest* twitterRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/users/lookup.json?user_id=%@", user]]
                                                          parameters:nil];
        
        
        [self performTwitterRequest:twitterRequest complete:^(NSDictionary *response) {
            
            NSLog(@"%@", response);
            
            
        }];
        
    }
    

}


-(void)performTwitterRequest:(SLRequest *)twitterRequest complete:(void(^)(NSDictionary *response))block
{
    twitterRequest.account = account;
    
    [twitterRequest performRequestWithHandler:^(NSData* responseData, NSHTTPURLResponse* urlResponse, NSError* error) {
        
        NSError *jsonError;
        
        id response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
        
        if (response) {
            NSDictionary *twitterData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];

            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) block(twitterData);
            });
        }
        
        if (jsonError) NSLog(@"JSON ERROR: %@", jsonError);
    }];
}

-(void)twitterAccess:(void(^)(BOOL success))block
{
    store = [[ACAccountStore alloc] init];
    
    ACAccountType *accountType = [store accountTypeWithAccountTypeIdentifier:
                                  ACAccountTypeIdentifierTwitter];
    
    [store requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error)
     {
         if (granted == YES)
         {
             NSArray *arrayOfAccounts = [store accountsWithAccountType:accountType];
             
             if ([arrayOfAccounts count] > 0)
             {
                 account = [arrayOfAccounts lastObject];
                 
                 if (account)
                 {
                     if (block) block(YES);
                 }else{
                     if (block) block(NO);
                 }
             }else{
                 if (block) block(NO);
             }
         }else
         {
             if (block) block(NO);
         }
     }];
}


- (NSDictionary *)heatMapData
{

    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:allTweets.count];
    
    return data;
}


#pragma mark -
#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [[HeatMapView alloc] initWithOverlay:overlay];
}

@end
