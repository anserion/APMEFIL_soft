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
//комплексная арифметика
//=====================================================================
unit arith_complex;

{$mode objfpc}{$H+}

interface

type
TComplex=record
   re,im:real;
end;
TComplexVector=array of TComplex;
TComplexMatrix=array of TComplexVector;

TRealVector=array of real;
TRealMatrix=array of TRealVector;

function c_zero:TComplex;
function c_one:TComplex;
function c_root_of_one_CCW(k,n:integer):TComplex;
function c_root_of_one_CW(k,n:integer):TComplex;
function c_dup(value:TComplex):TComplex;
function c_amp(a:TComplex):real;
function c_phi(a:TComplex):real;
function c_amp_cmp(a,b:TComplex):integer;
function c_add(a,b:TComplex):TComplex;
function c_sub(a,b:TComplex):TComplex;
function c_mul(a,b:TComplex):TComplex;
function c_div(a,b:TComplex):TComplex;
procedure c_AlgToTrig(alg:TComplex; var amp,phi:real);
function c_TrigToAlg(amp,phi:real):TComplex;
function c_sqr(arg:TComplex):TComplex;
function c_exp_ix(x:real):TComplex;
procedure c_sqrt(arg:TComplex; var res1,res2:TComplex);
function c_exp(arg:TComplex):TComplex;
function c_ln(arg:TComplex; k:integer):TComplex;
function c_power(arg,pow:TComplex; k:integer):TComplex;

function Power2RoundUp(N:integer):integer; //округление вверх до ближайшей степени двойки

procedure FFT_analys(var FFT_t,FFT_f:TComplexVector); //одномерный БПФ-анализ (по основанию 2)
procedure FFT_syntez(var FFT_f,FFT_t:TComplexVector); //одномерный БПФ-синтез (по основанию 2)

procedure DFT_analys(var DFT_t,DFT_f:TComplexVector); //одномерный спектральный анализ ДПФ
procedure DFT_syntez(t_size:integer; var DFT_f,DFT_t:TComplexVector); //одномерный спектральный синтез ДПФ
procedure DFT_analys_2D(var DFT_t,DFT_f:TComplexMatrix); //двумерный спектральный анализ ДПФ
procedure DFT_syntez_2D(t_width,t_height:integer; var DFT_f,DFT_t:TComplexMatrix); //двумерный спектральный синтез ДПФ

implementation

function c_zero:TComplex;
begin c_zero.re:=0; c_zero.im:=0; end;

function c_one:TComplex;
begin c_one.re:=1; c_one.im:=0; end;

function c_root_of_one_CCW(k,n:integer):TComplex;
var phi:real;
begin
     phi:=2*PI*k/n;
     c_root_of_one_CCW.re:=cos(phi);
     c_root_of_one_CCW.im:=sin(phi);
end;

function c_root_of_one_CW(k,n:integer):TComplex;
var phi:real;
begin
     phi:=-2*PI*k/n;
     c_root_of_one_CW.re:=cos(phi);
     c_root_of_one_CW.im:=sin(phi);
end;

function c_dup(value:TComplex):TComplex;
begin c_dup.re:=value.re; c_dup.im:=value.im; end;

function c_amp(a:TComplex):real;
begin c_amp:=sqrt(sqr(a.re)+sqr(a.im)); end;

function c_phi(a:TComplex):real;
var res,alpha1:real;
begin
     res:=0; alpha1:=0;
     if a.re<>0 then alpha1:=arctan(abs(a.im)/abs(a.re));
     if (a.re>0)and(a.im>=0) then res:=alpha1;
     if (a.re<0)and(a.im>=0) then res:=PI-alpha1;
     if (a.re>0)and(a.im<0) then res:=-alpha1;
     if (a.re<0)and(a.im<0) then res:=-PI+alpha1;
     c_phi:=res;
end;

function c_amp_cmp(a,b:TComplex):integer;
var amp2_a,amp2_b:real; res:integer;
begin
     res:=0;
     amp2_a:=sqr(a.re)+sqr(a.im);
     amp2_b:=sqr(b.re)+sqr(b.im);
     if amp2_a>amp2_b then res:=1;
     if amp2_a=amp2_b then res:=0;
     if amp2_a<amp2_b then res:=-1;
     c_amp_cmp:=res;
