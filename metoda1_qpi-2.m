%% Na�ten� dat a masek (ground truth)
location= '/Users/betyadamkova/Desktop/final_matlab/data';   % cesta k dat�m
addpath(location);
img_dat = imageDatastore(location);
l=length(img_dat.Files);  % po�et dat

location_m= '/Users/betyadamkova/Desktop/final_matlab/output'; % cesta k ground truth
addpath(location_m);
img_dat_m = imageDatastore(location_m);

%% Vytvo�en� prosotoru pro ukl�d�n� dat/ulozen� do prom�nn�ch
mask=[];
jaccard=[];
Img = [];
ground_t=[];
JI_all=[];
op=1;
%% Ulozen� dat do prom�nn�ch 
for i=1:l
  images{i} = imread(sprintf('data%d.tiff',i));
  Img = (cat(3, Img, images{i})); % obrazov� data ulozena do 3D matice
 images_gt{i} = imread(sprintf('output%d.tiff',i));
 ground_t = (cat(3, ground_t, images_gt{i})); 
 ground_t=logical(ground_t);   % ground truth ulo�eny do 3D matice
end

%% For cyklus pro v�b�r obrazu
[x,y,z]=size(Img);  % velikost obrazov� matice
jj=1;
for snimek=1:z  % for cyklus proch�z� vsechny obrazy
Img2=Img(:,:,snimek);       % v�b�r obrazu
im_maska=ground_t(:,:,snimek);   % v�b�r ground_t

%% �prava bin�rn�ho obrazu 
img=medfilt2(Img2,[7,7]); % filtrace medi�nov�m filtrem maska 7x7
Img_eq = adapthisteq(img); % ekvalizace histogramu obrazu
multi=multithresh(Img_eq,5); % prahov�n� (v�b�r prvn�ho prahu)
binar = im2bw(Img_eq, multi(1,1));         % p�evod na bin�rn� obraz s prvn�m prahem z multithresh
binar_fill = imfill(binar,'holes');       % vypln�n� d�r v obraze
binar_open = imopen(binar_fill, ones(3,3)); % operace otev�en� s maskou 3x3
binar_final = bwareaopen(binar_open, 50);   % odstran�n� mal�ch objekt�

%% Nalezen� st�ed� bun�k (jader)
cell_center = imextendedmax(Img_eq, 0.2);   % oblastn� maximum (spojen� pixely se stejnou intensitou) z H-max transform, na z�klad� �l�nk� (nap�: https://www.osapublishing.org/boe/fulltext.cfm?uri=boe-7-8-3111&id=348030)
% H maxima potla�uje v�echny intenzitn� maxima pod danou hranic�, z toho je
% pak hled�no oblastn� maximum, prah zde ud�v� m�ru odli�nosti pixel� aby byly uva�ov�ny za maxima

cell_center = imclose(cell_center, ones(5,5));  % operace uzav�en� s maskou 5x5 kv�li p�ipojen� mal�ch bod�
cell_center = imfill(cell_center, 'holes');     % vypln�n� d�r
%  center = imoverlay(Img_eq, cell_center,'r');
%% Aplikov�n� watershed
I_eq_c = imcomplement(Img_eq);  % obr�cen� k Img_eq (dopln�k)
I_mod = imimposemin(I_eq_c, ~binar_final | cell_center); % minimum v �edot�nov�m obrazu pouze v m�stech jedni�ek bin�rn�ho obrazu
W = watershed(I_mod,8);   % aplikov�n� metody watershed s 8-mi okol�m
W=im2double(W);

%% Zpracov�n� dat k v�po�tu podobnosti
minimum=mode(W(:));     % v�b�r nej�ast�j�� hodnoty (hodnota pozad�)
W(W>minimum)=1;         % v�echny hodnoty v�t�� ne� pozad� zm�n�ny na hodnotu jedna
W(W~=1)=0;              % pozad� s hodnotou nula
W=logical(W);           % p�evod na logical
W_vysledna{1,jj}=W;     % ulozen� v�ech vysegmentovan�ch masek

jj=jj+1;
o=1;oo=1;j=1;

Label1=bwlabel(W,4); % ozna�en� bun�k (o��slov�n�)
Label2=bwlabel(im_maska,4);  % ozna�en� bun�k v ground_t 
L1=Label1;
L2=Label2;
cells_water =max(Label1(:)); % zjist�n� po�tu bun�k po watershed
cells_gt=max(Label2(:));     % zjist�n� po�tu bun�k v ground_t


for m=1:cells_water  % dva for cykly ke zjist�n� p�ekryvu bun�k (zda je spln�na podm�nka poloviny)
    for n=1:cells_gt
       Label1=L1;
       Label2=L2;
       Label1(Label1~=m)=0; Label1=logical(Label1);  % Nahrazen� okol� bu�ky nulami (krom ��sla m=zna�en� aktu�ln� bu�ky)
       Label2(Label2~=n)=0; Label2=logical(Label2);
       jaccIn = sum(Label1(:) & Label2(:)) / sum(Label1(:) | Label2(:));  % v�po�et jaccarda pro dvojice bun�k    
          
           if jaccIn>0.5
                jaccard(1,o)=jaccIn;  % ukl�d�n� hodnot jaccarda pro konkr�tn� bu�ku
                o=o+1;
           else
           end
      
    end

    jacc_img=[];
    
    if isempty(jaccard)   % pokud je se vsemi bu�kami hodnota nula, dopln� se nula jako v�sledek (aby se neobjevovalo NaN)
        jacc_img(1,j)=0; 
        
    else
        jacc_img(1,j)=jaccard;  % ulozen� v�sledn� hodnoty za cel� obraz
    end   
      jaccard=[];  % vytvo�en� nov�ho pr�zdn�ho prostoru pro ukl�d�n�
      o=1;
      j=j+1;
end

 JI_all(1,op)=sum(jacc_img)/cells_water;  % ulo�en� jaccarda ze v�ech obraz� do jednoho vektoru
 jacc_img=[];
 j=1;
 op=op+1;
 
end
Jac_mean=sum(JI_all)/length(JI_all)