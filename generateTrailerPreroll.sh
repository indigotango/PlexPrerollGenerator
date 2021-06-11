#!/bin/bash
## Generate Plex prerolls to highlight recent movie
## additions to a Plex Media Server instance.

# Specify path to movie trailer video file
plexgen_TrailerFile=TENET.mp4

## STEP 1: generate trimmed + shifted trailer
## SOURCE: https://superuser.com/a/727388
## seek to 10 seconds in, trim to 12 seconds after that;
## use FFMPEG lossless codec (ffv1) to preserve quality
ffmpeg -ss 10 -i $plexgen_TrailerFile -to 12 -filter_complex "\
  [0:v][0:v]overlay=W/2:0[bg]; \
  [bg] [0:v]overlay=W/2-W[shifted]; \
  [0:v][shifted]xfade=transition=smoothleft:duration=1:offset=1.75[out]" \
-map "[out]" -vcodec ffv1 -an out1.mkv

## STEP 2: alpha overlay on trailer, output as lossless (ffv1)
## SOURCE: https://superuser.com/a/1520509
ffmpeg -i out1.mkv -i alpha_1080.mov -to 12 \
-filter_complex "overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" \
-vcodec ffv1 -an out2.mkv

## STEP 3: overlay Coming Soon / Title / Description text
## SOURCE: http://ffmpeg.shanewhite.co/
# Text for FFMPEG to overlay
plexgen_NowShowing="Now Showing on Plex"
plexgen_Title="Sample Movie Trailer"

# Perform text overlay in FFMPEG
ffmpeg -i out2.mkv -filter_complex "[0:v]\
  drawtext=fontfile=arial.ttf:\
  text='$plexgen_NowShowing':\
  fontsize=68:fontcolor=e5a00d:\
  alpha='if(lt(t,2.25),0,if(lt(t,3),(t-2.25)/0.5,if(lt(t,12),1,if(lt(t,13),(1-(t-12))/1,0))))':x=145:y=400, \
  drawtext=fontfile=arial_bold.ttf:\
  text='$plexgen_Title':\
  fontsize=120:fontcolor=ffffff:\
  alpha='if(lt(t,2.35),0,if(lt(t,3),(t-2.35)/0.5,if(lt(t,12),1,if(lt(t,13),(1-(t-12))/1,0))))':x=142:y=495, \
  drawtext=fontfile=arial_italic.ttf:\
  textfile=text_MovieDescription.txt:\
  fontsize=40:fontcolor=e5a00d:\
  line_spacing=11:\
  alpha='if(lt(t,2.45),0,if(lt(t,3),(t-2.45)/0.5,if(lt(t,12),1,if(lt(t,13),(1-(t-12))/1,0))))':x=145:y=640" \
-vcodec ffv1 out3.mkv

## STEP 4: overlay end wipe + music w/ output of STEP 3,
## use FFMPEG .mp4 encoding defaults (H.264 + AAC)
ffmpeg -i out3.mkv \
-i endwipe_1080.mov -i BG-music.wav \
-filter_complex "overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" \
-crf 18 -tune film preroll_NowShowing.mp4

## STEP 4: clean up temporary files
#rm out1.mkv
#rm out2.mkv
#rm out3.mkv