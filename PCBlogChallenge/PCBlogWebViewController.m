//
//  PCBlogWebViewController.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/22/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCBlogWebViewController.h"
#import <WebKit/WebKit.h>

@interface PCBlogWebViewController () <WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *webView;

@property (strong, nonatomic) UIBarButtonItem *closeAdButton;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;
@property (strong, nonatomic) UIBarButtonItem *actionButton;
@property (strong, nonatomic) UIBarButtonItem *reloadButton;

@end

@implementation PCBlogWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGFloat offsetY = self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y;
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, offsetY, self.view.bounds.size.width, self.view.bounds.size.height - offsetY)];
    [self.view addSubview:_webView];
    
    _webView.allowsBackForwardNavigationGestures = YES;
    _webView.navigationDelegate = self;
    [_webView loadRequest:[NSURLRequest requestWithURL:_linkURL]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    _backButton.enabled = webView.canGoBack;
    _forwardButton.enabled = webView.canGoForward;
}

@end
