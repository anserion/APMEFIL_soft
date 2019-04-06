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
//несколько полезных функций, забытых разработчиками FreePascal
//swap(a,b) - обмен переменных, min(a,b), max(a,b) - максимум и минимум
//quick_sort(A,left,right) - быстрая сортировка подмассива
//array_sort(A) - сортировка массива (в основе быстрая сортировка)
//lg(x) - логарифм по основанию 10
//=====================================================================
unit utils_unit;

{$mode objfpc}{$H+}

interface
uses classes;
type TBrez=array[0..4096,1..2] of integer;

function lg(x:real):real; //логарифм по основанию 10

procedure swap(var a,b:integer); //обмен содержимого двух ячеек памяти
procedure swap(var a,b:real); //обмен содержимого двух ячеек памяти
procedure swap(var a,b:TPoint); //обмен содержимого двух ячеек памяти

function min(a,b:integer):integer; //выбор минимального из двух значений
function min(a,b:real):real; //выбор минимального из двух значений

function max(a,b:integer):integer; //выбор максимального из двух значений
function max(a,b:real):real;

procedure quick_sort(var A:array of integer; L,R:integer); //быстрая сортировка
procedure quick_sort(var A:array of real; L,R:integer); //быстрая сортировка
procedure array_sort(var A:array of integer); //сортировка массива
procedure array_sort(var A:array of real); //сортировка массива

//проверка и в случае необходимости корректировка параметров
//рабочего прямоугольника для, например, битмапа rect(0,0,width-1,height-1)
procedure CorrectRectParams(width,height:integer; var left,top,right,bottom:integer);

//проверка нахождения точки внутри (включая границы) прямоугольника
function PlotInRect(x,y:integer; xmin,ymin,xmax,ymax:integer):boolean;

//алгоритм Брезенхема расчета координат точек окружности
function BrezCircle(xc,yc,r:integer; var Brez:TBrez):integer;

//алгоритм Брезенхема расчета координат точек отрезка
function BrezLine(x1,y1,x2,y2:integer; var Brez:TBrez):integer;

implementation

//логарифм по основанию 10
function lg(x:real):real;
begin
  lg:=ln(x)/ln(10);
end;

//обмен содержимого двух ячеек памяти
procedure swap(var a,b:integer);
var tmp:integer; begin tmp:=a; a:=b; b:=tmp; end;

procedure swap(var a,b:real);
var tmp:real; begin tmp:=a; a:=b; b:=tmp; end;

procedure swap(var a,b:TPoint);
var tmp:TPoint; begin tmp:=a; a:=b; b:=tmp; end;

//выбор минимального из двух значений
function min(a,b:integer):integer;
begin if a<b then min:=a else min:=b; end;

function min(a,b:real):real;
begin if a<b then min:=a else min:=b; end;

//выбор максимального из двух значений
function max(a,b:integer):integer;
begin if a>b then max:=a else max:=b; end;

function max(a,b:real):real;
begin if a>b then max:=a else max:=b; end;

//быстрая сортировка подмассива
procedure quick_sort(var A:array of integer; L,R:integer);
var i,j,x:integer;
begin
  i:=L; j:=R; x:=A[(i+j)div 2];
  while i<j do
  begin
    while A[j]>x do j:=j-1;
    while A[i]<x do i:=i+1;
    if i<=j then begin swap(A[i],A[j]); j:=j-1; i:=i+1; end;
  end;
  if L<j then quick_sort(A,L,j);
  if R>i then quick_sort(A,i,R);
end;

procedure quick_sort(var A:array of real; L,R:integer);
var i,j:integer; x:real;
begin
  i:=L; j:=R; x:=A[(i+j)div 2];
  while i<j do
  begin
    while A[j]>x do j:=j-1;
    while A[i]<x do i:=i+1;
    if i<=j then begin swap(A[i],A[j]); j:=j-1; i:=i+1; end;
  end;
  if L<j then quick_sort(A,L,j);
  if R>i then quick_sort(A,i,R);
end;

//сортировка массива
procedure array_sort(var A:array of integer);
var n:integer;
begin
  N:=length(A);
  quick_sort(A,0,N-1);
end;

procedure array_sort(var A:array of real);
var n:integer;
begin
  N:=length(A);
  quick_sort(A,0,N-1);
end;

