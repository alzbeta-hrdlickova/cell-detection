%% Načtení dat a masek (ground truth)

location= '/Users/betyadamkova/Desktop/final_matlab/data';   % cesta k datům
addpath(location);
img_dat = imageDatastore(location);
l=length(img_dat.Files);  % počet dat

location_m= '/Users/betyadamkova/Desktop/final_matlab/output'; % cesta k ground truth
addpath(location_m);
img_dat_m = imageDatastore(location_m);

%% Vytvoření prosotoru pro ukládání dat/ulození do proměnných
mask=[];
jaccard=[];
Img = [];
ground_t=[];
JI_all=[];
op=1;
%% Ulození dat do proměnných 
for i=1:l
  images{i} = imread(sprintf('data%d.tiff',i));
  Img = (cat(3, Img, images{i})); % obrazová data ulozena do 3D matice
 images_gt{i} = imread(sprintf('output%d.tiff',i));
 ground_t = (cat(3, ground_t, images_gt{i})); 
 ground_t=logical(ground_t);   % ground truth uloženy do 3D matice
end

%% For cyklus pro výběr obrazu
[x,y,z]=size(Img);  % velikost obrazové matice
jj=1;
for snimek=1:z  % for cyklus prochází vsechny obrazy
Img2=Img(:,:,snimek);       % výběr obrazu
im_maska=ground_t(:,:,snimek);   % výběr ground_t

%% Úprava binárního obrazu 
img=medfilt2(Img2,[7,7]); % filtrace mediánovým filtrem maska 7x7
Img_eq = adapthisteq(img); % ekvalizace histogramu obrazu
multi=multithresh(Img_eq,5); % prahování (výběr prvního prahu)
binar = im2bw(Img_eq, multi(1,1));         % převod na binární obraz s prvním prahem z multithresh
binar_fill = imfill(binar,'holes');       % vyplnění děr v obraze
binar_open = imopen(binar_fill, ones(3,3)); % operace otevření s maskou 3x3
binar_final = bwareaopen(binar_open, 50);   % odstranění malých objektů

%% Nalezení středů buněk (jader)
cell_center = imextendedmax(Img_eq, 0.2);   % oblastní maximum (spojené pixely se stejnou intensitou) z H-max transform, na základě článků (např: https://www.osapublishing.org/boe/fulltext.cfm?uri=boe-7-8-3111&id=348030)
% H maxima potlačuje všechny intenzitní maxima pod danou hranicí, z toho je
% pak hledáno oblastní maximum, prah zde udává míru odlišnosti pixelů aby byly uvažovány za maxima

cell_center = imclose(cell_center, ones(5,5));  % operace uzavření s maskou 5x5 kvůli připojení malých bodů
cell_center = imfill(cell_center, 'holes');     % vyplnění děr
%  center = imoverlay(Img_eq, cell_center,'r');
%% Aplikování watershed
I_eq_c = imcomplement(Img_eq);  % obrácené k Img_eq (doplněk)
I_mod = imimposemin(I_eq_c, ~binar_final | cell_center); % minimum v šedotónovém obrazu pouze v místech jedniček binárního obrazu
W = watershed(I_mod,8);   % aplikování metody watershed s 8-mi okolím
W=im2double(W);

%% Zpracování dat k výpočtu podobnosti
minimum=mode(W(:));     % výběr nejčastější hodnoty (hodnota pozadí)
W(W>minimum)=1;         % všechny hodnoty větší než pozadí změněny na hodnotu jedna
W(W~=1)=0;              % pozadí s hodnotou nula
W=logical(W);           % převod na logical
W_vysledna{1,jj}=W;     % ulození všech vysegmentovaných masek

jj=jj+1;
o=1;oo=1;j=1;

Label1=bwlabel(W,4); % označení buněk (očíslování)
Label2=bwlabel(im_maska,4);  % označení buněk v ground_t 
L1=Label1;
L2=Label2;
cells_water =max(Label1(:)); % zjistění počtu buněk po watershed
cells_gt=max(Label2(:));     % zjistění počtu buněk v ground_t


for m=1:cells_water  % dva for cykly ke zjistění překryvu buněk (zda je splněna podmínka poloviny)
    for n=1:cells_gt
       Label1=L1;
       Label2=L2;
       Label1(Label1~=m)=0; Label1=logical(Label1);  % Nahrazení okolí buňky nulami (krom čísla m=značení aktuální buňky)
       Label2(Label2~=n)=0; Label2=logical(Label2);
       jaccIn = sum(Label1(:) & Label2(:)) / sum(Label1(:) | Label2(:));  % výpočet jaccarda pro dvojice buněk    
          
           if jaccIn>0.5
                jaccard(1,o)=jaccIn;  % ukládání hodnot jaccarda pro konkrétní buňku
                o=o+1;
           else
           end
      
    end

    jacc_img=[];
    
    if isempty(jaccard)   % pokud je se vsemi buňkami hodnota nula, doplní se nula jako výsledek (aby se neobjevovalo NaN)
        jacc_img(1,j)=0; 
        
    else
        jacc_img(1,j)=jaccard;  % ulození výsledné hodnoty za celý obraz
    end   
      jaccard=[];  % vytvoření nového prázdného prostoru pro ukládání
      o=1;
      j=j+1;
end

 JI_all(1,op)=sum(jacc_img)/cells_water;  % uložení jaccarda ze všech obrazů do jednoho vektoru
 jacc_img=[];
 j=1;
 op=op+1;
 
end
Jac_mean=sum(JI_all)/length(JI_all)
