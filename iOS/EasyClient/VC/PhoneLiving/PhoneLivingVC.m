#import "PhoneLivingVC.h"
#import "EasyCameraCell.h"
#import "EasyCamera.h"
#import "EasyUrl.h"

@interface PhoneLivingVC ()<NetRequestDelegate>
{
    NetRequestTool *_requestTool;
      NSMutableArray *_dataArr;
    UiotHUD *_HUD;

    EasyUrl *_urlModel;
}
@property(nonatomic,strong) NetRequestTool *requestTool;
@end

@implementation PhoneLivingVC

static NSString *cellIdentifier1 = @"Cell1";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self initSomeView];
    _dataArr = [NSMutableArray array];
    self.requestTool = [[NetRequestTool alloc]init];
    self.requestTool.delegate = self;
//    NSString *cmsIp = [[NSUserDefaults standardUserDefaults] stringForKey:@"cms_ip"];
//    NSString *cmsPort = [[NSUserDefaults standardUserDefaults] stringForKey:@"cms_port"];
//    
//    _urlStr= @"http://%@:%@/api/getdevicelist?AppType=EasyCamera&TerminalType=Android";
//    _urlStr = [NSString stringWithFormat:_urlStr, cmsIp,cmsPort];
}

- (void)initSomeView
{
    self.view.backgroundColor = [UIColor whiteColor];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    //定义每个UICollectionView 横向的间距
    layout.minimumLineSpacing = 2;
    //定义每个UICollectionView 纵向的间距
    layout.minimumInteritemSpacing = 2;
    //定义每个UICollectionView 的边距距
    layout.sectionInset = UIEdgeInsetsMake(0, 2, 5, 2);//上左下右
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-40-64) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    
    [self.collectionView registerClass:[EasyCameraCell class] forCellWithReuseIdentifier:cellIdentifier1];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.collectionView];
    
    __weak typeof(self) weakSelf = self;
    //1. 添加头部控件的方法
    self.collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [_HUD show:YES];
        [weakSelf requestListData];
    }];
    
}

#pragma mark -  receiveData
- (void)receiveData:(NSMutableArray *)sender
{
    [_dataArr removeAllObjects];
    _dataArr = sender;
    [self.collectionView.mj_header endRefreshing];
    [_HUD hide:YES afterDelay:0.5];
    [self.collectionView reloadData];
}
// 请求数据
- (void)requestListData
{
    [self.requestTool  requestListData:_urlStr];
}

// 返回Items的个数 （图片的个数）
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataArr.count;
}

// item大小
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((ScreenWidth-10)/2, (ScreenWidth-10)/2);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EasyCameraCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier1 forIndexPath:indexPath];
    
    EasyCamera *model = _dataArr[indexPath.row];
    
    [cell produceCellModel:model];
    
    cell.backgroundColor = [UIColor orangeColor];
    
    return cell;
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cmsIp = [[NSUserDefaults standardUserDefaults] stringForKey:@"cms_ip"];
    NSString *cmsPort = [[NSUserDefaults standardUserDefaults] stringForKey:@"cms_port"];
    
    EasyCamera *model = _dataArr[indexPath.row];
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"html/text",@"text/plain", nil];
    NSString *urlStr =[NSString stringWithFormat:@"http://%@:%@/api/v1/startdevicestream?device=%@&channel=1&protocol=RTSP&reserve=1",cmsIp,cmsPort,model.serial];
    [manager POST:urlStr parameters:nil progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *easyDic = [responseObject objectForKey:@"EasyDarwin"];
        NSDictionary *headerDic =  [easyDic objectForKey:@"Header"];
        NSDictionary *bodyDic =  [easyDic objectForKey:@"Body"];
        if ([[headerDic objectForKey:@"ErrorNum"] isEqualToString:@"200"]) {
            _urlModel = [[EasyUrl alloc]init];
            _urlModel.channel = [bodyDic objectForKey:@"Channel"];
//            _urlModel.protocol = [bodyDic objectForKey:@"Protocol"];
            _urlModel.reserve = [bodyDic objectForKey:@"Reserve"];
            _urlModel.serial = [bodyDic objectForKey:@"Serial"];
//            _urlModel.url = [bodyDic objectForKey:@"URL"];
//            PlayViewController *playVC = [[PlayViewController alloc]init];
//            playVC.urlModel = _urlModel;
//            [self presentViewController:playVC animated:YES completion:nil];
            NSString *serviceString = [bodyDic objectForKey:@"Service"];
            NSArray *urlArray = [serviceString componentsSeparatedByString:@";"];
            NSString *ip = [urlArray[0] componentsSeparatedByString:@"="][1];
            NSString *port = [urlArray[1] componentsSeparatedByString:@"="][1];
            NSString *urlStrGetstream =[NSString stringWithFormat:@"http://%@:%@/api/v1/getdevicestream?device=%@&channel=1&protocol=RTSP&reserve=1",ip,port,model.serial];
            AFHTTPSessionManager * managerGetstream = [AFHTTPSessionManager manager];
            managerGetstream.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"html/text",@"text/plain", nil];
            [managerGetstream GET:urlStrGetstream parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary *serverDic = [responseObject objectForKey:@"EasyDarwin"];
                NSDictionary *serverHeaderDic =  [serverDic objectForKey:@"Header"];
                NSDictionary *serverBodyDic =  [serverDic objectForKey:@"Body"];
                if ([[serverHeaderDic objectForKey:@"ErrorNum"] isEqualToString:@"200"]) {
                    _urlModel.url = [serverBodyDic objectForKey:@"URL"];
                    _urlModel.protocol = [serverBodyDic objectForKey:@"Protocol"];
                    PlayViewController *playVC = [[PlayViewController alloc]init];
                    playVC.urlModel = _urlModel;
                    
                    [self presentViewController:playVC animated:YES completion:nil];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
            }];

        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error====%@",error);
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
