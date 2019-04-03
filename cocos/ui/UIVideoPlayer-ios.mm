/****************************************************************************
 Copyright (c) 2014-2016 Chukong Technologies Inc.
 Copyright (c) 2017-2018 Xiamen Yaji Software Co., Ltd.

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "ui/UIVideoPlayer.h"

// No Available on tvOS
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS && !defined(CC_TARGET_OS_TVOS)

using namespace cocos2d::experimental::ui;
//-------------------------------------------------------------------------------------

#include "platform/ios/CCEAGLView-ios.h"
#include "base/CCDirector.h"
#include "platform/CCFileUtils.h"

#include <AVKit/AVPlayerViewController.h>
#include <AVFoundation/AVPlayer.h>
#include <AVFoundation/AVPlayerItem.h>
#include <CoreGraphics/CGGeometry.h>

@interface UIVideoViewWrapperIos : NSObject

@property (strong, nonatomic) AVPlayerViewController * moviePlayer;

- (void) setFrame:(int) left :(int) top :(int) width :(int) height;
- (void) setURL:(int) videoSource :(std::string&) videoUrl;
- (void) play;
- (void) pause;
- (void) resume;
- (void) stop;
- (void) seekTo:(float) sec;
- (void) setVisible:(BOOL) visible;
- (void) setKeepRatioEnabled:(BOOL) enabled;
- (void) setFullScreenEnabled:(BOOL) enabled;
- (BOOL) isFullScreenEnabled;
- (void) initializeURL:(int)urlType url:(std::string&)url;
- (void) initializeMoviePlayer;
- (void) destroyMoviePlayer;
- (void) destroyURL;

-(id) init:(void*) videoPlayer;

-(void) videoFinished:(NSNotification*) notification;
-(void) playStateChange;
- (void)loadStateChange;


@end

@implementation UIVideoViewWrapperIos
{
    int _left;
    int _top;
    int _width;
    int _height;
    CMTime _currentTime;
    bool _paused;
    NSURL* _url;

    VideoPlayer* _videoPlayer;
}

-(id)init:(void*)videoPlayer
{
    if (self = [super init])
    {
        self.moviePlayer = nullptr;
        _videoPlayer = (VideoPlayer*)videoPlayer;
        _paused = false;
        _url = nullptr;
    }

    return self;
}

-(void) dealloc
{
    [self destroyMoviePlayer];
    [self destroyURL];
    [super dealloc];
}

-(void) setFrame:(int)left :(int)top :(int)width :(int)height
{
    _left = left;
    _width = width;
    _top = top;
    _height = height;
    if (self.moviePlayer != nullptr)
    {
        [self.moviePlayer.view setFrame:CGRectMake(left, top, width, height)];
    }
}

-(void) setFullScreenEnabled:(BOOL) enabled
{
    // not supported
}

-(BOOL) isFullScreenEnabled
{
    return false;
}

-(void) setURL:(int)videoSource :(std::string &)videoUrl
{
    [self destroyMoviePlayer];

    // should initialize url first
    [self initializeURL:videoSource url:videoUrl];
    [self initializeMoviePlayer];
}

-(void) videoFinished:(NSNotification *)notification
{
    if (_videoPlayer !=  nullptr)
    {
        [self destroyMoviePlayer];
        _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::COMPLETED);
    }
}

-(void) seekTo:(float)sec
{
    if (self.moviePlayer != nullptr)
        [self.moviePlayer.player seekToTime:CMTimeMake(sec * 100, 100)];
}

-(void) setVisible:(BOOL)visible
{
    if (self.moviePlayer != nullptr) {
        [self.moviePlayer.view setHidden:!visible];
    }
}

-(void) setKeepRatioEnabled:(BOOL)enabled
{
    // not supported
}

-(void) play
{
    if (self.moviePlayer != nullptr)
    {
        [self.moviePlayer.view setFrame:CGRectMake(_left, _top, _width, _height)];
        [self.moviePlayer.player play];
        _paused = false;
        _currentTime = CMTimeMake(0, 100);
        
        if (self.moviePlayer.player.status == AVPlayerStatusReadyToPlay)
        {
            _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::PLAYING);
        }
    }
}

-(void) pause
{
    if (self.moviePlayer != nullptr)
    {
        _currentTime = [self.moviePlayer.player currentTime];
        _paused = true;
        [self.moviePlayer.player pause];
        
        _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::PAUSED);
    }
}

-(void) resume
{
    if (self.moviePlayer != nullptr && _paused)
    {
        [self seekTo: CMTimeGetSeconds(_currentTime)];
        [self play];
        _paused = false;
    }
}

-(void) stop
{
    if (self.moviePlayer != nullptr)
    {
        // AVPlayer doesn't have a `stop` method, so invoke `destroyMoviePlayer` to have the same effect.
        [self destroyMoviePlayer];
        _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::STOPPED);
        _paused = false;
    }
}

-(void) initializeMoviePlayer
{
    [self destroyMoviePlayer];
    
    self.moviePlayer = [[AVPlayerViewController alloc] init];
    self.moviePlayer.view.userInteractionEnabled = true;
    self.moviePlayer.player = [AVPlayer playerWithURL:_url];
    self.moviePlayer.showsPlaybackControls = false;
    
    auto clearColor = [UIColor clearColor];
    self.moviePlayer.view.backgroundColor = clearColor;
    for (UIView * subView in self.moviePlayer.view.subviews)
        subView.backgroundColor = clearColor;
    
    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    auto eaglview = (CCEAGLView *) view->getEAGLView();
    [[eaglview superview] insertSubview:self.moviePlayer.view atIndex:0];
//    glClearColor(0, 0, 0, 0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.moviePlayer.player currentItem]];
    [self.moviePlayer.player addObserver:self forKeyPath:@"status" options:0 context:nil];
}

-(void) initializeURL:(int)urlType url:(std::string&)url
{
    [self destroyURL];
    
    if (urlType == 0)
        _url = [[NSURL alloc] initFileURLWithPath:@(url.c_str())];
    else
        _url = [[NSURL alloc] initWithString:@(url.c_str())];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == self.moviePlayer.player && [keyPath isEqualToString:@"status"])
    {
        if (self.moviePlayer.player.status == AVPlayerStatusReadyToPlay)
        {
            _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::PLAYING);
        }
    }
}

-(void) destroyMoviePlayer
{
    if (self.moviePlayer != nullptr)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.moviePlayer.player currentItem]];
        [self.moviePlayer.player removeObserver:self forKeyPath:@"status"];
        
        // It is more reasonable to invoke `stop` here, but because `stop` will invoke `destroyMoviePlayer` to real stop the video
        // so inoke `pause` here.
        _currentTime = [self.moviePlayer.player currentTime];
        _paused = true;
        [self.moviePlayer.player pause];
        [self.moviePlayer.view removeFromSuperview];
        self.moviePlayer = nullptr;
    }
}

-(void) destroyURL
{
    if (_url)
        [_url dealloc];
    
    _url = nullptr;
}

-(double) getDuration
{
    if (self.moviePlayer != nullptr)
    {
        return CMTimeGetSeconds(self.moviePlayer.player.currentItem.asset.duration);
    }
    
    return 0.0f;
}

-(double) getCurrentPlaybackTime
{
    if (self.moviePlayer != nullptr)
    {
        return CMTimeGetSeconds(self.moviePlayer.player.currentItem.currentTime);
    }
    
    return 0.0f;
}

@end
//------------------------------------------------------------------------------------------------------------

VideoPlayer::VideoPlayer()
: _isPlaying(false)
, _fullScreenDirty(false)
, _fullScreenEnabled(false)
, _keepAspectRatioEnabled(false)
, _videoPlayerIndex(-1)
, _eventCallback(nullptr)
{
    _videoView = [[UIVideoViewWrapperIos alloc] init:this];

#if CC_VIDEOPLAYER_DEBUG_DRAW
    _debugDrawNode = DrawNode::create();
    addChild(_debugDrawNode);
#endif
}

VideoPlayer::~VideoPlayer()
{
    if(_videoView)
    {
        [((UIVideoViewWrapperIos*)_videoView) dealloc];
    }
}

void VideoPlayer::setFileName(const std::string& fileName)
{
    _videoURL = FileUtils::getInstance()->fullPathForFilename(fileName);
    _videoSource = VideoPlayer::Source::FILENAME;
    [((UIVideoViewWrapperIos*)_videoView) setURL:(int)_videoSource :_videoURL];
}

void VideoPlayer::setURL(const std::string& videoUrl)
{
    _videoURL = videoUrl;
    _videoSource = VideoPlayer::Source::URL;
    [((UIVideoViewWrapperIos*)_videoView) setURL:(int)_videoSource :_videoURL];
}

void VideoPlayer::draw(Renderer* renderer, const Mat4 &transform, uint32_t flags)
{
    cocos2d::ui::Widget::draw(renderer,transform,flags);

    if (flags & FLAGS_TRANSFORM_DIRTY)
    {
        auto directorInstance = Director::getInstance();
        auto glView = directorInstance->getOpenGLView();
        auto frameSize = glView->getFrameSize();
        auto scaleFactor = [static_cast<CCEAGLView *>(glView->getEAGLView()) contentScaleFactor];

        auto winSize = directorInstance->getWinSize();

        auto leftBottom = convertToWorldSpace(Vec2::ZERO);
        auto rightTop = convertToWorldSpace(Vec2(_contentSize.width,_contentSize.height));

        auto uiLeft = (frameSize.width / 2 + (leftBottom.x - winSize.width / 2 ) * glView->getScaleX()) / scaleFactor;
        auto uiTop = (frameSize.height /2 - (rightTop.y - winSize.height / 2) * glView->getScaleY()) / scaleFactor;

        [((UIVideoViewWrapperIos*)_videoView) setFrame :uiLeft :uiTop
                                                          :(rightTop.x - leftBottom.x) * glView->getScaleX() / scaleFactor
                                                          :( (rightTop.y - leftBottom.y) * glView->getScaleY()/scaleFactor)];
    }

#if CC_VIDEOPLAYER_DEBUG_DRAW
    _debugDrawNode->clear();
    auto size = getContentSize();
    Point vertices[4]=
    {
        Point::ZERO,
        Point(size.width, 0),
        Point(size.width, size.height),
        Point(0, size.height)
    };
    _debugDrawNode->drawPoly(vertices, 4, true, Color4F(1.0, 1.0, 1.0, 1.0));
#endif
}

bool VideoPlayer::isFullScreenEnabled()const
{
    return [((UIVideoViewWrapperIos*)_videoView) isFullScreenEnabled];
}

void VideoPlayer::setFullScreenEnabled(bool enabled)
{
    [((UIVideoViewWrapperIos*)_videoView) setFullScreenEnabled:enabled];
}

void VideoPlayer::setKeepAspectRatioEnabled(bool enable)
{
    if (_keepAspectRatioEnabled != enable)
    {
        _keepAspectRatioEnabled = enable;
        [((UIVideoViewWrapperIos*)_videoView) setKeepRatioEnabled:enable];
    }
}

void VideoPlayer::play()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) play];
    }
}

void VideoPlayer::pause()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) pause];
    }
}

void VideoPlayer::resume()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) resume];
    }
}

void VideoPlayer::stop()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) stop];
    }
}

void VideoPlayer::seekTo(float sec)
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) seekTo:sec];
    }
}

bool VideoPlayer::isPlaying() const
{
    return _isPlaying;
}

void VideoPlayer::setVisible(bool visible)
{
    cocos2d::ui::Widget::setVisible(visible);

    if (!visible)
    {
        [((UIVideoViewWrapperIos*)_videoView) setVisible:NO];
    }
    else if(isRunning())
    {
        [((UIVideoViewWrapperIos*)_videoView) setVisible:YES];
    }
}

void VideoPlayer::onEnter()
{
    Widget::onEnter();
    if (isVisible())
    {
        [((UIVideoViewWrapperIos*)_videoView) setVisible: YES];
    }
}

void VideoPlayer::onExit()
{
    Widget::onExit();
    [((UIVideoViewWrapperIos*)_videoView) setVisible: NO];
}

void VideoPlayer::addEventListener(const VideoPlayer::ccVideoPlayerCallback& callback)
{
    _eventCallback = callback;
}

double VideoPlayer::getDuration() const
{
    double duration = -1;
    
    if (!_videoURL.empty())
    {
        duration = floor([((UIVideoViewWrapperIos *)_videoView) getDuration] * 1000.0f);
    }
    
    return duration;
}

double VideoPlayer::getCurrentPlaybackTime() const
{
    double currentPlaybackTime = -1;
    
    if (!_videoURL.empty())
    {
        currentPlaybackTime = floor([((UIVideoViewWrapperIos *)_videoView) getCurrentPlaybackTime] * 1000.0f);
    }
    
    return currentPlaybackTime;
}

void VideoPlayer::releaseVideo()
{
}

void VideoPlayer::onPlayEvent(int event)
{
    if (event == (int)VideoPlayer::EventType::PLAYING) {
        _isPlaying = true;
    } else {
        _isPlaying = false;
    }

    if (_eventCallback)
    {
        _eventCallback(this, (VideoPlayer::EventType)event);
    }
}

cocos2d::ui::Widget* VideoPlayer::createCloneInstance()
{
    return VideoPlayer::create();
}

void VideoPlayer::copySpecialProperties(Widget *widget)
{
    VideoPlayer* videoPlayer = dynamic_cast<VideoPlayer*>(widget);
    if (videoPlayer)
    {
        _isPlaying = videoPlayer->_isPlaying;
        _fullScreenEnabled = videoPlayer->_fullScreenEnabled;
        _fullScreenDirty = videoPlayer->_fullScreenDirty;
        _videoURL = videoPlayer->_videoURL;
        _keepAspectRatioEnabled = videoPlayer->_keepAspectRatioEnabled;
        _videoSource = videoPlayer->_videoSource;
        _videoPlayerIndex = videoPlayer->_videoPlayerIndex;
        _eventCallback = videoPlayer->_eventCallback;
        _videoView = videoPlayer->_videoView;
    }
}

#endif
