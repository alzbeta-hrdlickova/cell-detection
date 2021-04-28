function [ out ] = finta_vyhlazeni( vyhl, delka )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


   for j=(delka+1):1:(size(vyhl,1)-delka-1)
       for k=(delka+1):1:(size(vyhl,2)-delka-1)
           if vyhl(j,k)==1
               pp1=vyhl(j,k:k+delka);          %  *-->
               pp2=vyhl(j,k-delka:k);          %  <--*
               pp3=vyhl(j:j+delka,k);            %  *nahoru
               pp4= vyhl(j-delka:j,k);           %  *dolu
           
               p1=find(pp1==1);
               p2=find(pp2==1);
               p3=find(pp3==1);
               p4=find(pp4==1);
               
               if isempty(p1)==0||p1(end)==1
               vyhl(j,k:p1(end))=1;
               end
               if isempty(p2)==0||p2(1)==delka+1
               vyhl(j,(k-delka+p2(1)-1):k)=1;
               end
               if isempty(p3)==0||p3(end)==1
               vyhl(j:p3(end),k)=1;
               end
               if isempty(p4)==0||p4(1)==delka+1
               vyhl((j-delka+p4(1)-1):j,k)=1;
               end
           end

       end
   end

out=vyhl;
end

