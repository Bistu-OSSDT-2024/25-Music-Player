import media from '@ohos.multimedia.media';
import common from '@ohos.app.ability.common';
import display from '@ohos.display';
@Entry
@Component
struct Index {
  @State screenWidth:number = px2vp(display.getDefaultDisplaySync().width)
  @State screenHeight:number = px2vp(display.getDefaultDisplaySync().height)
  private rotaAngle:number=0;
  @State isPlay:boolean = false;
  private timer?: number;
  @State value: number = 0;
  private count: number = 0;
  private isSeek: boolean = true;
  private fileSize: number = -1;
  private fd: number = 0;
  @State duration:number = 0
  @State progressNow:number = 0
  @State durationTimeString:string = '00:00'
  @State progressTimeString:string = '00:00'
  private avPlayer?: media.AVPlayer = undefined;
  @State listViewPosition:number = this.screenHeight
  @State musicList:MusicClass[] = [
    new MusicClass('How to love','Cash,Sofia Reyes','How To Love.mp3','How to Love.jpg'),
    new MusicClass('Closer','The Chainsmokers,Halsey','Closer.mp3','Closer.jpg'),
    new MusicClass('The way I still love you','Reynard Silva','The way I still love you.mp3','The Way I Still Love You.jpg')
  ]
  @State currentMusic:MusicClass = this.musicList[0]
  @State currentIndex:number = 0
  onPageShow(): void {
    this.avPlayerUrlDemo()
  }//初始化播放器
  startRotate() {
    this.timer = setInterval(() => {
      // 保留2位小数
    }, 30);
    if (this.avPlayer != undefined) {
      if(this.avPlayer.state != 'playing'){
        this.avPlayer.play()
      }else {
        this.avPlayer.pause()
      }
    }
  }
  endPlay() {
    clearInterval(this.timer)
    if (this.avPlayer != undefined) {
      this.avPlayer.pause()
    }
  }
  async avPlayerUrlDemo() {
    let avPlayer: media.AVPlayer = await media.createAVPlayer();
    this.setAVPlayerCallback(avPlayer);
    // 通过UIAbilityContext的resourceManager成员的getRawFd接口获取媒体资源播放地址
    // 返回类型为{fd,offset,length},fd为HAP包fd地址，offset为媒体资源偏移量，length为播放长度
    let context = getContext(this) as common.UIAbilityContext;
    let fileDescriptor = await context.resourceManager.getRawFd(this.musicList[this.currentIndex].url);
    let avFileDescriptor: media.AVFileDescriptor =
      { fd: fileDescriptor.fd, offset: fileDescriptor.offset, length: fileDescriptor.length };
    this.isSeek = false; // 支持seek操作
    // 为fdSrc赋值触发initialized状态机上报
    avPlayer.fdSrc = avFileDescriptor;
    this.avPlayer = avPlayer
  }
  // 注册avplayer回调函数
  setAVPlayerCallback(avPlayer: media.AVPlayer) {
    avPlayer.on('timeUpdate', (seekDoneTime: number) => {
      if(this.duration > 0){
        let progress = seekDoneTime/this.duration
        this.progressNow = progress*100
      }
      this.progressTimeString = this.durationToTimeString(seekDoneTime)
    })
    avPlayer.on('seekDone', (seekDoneTime: number) => {
      console.info(`AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    })
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case 'idle':
          console.info('AVPlayer state idle called.');
          avPlayer.release();
          break;
        case 'initialized':
          console.info('AVPlayer state initialized called.');
          avPlayer.prepare();
          break;
        case 'prepared':
          console.info('AVPlayer state prepared called.');
          if(this.isPlay){
            avPlayer.play();
          }
          this.duration = avPlayer.duration
          this.durationTimeString = this.durationToTimeString(this.duration)
          console.log('duration:',avPlayer.duration)
          break;
        case 'playing':
          console.info('AVPlayer state playing called.');
          this.count++;
          break;
        case 'paused':
          console.info('AVPlayer state paused called.');
          break;
        case 'completed':
          console.info('AVPlayer state completed called.');
          if(this.currentIndex < this.musicList.length - 1){
            this.currentIndex += 1
            this.changeSong()
          }else {
            this.endPlay();
          }
          break;
        case 'stopped':
          console.info('AVPlayer state stopped called.');
          break;
        case 'released':
          console.info('AVPlayer state released called.');
          break;
        default:
          console.info('AVPlayer state unknown called.');
          break;
      }
    })
  }
  durationToTimeString(duration:number){
    let secondTotal:number = duration/1000
    let minute:number = Math.floor(secondTotal/60)//计算分钟
    let second:number = Math.floor(secondTotal%60)//计算秒钟
    return this.padWithZeros(minute,2) + ":" + this.padWithZeros(second,2)
  }
  padWithZeros(number:number, length:number) {
    return String(number).padStart(length, '0');
  }//转化为标准形式，加上0
  changeSong(){
    if(this.avPlayer != undefined){
      this.avPlayer.reset()
    }
    this.avPlayerUrlDemo()
  }//重置播放器以加载新歌曲
  playOrPause(){
    this.isPlay = !this.isPlay
    if(this.isPlay){
      this.startRotate()
    }else {
      this.endPlay()
    }

  }//启动或暂停

  @Builder NavigationMenus() { // CustomBuilder类型的菜单栏（播放器）
    Row() {
      Image($r('app.media.nav_down'))
        .size({ width: 25, height: 25 })
        .margin({ left: 20 })//下载图标
      Row(){
        Text('相关')
          .fontSize(14)
          .fontColor('#ffbdccf3')
          .margin({right:20})//相关图标
        Text('歌曲')
          .fontSize(14)
          .fontColor('#ff7594ee')
          .margin({right:20})//歌曲图标
        Text('歌词')
          .fontSize(14)
          .fontColor('#ff516cb8')//歌词图标
      }
      Image($r('app.media.nav_share'))
        .size({ width: 25, height: 25 })
        .margin({ right: 20 })//分享图标
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
  }
  build() {
    Stack({alignContent:Alignment.Bottom}){
        Flex({direction:FlexDirection.Column,justifyContent:FlexAlign.SpaceBetween}){
          Row() {
            Image($r('app.media.nav_down'))
              .size({ width: 25, height: 25 })//导航
            Row(){
              Text('相关')
                .fontSize(14)
                .fontColor('#76777A')
                .margin({right:20})
              Text('歌曲')
                .fontSize(14)
                .fontColor('#222628')
                .margin({right:20})
              Text('歌词')
                .fontSize(14)
                .fontColor('#76777A')
            }
            Image($r('app.media.nav_share'))
              .size({ width: 25, height: 25 })//导航菜单栏中的共享图标
          }
          .width('100%')
          .height(68)
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)//主布局，子元素垂直居中
          Row(){
            Image($rawfile(this.musicList[this.currentIndex].cover))
              .width(this.screenWidth - 50)
              .height(this.screenWidth - 50)

          }
          .margin({top:10})
          .justifyContent(FlexAlign.Center)
          .width('100%')//专辑中心图片部分

          Column(){
            Text(this.musicList[this.currentIndex].title)
              .fontColor('#222628')
              .fontSize(24)//当前歌曲

            Text(this.musicList[this.currentIndex].singer)
              .fontColor('#76777A')
              .fontSize(14)
              .margin({top:10})//当前歌手
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)//歌曲信息部分
          Column(){
            Row(){
              Image($r('app.media.tool_like'))
                .width(24)
                .height(24)//收藏图标
              Image($r('app.media.tool_slider'))
                .width(24)
                .height(24)//音效图标
              Image($r('app.media.tool_down'))
                .width(24)
                .height(24)//下载图标
              Image($r('app.media.tool_comment'))
                .width(24)
                .height(24)//评论图标
              Image($r('app.media.tool_more'))
                .width(24)
                .height(24)//更多图标
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            .height(50)//工具栏

            Column(){
              Progress({ value: this.progressNow, total: 100, type: ProgressType.Linear }) // 创建一个进度总长为100，初始进度值为24的线性进度条
                .width('100%')
                .margin({top:20})
                .backgroundColor('rgb(239,239,239)')
                .color(Color.White)//创建进度条
              Row(){
                Text(this.progressTimeString)
                  .fontColor('#76777A')
                  .fontSize(13)
                  .fontWeight(200)//当前时间显示
                Text(this.durationTimeString)
                  .fontColor('#76777A')
                  .fontSize(13)
                  .fontWeight(200)//所有时间显示
              }
              .width('100%')
              .margin({top:10})
              .justifyContent(FlexAlign.SpaceBetween)
            }//进度条和时间显示
            Row(){
              Image($r('app.media.control_loop'))
                .width(25)
                .height(25)//循环图标
              Image($r('app.media.control_last'))
                .width(32)
                .height(32)
                .objectFit(ImageFit.Auto)
                .onClick(()=>{
                  if(this.currentIndex > 0){
                    this.currentIndex -= 1
                    this.changeSong()
                  }//点击事件
                })//切换上一首歌
              Image( this.isPlay ? $r('app.media.control_pause') : $r('app.media.control_play'))
                .width(64)
                .height(64)
                .onClick(()=>{
                  this.playOrPause()
                })//暂停音乐
              Image($r('app.media.control_next'))
                .width(32)
                .height(32)
                .objectFit(ImageFit.Auto)
                .onClick(()=>{
                  if(this.currentIndex < this.musicList.length - 1){
                    this.currentIndex += 1
                    this.changeSong()
                  }
                })//切换下一首歌
              Image($r('app.media.control_list'))
                .width(25)
                .height(25)
                .onClick(()=>{
                  animateTo({
                    duration: 200,
                  }, () => {
                    let y = 20 + 40 + 62*this.musicList.length
                    this.listViewPosition = this.screenHeight - y
                  })
                })
            }
            .margin({top:30})
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .margin({bottom:40})
        }
        .width('100%')
        .height('100%')
        .padding({left:20,right:20})
        .radialGradient({
          center: [this.screenWidth/2, this.screenHeight/2],
          radius: this.screenWidth*2,
          colors: [[0xE0EEFF, 0.0], [0xE4F2FF, 0.3], [0xFBD4FF, 1]]
        })//全局布局设置
      ListView({musicList:$musicList,currentIndex:this.currentIndex,isPlaying:this.isPlay,
        playAction:(index:number)=>{
          this.currentIndex = index
          if(!this.isPlay){
            this.startRotate()
            this.isPlay = true
          }
          this.changeSong()
        },
        pauseAction:()=>{
          this.playOrPause()
        },
        pansEnd:()=>{
          animateTo({
            duration: 200,
          }, () => {
            this.listViewPosition = this.screenHeight
          })
        }})
        .position({y:this.listViewPosition})
    }
  }
}
class MusicClass{
  title:string
  singer:string
  url:string
  cover:string
  constructor(title:string,singer:string,url:string,cover:string) {
    this.title = title
    this.singer = singer
    this.url = url
    this.cover = cover
  }//封装音乐信息
}
@CustomDialog
export struct ListView {
  controller: CustomDialogController
  @Link musicList: MusicClass[]
  @Prop currentIndex: number
  @Prop isPlaying: boolean
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Down })//定义向下滑的手势PanDirection.Down
  pansEnd = () => {}
  pauseAction = () => {}
  playAction = (index:number) => {}//三个空方法在手势结束、暂停和播放时调用
  build() {
    Column(){
      Row(){
        Row(){
        }
        .width(40)
        .height(4)
        .backgroundColor('rgb(234,235,237)')
        .borderRadius(2)
      }//白条用于手势的触发区域
      .height(20)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .onTouch((event?: TouchEvent) => {
      })
      .gesture(
        PanGesture(this.panOption)
          .onActionStart((event?: GestureEvent) => {
            console.info('Pan start')//动作开始
          })
          .onActionUpdate((event?: GestureEvent) => {
            if (event) {
              console.info('event:',JSON.stringify(event))
              let globalY:number = event['globalY'];//动作进行
            }
          })
          .onActionEnd(() => {
            console.info('Pan end')
            this.pansEnd()
          })//动作结束
      )
      Row(){
        Text('当前播放')
          .fontSize(17)
          .fontWeight(600)
          .margin({left:20})
      }
      .height(40)
      .alignItems(VerticalAlign.Center)
      Divider()
        .width('100%')
        .height(0.8)
        .backgroundColor('rgb(226,226,226)')
      List({space:0}){
        ForEach(this.musicList,(item:MusicClass,index)=>{
          ListItem(){
            Row(){
              Column(){
                Text(item.title)
                  .fontColor('#222628')
                  .fontSize(16)
                Text(item.singer)
                  .fontColor('#76777A')
                  .fontSize(12)
                  .margin({bottom:8})
              }//遍历音乐数组创建列表
              .alignItems(HorizontalAlign.Start)
              if(this.currentIndex == index && this.isPlaying){
                Image($r('app.media.list_pause'))
                  .width(28)
                  .height(28)
                  .onClick(()=>{
                    this.pauseAction()
                  })
              }else{
                Image($r('app.media.list_play'))
                  .width(28)
                  .height(28)
                  .onClick(()=>{
                    this.playAction(index)
                  })
              }
            }
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            .height(62)
          }
        })
      }
      .divider({strokeWidth:0.5,color:'rgb(236,236,236)'})
      .padding({left:20,right:20})
    }//垂直两端对齐
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({topLeft:20,topRight:20})
    .shadow({ radius: 30, color: 'rgba(230,230,230,0.7)', offsetX: 0, offsetY: -20 })
  }
}