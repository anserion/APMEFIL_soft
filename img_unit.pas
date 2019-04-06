//Copyright 2017 Andrey S. Ionisyan
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
//низкоуровневые функций прямого рисования в видеопамяти битмапа
//=====================================================================
unit img_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, Graphics, Clipbrd, LCLintf, LCLtype, utils_unit, arith_complex;

type
//PInt32=^Int32;
TImg=class
  data:array of Int32; //байты изображения
  name:string; //текстовое имя изображения
  width,height:integer; //ширина и высота изображения
  parent_x0,parent_y0:integer; //рекомендуемые координаты рисования на родительском холсте
  DFT_width,DFT_height:integer; //размеры DFT-матриц (степени двойки)
  red_DFT_f,green_DFT_f,blue_DFT_f:TComplexMatrix; //комплексные коэффициенты ДПФ (частотные)
  red_DFT_t,green_DFT_t,blue_DFT_t:TComplexMatrix; //комплексные коэффициенты ДПФ (временные)
  constructor create; //конструктор
  destructor done; //деструктор
  procedure SetSize(new_width,new_height:integer); //установка нового полотна рисования
  function GetPixelAddress(x,y:integer):Integer; //расчет линейного адреса пиксела в img
  function GetPixelByAddress(address:Int32):Int32; //нахождение цвета пиксела по его линейному адресу
  procedure SetPixelByAddress(address:integer; C:Int32); //изменение цвета пиксела по его линейному адресу
  function CalcAverageColor:Int32; //расчет среднего арифметического яркостных характеристик img

  procedure SetPixel(x,y:integer; C:Int32); //изменение цвета пиксела img
  function GetPixel(x,y:integer):Int32; //выяснение цвета пиксела img
  procedure HorLine(xmin,xmax,y:integer; C:Int32); //рисование горизонтального отрезка заданного цвета
  procedure VerLine(x,ymin,ymax:integer; C:Int32); //рисование вертикального отрезка заданного цвета

  procedure CopyRect(img_dst:TImg; rect_src:TRect; rect_dst:TRect); //копирование прямоугольного участка
  procedure DrawToImg(img_dst:TImg; x0_dst,y0_dst:integer); //рисование на другом холсте
  procedure DrawFromImg(img_src:TImg; x0_src,y0_src:integer); //рисование с другого холста
  procedure CloneToImg(img_dst:TImg); //копирование в img_dst (битмапы одинаковые)
  procedure ScaleToImg(img_dst:TImg); //копирование в img_dst с масштабированием
  procedure RotateToImg(src_x0,src_y0,dst_x0,dst_y0:integer; alpha:real; dst_img:TImg); //копирование в img_dst с поворотом

  procedure FillRect(xmin,ymin,xmax,ymax:integer; C:Int32); //заполнение прямоугольника заданным цветом
  procedure clrscr(C:Int32); //очистка содержимого полотна рисования заданным цветом
  procedure FrameRect(xmin,ymin,xmax,ymax:integer; C:Int32); //рисование прямоугольника заданным цветом
  procedure Ellipse(x0,y0,xr,yr:integer; C:Int32); //рисование эллипса
  procedure Line(x1,y1,x2,y2:integer; C:Int32); //рисование отрезка
  procedure FloodFill(x0,y0:integer; c_old,c_new:Int32); //заполнение замкнутой области выбранным цветом
  procedure FloodFillFuzzy(x0,y0:integer; fuzzy_level:integer; c_old,c_new:Int32); //заполнение замкнутой области выбранным цветом
  procedure turtle(x0,y0:integer; S:string); //"черепашья" графика по командам Бейсиковского Draw
  procedure TextOut(x0,y0:integer; PenColor:Int32; TextToRender:string); //вывод текстовой информации

  procedure AffineTransform(img_dst:TImg; x0,y0,dx,dy,a11,a12,a21,a22,a31,a32:real); //аффинное преобразование на плоскости
  procedure MatrixFilter(img_dst:TImg; k11,k12,k13,k21,k22,k23,k31,k32,k33:real); //матричная фильтрация

  procedure CloneImgToBitmap(bitmap_dst:TBitmap); //перебрасывание изображения на внешний битмап
  procedure CloneBitmapToImg(bitmap_src:TBitmap); //перебрасывание изображения из внешнего битмапа
  procedure LoadFromFile(filename:string); //загрузка изображения из файла (формат по расширению)
  procedure SaveToFile(filename:string); //сохранение изображения в файл (формат по расширению)
  procedure CopyFromClipboard; //загрузка изображения из буфера обмена
  procedure CopyToClipboard; //сохранение изображения в буфер обмена

  procedure ImgToDFT; //нахождение комплексных коэффициентов Фурье
  procedure ImgFromDFT; //восстановление изображения по его коэффициентам Фурье
  procedure clrDFT(c:TComplex); //очистка содержимого массивов коэффициентов Фурье
  procedure CloneToDFT(img_dst:TIMG); //копирование коэффициентов в img_dst (размеры матриц DFT одинаковые)