//проверка и в случае необходимости корректировка параметров
//рабочего прямоугольника для, например, битмапа rect(0,0,width-1,height-1)
procedure CorrectRectParams(width,height:integer; var left,top,right,bottom:integer);
begin
  if Left<0 then left:=0;
  if Left>=width then left:=width-1;
  if Right<0 then Right:=0;
  if Right>=width then Right:=width-1;
  if top<0 then top:=0;
  if top>=height then top:=height-1;
  if Bottom<0 then Bottom:=0;
  if Bottom>=height then Bottom:=height-1;

  if Left>Right then swap(Left,Right);
  if Top>Bottom then swap(Top,Bottom);
end;

//проверка нахождения точки внутри (включая границы) прямоугольника
function PlotInRect(x,y:integer; xmin,ymin,xmax,ymax:integer):boolean;
begin PlotInRect:=(x>=xmin)and(x<=xmax)and(y>=ymin)and(y<=ymax); end;

//алгоритм Брезенхема расчета координат точек окружности
function BrezCircle(xc,yc,r:integer; var Brez:TBrez):integer;
var xf,yf,PixelsNum,x1,y1,x2,y2,d1,d2,dx,dy,i:integer;
begin
  i:=1; Brez[i,1]:=xc-r; Brez[i,2]:=yc;
  inc(i); Brez[i,1]:=xc+r; Brez[i,2]:=yc;
  inc(i); Brez[i,1]:=xc; Brez[i,2]:=yc-r;
  inc(i); Brez[i,1]:=xc; Brez[i,2]:=yc+r;
  xf:=xc+r;
  yf:=yc;
  for PixelsNum:=0 to ((3*r) div 4) do
  begin
      x1:=xf-1; x2:=xf;
      y1:=yf-1; y2:=yf-1;

      d1:=(xc-x1)*(xc-x1)+(yc-y1)*(yc-y1)-r*r;
      d2:=(xc-x2)*(xc-x2)+(yc-y2)*(yc-y2)-r*r;

      if (d1<0) then d1:=-d1;
      if (d2<0) then d2:=-d2;

      if (d1<d2) then begin xf:=x1; yf:=y1; end else begin xf:=x2; yf:=y2; end;
      dx:=xf-xc; dy:=yf-yc;

      inc(i); Brez[i,1]:=xc+dx; Brez[i,2]:=yc+dy;
      inc(i); Brez[i,1]:=xc-dx; Brez[i,2]:=yc+dy;
      inc(i); Brez[i,1]:=xc+dx; Brez[i,2]:=yc-dy;
      inc(i); Brez[i,1]:=xc-dx; Brez[i,2]:=yc-dy;
      inc(i); Brez[i,1]:=xc+dy; Brez[i,2]:=yc+dx;
      inc(i); Brez[i,1]:=xc-dy; Brez[i,2]:=yc+dx;
      inc(i); Brez[i,1]:=xc+dy; Brez[i,2]:=yc-dx;
      inc(i); Brez[i,1]:=xc-dy; Brez[i,2]:=yc-dx;
  end;
  BrezCircle:=i;
end;

//алгоритм Брезенхема расчета координат точек отрезка
function BrezLine(x1,y1,x2,y2:integer; var Brez:TBrez):integer;
var dx,dy,ix,iy,x,y,i,j,PlotX,PlotY,Hinc:integer;
    Plot:Boolean;
begin
     dx:=x2-x1; dy:=y2-y1;
     ix:=abs(dx); iy:=abs(dy);
     if ix>iy then Hinc:=ix else Hinc:=iy;
     PlotX:=x1; Ploty:=y1; x:=0; y:=0;
     i:=1; Brez[i,1]:=PlotX; Brez[i,2]:=PlotY;
     for j:=0 to Hinc do
         begin
              x:=x+ix; y:=y+iy; Plot:=false;
              if x>Hinc then
                 begin
                      Plot:=true; x:=x-Hinc;
                      if dx>0 then inc(PlotX);
                      if dx<0 then dec(PlotX);
                 end;
              if y>Hinc then
                 begin
                      Plot:=true; y:=y-Hinc;
                      if dy>0 then inc(PlotY);
                      if dy<0 then dec(PlotY);
                 end;
              if Plot then
                 begin
                      inc(i); Brez[i,1]:=PlotX; Brez[i,2]:=PlotY;
                 end;
         end;
     BrezLine:=i;
end;

end.

