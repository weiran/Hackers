//
//  SASlideMenuViewController.m
//  SASlideMenu
//
//  Created by Stefano Antonelli on 7/29/12.
//  Copyright (c) 2012 Stefano Antonelli. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SASlideMenuViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface SASlideMenuViewController (){
    UIViewController* selectedContent;
    BOOL isFirstViewWillAppear;
}

@property (nonatomic, strong) UIView* shield;

@end

@implementation SASlideMenuViewController

@synthesize slideMenuDataSource;
@synthesize controllers;

#pragma mark -
#pragma mark - SASlideMenuViewController

-(void) tapItem:(UIPanGestureRecognizer*)gesture{
    [self switchToContentViewController:selectedContent];
}

-(void) panItem:(UIPanGestureRecognizer*)gesture{
    UIView* panningView = gesture.view;
    CGPoint translation = [gesture translationInView:panningView];
    UIView* movingView = selectedContent.view;
    if (movingView.frame.origin.x + translation.x<0) {
        translation.x=0.0;
    }
    [movingView setCenter:CGPointMake([movingView center].x + translation.x, [movingView center].y)];
    [gesture setTranslation:CGPointZero inView:[panningView superview]];
    if ([gesture state] == UIGestureRecognizerStateEnded){
        CGFloat pcenterx = movingView.center.x;
        CGRect bounds = self.view.bounds;
        CGSize size = bounds.size;
        
        if (pcenterx > size.width ) {
            [self doSlideOut];
        }else{

            [UIView animateWithDuration:kSlideInInterval delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
                selectedContent.view.frame = CGRectMake(0,0,bounds.size.width,bounds.size.height);
                
            } completion:^(BOOL completed){
                [self.shield removeFromSuperview];
            }];
        }
	}
}
-(void) switchToContentViewController:(UIViewController*) content{
    CGRect bounds = self.view.bounds;
    self.view.userInteractionEnabled = NO;
    if (selectedContent) {
        //Animate out the currently selected UIViewController
        [UIView animateWithDuration:kSlideOutInterval delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
            selectedContent.view.frame = CGRectMake(bounds.size.width,0,bounds.size.width,bounds.size.height);
        } completion:
         ^(BOOL completed) {

             [selectedContent willMoveToParentViewController:nil];
             [selectedContent.view removeFromSuperview];
             [selectedContent removeFromParentViewController];
             
             content.view.frame = CGRectMake(bounds.size.width,0,0,bounds.size.height);
             [self addChildViewController:content];
             [self.view addSubview:content.view];
             [UIView animateWithDuration:kSlideInInterval delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
                 content.view.frame = CGRectMake(0,0,bounds.size.width,bounds.size.height);
                 
             } completion:^(BOOL completed){
                 selectedContent = content;
                 [content didMoveToParentViewController:self];
                 [self.shield removeFromSuperview];
                 self.view.userInteractionEnabled = YES;
             }];
         }];
    }else{
        [self addChildViewController:content];
        [self.view addSubview:content.view];
        content.view.frame = CGRectMake(0,0,bounds.size.width,bounds.size.height);
        selectedContent = content;
        [self.shield removeFromSuperview];
        [content didMoveToParentViewController:self];
        self.view.userInteractionEnabled = YES;
    }

}


-(void) addContentViewController:(UIViewController*) content withIdentifier:(NSString*)identifier{
    CALayer* layer = [content.view layer];
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.3;
    layer.shadowOffset = CGSizeMake(-15, 0);
    layer.shadowRadius = 10;
    layer.masksToBounds = NO;
    layer.shadowPath =[UIBezierPath bezierPathWithRect:layer.bounds].CGPath;
    
    [self.controllers setObject:content forKey:identifier];
}

-(void) doSlideOut{
    CGRect bounds = self.view.bounds;
    if (![selectedContent.view.subviews containsObject:self.shield]) {
        self.shield.frame = bounds;
        [selectedContent.view addSubview:self.shield];
    }
    [UIView animateWithDuration:kSlideInInterval delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        selectedContent.view.frame = CGRectMake(kMenuTableSize,0,bounds.size.width,bounds.size.height);
        
    } completion:nil];
}

#pragma mark -
#pragma mark - UIViewController

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (isFirstViewWillAppear) {
        NSString* identifier= [slideMenuDataSource initialSegueId];
        [self performSegueWithIdentifier:identifier sender:self];
        isFirstViewWillAppear = NO;
    }

}

-(void) viewDidLoad{
    [super viewDidLoad];

    isFirstViewWillAppear = YES;
    controllers = [[NSMutableDictionary alloc] init];
    self.shield = [[UIView alloc] initWithFrame:CGRectZero];

    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapItem:)];
    [self.shield addGestureRecognizer:tapGesture];
    
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panItem:)];
    [panGesture setMaximumNumberOfTouches:2];
    [panGesture setDelegate:self];
    [self.shield addGestureRecognizer:panGesture];
    
    self.tableView.delegate = self;
}

-(void) didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    [self.controllers removeAllObjects];
}



@end