end;

//фильтр наложения нескольких изображений друг на друга с учетом полупрозрачностей
procedure FilterCompose(dst_img:TIMG; src_img:array of TIMG; transparency:array of real);

implementation

//фильтр наложения нескольких изображений друг на друга с учетом полупрозрачностей
procedure FilterCompose(dst_img:TIMG; src_img:array of TIMG; transparency:array of real);
var i,N,images_num,address:integer; C,Cs:Int32;
    Rs,Gs,Bs: byte;
    K_emission,K_absorption:real;
begin
  images_num:=length(src_img);
  N:=dst_img.width*dst_img.height;
  //подготовка dst_img
  for i:=0 to N-1 do dst_IMG.data[i]:=0;
//собственно сведение
K_emission:=1;
for i:=images_num-1 downto 0 do
begin
  K_absorption:=K_emission*(1-Transparency[i]);
  K_emission:=K_emission*Transparency[i];
  for address:=0 to N-1 do
  begin
    C:=src_img[i].Data[address];
    Cs:=dst_img.Data[address];
    Rs:=trunc((Cs and 255)+(C and 255)*K_absorption);
    Gs:=trunc(((Cs>>8)and 255)+((C>>8)and 255)*K_absorption);
    Bs:=trunc(((Cs>>16)and 255)+((C>>16)and 255)*K_absorption);
    dst_IMG.Data[address]:=Rs+(Gs<<8)+(Bs<<16);
  end;
end;
end;

constructor TImg.create;
begin
  parent_x0:=0; parent_y0:=0;
  width:=0; height:=0;
  DFT_width:=0; DFT_height:=0;
  data:=nil;
  red_DFT_f:=nil; green_DFT_f:=nil; blue_DFT_f:=nil;
  red_DFT_t:=nil; green_DFT_t:=nil; blue_DFT_t:=nil;
end;

destructor TImg.done;
begin
  Finalize(data);
  SetLength(red_DFT_f,0,0); SetLength(red_DFT_t,0,0);
  SetLength(green_DFT_f,0,0); SetLength(green_DFT_t,0,0);
  SetLength(blue_DFT_f,0,0); SetLength(blue_DFT_t,0,0);
end;

procedure TImg.SetSize(new_width,new_height:integer);
begin
  if (new_width>0)and(new_height>0) then
  begin
    parent_x0:=0; parent_y0:=0;
    width:=new_width; height:=new_height;
    SetLength(data,width*height);
    DFT_width:=Power2RoundUp(width); DFT_height:=Power2RoundUp(height);
    SetLength(red_DFT_f,DFT_height,DFT_width);
    SetLength(red_DFT_t,height,width);
    SetLength(green_DFT_f,DFT_height,DFT_width);
    SetLength(green_DFT_t,height,width);
    SetLength(blue_DFT_f,DFT_height,DFT_width);
    SetLength(blue_DFT_t,height,width);
  end;
