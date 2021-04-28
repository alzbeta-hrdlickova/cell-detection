%projekt V2

clear all;
close all;
clc;

im=im2double(imread('dic9.tif'));                   %naètení obrázku
im_maska=im2double(imread('dic9_maska.png'));                   %naètení masky
im_maska(im_maska>0)=1;

figure
imshow(im)
figure
imshow(im_maska,[])
figure
set(surf(im),'LineStyle','none')

fim = filter2(fspecial('log',10),im,'valid');           %filtrace (tohle to pìknì srovná do roviny a na nulu, vlastnì to v jednom øádku udìlá to co bylo pùvodnì na 30)
fim = abs(fim);
%fim = filter2(fspecial('average',20),fim,'valid');
figure
set(surf(fim),'LineStyle','none')
figure
imshow(fim,[])

% v={'sobel','prewitt','roberts','log','canny'};
% ff=[0.25 0.5 0.75];
% for i=1:1:5
%     figure
%     p=1;
%     for j=1:1:3
% [~,threshold] = edge(fim,v{i});
% bin_grad_m = edge(fim,v{i},threshold * ff(j));
% subplot (1,3,p)
% imshow(bin_grad_m,[]);
% title(v{i})
% p=p+1;
%     end
% end

[~,prah] = edge(fim,'sobel');
bin_grad_m = edge(fim,'sobel',prah * 0.5);              %naprahování pro získání binárného obrazu, (hodnoty jsou anstavené podle for cyklu nahoøe, s tìmito hodnotami to vycházelo nejlépe)
figure
imshow(bin_grad_m,[]);

%rozšížení všech bodù
SE=strel('disk',2);
dil_im = imdilate(bin_grad_m,SE);

%vyplnnìní dìr mezi rozøíøenými body
pryc_bordel=bwareaopen(dil_im,500);
 f_im1 = imfill(pryc_bordel,'holes');
vyhl_dot=finta_vyhlazeni(double(f_im1),10);             %fce které si stím ještì trošku pohraje, jelikož to nerozširovalo tak jak jsem chtìl
 f_im2 = imfill(f_im1,'holes');

SE=strel('disk',2);
vyhl = imerode(f_im2,SE);                               %vyhlazení hran objektù

figure
imshow(vyhl);

test= filter2(fspecial('average',20),abs(fim),'same');              %zprùmìrování do masky pro watershed
test=test.*5;                                                       %úprava hodnot
test(vyhl==0)=0;                                                    %apliakce masky na vyhlazený binární obraz

figure
imshow(test,[]);

D = -bwdist(~test);
maska = imextendedmin(D,2);
D2 = imimposemin(D,maska);
Ld2 = watershed(D2);
bw3 = test;                                                 %watershed (ten co byl v tom odkazu)
bw3(Ld2 == 0) = 0;                                          %teï to koneènì funguje
figure;
imshow(bw3)


boundaries = bwboundaries(bw3);                             %ohranièení objektù

% figure
% imshow(im(5:size(im,1),5:size(im,2)));                   
% hold on;
% % b = boundaries{203};
% % bb = imfill(b);
% % plot(bb(:,2),bb(:,1),'g','LineWidth',3);
% for k=1:length(boundaries)
%        b = boundaries{k};
% %        bb = imfill(b,'holes');                              %vykreslení obrázku s ohranièením bunìk
% %        B=bwareaopen(b,10);
% %        BB = imerode(f_im2,strel('disk',1));
%    plot(b(:,2),b(:,1),'g','LineWidth',2);
% end

% figure
% imshow(im(1:size(im,1)-5,1:size(im,2)-5));                   
% hold on;

%ještì to chce lépe vyhladit,zbavit se bordelu, není to úplnì dokonalé
im_bin2=zeros(size(im,1)-5,size(im,2)-5);
out = bound_finta( boundaries,100,size(bw3));           %pofintìní hranic objektù
for k=1:length(out)
       B = out{k};
      plot(B(:,2)+5,B(:,1)+5,'r','LineWidth',2);
      im_bin=zeros(size(im,1)-5,size(im,2)-5);
      for j=1:1:size(B,1)
        im_bin(B(j,1),B(j,2))=1;
      end
      im_bin = imfill(im_bin,'holes');
      im_bin=im_bin*k;
      im_bin2=im_bin2+im_bin;
end
% figure;
% imshow(im_bin2,[]);
% figure;
% imshow(im_maska(1:size(im,1)-5,1:size(im,2)-5)-im_bin);

J = imcomplement(im_maska(1:size(im,1)-5,1:size(im,2)-5));
SE=strel('disk',1);
dil_J = imdilate(J,SE);
dil_J = imcomplement(dil_J);
%dil_J = imfill(dil_J,'holes');
boundaries_maska = bwlabel(dil_J);
boundaries_m = bwboundaries(boundaries_maska);

% for k=1:length(boundaries_m)
%        B = boundaries_m{k};
%       plot(B(:,2),B(:,1),'b','LineWidth',2);
% end
% 
% hold off

score=zeros(1,max(max(boundaries_maska)));
for i=1:1:max(max(boundaries_maska))
    for j=1:1:max(max(im_bin2))
        p=zeros(size(im_bin2));
        s=zeros(size(im_bin2));
        p(boundaries_maska==i & im_bin2==j)=1;
        s(boundaries_maska==i | im_bin2==j)=1;
        pom_score = sum(sum(p))/sum(sum(s));
       if pom_score > 0.5
           if pom_score > score(i)
            score(i)=pom_score;
           end
       end 
    end
end

SCORE=mean(score);