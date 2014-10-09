function []=ClickTrace()
% function to plot click in a file
% written by Marianne Marcoux
% Sept 23 2014
%
global afile iffn ife
close all; 
clear all;
xy=[];
bfile=uigetdir('E:\clics\marianne\test_file', 'Choose the folder where to input is');
afile=strcat(bfile, '/');
newdir=cd(afile);
savefld=uigetdir(bfile, 'Choose folder where to save output');
savedir=strcat(savefld, '/*.txt');
%savedir=strcat(afile, '/*.txt');
outfiles = dir(savedir);
outfile={outfiles(:).name};
nomout=size(outfile);
qqn=dir('*.wav');
iffn={qqn.name};
ife=1;
out = struct([]);
numofsound=size(iffn);
for i=1:numofsound(2)
    %soundnames{i}=iffn{ife};
    disp(['File '  iffn{i}]);
    [y, Fs, nbits] = wavread(qqn(i).name);
    scrsz = get(0,'ScreenSize');
    s.fh=figure('OuterPosition', [0 10 1000 750]);
    set(s.fh,'Renderer','painters');
    S.pb1 = uicontrol('Style','pushbutton','String','Horiz. zoom',...
        'Position',[20 620 80 40], 'callback', {@zoomr} );
    S.pb2 = uicontrol('Style','pushbutton','String','Zoom back',...
        'Position',[20 580 80 40], 'callback', {@zoomb} );
    S.pb2 = uicontrol('Style','pushbutton','String','Pan',...
        'Position',[20 540 80 40], 'callback', {@main} );
    S.pb4 = uicontrol('Style','pushbutton','String','Get clicks',...
        'Position',[20 480 80 40], 'callback', {@points} );
    S.pb5 = uicontrol('Style','pushbutton','String','Save clicks',...
        'Position',[20 440 80 40], 'callback', {@saveclick} );
    S.pb6 = uicontrol('Style','pushbutton','String','Id trains',...
        'Position',[20 260 80 40], 'callback', {@trains} );
     S.pb7 = uicontrol('Style','pushbutton','String','Save train',...
        'Position',[20 220 80 40], 'callback', {@savetrain} );
    S.pb8 = uicontrol('Style','pushbutton','String','Look at signal',...
        'Position',[20 140 80 40], 'callback', {@signal} );
    S.pb9 = uicontrol('Style','pushbutton','String','Play!',...
        'Position',[20 60 80 40], 'callback', {@playb} );
    
    myhandles = guihandles( s.fh);
    myhandles.y=y;
    myhandles.Fs=Fs;
    myhandles.savefld=savefld;
    myhandles.xy=xy;
    guidata(s.fh, myhandles);
    [Y,F,T,P] =spectrogram(y, 256, 250,256, Fs, 'yaxis');
    imagesc(T,F,10*log10(abs(P))); %plot spectrogram
    axis xy; axis tight; colormap(jet); view(0,90);
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    helpdlg('Use the left mouse to select point, "u" to undo and "e" to end. Then press save clicks','Point Selection');
    %     title('Use the left mouse to select point, "u" to undo and "e" to end','fontsize',12,'fontweight','b');
    colorbar
    %xticks=get(gca,'XTick');
    %xlabels=get(gca,'XTickLabel');
    hold on
    title([iffn{ife}]);
    %title('Spectrogram');
    
   waitfor(s.fh)
   ife=ife+1;  
end

    function []=zoomr(varargin) %horizontal zoom
        h = zoom;
        set(h,'Motion','horizontal','Enable','on');
        guidata(gcbo,myhandles) 
    end

    function []=zoomb(varargin) %zoom out
%         h = zoom;
%         set(h, 'Direction','out','Enable','on');
         zoom out
        guidata(gcbo,myhandles)
    end

    function []=main(varargin) %pan
        pan xon
        guidata(gcbo,myhandles)
    end

    function []=points(varargin) %pick clicks
        myhandles = guidata(gcbo);
        xy=myhandles.xy;
        zoom off
        but=1;
        n= size(xy, 1)+1;
        while but ~= 101 && but ~= 110;
            [xi,yi,but] = ginput(1); % pick where to put an horizontal line
            if but == 117
                 xy(n-1,:) = [];
                delete(point);
