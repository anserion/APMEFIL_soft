//Copyright 2015 Andrey S. Ionisyan (anserion@gmail.com)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

//=====================================================================
//подпрограммы цифровой фильтрации растровых изображений
//=====================================================================
unit filters_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,Graphics, utils_unit, globals_unit, img_unit;

//медианный фильтр
procedure FilterMedian(img:TIMG; Radius:integer);
//Адаптивный медианный фильтр от соли и перца
procedure FilterAdaptiveMedian(img:TIMG; Radius:integer);
//фильтр зашумления "солью и перцем" NoisePercent пикселей засвечиваются
//или белым или черным цветом
procedure FilterSaultPepper(img:TIMG; NoisePercent:real);
//процедура определения пикового соотношения сигнал/шум
procedure FilterPSNR(img_orig,img_new:TIMG; var PSNR_r,PSNR_g,PSNR_b:real);

implementation

//медианный фильтр
procedure FilterMedian(img:TIMG; Radius:integer);
var x,y,i,j,k,N,r,g,b:integer;
    tmp_img,filter_img:TIMG;
    red_data,green_data,blue_data:array of integer;
    C:Int32;
begin
     N:=Radius*Radius;
     tmp_img:=TIMG.create;
     tmp_IMG.SetSize(IMG.width,IMG.height);
     tmp_img.FillRect(0,0,tmp_img.width-1,tmp_img.height-1,0);

     filter_img:=TIMG.create;
     filter_img.SetSize(Radius,Radius);

     setlength(red_data,N);
     setlength(green_data,N);
     setlength(blue_data,N);

     for y:=radius to img.height-radius-1 do
     for x:=radius to img.width-radius-1 do
     begin
       img.CopyRect(filter_img,RECT(x,y,x+radius,y+radius),RECT(0,0,radius-1,radius-1));
       k:=0;
       for i:=0 to radius-1 do
       for j:=0 to radius-1 do
       begin
           C:=filter_img.GetPixel(i,j);
           red_data[k]:=red(C);
           green_data[k]:=green(C);
           blue_data[k]:=blue(C);
           k:=k+1;
       end;

       quick_sort(red_data,0,N-1); r:=red_data[N div 2];
       quick_sort(green_data,0,N-1); g:=green_data[N div 2];
       quick_sort(blue_data,0,N-1); b:=blue_data[N div 2];
       tmp_img.SetPixel(x,y,RGBToColor(r,g,b));
     end;
     tmp_IMG.CloneToIMG(img);

     setlength(red_data,0);
     setlength(green_data,0);
     setlength(blue_data,0);
     tmp_img.done; filter_img.done;
end;

//Адаптивный медианный фильтр от соли и перца
procedure FilterAdaptiveMedian(img:TIMG; Radius:integer);
var x,y,i,j,k,N,r,g,b:integer;
    tmp_img,tmp_src,filter_img:TIMG;
    red_data,green_data,blue_data:array of integer;
    pepper_color,sault_color,C:Int32;
begin
     N:=Radius*Radius;
     pepper_color:=0; sault_color:=65536*255+256*255+255;
     tmp_src:=TIMG.create;
     tmp_src.SetSize(IMG.width+radius+radius,IMG.height+radius+radius);
     tmp_src.FillRect(0,0,tmp_src.width-1,tmp_src.height-1,0);
     img.CopyRect(tmp_src,RECT(0,0,img.width-1,img.height-1),RECT(radius,radius,img.width+radius,img.height+radius));

     tmp_img:=TIMG.create;
     tmp_IMG.SetSize(IMG.width,IMG.height);
     tmp_img.FillRect(0,0,tmp_img.width-1,tmp_img.height-1,0);

     filter_img:=TIMG.create;
     filter_img.SetSize(Radius,Radius);

     setlength(red_data,N);
     setlength(green_data,N);
     setlength(blue_data,N);

     for y:=radius to tmp_src.height-radius-1 do
     for x:=radius to tmp_src.width-radius-1 do
     begin
       C:=tmp_src.GetPixel(x,y);
       if (C<>pepper_color)and(C<>sault_color) then tmp_img.SetPixel(x-radius,y-radius,C)
          else
       begin
         tmp_src.CopyRect(filter_img,RECT(x,y,x+radius,y+radius),RECT(0,0,radius-1,radius-1));
         k:=0; red_data[0]:=0; green_data[0]:=0; blue_data[0]:=0;
         for i:=0 to radius-1 do
         for j:=0 to radius-1 do
         begin
           C:=filter_img.GetPixel(i,j);
           if (C<>pepper_color)and(C<>sault_color) then
           begin
             red_data[k]:=red(C);
             green_data[k]:=green(C);
             blue_data[k]:=blue(C);
             k:=k+1;
           end;
         end;

         quick_sort(red_data,0,k-1); r:=red_data[k div 2];
         quick_sort(green_data,0,k-1); g:=green_data[k div 2];
         quick_sort(blue_data,0,k-1); b:=blue_data[k div 2];
         tmp_img.SetPixel(x-radius,y-radius,RGBToColor(r,g,b));
       end;
     end;
     tmp_IMG.CloneToIMG(img);

     setlength(red_data,0);
     setlength(green_data,0);
     setlength(blue_data,0);
     tmp_img.done; filter_img.done; tmp_src.done;
end;

//фильтр зашумления "солью и перцем" NoisePercent пикселей засвечиваются
//или белым или черным цветом
procedure FilterSaultPepper(img:TIMG; NoisePercent:real);
var x,y:integer;
begin
  for y:=0 to img.height-1 do
  for x:=0 to img.width-1 do
  begin
    if random*100<NoisePercent then img.SetPixel(x,y,Random(2)*(65536*255+256*255+255));
  end;
end;

//процедура определения пикового соотношения сигнал/шум
procedure FilterPSNR(img_orig,img_new:TIMG; var PSNR_r,PSNR_g,PSNR_b:real);
var x,y:integer;
    peakval,MSE_r,MSE_g,MSE_b:real;
    r_orig,r_new,g_orig,g_new,b_orig,b_new:Integer;
    C_orig,C_new:Int32;
begin
     peakval:=255;
     MSE_r:=0; MSE_g:=0; MSE_b:=0;
     for y:=0 to img_orig.height-1 do
     for x:=0 to img_orig.width-1 do
     begin
       C_orig:=img_orig.GetPixel(x,y);
       C_new:=img_new.GetPixel(x,y);
       MSE_r:=MSE_r+sqr(red(C_orig)-red(C_new));
       MSE_g:=MSE_g+sqr(green(C_orig)-green(C_new));
       MSE_b:=MSE_b+sqr(blue(C_orig)-blue(C_new));
     end;
     MSE_r:=MSE_r/(img_orig.width*img_orig.height);
     MSE_g:=MSE_g/(img_orig.width*img_orig.height);
     MSE_b:=MSE_b/(img_orig.width*img_orig.height);

     if MSE_r<>0 then PSNR_r:=10*lg(sqr(peakval)/MSE_r) else PSNR_r:=-1;
     if MSE_g<>0 then PSNR_g:=10*lg(sqr(peakval)/MSE_g) else PSNR_g:=-1;
     if MSE_b<>0 then PSNR_b:=10*lg(sqr(peakval)/MSE_b) else PSNR_b:=-1;
end;

end.

