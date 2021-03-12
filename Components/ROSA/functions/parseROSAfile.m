function rosadata=parseROSAfile(filepath)

    rosadata=struct('displays',{},'ATFormRAS',nan(4,4),'Trajectories',{});
    rosadata(1).ATFormRAS=[-1 0 0 0;
                            0 -1 0 0;
                            0 0 1 0;
                            0 0 0 1];% we know the transformation from ROSA to RAS 
    textfile=fileread(filepath);
    tokens=extractTokens(textfile);
    for i=1:length(tokens)
        switch(tokens(i).token)
            case 'TRdicomRdisplay' % we assume that TRdicomRdisplay is followed by a VOLUME tag
                if(strcmp(tokens(i+1).token,'VOLUME'))
                    rosadata.displays(end+1)=createDisplay(tokens(i).content,tokens(i+1).content);
                    i=i+1; %skip next token since it is already processed
                else
                    error('Malformed rosa file, dont know how to proceed');
                end
            case 'ELLIPS'
                    traj=createTrajectory(tokens(i).content);
                    if(~isempty(traj)) 
                        rosadata.Trajectories(end+1)=traj;
                    end
            case 'TRAJECTORY'
                    traj=createTrajectory(tokens(i).content);
                    if(~isempty(traj)) 
                        rosadata.Trajectories(end+1)=traj;
                    end
        end
        
        
    end
    
end



function display=createDisplay(str_dsp,str_volume)
    display=struct('volume',strrep(strtrim(str_volume),'\','/'),'ATForm',nan(4,4));
    c=strsplit(str_dsp,'\n');
    c=removeNonNumericCells(c); %remove non numeric cells
    %we can ignore cell 1
    tokens=split(c{2},' ');
    tokens=removeNonNumericCells(tokens);
    display.ATForm=reshape([cellfun(@str2num,tokens)],4,4)';
    %first line in string 
end

function c=removeNonNumericCells(c)
    c(cellfun(@(x) isempty(str2num(x)),c)) = [];
end

function [traj,N]=createTrajectory(str)
    try
        traj=struct('name','','start',nan(3,1),'end',nan(3,1));
        c=strsplit(str,'\n');
        c=cellfun(@(x)strtrim(x),c,'UniformOutput',false);
        c(cellfun('isempty',c))=[];
        N=str2num(c{1});
        tokens=split(c{2},' ');
        tokens(cellfun('isempty',tokens))=[];
        traj.name=tokens{1};
        traj.start=[str2num(tokens{5}) str2num(tokens{6}) str2num(tokens{7})];
        traj.end=[str2num(tokens{9}) str2num(tokens{10}) str2num(tokens{11})];
    catch
        traj=[];
            N=nan;
    end
end

function tokens=extractTokens(textfile)
%token starts with [%%tokenname%%]
%tokens are in an line
%ends before next []
    tokens=struct('token','','content','');
    [starti,endi]=regexp(textfile,'\[(.*?)\]');
    for i=1:length(starti)-1 %last token should be [END]
        tokens(i).token=textfile(starti(i)+1:endi(i)-1);
        tokens(i).content=textfile(endi(i)+1:starti(i+1)-1);
    end
    
end