end;

function c_add(a,b:TComplex):TComplex;
begin c_add.re:=a.re+b.re; c_add.im:=a.im+b.im; end;

function c_sub(a,b:TComplex):TComplex;
begin c_sub.re:=a.re-b.re; c_sub.im:=a.im-b.im; end;

function c_mul(a,b:TComplex):TComplex;
begin c_mul.re:=a.re*b.re-a.im*b.im; c_mul.im:=a.re*b.im+a.im*b.re; end;

function c_div(a,b:TComplex):TComplex;
begin
     c_div.re:=(a.re*b.re+a.im*b.im)/(b.re*b.re+b.im*b.im);
     c_div.im:=(a.im*b.re-a.re*b.im)/(b.re*b.re+b.im*b.im);
end;

procedure c_AlgToTrig(alg:TComplex; var amp,phi:real);
begin
     amp:=c_amp(alg);
     phi:=c_phi(alg);
end;

function c_TrigToAlg(amp,phi:real):TComplex;
begin c_TrigToAlg.re:=amp*cos(phi); c_TrigToAlg.im:=amp*sin(phi); end;

function c_sqr(arg:TComplex):TComplex;
begin c_sqr.re:=arg.re*arg.re-arg.im*arg.im; c_sqr.im:=2*arg.re*arg.im; end;

function c_exp_ix(x:real):TComplex;
begin c_exp_ix.re:=cos(x); c_exp_ix.im:=sin(x); end;

procedure c_sqrt(arg:TComplex; var res1,res2:TComplex);
var amp,phi:real;
begin
     amp:=sqrt(c_amp(arg));
     phi:=c_phi(arg);
     res1.re:=amp*cos(phi/2); res1.im:=amp*sin(phi/2);
     res2.re:=amp*cos(phi/2+PI); res2.im:=amp*sin(phi/2+PI);
end;

function c_exp(arg:TComplex):TComplex;
var exp_x:real;
begin
     exp_x:=exp(arg.re);
     c_exp.re:=exp_x*cos(arg.im);
     c_exp.im:=exp_x*sin(arg.im);
end;

function c_ln(arg:TComplex; k:integer):TComplex;
var amp,phi:real;
begin
     amp:=c_amp(arg);
     phi:=c_phi(arg);
     if amp>0 then amp:=ln(amp);
     c_ln.re:=amp;
     c_ln.im:=phi+2*PI*k;
end;

function c_power(arg,pow:TComplex; k:integer):TComplex;
begin
     c_power:=c_exp(c_mul(pow,c_ln(arg,k)));
end;

//================================================================
//быстрое преобразование Фурье с прореживанием по времени (спектральный анализ)
procedure FFT_analys(var FFT_t,FFT_f:TComplexVector);
var fft_tmp,W:TComplexVector;
    i,k,bb,dst_digit,tmp,N,NN,NN2,merge_step,sections,section_base:integer;
