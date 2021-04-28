clear all;
close all;
clc;

% pp=1;
% p=[0.25 0.5 0.75];
% finta_v=[10 20 30];
% finta_b=[100 200 300];
% for j=1:1:length(p)
%     for k=1:1:length(finta_v)
%         for l=1:1:length(finta_b)
%                 sc_text(pp,:)=[p(j) finta_v(k) finta_b(l)]
%                 parfor i=1:1:11
%                     a=['dic' num2str(i) '.tif'];
%                     A=['dic' num2str(i) '_maska.png'];
%                     im=im2double(imread(a)); 
%                     im_maska=im2double(imread(A));
%                     score(pp,i+1)= detekce(im,im_maska,p(j),finta_v(k),finta_b(l));
%                 end
%             pp=pp+1
%         end
%     end
% end
%********nejlešpí výsledek pro p(1),finta_v(1),finta_b(1)*************



for i=1:1:11
                    a=['dic' num2str(i) '.tif'];
                    A=['dic' num2str(i) '_maska.png'];
                    im=im2double(imread(a)); 
                    im_maska=im2double(imread(A));
                    score(i)= detekce(im,im_maska);
end

score

% 
% a=['dic' num2str(9) '.tif'];
% A=['dic' num2str(9) '_maska.png'];
% im=im2double(imread(a)); 
% im_maska=im2double(imread(A));
% score= detekce(im,im_maska);
