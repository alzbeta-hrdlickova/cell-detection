%% Naètení dat a masek (ground truth)
location= '/Users/betyadamkova/Desktop/final_matlab/data';   % cesta k datùm
addpath(location);
img_dat = imageDatastore(location);
l=length(img_dat.Files);  % poèet dat

location_m= '/Users/betyadamkova/Desktop/final_matlab/output'; % cesta k ground truth
addpath(location_m);
img_dat_m = imageDatastore(location_m);

%% Vytvoøení prosotoru pro ukládání dat/ulození do promìnných
mask=[];
jaccard=[];
Img = [];
ground_t=[];
JI_all=[];
op=1;
%% Ulození dat do promìnných 
for i=1:l
  images{i} = imread(sprintf('data%d.tiff',i));
  Img = (cat(3, Img, images{i})); % obrazová data ulozena do 3D matice
 images_gt{i} = imread(sprintf('output%d.tiff',i));
 ground_t = (cat(3, ground_t, images_gt{i})); 
 ground_t=logical(ground_t);   % ground truth uloženy do 3D matice
end

%% For cyklus pro výbìr obrazu
[x,y,z]=size(Img);  % velikost obrazové matice
jj=1;
for snimek=1:z  % for cyklus prochází vsechny obrazy
Img2=Img(:,:,snimek);       % výbìr obrazu
im_maska=ground_t(:,:,snimek);   % výbìr ground_t

%% Úprava binárního obrazu 
img=medfilt2(Img2,[7,7]); % filtrace mediánovým filtrem maska 7x7
Img_eq = adapthisteq(img); % ekvalizace histogramu obrazu
multi=multithresh(Img_eq,5); % prahování (výbìr prvního prahu)
binar = im2bw(Img_eq, multi(1,1));         % pøevod na binární obraz s prvním prahem z multithresh
binar_fill = imfill(binar,'holes');       % vyplnìní dìr v obraze
binar_open = imopen(binar_fill, ones(3,3)); % operace otevøení s maskou 3x3
binar_final = bwareaopen(binar_open, 50);   % odstranìní malých objektù

%% Nalezení støedù bunìk (jader)
cell_center = imextendedmax(Img_eq, 0.2);   % oblastní maximum (spojené pixely se stejnou intensitou) z H-max transform, na základì èlánkù (napø: https://www.osapublishing.org/boe/fulltext.cfm?uri=boe-7-8-3111&id=348030)
% H maxima potlaèuje všechny intenzitní maxima pod danou hranicí, z toho je
% pak hledáno oblastní maximum, prah zde udává míru odlišnosti pixelù aby byly uvažovány za maxima

cell_center = imclose(cell_center, ones(5,5));  % operace uzavøení s maskou 5x5 kvùli pøipojení malých bodù
cell_center = imfill(cell_center, 'holes');     % vyplnìní dìr
%  center = imoverlay(Img_eq, cell_center,'r');
%% Aplikování watershed
I_eq_c = imcomplement(Img_eq);  % obrácené k Img_eq (doplnìk)
I_mod = imimposemin(I_eq_c, ~binar_final | cell_center); % minimum v šedotónovém obrazu pouze v místech jednièek binárního obrazu
W = watershed(I_mod,8);   % aplikování metody watershed s 8-mi okolím
W=im2double(W);

%% Zpracování dat k výpoètu podobnosti
minimum=mode(W(:));     % výbìr nejèastìjší hodnoty (hodnota pozadí)
W(W>minimum)=1;         % všechny hodnoty vìtší než pozadí zmìnìny na hodnotu jedna
W(W~=1)=0;              % pozadí s hodnotou nula
W=logical(W);           % pøevod na logical
W_vysledna{1,jj}=W;     % ulození všech vysegmentovaných masek

jj=jj+1;
o=1;oo=1;j=1;

Label1=bwlabel(W,4); % oznaèení bunìk (oèíslování)
Label2=bwlabel(im_maska,4);  % oznaèení bunìk v ground_t 
L1=Label1;
L2=Label2;
cells_water =max(Label1(:)); % zjistìní poètu bunìk po watershed
cells_gt=max(Label2(:));     % zjistìní poètu bunìk v ground_t


for m=1:cells_water  % dva for cykly ke zjistìní pøekryvu bunìk (zda je splnìna podmínka poloviny)
    for n=1:cells_gt
       Label1=L1;
       Label2=L2;
       Label1(Label1~=m)=0; Label1=logical(Label1);  % Nahrazení okolí buòky nulami (krom èísla m=znaèení aktuální buòky)
       Label2(Label2~=n)=0; Label2=logical(Label2);
       jaccIn = sum(Label1(:) & Label2(:)) / sum(Label1(:) | Label2(:));  % výpoèet jaccarda pro dvojice bunìk    
          
           if jaccIn>0.5
                jaccard(1,o)=jaccIn;  % ukládání hodnot jaccarda pro konkrétní buòku
                o=o+1;
           else
           end
      
    end

    jacc_img=[];
    
    if isempty(jaccard)   % pokud je se vsemi buòkami hodnota nula, doplní se nula jako výsledek (aby se neobjevovalo NaN)
        jacc_img(1,j)=0; 
        
    else
        jacc_img(1,j)=jaccard;  % ulození výsledné hodnoty za celý obraz
    end   
      jaccard=[];  % vytvoøení nového prázdného prostoru pro ukládání
      o=1;
      j=j+1;
end

 JI_all(1,op)=sum(jacc_img)/cells_water;  % uložení jaccarda ze všech obrazù do jednoho vektoru
 jacc_img=[];
 j=1;
 op=op+1;
 
end
Jac_mean=sum(JI_all)/length(JI_all)