begin
   N:=length(FFT_t);
   //bb - число бит от размера входного вектора
   bb:=1; tmp:=N-1;
   while tmp>1 do begin tmp:=tmp>>1; bb:=bb+1; end;
   //двоично-инверсная перестановка
   for i:=0 to N-1 do
   begin
     tmp:=i; dst_digit:=0;
     for k:=1 to bb do
     begin
       dst_digit:=dst_digit<<1+(tmp and 1);
       tmp:=tmp>>1;
     end;
      FFT_f[dst_digit]:=FFT_t[i];
   end;
   //сборка спектра
   SetLength(fft_tmp,N);
   SetLength(W,N);
   NN2:=1;
   for merge_step:=1 to bb do
   begin
     NN:=NN2*2; //число элементов в текущем разбиении 2,4,8,16,...,N
     //формируем массив поворотных коэффициентов для текущего шага сборки коэффициентов
     for k:=0 to NN2-1 do W[k]:=c_root_of_one_CW(k,NN);
     sections:=N div NN; //число двоичных разбиений исходной последовательности на текущем шаге сборки
     //анализируем каждое разбиение
     for i:=0 to sections-1 do
     begin
       section_base:=i*NN;
       //применяем алгоритм "бабочка" для текущего разбиения
       for k:=0 to NN2-1 do
       begin
         fft_tmp[section_base+k]:=c_add(FFT_f[section_base+k],c_mul(FFT_f[section_base+k+NN2],W[k]));
         fft_tmp[section_base+k+NN2]:=c_sub(FFT_f[section_base+k],c_mul(FFT_f[section_base+k+NN2],W[k]));
       end;
     end;
     //подготавливаемся к следующему укрупнению (сборке)
     for k:=0 to N-1 do FFT_f[k]:=fft_tmp[k];
     NN2:=NN;
   end;

   //"уменьшаем" коэффициенты после анализа
   for k:=0 to N-1 do
   begin
     FFT_f[k].re:=FFT_f[k].re/N;
     FFT_f[k].im:=FFT_f[k].im/N;
   end;
   //высвобождаем память
   SetLength(fft_tmp,0);
   SetLength(W,0);
end;

//быстрое преобразование Фурье с прореживанием по времени (спектральный синтез)
procedure FFT_syntez(var FFT_f,FFT_t:TComplexVector);
var fft_tmp:TComplexVector;
    k,N:integer;
begin
   N:=length(FFT_f);
   SetLength(fft_tmp,N);
   //выполняем комплексное сопряжение и масштабирование входного спектра
   for k:=0 to N-1 do
   begin
     FFT_tmp[k].re:=FFT_f[k].re;// /N;
     FFT_tmp[k].im:=-FFT_f[k].im;// /N;
   end;
   //проводим прямое преобразование Фурье над комплексно-сопряженным спектром
   FFT_analys(FFT_tmp,FFT_t);
   //выполняем комплексное сопряжение и масштабирование результата
   for k:=0 to N-1 do
   begin
     FFT_t[k].re:=FFT_t[k].re*N;
     FFT_t[k].im:=-FFT_t[k].im*N;
   end;
   //высвобождаем промежуточную память
   SetLength(fft_tmp,0);
end;

//функция выполняет округление числа N вверх до ближайшей степени двойки
function Power2RoundUp(N:integer):integer;
var NN,bb,tmp:integer;
begin
  bb:=1; tmp:=N-1;
  while tmp>1 do begin tmp:=tmp>>1; bb:=bb+1; end;
  NN:=(1<<bb); if N>NN then NN:=NN<<1;
  Power2RoundUp:=NN;
end;

//преобразование Фурье (спектральный анализ)
//число отсчетов входного сигнала - любое натуральное число
//размер выходного спектра будет равен степени двойки (специфика данного алгоритма)
//память для DFT_f должна быть выделена до вызова подпрограммы
procedure DFT_analys(var DFT_t,DFT_f:TComplexVector);
var fft_tmp:TComplexVector;
    k,N,NN:integer;
begin
  N:=length(DFT_t);
  NN:=Power2RoundUp(N);
  SetLength(fft_tmp,NN);
  for k:=0 to N-1 do fft_tmp[k]:=DFT_t[k];
  for k:=N to NN-1 do begin fft_tmp[k].re:=0; fft_tmp[k].im:=0; end;
  FFT_analys(fft_tmp,DFT_f);
  SetLength(fft_tmp,0);
end;

//преобразование Фурье (спектральный синтез)
//размер входного спектра должен быть равен степени двойки (специфика данного алгоритма)
//число отсчетов выходного сигнала - натуральное число, не превышающее размера спектра
//память для DFT_t должна быть выделена до вызова подпрограммы
procedure DFT_syntez(t_size:integer; var DFT_f,DFT_t:TComplexVector);
var fft_tmp:TComplexVector; k,f_size:integer;
begin
  f_size:=length(DFT_f);
  SetLength(fft_tmp,f_size);
  FFT_syntez(DFT_f,fft_tmp);
  if t_size>f_size then t_size:=f_size;
  for k:=0 to t_size-1 do DFT_t[k]:=fft_tmp[k];
  SetLength(fft_tmp,0);