end;

//расчет линейного адреса пиксела в img
function TIMG.GetPixelAddress(x,y:integer):Integer;
begin GetPixelAddress:=width*y+x; end;

//нахождение цвета пиксела по его линейному адресу
function TIMG.GetPixelByAddress(address:Int32):Int32;
begin GetPixelByAddress:=data[address]; end;

//изменение цвета пиксела по его линейному адресу
procedure TIMG.SetPixelByAddress(address:integer; C:Int32);
begin data[address]:=C; end;

//изменение цвета пиксела
procedure TIMG.SetPixel(x,y:integer; C:Int32);
begin
  if (x>=0)and(y>=0)and(x<width)and(y<height) then data[x+y*width]:=C;
end;

//выяснение цвета пиксела
function TIMG.GetPixel(x,y:integer):Int32;
begin
  if (x>=0)and(y>=0)and(x<width)and(y<height) then
     GetPixel:=data[x+y*width] else GetPixel:=0;
end;

//копирование прямоугольного участка в img_dst
//области копирования-вставки имеют разные размеры
//масштабирование не производится
procedure TIMG.CopyRect(img_dst:TImg; rect_src,rect_dst:TRect);
var x,y,WW,HH:integer; C:Int32;
begin
  CorrectRectParams(self.width,self.height,rect_src.left,rect_src.top,rect_src.right,rect_src.bottom);
  CorrectRectParams(img_dst.width,img_dst.height,rect_dst.left,rect_dst.top,rect_dst.right,rect_dst.bottom);
  HH:=min(rect_src.bottom-rect_src.top+1,rect_dst.bottom-rect_dst.top+1);
  WW:=min(rect_src.Right-rect_src.Left+1,rect_dst.Right-rect_dst.Left+1);
  for y:=0 to HH-1 do
  for x:=0 to WW-1 do
  begin
     C:=GetPixel(x+rect_src.Left,y+rect_src.Top);
     if C<>-1 then img_dst.SetPixel(x+rect_dst.Left,y+rect_dst.Top,C);
  end;
end;

//рисование битмапа на img_dst
procedure TIMG.DrawToImg(img_dst:TImg; x0_dst,y0_dst:integer);
begin
CopyRect(img_dst,rect(0,0,width-1,height-1),rect(x0_dst,y0_dst,img_dst.width-1,img_dst.height-1));
end;

//рисование битмапа из img_src
procedure TIMG.DrawFromImg(img_src:TImg; x0_src,y0_src:integer);
begin
img_src.CopyRect(self,rect(x0_src,y0_src,img_src.width-1,img_src.height-1),rect(0,0,width-1,height-1));
end;

//быстрое копирование img_src в img_dst (битмапы одинаковые)
procedure TIMG.CloneToIMG(img_dst:TImg);
var i,N:integer; C:int32;
begin
  if (width=img_dst.width)and(height=img_dst.height) then
  begin
    N:=width*height-1;
    for i:=0 to N do
    begin
       C:=data[i];
       if C<>-1 then img_dst.data[i]:=C;
    end;
  end;
end;

//рисование горизонтального отрезка заданного цвета
procedure TIMG.HorLine(xmin,xmax,y:integer; C:Int32);
var x:integer;
begin
   if (y>=0)and(y<height) then
   begin
     if xmin>xmax then swap(xmin,xmax);
     if (xmax>=0)and(xmin<width) then
     begin
       if xmin<0 then xmin:=0;
       if xmax>=width then xmax:=width-1;
       for x:=xmin to xmax do data[x+y*width]:=C;
     end;
   end;
end;

//рисование вертикального отрезка заданного цвета
procedure TIMG.VerLine(x,ymin,ymax:integer; C:Int32);
var y:integer;
begin
   if (x>=0)and(x<width) then
   begin
     if ymin>ymax then swap(ymin,ymax);
     if (ymax>=0)and(ymin<height) then
     begin
       if ymin<0 then ymin:=0;
       if ymax>=height then ymax:=height-1;
       for y:=ymin to ymax do SetPixel(x,y,C);
     end;
   end;
