//Copyright 2018 Andrey S. Ionisyan (anserion@gmail.com)
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

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  //Windows,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, StdCtrls, ExtDlgs, FPCanvas, LCLintf, LCLType,
  globals_unit, img_unit, arith_complex, filters_unit, lclvlc, libvlc, vlc;

type
  { TForm1 }

  TForm1 = class(TForm)
    ButtonPepperSalt: TButton;
    ButtonAdaptiveMedian: TButton;
    ButtonRestore: TButton;
    ButtonMedian: TButton;
    CheckBox_timer: TCheckBox;
    EditPepperSalt: TEdit;
    EditMedian: TEdit;
    EditTimer: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    LabelPSNR_filter: TLabel;
    LabelPSNR_blue_filter: TLabel;
    LabelPSNR_green_filter: TLabel;
    LabelPSNR_red_noise: TLabel;
    LabelPSNR_green_noise: TLabel;
    LabelPSNR_blue_noise: TLabel;
    LabelPSNR_noise: TLabel;
    LabelPSNR_red_filter: TLabel;
    MenuItemPictureOpen: TMenuItem;
    MenuItemCameraOpen: TMenuItem;
    ImageView: TPaintBox;
    CameraPanel: TPanel;
    PanelColor: TPanel;
    MainMenu: TMainMenu;
    MenuItemFile: TMenuItem;
    MenuItemHelpUser: TMenuItem;
    MenuItemHelpProgrammer: TMenuItem;
    MenuItemHelpAbout: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemHelp: TMenuItem;
    MenuItemHelpTeacher: TMenuItem;
    MenuItemVideoOpen: TMenuItem;
    OpenPictureDialog: TOpenPictureDialog;
    PanelStatus: TPanel;
    Timer1: TTimer;
    procedure ButtonAdaptiveMedianClick(Sender: TObject);
    procedure ButtonMedianClick(Sender: TObject);
    procedure ButtonPepperSaltClick(Sender: TObject);
    procedure ButtonRestoreClick(Sender: TObject);
    procedure CameraPanelPaint(Sender: TObject);
    procedure CheckBox_timerClick(Sender: TObject);
    procedure EditMedianChange(Sender: TObject);
    procedure EditPepperSaltChange(Sender: TObject);
    procedure EditTimerChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ImageViewPaint(Sender: TObject);
    procedure MenuItemCameraOpenClick(Sender: TObject);
    procedure MenuItemHelpProgrammerClick(Sender: TObject);
    procedure MenuItemHelpTeacherClick(Sender: TObject);
    procedure MenuItemHelpUserClick(Sender: TObject);
    procedure MenuItemHelpAboutClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemPictureOpenClick(Sender: TObject);
    procedure MenuItemVideoOpenClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    SummaryBitmap:TBitmap; //битмап рисования сводного изображения на PaintBox
    OriginalBitmap:TBitmap;
    procedure RefreshStatusBar; //обновить панель состояния программы
    procedure RefreshImageView; //быстрая перерисовка рабочей области программы
    procedure ComposeSummaryIMG; //вывести все слои в область вывода, с доп. информацией
  end;

var
  Form1: TForm1;
  VLC_Player: TLCLVLCPlayer;

implementation

{$R *.lfm}

{ TForm1 }


//быстрая перерисовка рабочей области программы
procedure TForm1.RefreshImageView;
begin
  ImageView.Canvas.Brush.Style:=bsSolid;
  ImageView.Canvas.Brush.Color:=clGray;
  ImageView.Canvas.FillRect(0,0,ImageView.width,SummaryIMG.parent_y0);
  ImageView.Canvas.FillRect(0,SummaryIMG.parent_y0+SummaryIMG.height,ImageView.width,ImageView.height);
  ImageView.Canvas.FillRect(0,SummaryIMG.parent_y0,SummaryIMG.parent_x0,SummaryIMG.parent_y0+SummaryIMG.height);
  ImageView.Canvas.FillRect(SummaryIMG.parent_x0+SummaryIMG.width,SummaryIMG.parent_y0,ImageView.Width,SummaryIMG.parent_y0+SummaryIMG.height);
  ImageView.Canvas.Draw(SummaryIMG.parent_x0,SummaryIMG.parent_y0,SummaryBitmap);
