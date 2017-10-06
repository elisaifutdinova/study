function marks = visualizeEverything(params)

% visualisation signals script

% input - params - a data structure consisting of
% data (requered) - MxN matrix, M is number of channels and N is length of data
% pwd - directory path  - return to that directory after exection
% title - string - title of visualization
% fsamp - int - frequency sample 
% xshift - float - from where (in seconds, not samples) we should start to
% observe the data
% labels -  matrix (?)  - each row is a name of channel  
% coef - float - multiplies the signal by this number   
% positions - array - positions from where signals should start
% elements - matrix Nx2 - marked events, every row is a pair (start, duration)
% borders - array - array of labeled borders between segments

% for exit close the visualization window
% output - matrix Nx2 - exach row is a pair (start, duration) in seconds of labeled
% events

% controlling
% left-right bottons - go to the left and to the right
% up-down - decrease-increase twise length of the window
% single click  - make a border to start event, the second single
% click make an end of the event and the labeled event is created
% esc - delete the last event


%change the directory
if isfield(params, 'pwd')
    cd(params.pwd)
end

if ~isfield(params, 'data')
    disp('there is no data to plot');
    return
end

global marks curr YLim;
curr = 0;
marks  = [];

% get signal data: n by x matrix:
%n signals by x values
data = params.data;
DNUM = length(data(:,1));



title = '';
if isfield(params, 'title')
    title = params.title;
end

%get x 
x = 1:length(data(1, :));
if isfield(params, 'xshift')
    x = x+params.xshift;
end
if isfield(params, 'fsamp')
    x = x/params.fsamp;
end

%get labels
labels = 1:DNUM;
if isfield(params, 'labels')
    labels = params.labels;
end
labels = char(labels);

% get coef
coef = 1;
if isfield(params, 'coef')
    coef = params.coef;
end
    
%get positions
positions = zeros(1, DNUM);
if ~isfield(params, 'positions')
    for i = 2:DNUM
        positions(i) = positions(i-1) + abs(max(data(i-1, :))) + abs(min(data(i, :)));
    end   
else
    positions = params.positions*coef;
end   





hposition = max(data(end, :))*coef + positions(end);
lposition = min(data(1, :));
YLim = [lposition hposition];
XLim = [x(1), x(1) + 30];

fig = figure('units','normalized',...
        'outerposition',[0 0 1 1],...
        'MenuBar', 'none',...
        'NumberTitle', 'off',...
        'Name', title,...
        'KeyPressFcn', @dispkeyevent);

axes('Units','pixels',...
    'Box','on',...   
    'NextPlot', 'add',...
    'Tag','axMain', 'XLim', XLim, 'YLim', YLim);
set(gca, 'ButtonDownFcn', @btndownfunc);
set(gca, 'YTick', positions);
set(gca, 'YTickLabel', labels);
grid on
hold on

for i = 1:DNUM
    plot(x, positions(i) + data(i, :)*coef);
end

%borders
if isfield(params, 'borders') && ~isempty(params.borders)
    y = [YLim(1)+50, YLim(2)-100];
    for b = params.borders
        plot([b, b], y, '--r' );
    end
end

% elements: n by 2 matrix
% n elements with2 parameters: startand duration
if isfield(params, 'elements') && ~isempty(params.elements)
    y = [YLim(1)+100, YLim(2)-100];
    y = [y fliplr(y)];
    for i = 1:length(params.elements(:,1))
        st = params.elements(i,1);
        en = params.elements(i,1) + params.elements(i,2);
        x = [st, st, en, en];
        fill(x, y, 'magenta', 'FaceAlpha', 0.3);
    end
end
    
hold on;
uiwait(fig);     
    
function btnRight_Callback (src, evt)
handles = guihandles(src);
lims = get(handles.axMain,'XLim');
set(handles.axMain, 'XLim', lims+0.75*(lims(2)-lims(1)))

function btnLeft_Callback (src, evt)
handles = guihandles(src);
lims = get(handles.axMain,'XLim');
set(handles.axMain, 'XLim', lims-0.75*(lims(2)-lims(1)))

function btnBigger_Callback (src, evt)
handles = guihandles(src);
lims = get(handles.axMain,'XLim');
set(handles.axMain, 'XLim', [lims(1), lims(1) + (lims(2) - lims(1))*2])

function btnLess_Callback (src, evt)
handles = guihandles(src);
lims = get(handles.axMain,'XLim');
set(handles.axMain, 'XLim', [lims(1), lims(1) + (lims(2) - lims(1))/2])

function btnEsc_Callback (src, evt)
global marks  curr;
marks  = marks(1:end-1, :);
children = get(gca, 'children');
delete(children(1));
delete(children(2));

function dispkeyevent (src, evt)
c = evt.Key;
if strcmp(c, 'rightarrow')
    btnRight_Callback (src, evt);
elseif strcmp(c, 'leftarrow')
    btnLeft_Callback (src, evt);
elseif strcmp(c, 'uparrow')
    btnBigger_Callback (src, evt);
elseif strcmp(c, 'downarrow')
    btnLess_Callback (src, evt);
elseif strcmp(c, 'escape')
    btnEsc_Callback (src, evt);
end


function closefunc(src, evt)
global spindels xshift;
%set(src,'Position',[1 1 1680 1050]);
%saveas(src,'image','bmp'); 
%print(src,'image.png');
uiresume(src);
delete(src);


function btndownfunc(~, ~, ~)
global marks curr YLim;
point = get(gca, 'CurrentPoint');
point = point(1, 1);
if curr == 0
    curr = point;
    line([point point], YLim, 'Color', 'magenta');
else
    x = [curr curr point point];
    y = [YLim fliplr(YLim)];
    fill(x, y, 'yellow', 'FaceAlpha', 0.3);
    marks  = [marks ; [curr, point-curr]];
    curr = 0;
end