end;

//заполнение прямоугольника заданным цветом
procedure TIMG.FillRect(xmin,ymin,xmax,ymax:integer; C:Int32);
var y:integer;
begin
  CorrectRectParams(width,height,xmin,ymin,xmax,ymax);
  for y:=ymin to ymax do HorLine(xmin,xmax,y,C);
end;

//очистка содержимого полотна рисования заданным цветом
procedure TIMG.clrscr(C:Int32);
begin FillRect(0,0,Width-1,Height-1,C); end;

//рисование прямоугольника заданным цветом
procedure TIMG.FrameRect(xmin,ymin,xmax,ymax:integer; C:Int32);
begin
  HorLine(xmin,xmax,ymin,C);
  HorLine(xmin,xmax,ymax,C);
  VerLine(xmin,ymin,ymax,C);
  VerLine(xmax,ymin,ymax,C);
end;

//аффинное преобразование на плоскости
procedure TIMG.AffineTransform(img_dst:TImg; x0,y0,dx,dy,a11,a12,a21,a22,a31,a32:real);
var C:Int32;
    xnum,ynum,xx,yy:integer;
    x,y, x_new,y_new:real;
begin
  xnum:=trunc(width/dx);
  ynum:=trunc(height/dy);
  for yy:=0 to ynum-1 do
  for xx:=0 to xnum-1 do
  begin
     x:=xx*dx-x0; y:=yy*dy-y0;
     x_new:=x*a11+y*a21+a31+x0;
     y_new:=x*a12+y*a22+a32+y0;
     C:=GetPixel(trunc(x+x0),trunc(y+y0));
     img_dst.SetPixel(trunc(x_new),trunc(y_new),C);
  end;
end;

//расчет среднего арифметического яркостных характеристик холста
function TIMG.CalcAverageColor:Int32;
var i,N:integer; Rs,Gs,Bs:real; C:Int32;
begin
  N:=width*height;
  if N<>0 then
  begin
    Rs:=0; Gs:=0; Bs:=0;
    for i:=0 to N-1 do
    begin
      C:=data[i];
      Rs:=Rs+red(C); Gs:=Gs+green(C); Bs:=Bs+blue(C);
    end;
    CalcAverageColor:=RGBToColor(trunc(Rs/N),trunc(Gs/N),trunc(Bs/N));
  end else CalcAverageColor:=0;
end;

//копирование из img_src в img_dst с масштабированием
procedure TIMG.ScaleToIMG(img_dst:TImg);
var x_src,y_src,x_dst,y_dst:integer; C:Int32;
    kx,ky:real;
begin
  kx:=width/img_dst.width;
  ky:=height/img_dst.height;
  for y_dst:=0 to img_dst.height-1 do
  begin
    y_src:=trunc(y_dst*ky);
    if y_src<height then
    for x_dst:=0 to img_dst.width-1 do
    begin
      x_src:=trunc(x_dst*kx);
      if x_src<width then
      begin
        C:=GetPixel(x_src,y_src);
        img_dst.SetPixel(x_dst,y_dst,C);
      end;
    end;
  end;
end;

//копирование в img_dst с поворотом
procedure TIMG.RotateToImg(src_x0,src_y0,dst_x0,dst_y0:integer; alpha:real; dst_img:TImg);
var x_dst,y_dst,x_src,y_src:integer;
begin
  for y_dst:=0 to dst_img.height-1 do
  for x_dst:=0 to dst_img.width-1 do
  begin
    x_src:=src_x0+trunc((x_dst-dst_x0)*cos(alpha)-(y_dst-dst_y0)*sin(alpha));
    y_src:=src_y0+trunc((x_dst-dst_x0)*sin(alpha)+(y_dst-dst_y0)*cos(alpha));
    if (x_src>=0)and(y_src>=0)and(x_src<width)and(y_src<height) then
        dst_img.SetPixel(x_dst,y_dst,GetPixel(x_src,y_src));
  end;