end;

//вывести все слои в область вывода, с доп. информацией
//например, обозначить область выделения
procedure TForm1.ComposeSummaryIMG;
begin
  if PepperSaltFlag then
     Layers[1].CopyRect(SummaryIMG,
       rect(0,0,(Layers[1].width div 2)-1,Layers[1].height-1),
       rect(0,0,(SummaryIMG.width div 2)-1,SummaryIMG.height-1))
  else
     Layers[0].CopyRect(SummaryIMG,
       rect(0,0,(Layers[0].width div 2)-1,Layers[0].height-1),
       rect(0,0,(SummaryIMG.width div 2)-1,SummaryIMG.height-1));

  if MedianFilterFlag or AdaptiveMedianFilterFlag then
     Layers[2].CopyRect(SummaryIMG,
       rect(0,0,Layers[2].width-1,Layers[2].height-1),
       rect((SummaryIMG.width div 2)-1,0,SummaryIMG.width-1,SummaryIMG.height-1))
  else
     Layers[1].CopyRect(SummaryIMG,
       rect((Layers[1].width div 2)-1,0,Layers[1].width-1,Layers[0].height-1),
       rect((SummaryIMG.width div 2)-1,0,SummaryIMG.width-1,SummaryIMG.height-1));

  SummaryIMG.CloneImgToBitmap(SummaryBitmap);
  RefreshImageView;
end;

//обновление содержимого полей панели статуса (перерасчет соотношения сигнал/шум)
procedure TForm1.RefreshStatusBar;
var PSNR_r,PSNR_g,PSNR_b:real; s_r,s_g,s_b:string;
begin
  PSNR_r:=-1; PSNR_g:=-1; PSNR_b:=-1;
  if PepperSaltFlag then
  begin
   Layers[0].CopyRect(img_orig_PSNR,
     rect(0,0,(Layers[0].width div 2)-1,Layers[0].height-1),
     rect(0,0,img_orig_PSNR.width-1,img_orig_PSNR.height-1));

   Layers[1].CopyRect(img_new_PSNR,
     rect(0,0,(Layers[1].width div 2)-1,Layers[1].height-1),
     rect(0,0,img_new_PSNR.width-1,img_new_PSNR.height-1));

   FilterPSNR(img_orig_PSNR,img_new_PSNR,PSNR_r,PSNR_g,PSNR_b);
  end;

  s_r:='infinity'; s_g:='infinity'; s_b:='infinity';
  if PSNR_r<>-1 then s_r:=FloatToStr(trunc(PSNR_r*10)/10);
  if PSNR_g<>-1 then s_g:=FloatToStr(trunc(PSNR_g*10)/10);
  if PSNR_b<>-1 then s_b:=FloatToStr(trunc(PSNR_b*10)/10);
  LabelPSNR_red_noise.caption:='R канал: '+s_r+' Дб';
  LabelPSNR_green_noise.caption:='G канал: '+s_g+' Дб';
  LabelPSNR_blue_noise.caption:='B канал: '+s_b+' Дб';

  PSNR_r:=-1; PSNR_g:=-1; PSNR_b:=-1;
  if MedianFilterFlag or AdaptiveMedianFilterFlag then
  begin
    Layers[0].CopyRect(img_orig_PSNR,
      rect((Layers[0].width div 2)-1,0,Layers[0].width-1,Layers[0].height-1),
      rect(0,0,img_orig_PSNR.width-1,img_orig_PSNR.height-1));

    Layers[2].CopyRect(img_new_PSNR,
      rect(0,0,Layers[2].width-1,Layers[2].height-1),
      rect(0,0,img_new_PSNR.width-1,img_new_PSNR.height-1));

    FilterPSNR(img_orig_PSNR,img_new_PSNR,PSNR_r,PSNR_g,PSNR_b);
  end;

  s_r:='infinity'; s_g:='infinity'; s_b:='infinity';
  if PSNR_r<>-1 then s_r:=FloatToStr(trunc(PSNR_r*10)/10);
  if PSNR_g<>-1 then s_g:=FloatToStr(trunc(PSNR_g*10)/10);
  if PSNR_b<>-1 then s_b:=FloatToStr(trunc(PSNR_b*10)/10);
  LabelPSNR_red_filter.caption:='R канал: '+s_r+' Дб';
  LabelPSNR_green_filter.caption:='G канал: '+s_g+' Дб';
  LabelPSNR_blue_filter.caption:='B канал: '+s_b+' Дб';
