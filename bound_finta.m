function [ out ] = bound_finta( B,min,s )
% B{} - cell boundaries
% min - minimální délak hranic
% s=[x y] - velikost obrazu
PP=size(B,1);
pp=0;
u=0;
while PP>pp
    PP=size(B,1);
        k=1;
        
        for i=1:1:size(B,1)
            b=B{i};
            if size(b,1)>min
                obr=zeros(s(1),s(2));
                for j=1:1:size(b,1)
                    obr(b(j,1),b(j,2))=1;
                end
                
                    SE=strel('disk',4);
                    obr = imdilate(obr,SE);
                    obr=bwareaopen(obr,300);
                    obr = imfill(obr,'holes');
                    SE=strel('diamond',3);
                    obr = imerode(obr,SE);
                    o{k} =  bwboundaries(obr); 
                    
                    if size(o{k},1)>1
                        z=o{k};
                      for finta_p=1:1:size(o{k},1) 
                            Z=z{finta_p,1};
                         if size(Z,1)>min
                            o{k+u}=z(finta_p,1);
                            u=u+1;
                         end
                      end
                    end
                    
                    if u==0
                    k=k+1;
                    elseif u>0
                      k=k+u;
                      u=0;
                    end
                    
            end
        end
o = o(~cellfun('isempty', o));

        B=o;
        pp=size(B,1);
end

for l=1:1:length(o)
   z=o{1,l}; 
   Z=z{1,1};
   out{l,1}=Z;
end

end
