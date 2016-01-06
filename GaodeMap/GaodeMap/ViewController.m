//
//  ViewController.m
//  GaodeMap
//
//  Created by xalo on 15/12/30.
//  Copyright © 2015年 SWP. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

#define APIKey @"c0a38e87b986fda7209dd8b8c83b17fc"

@interface ViewController ()<MAMapViewDelegate,AMapSearchDelegate, UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate>
{
    //显示地图
    MAMapView *_mapView;
    UIButton *_locationButton;//定位按钮，主要用于修改定位模式
    
    //当前地址
    AMapSearchAPI *_search;//search变量
    CLLocation *_currentLocation;//用户经纬度
    
    //用于显示附近搜索结果的tableView
    UITableView *_tableView;
    NSArray *_pois; // 搜索结果
    //当获得新的搜索结果时，需要清空原有的annotation
    NSMutableArray *_annotations;
    
    //长按手势获取标记
    UILongPressGestureRecognizer *_longPressGesture;
    //目的地标记
    MAPointAnnotation *_destinationPoint;
    
    //记录所有MAPolyline类型
    NSArray *_pathPolylines;
}

@end

@implementation ViewController

#pragma mark - init -
//初始化
- (void)initMapView{
    [MAMapServices sharedServices].apiKey = APIKey;
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) * 0.5)];
    _mapView.delegate = self;
    //罗盘位置
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 22);
    //比例尺位置
    _mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, 22);
    //显示地图
    [self.view addSubview:_mapView];
    //1.打开定位功能
    _mapView.showsUserLocation = YES;
    //2.需要添加字段 NSLocationAlwaysUsageDescription
}

//初始化按钮
- (void)initControls{
    //定位
    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.frame = CGRectMake(20, CGRectGetHeight(_mapView.bounds) - 80, 40, 40);
    _locationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _locationButton.backgroundColor = [UIColor whiteColor];
    _locationButton.layer.cornerRadius = 5;
    [_locationButton addTarget:self action:@selector(locateAction) forControlEvents:UIControlEventTouchUpInside];
    [_locationButton setImage:[UIImage imageNamed:@"iconfont-dingweizhuanhuan"] forState:UIControlStateNormal];
    [_mapView addSubview:_locationButton];
    
    //附近搜索
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    searchButton.frame = CGRectMake(80, CGRectGetHeight(_mapView.bounds) - 80, 40, 40);
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    searchButton.backgroundColor = [UIColor whiteColor];
    [searchButton setImage:[UIImage imageNamed:@"iconfont-sousuo"] forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
    [_mapView addSubview:searchButton];
    
    //搜索路线
    UIButton *pathButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    pathButton.frame = CGRectMake(140, CGRectGetHeight(_mapView.bounds) - 80, 40, 40);
    pathButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    pathButton.backgroundColor = [UIColor whiteColor];
    [pathButton setImage:[UIImage imageNamed:@"iconfont-xuanzexianlu"] forState:UIControlStateNormal];
    
    [pathButton addTarget:self action:@selector(pathAction) forControlEvents:UIControlEventTouchUpInside];
    [_mapView addSubview:pathButton];
}

//search初始化
- (void)initSearch{
    [AMapSearchServices sharedServices].apiKey = APIKey;
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
}

//初始化tableview
- (void)initTableView{
    CGFloat halfHeight = CGRectGetHeight(self.view.bounds) * 0.5;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, halfHeight, CGRectGetWidth(self.view.bounds), halfHeight) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

//
- (void)initAttributes
{
    _annotations = [NSMutableArray array];
    _pois = nil;
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _longPressGesture.delegate = self;
    [_mapView addGestureRecognizer:_longPressGesture];
}

#pragma mark - life cycle -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.navigationController.nav0igationBar.translucent = NO;
    [self initMapView];
    [self initControls];
    [self initSearch];
    [self locateAction];
    [self initTableView];
    [self initAttributes];
}


#pragma mark - action -
//修改定位模式
/*
 
 MAUserTrackingModeNone
 MAUserTrackingModeFollow 跟随用户位置：地图中心店始终为用户所在位置
 MAUserTrackingModeFollowWithHeading 跟随用户位置和方向：地图中心点始终为用户所在位置，地图旋转方向随手机方向变化
 */
- (void)locateAction{
    if (_mapView.userTrackingMode != MAUserTrackingModeFollowWithHeading) {
        [_mapView setUserTrackingMode:MAUserTrackingModeFollowWithHeading animated:YES];
    }
}

//请求附近搜索
- (void)searchAction{
    if (_currentLocation == nil || _search == nil) {
        NSLog(@"search failed");
        return;
    }
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.keywords = @"餐饮";
    request.radius = 1000;
    [_search AMapPOIAroundSearch:request];
    
   
}

//长按手势响应
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gesture locationInView:_mapView];
        NSLog(@"press on (%f , %f)",p.x,p.y);
        //将坐标转换为经纬度
        CLLocationCoordinate2D coodinate = [_mapView convertPoint:p toCoordinateFromView:_mapView];
        
        //添加标志
        if (_destinationPoint != nil) {
            //清理
            [_mapView removeAnnotation:_destinationPoint];
            _destinationPoint = nil;
            
            //清理搜索路线
            [_mapView removeOverlays:_pathPolylines];
            _pathPolylines = nil;
        }
        _destinationPoint = [[MAPointAnnotation alloc] init];
        _destinationPoint.coordinate = coodinate;
        _destinationPoint.title = @"Destination";
        [_mapView addAnnotation:_destinationPoint];
    }
}