end;

//матричная фильтрация
procedure TIMG.MatrixFilter(img_dst:TImg; k11,k12,k13,k21,k22,k23,k31,k32,k33:real);
var x,y:integer;
    C11,C12,C13,C21,C22,C23,C31,C32,C33: Int32;
    R11,R12,R13,R21,R22,R23,R31,R32,R33: integer;
    G11,G12,G13,G21,G22,G23,G31,G32,G33: integer;
    B11,B12,B13,B21,B22,B23,B31,B32,B33: integer;
    R,G,B:integer; C:Int32;
begin
  for y:=1 to height-2 do
  for x:=1 to width-2 do
  begin
     C11:=GetPixel(x-1,y-1);
     C12:=GetPixel(x,y-1);
     C13:=GetPixel(x+1,y-1);
     C21:=GetPixel(x-1,y);
     C22:=GetPixel(x,y);
     C23:=GetPixel(x+1,y);
     C31:=GetPixel(x-1,y+1);
     C32:=GetPixel(x,y+1);
     C33:=GetPixel(x+1,y+1);

     R11:=red(C11); G11:=green(C11); B11:=blue(C11);
     R12:=red(C12); G12:=green(C12); B12:=blue(C12);
     R13:=red(C13); G13:=green(C13); B13:=blue(C13);
     R21:=red(C21); G21:=green(C21); B21:=blue(C21);
     R22:=red(C22); G22:=green(C22); B22:=blue(C22);
     R23:=red(C23); G23:=green(C23); B23:=blue(C23);
     R31:=red(C31); G31:=green(C31); B31:=blue(C31);
     R32:=red(C32); G32:=green(C32); B32:=blue(C32);
     R33:=red(C33); G33:=green(C33); B33:=blue(C33);

     B:=trunc(B11*k11+B12*k12+B13*k13+B21*k21+B22*k22+B23*k23+B31*k31+B32*k32+B33*k33);
     if B<0 then B:=0; if B>255 then B:=255;
     G:=trunc(G11*k11+G12*k12+G13*k13+G21*k21+G22*k22+G23*k23+G31*k31+G32*k32+G33*k33);
     if G<0 then G:=0; if G>255 then G:=255;
     R:=trunc(R11*k11+R12*k12+R13*k13+R21*k21+R22*k22+R23*k23+R31*k31+R32*k32+R33*k33);
     if R<0 then R:=0; if R>255 then R:=255;
     C:=RGBToCOlor(R,G,B);
     img_dst.SetPixel(x,y,C);
  end;
  for x:=0 to width-1 do
  begin
     C:=GetPixel(x,0); img_dst.SetPixel(x,0,C);
     C:=GetPixel(x,height-1); img_dst.SetPixel(x,height-1,C);
  end;
  for y:=0 to height-1 do
  begin
     C:=GetPixel(0,y); img_dst.SetPixel(0,y,C);
     C:=GetPixel(width-1,y); img_dst.SetPixel(width-1,y,C);
  end;
end;

//рисование эллипса на img
procedure TIMG.Ellipse(x0,y0,xr,yr:integer; C:Int32);
var tt,xx,yy:integer; t:real;
begin
  for tt:=0 to 628 do
  begin
     t:=tt/100;
     xx:=trunc(x0+xr*cos(t));
     yy:=trunc(y0+yr*sin(t));
     SetPixel(xx,yy,C);
  end;
end;

//рисование отрезка на img
procedure TIMG.Line(x1,y1,x2,y2:integer; C:Int32);
var xx,xnum:integer; x,y,k,bb,dx:real;
begin
  if y1=y2 then HorLine(x1,x2,y1,C)
  else if x1=x2 then VerLine(x1,y1,y2,C)
  else
  begin
    k:=(y2-y1)/(x2-x1);
    bb:=y1-k*x1;
    dx:=(x2-x1)/1000;
    xnum:=trunc(abs(k));
    for xx:=0 to 1000 do
    begin
       x:=x1+xx*dx;
       y:=k*x+bb;
       SetPixel(trunc(x),trunc(y),C);
    end;
  end;
