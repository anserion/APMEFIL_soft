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
//функции расчета компонент цвета в разных цветовых моделях
//=====================================================================
unit colors_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, utils_unit;

type
  TFullColor=record
    red,green,blue:real;
    hue,saturation,value,lightness:real;
    cyan,magenta,yellow,black:real;
    Y,Cr,Cb,U,V: real;
    XX,YY,ZZ:real;
  end;

//расчет цветовых моделей HSV,HSL,CMYK,YUV,YCrCb,XYZ по известным RGB
function ConvertRGBToFull(red,green,blue:real):TFullColor;

implementation

//расчет цветовых моделей HSV,HSL,CMYK,YUV,YCrCb,XYZ по известным RGB
function ConvertRGBToFull(red,green,blue:real):TFullColor;
var C:TFullColor; max,min:real;
begin
  C.red:=red; C.green:=green; C.blue:=blue;
  max:=C.red; if max<C.green then max:=C.green; if max<C.blue then max:=C.blue;
  min:=C.red; if min>C.green then min:=C.green; if min>C.blue then min:=C.blue;

  if max=min then C.hue:=0 else
  begin
    if (max=C.red) and (C.green>=C.blue) then C.hue:=60*(C.green-C.blue)/(max-min);
    if (max=C.red) and (C.green<C.blue) then C.hue:=60*(C.green-C.blue)/(max-min)+360;
    if max=C.green then C.hue:=60*(C.blue-C.red)/(max-min)+120;
    if max=C.blue then C.hue:=60*(C.red-C.green)/(max-min)+240;
  end;
  if max=0 then C.saturation:=0 else C.saturation:=1-min/max;
  C.value:=max;
  C.lightness:=0.5*(max+min);

  C.Y:=0.299*C.red+0.587*C.green+0.114*C.blue;
  C.U:=-0.14713*C.red-0.28886*C.green+0.436*C.blue; //+128
  C.V:=0.615*C.red-0.51499*C.green-0.10001*C.blue;  //+128
  C.Cb:=C.U; C.Cr:=C.V;

  C.XX:=0.49*C.red+0.31*C.green+0.1999646*C.blue;
  C.YY:=0.17695983*C.red+0.81242258*C.green+0.0106175*C.blue;
  C.ZZ:=0*C.red+0.01008*C.green+0.989913*C.blue;

  C.black:=1-C.red;
  if C.black>1-C.green then C.black:=1-C.green;
  if C.black>1-C.blue then C.black:=1-C.blue;
  if C.black=1 then begin C.cyan:=0; C.magenta:=0; C.yellow:=0; end
  else
    begin
       C.cyan:=(1-C.red-C.black)/(1-C.black);
       C.magenta:=(1-C.green-C.black)/(1-C.black);
       C.yellow:=(1-C.blue-C.black)/(1-C.black);
    end;

  ConvertRGBToFull:=C;
end;

end.