end;

//быстрое двумерное преобразование Фурье (спектральный анализ)
//размеры входного изображения - любые (не обязательно степень двойки)
//размер матрицы выходного спектра будет равен степени двойки
//по числу строк и по числу столбцов (специфика данного алгоритма)
//память для DFT_f должна быть выделена до вызова подпрограммы
procedure DFT_analys_2D(var DFT_t,DFT_f:TComplexMatrix);
var dft_tmp_t,dft_tmp_f:TComplexVector;
    x,y,width,height,p2_width,p2_height:integer;
begin
  height:=length(DFT_t);
  width:=length(DFT_t[0]);
  //округляем размеры вверх до ближайшей степени двойки
  p2_height:=Power2RoundUp(height);
  p2_width:=Power2RoundUp(width);
  //проводим БПФ по строчкам
  for y:=0 to height-1 do DFT_analys(DFT_t[y],DFT_f[y]);
  //выделяем память для хранения содержимого столбцов
  SetLength(dft_tmp_t,height);
  SetLength(dft_tmp_f,p2_height);
  //проводим БПФ по столбцам
  for x:=0 to p2_width-1 do
  begin
    for y:=0 to height-1 do dft_tmp_t[y]:=DFT_f[y,x];
    DFT_analys(dft_tmp_t,dft_tmp_f);
    for y:=0 to p2_height-1 do DFT_f[y,x]:=dft_tmp_f[y];
  end;

  //огрубление результата
  //for y:=0 to p2_height-1 do
  //for x:=0 to p2_width-1 do
  //begin
  //  DFT_f[y,x].re:=10*trunc(0.1*DFT_f[y,x].re);
  //  DFT_f[y,x].im:=10*trunc(0.1*DFT_f[y,x].im);
  //end;
  //высвобождаем память
  SetLength(dft_tmp_t,0);
  SetLength(dft_tmp_f,0);
end;

//быстрое двумерное преобразование Фурье (спектральный синтез)
//размер матрицы входного спектра будет равен степени двойки
//по числу строк и по числу столбцов (специфика данного алгоритма)
//размеры выходного изображения - любые (не обязательно степень двойки),
//не превышающие размер матрицы спектра
//память для DFT_t должна быть выделена до вызова подпрограммы
procedure DFT_syntez_2D(t_width,t_height:integer;var DFT_f,DFT_t:TComplexMatrix);
var dft_tmp_t,dft_tmp_f:TComplexMatrix;
    x,y,p2_width,p2_height:integer;
begin
  p2_height:=length(DFT_f);
  p2_width:=length(DFT_f[0]);
  SetLength(dft_tmp_f,p2_height,p2_width);
  SetLength(dft_tmp_t,p2_height,p2_width);
  //комплексное сопряжение и масштабирование входного спектра
  for y:=0 to p2_height-1 do
  for x:=0 to p2_width-1 do
  begin
    dft_tmp_f[y,x].re:=DFT_f[y,x].re;// /(p2_width*p2_height);
    dft_tmp_f[y,x].im:=-DFT_f[y,x].im;// /(p2_width*p2_height);
  end;
  //прямое ДПФ
  DFT_analys_2D(dft_tmp_f,dft_tmp_t);
  //комплексное сопряжение и масштабирование выходного сигнала
  for y:=0 to p2_height-1 do
  for x:=0 to p2_width-1 do
  begin
    dft_tmp_t[y,x].re:=dft_tmp_t[y,x].re*(p2_width*p2_height);
    dft_tmp_t[y,x].im:=-dft_tmp_t[y,x].im*(p2_width*p2_height);
  end;
  //усечение результата
  if t_height>p2_height then t_height:=p2_height;
  if t_width>p2_width then t_width:=p2_width;
  for y:=0 to t_height-1 do
  for x:=0 to t_width-1 do
    DFT_t[y,x]:=dft_tmp_t[y,x];
  //высвобождение памяти
  SetLength(dft_tmp_t,0,0);
  SetLength(dft_tmp_f,0,0);
end;

end.