//搜索路线按钮
- (void)pathAction{
    if (_destinationPoint == nil || _currentLocation == nil || _search == nil) {
        NSLog(@"path search failed");
        return;
    }
    AMapRouteShareSearchRequest *request = [[AMapRouteShareSearchRequest alloc] init];
    request.type = 2;//0 为驾车， 1 为公交
    request.startCoordinate = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.destinationCoordinate = [AMapGeoPoint locationWithLatitude:_destinationPoint.coordinate.latitude longitude:_destinationPoint.coordinate.longitude];
    [_search AMapRouteShareSearch:request];
}

#pragma mark - MAMapViewDelegate -
//替换定位按钮图标：使用mapView回调方法监听定位模式状态
- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated{
    //修改定位按钮状态
    if (mode == MAUserTrackingModeNone) {
        [_locationButton setImage:[UIImage imageNamed:@"iconfont-dingweizhuanhuan"] forState:UIControlStateNormal];
    } else {
         [_locationButton setImage:[UIImage imageNamed:@"iconfont-dingwei"] forState:UIControlStateNormal];
    }
    
}

//获取当前用户经纬度
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
//    NSLog(@"userLocation: %@",userLocation.location);
    _currentLocation = [userLocation.location copy];
}

//在选中用户位置annotation时弹出当前地址
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view{
    //选中定位annotation的时候进行逆地理编码查询
    if ([view.annotation isKindOfClass:[MAUserLocation class]]) {
        [self reGeoAction];
    }
}

//得到附近搜索的结果后，取出或创建annotationView
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation{
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        //设置标注的图片
        annotationView.image = [UIImage imageNamed:@"iconfont-canyin"];
        //设置中心点偏移，使得标注底部中间点成为经纬度对应点。
        annotationView.centerOffset = CGPointMake(0, -18);
        //设置弹出气泡的位置
        annotationView.calloutOffset = CGPointMake(0, -18);
        //下落动画
        annotationView.animatesDrop = YES;
        
        annotationView.canShowCallout = YES;
        
        return  annotationView;
    }
    return nil;
}

//逆地理编码
//1.发起搜索请求
- (void)reGeoAction{
    if (_currentLocation) {
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];//逆地理编码请求
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];//经纬度
        [_search AMapReGoecodeSearch:request];//发起请求
    }
}

//绘制搜索的路线
- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id<MAOverlay>)overlay{
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        polylineView.lineWidth = 4;
        polylineView.strokeColor = [UIColor magentaColor];
        return polylineView;
    }
    return nil;
}
#pragma mark - AMapSearchDelegate -

//请求出错回调
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error{
    NSLog(@"request: %@, error :%@",request,error);
}

//返回数据
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response{
    NSLog(@"response :%@",response);
    
    NSString *title = response.regeocode.addressComponent.city;
    NSLog(@"title :%@",title);
    if (title.length == 0) {
        title = response.regeocode.addressComponent.province;
    }
    _mapView.userLocation.title = title;
    _mapView.userLocation.subtitle = response.regeocode.formattedAddress;
}

//得到搜索附近的回调方法
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    NSLog(@"request :%@", request);
    NSLog(@"response: %@", response);
    if (response.pois.count > 0) {
        _pois = response.pois;
        [_tableView reloadData];
        //清空标注
        [_mapView removeAnnotations:_annotations];
        [_annotations removeAllObjects];
    }
}

//获取搜索路线
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response{
    if (response.count > 0) {
        [_mapView removeOverlays:_pathPolylines];
        _pathPolylines = nil;
        
        //只显示第一条
        
    }
}

//路线解析方法
- (NSArray *)polylinesForPath:(AMapPath *)path
{
    if (path == nil || path.steps.count == 0) {
        return nil;
    }
    NSMutableArray *polylines = [NSMutableArray array];
    [path.steps enumerateObjectsUsingBlock:^(AMapStep *step, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger count = 0;
        CLLocationCoordinate2D *coordinates = [self coordiantesForString:step.polyline coordinateCount:&count parseToken:@";"];
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
        [polylines addObject:polyline];
        free(coordinates),coordinates = NULL;
    }];
    return polylines;
}

//解析经纬度串
- (CLLocationCoordinate2D *)coordiantesForString:(NSString *)string
                                 coordinateCount:(NSUInteger *)coordinateCount
                                      parseToken:(NSString *)token
{
    if (string == nil) {
        return NULL;
    }
    if (token == nil) {
        token = @",";
    }
    NSString *str = @"";
    if (![token isEqualToString:@","]) {
        str = [string stringByReplacingOccurrencesOfString:token withString:@","];
    }
    else
    {
        str = [NSString stringWithString:string];
    }
    NSArray *components = [str componentsSeparatedByString:@","];
    NSUInteger count = [components count] / 2;
    if (coordinateCount != NULL) {
        *coordinateCount = count;
    }
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(count * sizeof(CLLocationCoordinate2D));
    for (int i = 0; i < count; i ++) {
        coordinates[i].longitude = [[components objectAtIndex:2 * i] doubleValue];
        coordinates[i].latitude = [[components objectAtIndex:2 * i + 1] doubleValue];
    }
    return coordinates;
}
#pragma mark - UITableViewDataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _pois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    AMapPOI *poi = _pois[indexPath.row];
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // 为点击的poi点添加标注
    AMapPOI *poi = _pois[indexPath.row];
    //MAPointAnnotation用作地图上的标记，只提供数据
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
    annotation.title = poi.name;
    annotation.subtitle = poi.address;
    //将搜索结果添加到
    [_annotations addObject:annotation];
    //添加标注
    [_mapView addAnnotation:annotation];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
