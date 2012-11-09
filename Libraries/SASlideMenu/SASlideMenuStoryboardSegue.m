//
//  SASlideMenuStoryboardSegue.m
//  SASlideMenu
//
//  Created by Stefano Antonelli on 7/30/12.
//  Copyright (c) 2012 Stefano Antonelli. All rights reserved.
//

#import "SASlideMenuStoryboardSegue.h"
#import "SASlideMenuViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation SASlideMenuStoryboardSegue


-(void) perform{
    SASlideMenuViewController* source = self.sourceViewController;
    NSString* identifier = self.identifier;
    UIViewController* content = [source.controllers objectForKey:identifier];
    
    if (!content) {
        UINavigationController* destination = self.destinationViewController;
        
        
        UIButton* menuButton = [[UIButton alloc] init];
        [source.slideMenuDataSource configureMenuButton:menuButton];
        [menuButton addTarget:source action:@selector(doSlideOut) forControlEvents:UIControlEventTouchUpInside];
        
        UINavigationItem* navigationItem = destination.navigationBar.topItem;
        navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
        [source switchToContentViewController:destination];
        [source addContentViewController:destination withIdentifier:self.identifier];
    }else{
        [source switchToContentViewController:content];
    }    
}
@end