end;

//заполнение замкнутой области выбранным цветом ("хороший способ")
procedure TIMG.FloodFill(x0,y0:integer; c_old,c_new:Int32);
var c:Int32; x,xmin,xmax:integer;
begin
  if (x0>=0)and(x0<width)and(y0>=0)and(y0<height) then
  begin
    c:=GetPixel(x0,y0);
    if (c>=0)and(c<>c_new)and(c=c_old) then
    begin
      xmin:=x0;
      repeat
        c:=GetPixel(xmin,y0);
        xmin:=xmin-1;
      until (c<0)or(c=c_new)or(c<>c_old)or(xmin<0);
      xmin:=xmin+1;
      xmax:=x0;
      repeat
        c:=GetPixel(xmax,y0);
        xmax:=xmax+1;
      until (c<0)or(c=c_new)or(c<>c_old)or(xmax>=width);
      xmax:=xmax-1;
      HorLine(xmin,xmax,y0,c_new);
      for x:=xmin to xmax do FloodFill(x,y0-1,c_old,c_new);
      for x:=xmin to xmax do FloodFill(x,y0+1,c_old,c_new);
    end;
  end;
end;


//заполнение замкнутой области выбранным цветом (с учетом контрастности границы)
procedure TIMG.FloodFillFuzzy(x0,y0:integer; fuzzy_level:integer; c_old,c_new:Int32);
var c:Int32; x,xmin,xmax:integer;
begin
  if (x0>=0)and(x0<width)and(y0>=0)and(y0<height) then
  begin
    c:=GetPixel(x0,y0);
    if (c>=0)and(c<>c_new)and
       (abs((red(c)+green(c)+blue(c))/3-(red(c_old)+green(c_old)+blue(c_old))/3)<=fuzzy_level)
       then
    begin
      xmin:=x0;
      repeat
        c:=GetPixel(xmin,y0);
        xmin:=xmin-1;
      until (c<0)or(c=c_new)or(xmin<0)or(abs((red(c)+green(c)+blue(c))/3-(red(c_old)+green(c_old)+blue(c_old))/3)>fuzzy_level);
      xmin:=xmin+1;
      xmax:=x0;
      repeat
        c:=GetPixel(xmax,y0);
        xmax:=xmax+1;
      until (c<0)or(c=c_new)or(xmax>=width)or(abs((red(c)+green(c)+blue(c))/3-(red(c_old)+green(c_old)+blue(c_old))/3)>fuzzy_level);
      xmax:=xmax-1;
      HorLine(xmin,xmax,y0,c_new);
      for x:=xmin to xmax do FloodFillFuzzy(x,y0-1,fuzzy_level,c_old,c_new);
      for x:=xmin to xmax do FloodFillFuzzy(x,y0+1,fuzzy_level,c_old,c_new);
    end;
  end;
end;

//"черепашья" графика по командам Бейсиковского Draw
procedure TIMG.turtle(x0,y0:integer; S:string);
begin
  //заглушка
end;

//Вывод текстовой информации
//рисуем текст через инструменты Bitmap.Canvas (исправить)
procedure TIMG.TextOut(x0,y0:integer; PenColor:Int32; TextToRender:string);
var tmp_bitmap:TBitmap; tmp_img:TIMG;
begin
  tmp_bitmap:=TBitmap.Create;
  tmp_bitmap.SetSize(tmp_bitmap.Canvas.TextWidth(TextToRender),
                     tmp_bitmap.Canvas.TextHeight(TextToRender));
  tmp_bitmap.Canvas.Font.Color:=PenColor;
  tmp_bitmap.Canvas.Brush.Style:=bsClear;
  tmp_bitmap.Canvas.TextOut(0,0,TextToRender);
  tmp_img:=TIMG.Create;
  tmp_img.SetSize(tmp_bitmap.width,tmp_bitmap.height);
  tmp_IMG.CloneBitmapToImg(tmp_bitmap);
  tmp_IMG.DrawToIMG(self,x0,y0);
  tmp_bitmap.free;
  tmp_img.done;