end;

//иницализация программы
procedure TForm1.FormCreate(Sender: TObject);
var i:integer; tmp_IMG:TIMG;
begin
  //инфраструктура камеры видеозахвата VLC
  CameraPanel.left:=PanelColor.Width+5;
  CameraPanel.width:=512;
  CameraPanel.height:=512;
  CameraBitmap:=TBitmap.Create;
  CameraBitmap.SetSize(CameraPanel.width,CameraPanel.height);
  Camera_Flag:=false;
  VLC_player:=TLCLVLCPlayer.Create(self);
  VLC_player.ParentWindow:=CameraPanel;
  //VLC_player.FitWindow:=true;

  //отключаем зашумление
  PepperSaltFlag:=false;
  //настраиваем медианный фильтр
  MedianRadius:=StrToInt(EditMedian.text);
  //отключаем медианный фильтр
  MedianFilterFlag:=false;
  //отключаем адаптивный медианный фильтр
  AdaptiveMedianFilterFlag:=false;
  //создаем холст сводного изображения
  SummaryIMG:=TImg.Create;
  SummaryIMG.SetSize(CameraPanel.width,CameraPanel.height);
  SummaryIMG.parent_x0:=CameraPanel.width+10;
  SummaryIMG.parent_y0:=CameraPanel.top;
  //создаем холсты определения соотношения сигнал/шум
  img_orig_PSNR:=TImg.Create;
  img_orig_PSNR.SetSize(SummaryIMG.width div 2,SummaryIMG.height);

  img_new_PSNR:=TImg.Create;
  img_new_PSNR.SetSize(SummaryIMG.width div 2,SummaryIMG.height);

  //создаем слои рисования и сразу их очищаем
  //слой 0 - исходное изображение
  //слой 1 - зашумленное изображение
  //слой 2 - отфильтрованное изображение
  SetLength(Layers,3);
  for i:=0 to length(Layers)-1 do Layers[i]:=TImg.Create;
  Layers[0].SetSize(SummaryIMG.Width,SummaryIMG.Height);
  Layers[0].parent_x0:=0; Layers[0].parent_y0:=0;
  Layers[1].SetSize(SummaryIMG.Width,SummaryIMG.Height);
  Layers[1].parent_x0:=0; Layers[1].parent_y0:=0;
  Layers[2].SetSize(SummaryIMG.Width div 2,SummaryIMG.Height);
  Layers[2].parent_x0:=SummaryIMG.Width div 2; Layers[2].parent_y0:=0;
  for i:=0 to length(Layers)-1 do Layers[i].clrscr(0);

  //Создаем пустой рабочий битмап как передаточный узел между TIMG и TCanvas
  SummaryBitmap:=TBitmap.Create;
  SummaryBitmap.SetSize(SummaryIMG.width,SummaryIMG.height);
  OriginalBitmap:=TBitmap.Create;
  OriginalBitmap.SetSize(Layers[0].width,Layers[0].height);

  //Загружем и прорисовываем первое изображение
  tmp_IMG:=TIMG.Create;
  tmp_IMG.LoadFromFile('cat.jpg');
  tmp_IMG.ScaleToImg(Layers[0]);
  tmp_IMG.done;
  Layers[1].DrawFromImg(Layers[0],0,0);
  Layers[0].CopyRect(Layers[2],
     rect((Layers[0].width div 2)-1,0,Layers[0].width-1,Layers[0].height-1),
     rect(0,0,Layers[2].width-1,Layers[2].height-1));

  ComposeSummaryIMG;
  //обновляем содержимое панели статуса
  RefreshStatusBar;
  //если взведен флажок таймера, то включаем таймер
  timer1.enabled:=CheckBox_timer.Checked;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var i:integer;
begin
  //корректно высвобождаем занятую память
  Timer1.Enabled:=false;
  Camera_Flag:=false;
  VLC_player.Stop;
  VLC_player.free;
  CameraBitmap.Free;
  img_orig_PSNR.done;
  img_new_PSNR.done;
  SummaryIMG.done;
  for i:=0 to length(Layers)-1 do Layers[i].done; SetLength(Layers,0);
  SummaryBitmap.free;
  OriginalBitmap.Free;
