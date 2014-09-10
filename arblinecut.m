function [] = arblinecut(plothandle)
%ARBLINECUT Mouse-controlled method for creating linecuts in an arbitrary
%direction through 2D data
%   ARBLINECUT(H) enables mouse selection of an arbitrary line through a
%   pcolor or image plot. Data along this line is interpolated and plotted
%   in a new figure. H is the handle to a valid plot object. Once
%   ARBLINECUT is called, click on the plot at one endpoint of the desired
%   linecut and drag to the other endpoint, then release. Each mouse click
%   will produce a new linecut.
%
%   With the main plot figure in focus, press the backspace key to delete
%   all drawn lines and open linecut windows. Press the x or y key to set
%   the bottom axis of all ensuing linecut plots to x or y. Press the
%   return key or right click on the main figure in order to stop
%   ARBLINECUT.

%   Patrick Maher
%   v1.0 9/10/14

hand.mainplot=plothandle;
hand.interpaxis='x'; %bottom axis values for linecut plots
hand.mainax=get(hand.mainplot,'Parent');
hand.mainfig=get(hand.mainax,'Parent');
hand.colord=get(hand.mainax,'ColorOrder');
hand.Xdata=get(hand.mainplot,'Xdata');
hand.Ydata=get(hand.mainplot,'Ydata');
hand.counter=0; %for tracking color of lines
hand.linehands=[]; hand.fighands=[];

if strcmp(get(hand.mainplot,'Type'),'image') %if object is an image
    hand.Zdata=get(hand.mainplot,'Cdata'); 
    if length(size(hand.Zdata))>2
        error('RGB data not supported');
    end
    hand.plottype='image';
    %make sure X and Y data are the right size
    if length(hand.Xdata)==1
        hand.Xdata=hand.Xdata:(hand.Xdata+size(hand.Zdata,2)-1);
    else
        hand.Xdata=linspace(hand.Xdata(1),hand.Xdata(end),size(hand.Zdata,2));
    end
    if length(hand.Ydata)==1
        hand.Ydata=hand.Ydata:(hand.Ydata+size(hand.Zdata,1)-1);
    else
        hand.Ydata=linspace(hand.Ydata(1),hand.Ydata(end),size(hand.Zdata,1));
    end
elseif all(all(get(hand.mainplot,'Zdata')==0)) %if object is pcolor
    hand.Zdata=get(hand.mainplot,'Cdata');
    hand.plottype='pcolor';
else
    error('Unsupported object type');
end

set(hand.mainfig,'WindowButtonDownFcn',@MouseDown,'WindowButtonUpFcn',@MouseUp,'KeyPressFcn',@KeyPress);
guidata(hand.mainfig, hand);
end

function MouseDown(src,eventData)
hand=guidata(src);
clickType = get(src, 'SelectionType');
if strcmp(clickType,'alt') %right click, stop process
    set(hand.mainfig,'WindowButtonDownFcn',{},'WindowButtonUpFcn',{},'KeyPressFcn',{});
else
    point=get(hand.mainax,'CurrentPoint');
    hand.origx=point(1,1); hand.origy=point(1,2);
    hand.linehands(end+1)=line([hand.origx hand.origx], [hand.origy hand.origy]);
    set(hand.linehands(end),'Color',hand.colord(mod(hand.counter,size(hand.colord,1))+1,:),'LineWidth',2);
    guidata(hand.mainfig,hand);
    set(hand.mainfig,'WindowButtonMotionFcn',@MouseMove);
end
end

function MouseMove(src,eventData)
hand=guidata(src);
point=get(hand.mainax,'CurrentPoint');
set(hand.linehands(end),'XData',[hand.origx point(1,1)]);
set(hand.linehands(end),'YData',[hand.origy point(1,2)]);
end

function MouseUp(src,eventData)
hand=guidata(src);
set(hand.mainfig,'WindowButtonMotionFcn',{});
xdata=get(hand.linehands(end),'XData');ydata=get(hand.linehands(end),'YData');
interp_pts=200; %reasonable number of points for most plots
arbxaxis=linspace(xdata(1),xdata(2),interp_pts);
arbyaxis=linspace(ydata(1),ydata(2),interp_pts);
%use griddata rather than interp2 in case data is irregular
arbline=griddata(hand.Xdata,hand.Ydata,hand.Zdata,arbxaxis,arbyaxis);
hand.fighands(end+1)=figure;
if strcmpi(hand.interpaxis,'x')
    arbaxis=arbxaxis;
elseif strcmpi(hand.interpaxis,'y')
    arbaxis=arbyaxis;
end
plot(arbaxis,arbline,'Color',hand.colord(mod(hand.counter,size(hand.colord,1))+1,:));
hand.counter=hand.counter+1; %cycle to next color
guidata(hand.mainfig, hand);
p=polyfit(xdata,ydata,1); %find the equation of the drawn line
title(['y = ' num2str(p(1)) 'x + ' num2str(p(2))]);
end

function KeyPress(src,eventData)
hand=guidata(src);
key=eventData.Key;
switch key
    case 'backspace'
        hand.fighands=hand.fighands(ishandle(hand.fighands));
        hand.linehands=hand.linehands(ishandle(hand.linehands));
        delete([hand.linehands hand.fighands]);
        hand.linehands=[]; hand.fighands=[];
        hand.counter=0;
    case 'x'
        hand.interpaxis='x';
    case 'y'
        hand.interpaxis='y';
    case 'return'
        set(hand.mainfig,'WindowButtonDownFcn',{},'WindowButtonUpFcn',{},'KeyPressFcn',{});
end
guidata(hand.mainfig,hand);
end