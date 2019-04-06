//Copyright 2015 Andrey S. Ionisyan
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
//глобальные переменные, такие как сводный холст, слои, мышиные координаты и т.д.
//=====================================================================
unit globals_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, Graphics, img_unit;

var
SummaryIMG: TImg; //буфер слияния всех слоев в одно изображение
Layers: array of TImg; //слои (холсты) рисования

PepperSaltFlag: boolean; //флаг включения и отключения зашумления
PepperSaltPercent: integer; //проценты зашумления солью и перцем
MedianRadius: integer; //радиус фильтрации медианного фильтра
MedianFilterFlag: boolean; //флаг включения и отключения медианного фильтра
AdaptiveMedianFilterFlag: boolean; //флаг включения и отключения адаптивного медианного фильтра

img_orig_PSNR:TIMG; img_new_PSNR:TIMG; //вспомогательные холсты определения PSNR
CameraBitmap: TBitmap; //полотно для получения данных от VLC
Camera_Flag: boolean; //индикатор видеозахвата
implementation

end.