%                 delete(l);
                 n=n-1;
            elseif but == 1
                point=plot(xi,yi,'ko');
                xy(n,:) = [xi;yi];
                n = n+1;
            end
        end
        drawnow;
            myhandles.xy=xy;
            guidata(gcbo,myhandles) 
    end

    function []=saveclick(varargin) % function to save detections
        myhandles = guidata(gcbo);
        xy=myhandles.xy;
        x1=xy(:,1);
        savefile=[savefld, '\', qqn(ife).name, '.txt'];
        fileID = fopen(savefile,'w');
        fprintf(fileID,'%8s\n','x1');
        for j=1:length(x1);
            fprintf(fileID,'%8.4f\n',x1(j));
        end
    end

    function []=trains(varargin) % function to identify trains
        myhandles = guidata(gcbo);
        xy=myhandles.xy;
        haxes1 = gca; % handle to axes
        haxes1_pos = get(haxes1,'Position'); % store position of first axes
        haxes1_Xlim = get(haxes1,'Xlim');
        haxes1_Ylim = get(haxes1,'Ylim');
        haxes2 = axes('Position',haxes1_pos,'Color','none', 'Xlim',haxes1_Xlim, 'Ylim', haxes1_Ylim);
        linkaxes([haxes1 haxes2],'xy');
        x1=xy(:,1);
        y1=xy(:,2);
        hold on
        plot(x1, y1, 'bo') % replot points to be used for data cursor
        %        hbox=msgbox('Select all clicks from first train.'\n 'Press «e» when you are done');
        prompt = {'Please provide an ID for the train. Select all the clicks from one train (use «Alt» to select multiple clicks). Click «Cancel» if you are done all the trains. Click «Save train» to save.'};
        answer = inputdlg(prompt);
            dcm_obj = datacursormode(gcf);
            set(dcm_obj,'DisplayStyle','datatip','SnapToDataVertex','on','Enable','on');
            myhandles.dcm_obj=dcm_obj;
            myhandles.answer=answer;
            guidata(gcbo,myhandles)
    end

    function []=savetrain(varargin)
    myhandles = guidata(gcbo);
    dcm_obj=myhandles.dcm_obj;
    answer=myhandles.answer;
    savefld= myhandles.savefld;
        info_struct = getCursorInfo(dcm_obj);
        xloc= [arrayfun(@(x) (x.Position(1)),info_struct)];
        sfld=savefld;
        nfld=iffn{ife};
        savefiletrain=strcat(sfld, '\', nfld, '_', answer, '.txt');
        fileID = fopen(char(savefiletrain),'w');
        fprintf(fileID,'%8s %8s\n','x1', 'train_id');
        for j=1:length(xloc);
            fprintf(fileID,'%8.4f %8s\n',xloc(j), answer{1});
        end
        fclose(fileID);
        delete(findall(gca,'Type','hggroup','HandleVisibility','off'));
    end

%playback when button is pushed
function []=playb(y,Fs) 
myhandles = guidata(gcbo);
y=myhandles.y;
Fs=myhandles.Fs;
wavplay(y, Fs, 'async')
end
      
%open a new figure to investigate signal of each click
    function []=signal(varargin)
        myhandles = guidata(gcbo);
        xy=myhandles.xy;
        y=myhandles.y;
        savefld= myhandles.savefld;
        x1=xy(:,1);
        numofclicks=length(x1);
        clickends=[];
        for i=1:numofclicks
            h2=figure('OuterPosition', [0 10 1265 750]);
            set(h2,'Renderer','painters');
            minplot=(x1(i)*Fs)- 600;
            maxplot=(x1(i)*Fs)+ 1000;
            rangeplot=fix(minplot):fix(maxplot);
            plot(1:length(rangeplot), y(rangeplot), '-k');
            axis tight;
            title('Click to select beginnig and end of click');
            [start,dump]=ginput(2);
            hold on
            plot([start(1) start(1)],get(gca,'ylim'));
            plot([start(2) start(2)],get(gca,'ylim'));
            button= questdlg('Okay to save and move to next click?','Done?','save','redo', 'save');
            while sum(button) == 426 %if answer is redo
                [start,dump]=ginput(2);
                button= questdlg('Okay to save and move to next click?','Done?','save','redo', 'save');
            end
            if sum(button) == 431 %if answer is "save", save and move to new file
                close(h2)
                sample_start=fix(minplot)+round(start);% provide the time start in second
                time_start=sample_start/Fs;
                clickends(i,1:2)=time_start'; %save in matrix
            end
            waitfor(h2)
        end
        % save starts and ends in a .txt file
        sfld=savefld;
        nfld=iffn{ife};
        savefileends=strcat(sfld, '\', nfld, '_ends', '.txt');
        fileID = fopen(char(savefileends),'w');
        fprintf(fileID,'%8s %8s\n','start_sec', 'end_sec');
        for j=1:size(clickends,1);
            fprintf(fileID,'%8.4f %8.4f\n',clickends(j,1), clickends(j,2));
        end
        fclose(fileID);
    end

end