end;

//перебрасывание изображения из TImg на внешний битмап
procedure TIMG.CloneImgToBitmap(bitmap_dst:TBitmap);
var x,y,dst_bpp:integer; src_ptr: PInt32; dst_ptr:PByte; R,G,B:byte;
begin
  if (width=bitmap_dst.width)and(height=bitmap_dst.height) then
  begin
    bitmap_dst.BeginUpdate(false);
    dst_bpp:=bitmap_dst.RawImage.Description.BitsPerPixel div 8;
    dst_ptr:=bitmap_dst.RawImage.Data;
    src_ptr:=PInt32(data);
    for y:=0 to height-1 do
    for x:=0 to width-1 do
    begin
       R:=(src_ptr^)and 255;
       G:=((src_ptr^)>>8)and 255;
       B:=((src_ptr^)>>16)and 255;
       dst_ptr^:=B; (dst_ptr+1)^:=G; (dst_ptr+2)^:=R;
      inc(dst_ptr,dst_bpp); inc(src_ptr);
    end;
    bitmap_dst.EndUpdate(false);
  end;
end;

//перебрасывание изображения из внешнего битмапа на TImg
procedure TIMG.CloneBitmapToImg(bitmap_src:TBitmap);
var x,y,src_bpp:integer; dst_ptr: PInt32; Src_ptr:PByte; R,G,B:byte;
begin
  if (width=bitmap_src.width)and(height=bitmap_src.height) then
  begin
    src_ptr:=bitmap_src.RawImage.Data;
    src_bpp:=bitmap_src.RawImage.Description.BitsPerPixel div 8;
    dst_ptr:=PInt32(data);
    for y:=0 to height-1 do
    for x:=0 to width-1 do
    begin
      R:=(src_ptr+2)^; G:=(src_ptr+1)^; B:=src_ptr^;
      dst_ptr^:=R+(G<<8)+(B<<16);
      inc(dst_ptr); inc(src_ptr,src_bpp);
    end;
  end;
end;

//загрузка изображения из файла (формат по расширению)
procedure TIMG.LoadFromFile(filename:string);
var tmp_picture: TPicture;
begin
  tmp_picture:=TPicture.Create;
  tmp_picture.LoadFromFile(filename);
  SetSize(tmp_picture.width,tmp_picture.height);
  CloneBitmapToImg(tmp_picture.Bitmap);
  tmp_picture.Free;
end;

//сохранение изображения в файл (формат по расширению)
procedure TIMG.SaveToFile(filename:string);
var tmp_picture:TPicture;
begin
  tmp_picture:=TPicture.Create;
  tmp_picture.bitmap.setsize(Width,Height);
  CloneImgToBitmap(tmp_picture.Bitmap);
  tmp_picture.SaveToFile(filename);
  tmp_picture.free;
end;

//загрузка изображения из буфера обмена
procedure TIMG.CopyFromClipboard;
var tmp_bitmap:TBitmap; tmp_x0,tmp_y0:integer;
begin
  tmp_bitmap:=TBitmap.Create;
  if Clipboard.HasFormat(PredefinedClipboardFormat(pcfDelphiBitmap)) then
     tmp_bitmap.LoadFromClipboardFormat(PredefinedClipboardFormat(pcfDelphiBitmap));
  if Clipboard.HasFormat(PredefinedClipboardFormat(pcfBitmap)) then
     tmp_bitmap.LoadFromClipboardFormat(PredefinedClipboardFormat(pcfBitmap));
  tmp_x0:=parent_x0; tmp_y0:=parent_y0;
  SetSize(tmp_bitmap.width,tmp_bitmap.height);
  parent_x0:=tmp_x0; parent_y0:=tmp_y0;
  CloneBitmapToImg(tmp_bitmap);
  tmp_bitmap.free;