end;

//включение и отключение адаптивного медианного фильтра
procedure TForm1.ButtonAdaptiveMedianClick(Sender: TObject);
begin
  if AdaptiveMedianFilterFlag then
  begin
     AdaptiveMedianFilterFlag:=false;
     ButtonAdaptiveMedian.Caption:='вкл. адаптивный';
  end
     else
  begin
     MedianFilterFlag:=false;
     ButtonMedian.Caption:='вкл. медианный';
     AdaptiveMedianFilterFlag:=true;
     ButtonAdaptiveMedian.Caption:='откл. адаптивный';
  end;
end;

//включение и отключение медианного фильтра
procedure TForm1.ButtonMedianClick(Sender: TObject);
begin
  if MedianFilterFlag then
  begin
     MedianFilterFlag:=false;
     ButtonMedian.Caption:='вкл. медианный';
  end
     else
  begin
     AdaptiveMedianFilterFlag:=false;
     ButtonAdaptiveMedian.Caption:='вкл. адаптивный';
     MedianFilterFlag:=true;
     ButtonMedian.Caption:='откл. медианный';
  end;
end;

//включение и отключение зашумления
procedure TForm1.ButtonPepperSaltClick(Sender: TObject);
begin
   Timer1.Interval:=StrToInt(EditTimer.text);
   if PepperSaltFlag then
   begin
      PepperSaltFlag:=false;
      ButtonPepperSalt.Caption:='вкл. шум';
      Layers[1].DrawFromImg(Layers[0],0,0);
   end
      else
   begin
      PepperSaltFlag:=true;
      ButtonPepperSalt.Caption:='откл. шум';
   end;
end;

//восстановить изображение полностью
procedure TForm1.ButtonRestoreClick(Sender: TObject);
begin
  Layers[1].DrawFromImg(Layers[0],0,0); Layers[2].DrawFromImg(Layers[0],0,0);
  Layers[0].CopyRect(Layers[2],
     rect((Layers[0].width div 2)-1,0,Layers[0].width-1,Layers[0].height-1),
     rect(0,0,Layers[2].width-1,Layers[2].height-1));

  AdaptiveMedianFilterFlag:=false; ButtonAdaptiveMedian.caption:='вкл. адаптивный';
  MedianFilterFlag:=false; ButtonMedian.caption:='вкл. медианный';
  PepperSaltFlag:=false; ButtonPepperSalt.caption:='вкл. шум';
  Timer1.enabled:=false; CheckBox_timer.Checked:=false;
  Camera_Flag:=false; VLC_Player.Stop;
  ComposeSummaryIMG;
  RefreshStatusBar;
end;

procedure TForm1.CameraPanelPaint(Sender: TObject);
begin
  if not(Camera_Flag) then
  begin
  Layers[0].CloneImgToBitmap(OriginalBitmap);
  CameraPanel.Canvas.Draw(0,0,OriginalBitmap);
  end;
end;

procedure TForm1.CheckBox_timerClick(Sender: TObject);
begin
  timer1.enabled:=CheckBox_timer.Checked;
end;

procedure TForm1.EditMedianChange(Sender: TObject);
begin
  AdaptiveMedianFilterFlag:=false; ButtonAdaptiveMedian.caption:='вкл. адаптивный';
  MedianFilterFlag:=false; ButtonMedian.caption:='вкл. медианный';
end;

procedure TForm1.EditPepperSaltChange(Sender: TObject);
begin
  PepperSaltFlag:=false;
  PepperSaltFlag:=false;
  ButtonPepperSalt.Caption:='вкл. шум';
  Layers[1].DrawFromImg(Layers[0],0,0);
end;

procedure TForm1.EditTimerChange(Sender: TObject);
begin
  Timer1.Enabled:=false;
  CheckBox_timer.checked:=false;
end;

//процедура обновления содержимого полотна рисования
procedure TForm1.ImageViewPaint(Sender: TObject);
begin ComposeSummaryIMG; end;

procedure TForm1.MenuItemCameraOpenClick(Sender: TObject);
begin
  ButtonRestoreClick(self);
  Camera_Flag:=true;
  VLC_player.PlayFile('dshow://');