end;

//сохранение изображения в буфер обмена
procedure TIMG.CopyToClipboard;
var tmp_bitmap:TBitmap;
begin
  tmp_bitmap:=TBitmap.Create;
  tmp_bitmap.SetSize(width,height);
  CloneImgToBitmap(tmp_bitmap);
  Clipboard.assign(tmp_bitmap);
  tmp_bitmap.free;
end;

//нахождение комплексных коэффициентов Фурье
procedure TIMG.ImgToDFT;
var x,y:integer;
begin
  for y:=0 to height-1 do
    for x:=0 to width-1 do
    begin
      red_DFT_t[y,x].re:=red(GetPixel(x,y));
      red_DFT_t[y,x].im:=0;
    end;
  DFT_analys_2D(red_DFT_t,red_DFT_f);

  for y:=0 to height-1 do
    for x:=0 to width-1 do
    begin
      green_DFT_t[y,x].re:=green(GetPixel(x,y));
      green_DFT_t[y,x].im:=0;
    end;
  DFT_analys_2D(green_DFT_t,green_DFT_f);

  for y:=0 to height-1 do
    for x:=0 to width-1 do
    begin
      blue_DFT_t[y,x].re:=blue(GetPixel(x,y));
      blue_DFT_t[y,x].im:=0;
    end;
  DFT_analys_2D(blue_DFT_t,blue_DFT_f);
end;

//восстановление изображения по его коэффициентам Фурье
procedure TIMG.ImgFromDFT;
var x,y,r,g,b:integer;
begin
  if height>0 then
  begin
    clrscr(0);
    DFT_syntez_2D(width,height,red_DFT_f,red_DFT_t);
    DFT_syntez_2D(width,height,green_DFT_f,green_DFT_t);
    DFT_syntez_2D(width,height,blue_DFT_f,blue_DFT_t);

    for y:=0 to height-1 do
      for x:=0 to width-1 do
      begin
        r:=trunc(red_DFT_t[y,x].re);
        if r<0 then r:=0;
        if r>255 then r:=255;
        g:=trunc(green_DFT_t[y,x].re);
        if g<0 then g:=0;
        if g>255 then g:=255;
        b:=trunc(blue_DFT_t[y,x].re);
        if b<0 then b:=0;
        if b>255 then b:=255;
        SetPixel(x,y,RGBtoColor(r,g,b));
      end;
  end;
end;

//очистка содержимого массивов коэффициентов Фурье
procedure TIMG.clrDFT(c:TComplex);
var x,y:integer;
begin
  for y:=0 to DFT_height-1 do
    for x:=0 to DFT_width-1 do
      red_DFT_f[y,x]:=c;

  for y:=0 to DFT_height-1 do
    for x:=0 to DFT_width-1 do
      green_DFT_f[y,x]:=c;

  for y:=0 to DFT_height-1 do
    for x:=0 to DFT_width-1 do
      blue_DFT_f[y,x]:=c;
end;

//быстрое копирование Фурье-коэффициентов из img_src в img_dst (DFT-матрицы одинаковые)
procedure TIMG.CloneToDFT(img_dst:TImg);
var x,y:integer;
begin
  if (DFT_width=img_dst.DFT_width)and(DFT_height=img_dst.DFT_height) then
  begin
    for y:=0 to DFT_height-1 do
      for x:=0 to DFT_width-1 do
      begin
        img_dst.red_DFT_f[y,x]:=red_DFT_f[y,x];
        img_dst.green_DFT_f[y,x]:=green_DFT_f[y,x];
        img_dst.blue_DFT_f[y,x]:=blue_DFT_f[y,x];
      end;
  end;
end;

//=====================================================================
//конец низкоуровневых функций прямого рисования в видеопамяти битмапа
//=====================================================================

end.