end;

//руководство программиста
procedure TForm1.MenuItemHelpProgrammerClick(Sender: TObject);
begin
MessageBox(0,'Руководство программиста в разработке','Руководство программиста',0);
end;

//методические рекомендации
procedure TForm1.MenuItemHelpTeacherClick(Sender: TObject);
begin
MessageBox(0,'Методические рекомендации в разработке','Методические рекомендации',0);
end;

//Руководство пользователя
procedure TForm1.MenuItemHelpUserClick(Sender: TObject);
begin
MessageBox(0,'Руководство пользователя в разработке','Руководство пользователя',0);
end;

//подпрограмма вывода окна сведений о программе
procedure TForm1.MenuItemHelpAboutClick(Sender: TObject);
begin
  MessageBox(0,
             'Медианная фильтрация видеопотока'+chr(13)+
             ' '+chr(13)+
             'Условия распространения и использования:'+chr(13)+
             'свободное программное обеспечение'+chr(13)+
             '(Apache-2.0 лицензия)'+chr(13)+
             ' '+chr(13)+
             'автор: к.ф.-м.н. Ионисян А.С.'
             ,'О программе',0);
end;

//подпрограмма выбора и загрузки внешнего видеофайла в активный слой рисования
procedure TForm1.MenuItemVideoOpenClick(Sender: TObject);
begin
  if OpenPictureDialog.execute then
  begin
    ButtonRestoreClick(self);
    Camera_Flag:=true;
    VLC_player.PlayFile(OpenPictureDialog.Filename);
  end;
end;

//главный цикл обработки
procedure TForm1.Timer1Timer(Sender: TObject);
var CameraPanel_DC:HDC;
begin
  Timer1.Interval:=StrToInt(EditTimer.text);
  if Camera_flag then
  begin
      if VLC_Player.State=libvlc_Ended then VLC_player.PlayFile(OpenPictureDialog.Filename);
      CameraPanel_DC:=LCLIntf.GetDC(CameraPanel.Handle);
      CameraBitmap.LoadFromDevice(CameraPanel_DC);
      LCLIntF.ReleaseDC(CameraBitmap.Handle,CameraPanel_DC);
      Layers[0].CloneBitmapToImg(CameraBitmap);
  end;

  if PepperSaltFlag then
  begin
       PepperSaltPercent:=StrToInt(EditPepperSalt.text);
       Layers[1].DrawFromImg(Layers[0],0,0);
       FilterSaultPepper(Layers[1],PepperSaltPercent);
  end;

  if MedianFilterFlag then
  begin
       MedianRadius:=StrToInt(EditMedian.text);
       if PepperSaltFlag then Layers[2].DrawFromImg(Layers[1],Layers[1].width div 2,0)
                         else Layers[2].DrawFromImg(Layers[0],Layers[0].width div 2,0);
       FilterMedian(Layers[2],MedianRadius);
  end;

  if AdaptiveMedianFilterFlag then
  begin
       MedianRadius:=StrToInt(EditMedian.text);
       if PepperSaltFlag then Layers[2].DrawFromImg(Layers[1],Layers[1].width div 2,0)
                         else Layers[2].DrawFromImg(Layers[0],Layers[0].width div 2,0);
       FilterAdaptiveMedian(Layers[2],MedianRadius);
  end;

  ComposeSummaryIMG;
  RefreshStatusBar;
end;

//точка выхода из программы
procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  ButtonRestoreClick(self);
  close;
end;

//загрузка изображения для тестирования
procedure TForm1.MenuItemPictureOpenClick(Sender: TObject);
var tmp_IMG:TIMG;
begin
  if OpenPictureDialog.Execute then
  begin
       ButtonRestoreClick(self);
       tmp_IMG:=TIMG.Create;
       tmp_IMG.LoadFromFile(OpenPictureDialog.filename);
       tmp_IMG.ScaleToImg(Layers[0]);
       Layers[1].DrawFromImg(Layers[0],0,0);
       tmp_IMG.done;

       Layers[0].CloneImgToBitmap(OriginalBitmap);
       CameraPanel.Canvas.Draw(0,0,OriginalBitmap);

       ComposeSummaryIMG;
       RefreshStatusBar;
  end;
end;

end.

