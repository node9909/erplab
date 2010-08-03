%
% Author: Javier Lopez-Calderon & Steven Luck
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

%b8d3721ed219e65100184c6b95db209bb8d3721ed219e65100184c6b95db209b
%
% ERPLAB Toolbox
% Copyright � 2007 The Regents of the University of California
% Created by Javier Lopez-Calderon and Steven Luck
% Center for Mind and Brain, University of California, Davis,
% javlopez@ucdavis.edu, sjluck@ucdavis.edu
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function varargout = basicfilterGUI2(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
      'gui_Singleton',  gui_Singleton, ...
      'gui_OpeningFcn', @basicfilterGUI2_OpeningFcn, ...
      'gui_OutputFcn',  @basicfilterGUI2_OutputFcn, ...
      'gui_LayoutFcn',  [] , ...
      'gui_Callback',   []);
if nargin && ischar(varargin{1})
      gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
      [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
      gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%--------------------------------------------------------------------------
function basicfilterGUI2_OpeningFcn(hObject, eventdata, handles, varargin)

warning('off','MATLAB:dispatcher:InexactMatch')
warning('off','MATLAB:dispatcher:InexactCaseMatch')

ERPLAB    = varargin{1};
colorband = [0.9922    0.9176    0.7961];
handles.colorband = colorband;

if iserpstruct(ERPLAB) % for erpset
      chanArray = 1:ERPLAB.nchan;
      typedata = 'ERP';
      set(handles.checkbox_removedc, 'Visible', 'on')
      set(handles.checkbox_removedc, 'Value', 0)
      set(handles.checkbox_removedc, 'String', 'Remove mean value (DC bias) before filtering (not usually appropriate for baseline-corrected data)')
      set(handles.checkbox_removedc, 'Enable', 'off')
      set(handles.checkbox_boundary, 'Visible', 'off')
      set(handles.edit_boundary,'Visible', 'off');
      set(handles.text_boundary,'Visible', 'off');
      highpasscutoff = 0;
      minboundarysamdist = inf;
else
      chanArray = 1:ERPLAB.nbchan;
      
      if isempty(ERPLAB.epoch) % for continuous dataset
            set(handles.checkbox_boundary, 'Enable', 'on')
            set(handles.checkbox_boundary, 'Value', 1)
            set(handles.edit_boundary,'Enable', 'on');
            set(handles.edit_boundary,'BackgroundColor', [1 1 1]);
            label1 = '<HTML><left>Apply filter to segments defined';
            label2 = '<HTML><left>by boundary events (Strongly Recommended)';
            set(handles.checkbox_boundary, 'string',[label1 '<br>' label2]);
            set(handles.edit_boundary, 'string', '''boundary''');
            set(handles.checkbox_removedc, 'Value', 1)
            highpasscutoff = 0.1;
            typedata = 'continuous EEG';
            minboundarysamdist = boundarydistance(ERPLAB.event);
            
            
      else  % for epoched dataset
            set(handles.checkbox_boundary, 'Value', 0)
            set(handles.checkbox_boundary, 'Enable', 'off')
            set(handles.edit_boundary, 'string', '');
            set(handles.edit_boundary,'Enable', 'off');
            set(handles.edit_boundary,'BackgroundColor', [0.75 0.75 0.75]);
            label1 = '<HTML><font color=#808080 ><left>Apply filter to segments defined</font>';
            label2 = '<HTML><font color=#808080 ><left>by boundary events (Strongly Recommended)</font>';
            set(handles.checkbox_boundary, 'string',[label1 '<br>' label2]);
            set(handles.text_boundary,'Enable', 'off');
            set(handles.checkbox_removedc, 'String', 'Remove mean value (DC bias) before filtering (not usually appropriate for baseline-corrected data)')
            set(handles.checkbox_removedc, 'Value', 0)
            set(handles.checkbox_removedc, 'Enable', 'off')
            highpasscutoff = 0;
            typedata = 'epoched EEG';
            minboundarysamdist = inf;
            
      end
end

fs    = ERPLAB.srate;
fnyq  = fs/2;
handles.minboundarysamdist = minboundarysamdist;
handles.maxsliders = fnyq-1;
handles.output  = [];
handles.ERPLAB  = ERPLAB;
handles.fs      = fs;
handles.xmaxfreqr   = [0 100];
handles.xmaxpimpz   = [0 100];
handles.valhp   = '0';
handles.vallp   = '0';
handles.iswarngain = 0;
handles.iswarnroff = 0;
handles.ishopermission = 0;  % high order permission (butterworth)
handles.autorder = 0;
handles.datafr.chan = [];
handles.datafr.ym   = [];
handles.datafr.yf   = [];
handles.datafr.f    = [];

%
% Name & version
%
version = geterplabversion;
set(handles.figure1,'Name', ['ERPLAB BETA ' version '   -   Basic Filter GUI for ' typedata])

%
% Prepare List of current Channels
%
listch = [];
nchan  = length(chanArray); % Total number of channels

if isempty(ERPLAB.chanlocs)
      for e = 1:nchan
            ERPLAB.chanlocs(e).labels = ['Ch' num2str(e)];
      end
end

for ch =1:nchan
      listch{ch} = [num2str(ch) ' = ' ERPLAB.chanlocs(ch).labels ];
end

set(handles.edit_channels,'String', vect2colon(chanArray, 'Sort', 'no', 'Delimiter','no'))
set(handles.popupmenu_channels,'String', listch)
ordervector = 2:2:8;
set(handles.popupmenu_order,'String', char([{'automin'}; cellstr(num2str(ordervector'))])) % set order list
set(handles.popupmenu_order,'Value', 2);
set(handles.popupmenu_dboct,'String', num2str(6*ordervector')) % set db/oct list
set(handles.popupmenu_dbdec,'String', num2str(20*ordervector')) % set db/dec list
set(handles.radiobutton_freqr,'Value', 1);
set(handles.radiobutton_impr,'Value', 0);

%
% Slider memory
%
if fnyq>30
      lowpasscutoff  = 30;
      handles.mvaluel= 30; % initial value lowpass
else
      lowpasscutoff  = round(handles.maxsliders*5)/10;
      handles.mvaluel= round(handles.maxsliders*5)/10;
end

handles.memvaluel = 30;
handles.memvalueh = 0.1;
handles.morder  = 2;
handles.mem6dbl = '---';
handles.mem6dbh = '---';
handles.mem3dbl = '---';
handles.mem3dbh = '---';

%
% Causality (pending)
%
set(handles.noncausal,'Value',1); % only noncausal, for now.
set(handles.causal,'Value',0);
set(handles.causal,'Enable','off');
set(handles.edit_highpass, 'String', num2str(highpasscutoff));
set(handles.edit_lowpass,  'String', num2str(lowpasscutoff));
set(handles.edit_highpass, 'BackgroundColor', [1 1 1]);
set(handles.edit_lowpass,  'BackgroundColor', [1 1 1]);
slider_step(1) = 0.1/handles.maxsliders;
slider_step(2) = 0.5/handles.maxsliders;
set(handles.slider_highpass, 'Value', highpasscutoff, 'Max', handles.maxsliders, 'Min', 0, 'SliderStep', slider_step)
set(handles.slider_lowpass,  'Value', lowpasscutoff, 'Max', handles.maxsliders, 'Min', 0, 'SliderStep', slider_step)
chanArraystr   = vect2colon(chanArray, 'Delimiter', 'no');
set(handles.edit_channels, 'String', chanArraystr)
tooltip1 = '<html><i>Cutoff frequency = frequency where the magnitude<br>response of the filter is either 0.5 (-6dB) or 0.707 (-3dB)';
tooltip2  = ['<html><i>The filter does not attenuate all frequencies outside the desired frequency range completely;<br>'...
      'in particular, there is a region just outside the intended passband where frequencies are attenuated,<br>'...
      'but not rejected. This is known as the filter roll-off, and it is usually expressed in dB of attenuation<br>'...
      'per octave or decade of frequency. In general, the roll-off for an order-n filter is 6n dB per octave or<br>'...
      '20n dB per decade.'];

set(handles.edit_tip_cutoff, 'tooltip',tooltip1);
set(handles.edit_tip_rolloff, 'tooltip',tooltip2);

if highpasscutoff== 0
      set(handles.togglebutton_highpass, 'Value',0);
      set(handles.togglebutton_highpass, 'BackgroundColor', [0.8 0.8 0.75]);
      set(handles.slider_highpass, 'Enable', 'off');
      set(handles.edit_highpass, 'Enable', 'off');
else
      set(handles.togglebutton_highpass, 'Value',1);
      set(handles.togglebutton_highpass, 'BackgroundColor', [1 1 0.5]);
      set(handles.edit_highpass, 'Enable', 'on');
end

set(handles.radiobutton_gaussian,'Enable','off')
set(handles.togglebutton_lowpass, 'Value',1);
set(handles.togglebutton_lowpass, 'BackgroundColor', [1 1 0.5]);
set(handles.popupmenu_FRscale, 'String', {'Linear' 'Decibels'});
      set(handles.popupmenu_FRscale,'Value', 1);
      set(handles.popupmenu_FRscale,'Enable', 'on');




handles.mvalueh = 0.1;             % memory value highpass

% Update handles structure
guidata(hObject, handles);

%
% Color GUI
%
handles = painterplab(handles);

%
% pre-plot
%
plot(1,1)
axis([0 fnyq -0.75 1.25])


plotresponsefilter(hObject, eventdata, handles);

drawnow
% UIWAIT makes str2codeGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);

%--------------------------------------------------------------------------
function varargout = basicfilterGUI2_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);
pause(0.1)

%--------------------------------------------------------------------------
function slider_highpass_Callback(hObject, eventdata, handles)

valueh = get(handles.slider_highpass, 'Value');
valueh = round(valueh*10)/10;

if valueh<0.1;
      valueh = 0;
      set(handles.slider_highpass, 'Value', 0);
end

if get(handles.radiobutton_butter, 'Value');
      typef = 0; % 0 means Butterworth
elseif get(handles.radiobutton_fir, 'Value');
      typef = 1;% 1 means FIR
elseif get(handles.radiobutton_PM_notch, 'Value');
      typef = 2; % 2 means PM Notch
end

posh = get(handles.popupmenu_order,'Value'); % order pop menu current position
autorder = handles.autorder;

%
% FILTER order
%
orderindx  = get(handles.popupmenu_order, 'Value');
orderlist  = cellstr(get(handles.popupmenu_order, 'String'));
order      = str2num(strrep(orderlist{orderindx},'automin:','')); % get rid of auto (in case of)

if isempty(order)
      return
end

tonhp   = get(handles.togglebutton_highpass, 'Value');

if typef==2
      if valueh>=5 && valueh<=handles.maxsliders-5
            set(handles.slider_lowpass, 'Value', valueh);
            valuehstr = sprintf('%.1f', valueh);
            set(handles.edit_highpass, 'String', valuehstr);
      else
            if valueh<5
                  nvaln = 5;
            elseif valueh>handles.maxsliders-5
                  nvaln = handles.maxsliders-5;
            end
            
            nvalstr = sprintf('%.1f',nvaln);
            set(handles.edit_highpass, 'String', nvalstr);
            set(handles.slider_highpass, 'Value', nvaln);
      end
else
      if tonhp
            if valueh==0
                  set(handles.edit_highpass, 'Enable', 'off');
                  set(handles.togglebutton_highpass, 'Value', 0);
                  set(handles.slider_highpass, 'Enable','off');
                  set(handles.edit_highpass, 'String', '0');
                  set(handles.checkbox_removedc, 'Enable', 'off')
                  set(handles.edit_highpass, 'BackgroundColor', [0.75 0.75 0.75]);
                  set(handles.togglebutton_highpass, 'BackgroundColor', [0.8 0.8 0.75]);
            else
                  valuehstr = sprintf('%.1f', valueh);
                  set(handles.edit_highpass, 'String', valuehstr);
                  set(handles.edit_highpass, 'Enable', 'on');
                  set(handles.checkbox_removedc, 'Enable', 'on')
                  set(handles.edit_highpass, 'BackgroundColor', [1 1 1]);
            end
      else
            set(handles.edit_highpass, 'Enable', 'off');
            set(handles.togglebutton_highpass, 'Value', 0);
            set(handles.slider_highpass, 'Enable','off');
            set(handles.edit_highpass, 'String', '0');
            set(handles.checkbox_removedc, 'Enable', 'off')
            set(handles.edit_highpass, 'BackgroundColor', [0.75 0.75 0.75]);
      end
end

if typef==0 && autorder==1
      % order starts again for auto butter
      orderlist  = cellstr(get(handles.popupmenu_order, 'String'));     % whole list
      orderlist{1} = 'automin:2';
      set(handles.popupmenu_order, 'String', orderlist);
      set(handles.popupmenu_order, 'Value',1);
      set(handles.popupmenu_dboct, 'Value',1);
      set(handles.popupmenu_dbdec, 'Value',1);
end

%
% Plot corresponding response
%
if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
      plotresponsefilter(hObject, eventdata, handles);
end


% -------------------------------------------------------------------------
function slider_highpass_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%--------------------------------------------------------------------------
function slider_lowpass_Callback(hObject, eventdata, handles)

valuel = get(handles.slider_lowpass, 'Value');
valuel = round(valuel*10)/10;

if valuel<0.1;
      valuel = 0;
      set(handles.slider_lowpass, 'Value', 0);
end

if get(handles.radiobutton_butter, 'Value');
      typef = 0; % 0 means Butterworth
elseif get(handles.radiobutton_fir, 'Value');
      typef = 1;% 1 means FIR
elseif get(handles.radiobutton_PM_notch, 'Value');
      typef = 2; % 2 means PM Notch
end

autorder = handles.autorder;

%
% FILTER order
%
orderindx = get(handles.popupmenu_order, 'Value');
orderlist = cellstr(get(handles.popupmenu_order, 'String'));
order     = str2num(strrep(orderlist{orderindx},'automin:','')); % get rid of auto (in case of)

if isempty(order)
      return
end

tonlp     = get(handles.togglebutton_lowpass, 'Value');

if tonlp
      if valuel==0
            set(handles.edit_lowpass, 'Enable', 'off');
            set(handles.togglebutton_lowpass, 'Value', 0);
            set(handles.slider_lowpass, 'Enable','off');
            set(handles.edit_lowpass, 'String', '0');
            set(handles.edit_lowpass, 'BackgroundColor', [0.75 0.75 0.75]);
            set(handles.togglebutton_lowpass, 'BackgroundColor', [0.8 0.8 0.75]);
      else
            valuelstr = sprintf('%.1f', valuel);
            set(handles.edit_lowpass, 'String', valuelstr);
            set(handles.edit_lowpass, 'Enable', 'on');
            set(handles.edit_lowpass, 'BackgroundColor', [1 1 1]);
      end
else
      set(handles.edit_lowpass, 'Enable', 'off');
      set(handles.togglebutton_lowpass, 'Value', 0);
      set(handles.slider_lowpass, 'Enable','off');
      set(handles.edit_lowpass, 'String', '0');
      set(handles.edit_lowpass, 'BackgroundColor', [0.75 0.75 0.75]);
end

if typef==0 && autorder==1
      % order starts again for auto butter
      orderlist  = cellstr(get(handles.popupmenu_order, 'String'));     % whole list
      orderlist{1} = 'automin:2';
      set(handles.popupmenu_order, 'String', orderlist);
      set(handles.popupmenu_order, 'Value',1);
      set(handles.popupmenu_dboct, 'Value',1);
      set(handles.popupmenu_dbdec, 'Value',1);
end

%
% Plot corresponding response
%
if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
      plotresponsefilter(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function slider_lowpass_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%--------------------------------------------------------------------------
function popupmenu_order_Callback(hObject, eventdata, handles)

orderindx = get(handles.popupmenu_order, 'Value');
orderlist = cellstr(get(handles.popupmenu_order, 'String'));

if orderindx==1
      orderlist    = regexprep(orderlist,'automin:','','ignorecase'); %get rid of auto: (if any)
      newlaborder  = ['automin:' orderlist{2}];
      orderlist{1} = newlaborder;
      set(handles.popupmenu_order,'String', orderlist);
      handles.autorder = 1;
      
      if get(handles.radiobutton_butter,'Value')
            order          = str2num(strrep(orderlist{1},'automin:','')); % get rid of auto (in case of)
            set(handles.popupmenu_dboct,'Value', 1);
            set(handles.popupmenu_dbdec,'Value', 1);
      end
else
      orderlist{1} = 'automin';
      set(handles.popupmenu_order,'String', orderlist);
      handles.autorder = 0;
      
      if get(handles.radiobutton_butter,'Value')
            set(handles.popupmenu_dboct,'Value', orderindx-1);
            set(handles.popupmenu_dbdec,'Value', orderindx-1);
      end
end

% Update handles structure
guidata(hObject, handles);
%
% Plot corresponding response
%
if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
      plotresponsefilter(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function popupmenu_order_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function edit_highpass_Callback(hObject, eventdata, handles)

valueh = str2num(get(handles.edit_highpass, 'String'));
autorder = handles.autorder;

if valueh<0.001;
      valueh = 0;
end

if isempty(valueh) || valueh<=0
      set(handles.edit_highpass, 'String', '0')
      set(handles.edit_highpass, 'Enable', 'off')
      set(handles.edit_highpass, 'BackgroundColor', [0.75 0.75 0.75]);
      set(handles.slider_highpass, 'Value', 0);
      set(handles.slider_highpass, 'Enable', 'off');
      set(handles.togglebutton_highpass, 'Value', 0);
      set(handles.togglebutton_highpass, 'BackgroundColor', [0.8 0.8 0.75]);
      plotresponsefilter(hObject, eventdata, handles);
      return
end
if  valueh>handles.maxsliders
      set(handles.edit_highpass, 'String', num2str(handles.maxsliders))
      set(handles.slider_highpass, 'Value', handles.maxsliders);
      set(handles.slider_highpass, 'Enable', 'on');
      set(handles.togglebutton_highpass, 'Value', 1);
      set(handles.togglebutton_highpass, 'BackgroundColor', [1 1 0.5]);
      plotresponsefilter(hObject, eventdata, handles);
      return
end

if get(handles.radiobutton_butter, 'Value');
      typef = 0; % 0 means Butterworth
elseif get(handles.radiobutton_fir, 'Value');
      typef = 1;% 1 means FIR
elseif get(handles.radiobutton_PM_notch, 'Value');
      typef = 2; % 2 means PM Notch
end

notchpm =  get(handles.radiobutton_PM_notch,'Value');

if notchpm
      if valueh>=5 && valueh<=handles.maxsliders-5
            set(handles.slider_highpass, 'Value', valueh);
      else
            if valueh<5
                  nvaln = 5;
            elseif valueh>handles.maxsliders-5
                  nvaln = handles.maxsliders-5;
            end
            
            nvalstr = sprintf('%.1f',nvaln);
            set(handles.edit_highpass, 'String', nvalstr);
            set(handles.slider_highpass, 'Value', nvaln);
      end
      
      %
      % Plot corresponding response
      %
      if get(handles.radiobutton_fdatafr,'Value')
            plotresponse_fd_data(hObject, eventdata, handles)
      elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
            plotresponsefilter(hObject, eventdata, handles);
      end
else
      set(handles.slider_highpass, 'Value', valueh);
      
      if typef==0 && autorder==1
            % order starts again for auto butter
            orderlist  = cellstr(get(handles.popupmenu_order, 'String'));     % whole list
            orderlist{1} = 'automin:2';
            set(handles.popupmenu_order, 'String', orderlist);
            set(handles.popupmenu_order, 'Value',1);
      end
      
      %
      % Plot corresponding response
      %
      if get(handles.radiobutton_fdatafr,'Value')
            plotresponse_fd_data(hObject, eventdata, handles)
      elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
            plotresponsefilter(hObject, eventdata, handles);
      end
end

%--------------------------------------------------------------------------
function edit_highpass_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function edit_lowpass_Callback(hObject, eventdata, handles)

valuel = str2num(get(handles.edit_lowpass, 'String'));
autorder = handles.autorder;

if valuel<0.001;
      valuel = 0;
end
if isempty(valuel) || valuel<=0
      set(handles.edit_lowpass, 'String', '0')
      set(handles.edit_lowpass, 'Enable', 'off')
      set(handles.edit_lowpass, 'BackgroundColor', [0.75 0.75 0.75]);
      set(handles.slider_lowpass, 'Value', 0);
      set(handles.slider_lowpass, 'Enable', 'off');
      set(handles.togglebutton_lowpass, 'Value', 0);
      set(handles.togglebutton_lowpass, 'BackgroundColor', [0.8 0.8 0.75]);
      plotresponsefilter(hObject, eventdata, handles);
      return
end
if  valuel>handles.maxsliders
      set(handles.edit_lowpass, 'String', num2str(handles.maxsliders))
      set(handles.edit_lowpass, 'Enable', 'on')
      set(handles.slider_lowpass, 'Value', handles.maxsliders);
      set(handles.slider_lowpass, 'Enable', 'on');
      set(handles.togglebutton_lowpass, 'Value', 1);
      set(handles.togglebutton_lowpass, 'BackgroundColor', [1 1 0.5]);
      plotresponsefilter(hObject, eventdata, handles);
      return
end

set(handles.slider_lowpass, 'Value', valuel);


if get(handles.radiobutton_butter, 'Value');
      typef = 0; % 0 means Butterworth
elseif get(handles.radiobutton_fir, 'Value');
      typef = 1;% 1 means FIR
elseif get(handles.radiobutton_PM_notch, 'Value');
      typef = 2; % 2 means PM Notch
end

if typef==0 && autorder==1
      % order starts again for auto butter
      orderlist  = cellstr(get(handles.popupmenu_order, 'String'));     % whole list
      orderlist{1} = 'automin:2';
      set(handles.popupmenu_order, 'String', orderlist);
      set(handles.popupmenu_order, 'Value',1);
end

%
% Plot corresponding response
%
if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
      plotresponsefilter(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function edit_lowpass_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_channels_Callback(hObject, eventdata, handles)

numch = get(hObject, 'Value');
nums  = str2num(get(handles.edit_channels, 'String'));
nums  = [nums numch];

if isempty(nums)
      msgboxText{1} =  'Invalid channel indexing.';
      title = 'ERPLAB: basicfilterGUI() error:';
      errorfound(msgboxText, title);
      return
end
chxstr = vect2colon(nums,'Delimiter','off', 'Sort','on');
set(handles.edit_channels,'String', chxstr)

if  get(handles.radiobutton_ufdatafr,'Value');
      plotresponse_uf_data(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function popupmenu_channels_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function edit_channels_Callback(hObject, eventdata, handles)

chx = str2num(get(handles.edit_channels,'String'));

if isempty(chx)
      msgboxText{1} =  'Invalid channel indexing.';
      title = 'ERPLAB: basicfilterGUI() error:';
      errorfound(msgboxText, title);
      return
end

chxstr = vect2colon(chx,'Delimiter','off', 'Sort','on');
set(handles.edit_channels,'String', chxstr)

if  get(handles.radiobutton_ufdatafr,'Value');
      plotresponse_uf_data(hObject, eventdata, handles);
elseif get(handles.radiobutton_fdatafr,'Value');
      plotresponse_fd_data(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function edit_channels_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function pushbutton_cancel_Callback(hObject, eventdata, handles)

handles.output= [];

% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

%--------------------------------------------------------------------------
function pushbutton_apply_Callback(hObject, eventdata, handles)

iswarngain = handles.iswarngain;
iswarnroff = handles.iswarnroff;

if iswarngain==1 || iswarngain==2
      
      BackERPLABcolor = [1 0.9 0.3];    % yellow
      
      if iswarngain==1
            question = ['With this filter setting, there will be significant \n'...
                  'attenuation at passband.  This is almost always a \n'...
                  'bad thing. This problem can usually be eliminated by \n'...
                  'selecting a lower high-pass cuttoff, higher low-pass \n'...
                  'cuttoff, and/or a higher filter order. '];
      elseif iswarngain==2
            question = ['With this filter setting, there will be some \n'...
                  'amplification at the passband frequencies. \n'...
                  'This problem can be eliminated by selecting \n'...
                  'a higher filter order. '];
      end
      
      title       = 'WARNING!';
      oldcolor    = get(0,'DefaultUicontrolBackgroundColor');
      set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
      button      = questdlg(sprintf(question), title,'Procced anyway', 'Cancel','Procced anyway');
      set(0,'DefaultUicontrolBackgroundColor',oldcolor)
      
      if ~strcmpi(button,'Procced anyway')
            disp('User selected Cancel')
            return
      end
end

highpasscutoff = str2num(get(handles.edit_highpass, 'string'));
lowpasscutoff  = str2num(get(handles.edit_lowpass,  'string'));
orderindx      = get(handles.popupmenu_order, 'Value');
orderlist      = cellstr(get(handles.popupmenu_order, 'String'));
order          = str2num(orderlist{orderindx});
channelArray   = str2num(get(handles.edit_channels, 'string'));

if length(channelArray)>length(unique(channelArray))
      msgboxText{1} =  'Error: You have specified repeated channels.';
      title = 'ERPLAB: basicfilterGUI() error:';
      errorfound(msgboxText, title);
      return
end

if get(handles.radiobutton_butter, 'Value'); % 0 means Butterworth
      typefilter = 'butter';
elseif get(handles.radiobutton_fir, 'Value'); % 1 means FIR
      typefilter = 'fir';
elseif get(handles.radiobutton_PM_notch, 'Value'); % 2 means PM Notch
      typefilter = 'notch';
end

if strcmp(typefilter, 'fir') || strcmp(typefilter, 'notch')
      minboundarysamdist = handles.minboundarysamdist;
      if get(handles.checkbox_boundary,'Value')
            if minboundarysamdist<3*order
                  BackERPLABcolor = [ 1 1 0];
                  question =  ['You have set the checkbox for filtering between boundary events.\n'...
                        'Event codes ''boundary'' or -99 were found in you dataset.\n\n'...
                        'However, at least one of the segments among boundaries \n'...
                        'has less samples than 3 times the filter order you are currently setting.\n\n'...
                        'You may either decrese the order of the filter - if it is possible - (recommended),\n'...
                        'or uncheck the option for filtering between boundary events (not recommended).'];
                  questionstr = sprintf(question);
                  titlex = 'ERPLAB: Filter order vs number of samples';
                  oldcolor = get(0,'DefaultUicontrolBackgroundColor');
                  set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
                  button = questdlg(questionstr, titlex,'OK','OK');
                  set(0,'DefaultUicontrolBackgroundColor',oldcolor)
                  return
            end
      end
end

if strcmp(typefilter, 'notch')
      lowpasscutoff = highpasscutoff;
end

remove_dc  = get(handles.checkbox_removedc, 'Value');

if get(handles.checkbox_boundary, 'Value')
      boundarystr  = get(handles.edit_boundary, 'String');
      if strcmpi(boundarystr,'boundary')||strcmpi(boundarystr,'''boundary''')
            boundary = 'boundary';
      else
            if ~strcmp(boundarystr,'')
                  boundary = str2num(boundarystr);
                  if isempty(boundary);
                        boundary = boundarystr;
                  end
            else
                  boundary = [];
            end
      end
else
      boundary = [];
end

if ~isempty(highpasscutoff) && ~isempty(lowpasscutoff) && ~isempty(order) && ~isempty(channelArray)
      outstr = {highpasscutoff, lowpasscutoff, order, channelArray, typefilter, remove_dc, boundary};
      handles.output = outstr;
      
      % Update handles structure
      guidata(hObject, handles);
      uiresume(handles.figure1);
end

%--------------------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, eventdata, handles)

if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
      % The GUI is still in UIWAIT, us UIRESUME
      uiresume(handles.figure1);
else
      % The GUI is no longer waiting, just close it
      delete(handles.figure1);
end

%--------------------------------------------------------------------------
function checkbox_removedc_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function togglebutton_highpass_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      
      set(handles.edit_highpass, 'Enable', 'on');
      set(handles.edit2_highpass, 'Enable', 'on');
      set(handles.togglebutton_highpass, 'Value', 1);
      set(handles.slider_highpass, 'Enable','on');
      mvalueh = round(handles.mvalueh*10)/10;
      
      if mvalueh<0.1
            handles.mvalueh = 0.1;
      end
      
      set(handles.slider_highpass, 'Value', handles.mvalueh);
      set(handles.edit_highpass, 'String', num2str(handles.mvalueh));
      set(handles.checkbox_removedc, 'Enable', 'on')
      set(handles.edit_highpass, 'BackgroundColor', [1 1 1]);
      set(handles.togglebutton_highpass, 'BackgroundColor', [1 1 0.5]);
      
      %
      % Roll off
      %
      set(handles.popupmenu_dboct, 'Enable', 'on');
      set(handles.popupmenu_dbdec, 'Enable', 'on');
      set(handles.popupmenu_order, 'Enable', 'on');
      
      %
      % Plot filter related responses
      %
      set(handles.radiobutton_freqr, 'Enable', 'on');
      set(handles.radiobutton_impr, 'Enable', 'on');
      set(handles.radiobutton_fdatafr, 'Enable', 'on');
      
      % Update handles structure
      guidata(hObject, handles);
else
      set(handles.togglebutton_highpass, 'Value', 0);
      set(handles.slider_highpass, 'Value', 0);
      set(handles.slider_highpass, 'Enable','off');
      set(handles.edit_highpass, 'String', '0');
      set(handles.edit_highpass, 'Enable', 'off');
      set(handles.checkbox_removedc, 'Enable', 'off')
      set(handles.edit_highpass, 'BackgroundColor', [0.75 0.75 0.75]);
      set(handles.togglebutton_highpass, 'BackgroundColor', [0.8 0.8 0.75]);
      
%       if get(handles.togglebutton_lowpass, 'Value')==0;
%             
%             %
%             % Roll off
%             %
%             set(handles.popupmenu_dboct, 'Enable', 'off');
%             set(handles.popupmenu_dbdec, 'Enable', 'off');
%             set(handles.popupmenu_order, 'Enable', 'off');
%             
%             %
%             % Plot filter related responses
%             %
%             set(handles.radiobutton_freqr,'Value',0)
%             set(handles.radiobutton_impr,'Value',0)
%             set(handles.radiobutton_ufdatafr,'Value',1)
%             set(handles.radiobutton_fdatafr,'Value',0)
%             set(handles.radiobutton_freqr, 'Enable', 'off');
%             set(handles.radiobutton_impr, 'Enable', 'off');
%             set(handles.radiobutton_fdatafr, 'Enable', 'off');
%             
%             plotresponse_uf_data(hObject, eventdata, handles);
%             return
%       end
end

if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
else
      plotresponsefilter(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function togglebutton_lowpass_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.edit_lowpass, 'Enable', 'on');
      set(handles.edit2_lowpass, 'Enable', 'on');
      set(handles.slider_lowpass, 'Enable','on');
      fc = round(handles.mvaluel*10)/10;
      
      if fc==0
            fc = round(handles.maxsliders*5)/10;
      end
      
      set(handles.slider_lowpass, 'Value', fc);
      set(handles.edit_lowpass, 'String', num2str(fc));
      set(handles.edit_lowpass, 'BackgroundColor', [1 1 1]);
      set(handles.togglebutton_lowpass, 'BackgroundColor', [1 1 0.5]);
      
      %
      % Roll off
      %
      set(handles.popupmenu_dboct, 'Enable', 'on');
      set(handles.popupmenu_dbdec, 'Enable', 'on');
      set(handles.popupmenu_order, 'Enable', 'on');
      
      %
      % Plot filter related responses
      %
      set(handles.radiobutton_freqr, 'Enable', 'on');
      set(handles.radiobutton_impr, 'Enable', 'on');
      set(handles.radiobutton_fdatafr, 'Enable', 'on');
else
      set(handles.edit_lowpass, 'Enable', 'off');
      set(handles.slider_lowpass, 'Enable','off');
      set(handles.slider_lowpass, 'Value', 0);
      set(handles.edit_lowpass, 'String', '0');
      set(handles.edit_lowpass, 'BackgroundColor', [0.75 0.75 0.75]);
      set(handles.togglebutton_lowpass, 'BackgroundColor', [0.8 0.8 0.75]);
      
%       if get(handles.togglebutton_highpass, 'Value')==0;
%             
%             %
%             % Roll off
%             %
%             set(handles.popupmenu_dboct, 'Enable', 'off');
%             set(handles.popupmenu_dbdec, 'Enable', 'off');
%             set(handles.popupmenu_order, 'Enable', 'off');
%             
%             %
%             % Plot filter related responses
%             %
%             set(handles.radiobutton_freqr,'Value',0)
%             set(handles.radiobutton_impr,'Value',0)
%             set(handles.radiobutton_ufdatafr,'Value',1)
%             set(handles.radiobutton_fdatafr,'Value',0)
%             
%             set(handles.radiobutton_freqr, 'Enable', 'off');
%             set(handles.radiobutton_impr, 'Enable', 'off');
%             set(handles.radiobutton_fdatafr, 'Enable', 'off');
%             
%             plotresponse_uf_data(hObject, eventdata, handles);
%             return            
%       end
end

if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
else
      plotresponsefilter(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function radiobutton_freqr_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_impr,'Value', 0);
      set(handles.radiobutton_ufdatafr,'Value', 0);
      set(handles.radiobutton_fdatafr,'Value', 0);
      %set(handles.popupmenu_FRscale,'Value', 1);
      set(handles.popupmenu_FRscale,'Enable', 'on');
      set(handles.radiobutton_butter, 'Enable', 'on')
      set(handles.radiobutton_fir, 'Enable', 'on')
      set(handles.radiobutton_PM_notch,'Enable','on')
      plotresponsefilter(hObject, eventdata, handles);
else
      set(handles.radiobutton_freqr,'Value', 1);
end

%--------------------------------------------------------------------------
function radiobutton_impr_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_freqr,'Value', 0);
      set(handles.radiobutton_ufdatafr,'Value', 0);
      set(handles.radiobutton_fdatafr,'Value', 0);
      %set(handles.popupmenu_FRscale,'Value', 1);
      set(handles.popupmenu_FRscale,'Enable', 'off');
      set(handles.radiobutton_butter, 'Enable', 'on')
      set(handles.radiobutton_fir, 'Enable', 'on')
      set(handles.radiobutton_PM_notch,'Enable','on')
      plotresponsefilter(hObject, eventdata, handles);
else
      set(handles.radiobutton_impr,'Value', 1);
end

%--------------------------------------------------------------------------
function radiobutton_ufdatafr_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_freqr,'Value', 0);
      set(handles.radiobutton_impr,'Value', 0);
      set(handles.radiobutton_fdatafr,'Value', 0);
%       set(handles.popupmenu_FRscale,'Value', 1);
      set(handles.popupmenu_FRscale,'Enable', 'on');
      set(handles.radiobutton_butter, 'Enable', 'off')
      set(handles.radiobutton_fir, 'Enable', 'off')
      set(handles.radiobutton_PM_notch,'Enable','off')
      drawnow
      plotresponse_uf_data(hObject, eventdata, handles);
else
      set(handles.radiobutton_ufdatafr,'Value', 1);
end

%--------------------------------------------------------------------------
function radiobutton_fdatafr_Callback(hObject, eventdata, handles)


if get(hObject,'Value')
      set(handles.radiobutton_freqr,'Value', 0);
      set(handles.radiobutton_impr,'Value', 0);
      set(handles.radiobutton_ufdatafr,'Value', 0);
%       set(handles.popupmenu_FRscale,'Value', 1);
      set(handles.popupmenu_FRscale,'Enable', 'on');      
      set(handles.radiobutton_butter, 'Enable', 'on')
      set(handles.radiobutton_fir, 'Enable', 'on')
      set(handles.radiobutton_PM_notch,'Enable','on')
      drawnow
      plotresponse_fd_data(hObject, eventdata, handles);
else
      set(handles.radiobutton_fdatafr,'Value', 1);
end

%--------------------------------------------------------------------------
function checkbox_boundary_Callback(hObject, eventdata, handles)

if get(hObject, 'Value')
      set(handles.edit_boundary,'Enable', 'on');
      set(handles.edit_boundary,'BackgroundColor', [1 1 1]);
      
      if get(handles.radiobutton_butter, 'Value'); % 0 means Butterworth
            typef = 0;
      elseif get(handles.radiobutton_fir, 'Value'); % 1 means FIR
            typef = 1;
      elseif get(handles.radiobutton_PM_notch, 'Value'); % 2 means PM Notch
            typef = 2;
      end
      
      if typef==1 || typef==2
            
            %
            % FILTER order
            %
            orderindx  = get(handles.popupmenu_order, 'Value');               % where
            orderlist  = cellstr(get(handles.popupmenu_order, 'String'));     % whole list
            order      = str2num(strrep(orderlist{orderindx},'automin:','')); % get rid of auto (in case of)
            
            minboundarysamdist = handles.minboundarysamdist;
            
            if get(handles.checkbox_boundary,'Value')
                  if minboundarysamdist<3*order
                        BackERPLABcolor = [ 1 1 0];
                        question =  ['You have set the checkbox for filtering between boundary events.\n'...
                              'Event codes ''boundary'' or -99 were found in you dataset.\n\n'...
                              'However, at least one of the segments among boundaries \n'...
                              'has less samples than 3 times the filter order you are currently setting.\n\n'...
                              'You may either decrese the order of the filter - if it is possible - (recommended),\n'...
                              'or uncheck the option for filtering between boundary events (not recommended).'];
                        questionstr = sprintf(question);
                        titlex = 'ERPLAB: Filter order vs number of samples';
                        oldcolor = get(0,'DefaultUicontrolBackgroundColor');
                        set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
                        button = questdlg(questionstr, titlex,'OK','OK');
                        set(0,'DefaultUicontrolBackgroundColor',oldcolor)
                        return
                  end
            end
      end
else
      set(handles.edit_boundary,'Enable', 'off');
      set(handles.edit_boundary,'BackgroundColor', [0.75 0.75 0.75]);
end

%--------------------------------------------------------------------------
function checkbox_notch_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function no_filter(hObject,handles, msgtx)
plot(1, 1, 'w');
text(0.32,0.5, msgtx,'FontSize',18, 'color', [1 0 0])
axis([0  1 0 1])
set(handles.slider_highpass, 'Value', 0);
set(handles.slider_lowpass, 'Value', 0);
set(handles.slider_highpass, 'Enable', 'off')
set(handles.slider_lowpass, 'Enable', 'off')
set(handles.togglebutton_highpass, 'Value', 0)
set(handles.togglebutton_lowpass, 'Value', 0)
set(handles.edit_highpass,'String','0')
set(handles.edit_highpass,'Enable','off')
set(handles.edit2_highpass,'String','[---]')
set(handles.edit2_highpass,'Enable','off')
set(handles.edit_lowpass,'String','0')
set(handles.edit_lowpass,'Enable','off')
set(handles.edit2_lowpass,'String','[---]')
set(handles.edit2_lowpass,'Enable','off')
set(handles.checkbox_removedc, 'Enable','off')
handles.memvalueh = 0.1;
handles.mvalueh = 0.1;     % memory value highpass
fc = round(handles.maxsliders*5)/10;
handles.memvaluel = fc;
handles.mvaluel = fc;     % memory value highpass

% Update handles structure
guidata(hObject, handles);
return

%##########################################################################
%##########################################################################
%##########################################################################
%##########################################################################

function hfr = plotresponsefilter(hObject, eventdata, handles)

%
% IMPORTANT: This function plot the filter response of FILTFILT function only.
%
hfr = [];
valueh = get(handles.slider_highpass, 'Value');
valuel = get(handles.slider_lowpass,  'Value');
axes(handles.axes1);

if valueh==0 && valuel==0
      if get(handles.radiobutton_freqr, 'Value') ||...
                  get(handles.radiobutton_impr, 'Value')  ||...
                  get(handles.radiobutton_fdatafr, 'Value')
            msgtx = '--NO FILTERING--';
            no_filter(hObject, handles, msgtx)
      end
      return
else
      xmaxp = handles.xmaxfreqr;
      if nargout==0
            %if ~isempty(xmaxp)
            if get(handles.radiobutton_freqr, 'Value') || get(handles.radiobutton_impr, 'Value')
                  %             posaxes1 = get(gca,'YLim');
                  msgtx = 'Working, please wait...';
                  text(mean(xmaxp)/3, 1.12, msgtx,'FontSize',14, 'color', 'k')
                  drawnow
            end
            %end
      end
end

fs     = handles.fs;
fnyq   = fs/2;

%
% FILTER order
%
orderindx  = get(handles.popupmenu_order, 'Value');               % where
orderlist  = cellstr(get(handles.popupmenu_order, 'String'));     % whole list
order      = str2num(strrep(orderlist{orderindx},'automin:','')); % get rid of auto (in case of)

if isempty(order)
      disp('Still busy...')
      return
end

if get(handles.radiobutton_butter, 'Value'); % 0 means Butterworth
      typef = 0;
elseif get(handles.radiobutton_fir, 'Value'); % 1 means FIR
      typef = 1;
elseif get(handles.radiobutton_PM_notch, 'Value'); % 2 means PM Notch
      typef = 2;
end

n = round(fnyq);  % number of points for frequency response.
hpzoom = diff(str2num(char(get(handles.edit_xmaxplot,'String'))));

%
% Augmented number of points for frequency response.
%
if hpzoom<=5
      n = n*50;
elseif hpzoom<=0.5
      n = n*1000;
end

if typef==2 % PM Notch
      valuel = valueh;
end

bt = [];
at = [];

[bt, at, labelf, v, frec3dB, xdB_at_fx, orderx] = filter_tf(typef, order, valuel, valueh, fs);

if ~v % something is wrong or turned off
      disp('Filter coefficient calculation failed...')
      if get(handles.radiobutton_freqr, 'Value') ||...
                  get(handles.radiobutton_impr, 'Value')  ||...
                  get(handles.radiobutton_fdatafr, 'Value')
            msgtx = '--NO FILTERING--';
            no_filter(hObject, handles, msgtx)
      end
      
      handles.autorder = 0;
      % Update handles structure
      guidata(hObject, handles);
      return
else
      autorder = handles.autorder;
end

if ~isempty(orderx)
      if orderx~=order
            order = orderx;
            str = ['\nWARNING: Odd order symmetric FIR filters must have a gain of zero \n'...
                  'at the Nyquist frequency. The order has been increased to %g.\n'];
            fprintf(str, order);
      end
end

%
% Automin for FIR
%
if autorder == 1 && typef==1
      
      slidersoff(hObject, eventdata, handles)
      orderlist    = cellstr(get(handles.popupmenu_order,'String'));
      orderlist{1} = 'automin...';
      set(handles.popupmenu_order, 'String', orderlist)
      set(handles.popupmenu_order, 'Value', 1)
      set(handles.text_halfamp, 'String','updating...');
      set(handles.text_halfpow, 'String','updating...');
      drawnow
      
      xdB_at_fx = 0;
      order = 4;
      j=1;
      
      while mean(xdB_at_fx)~=-6 && order<=4096-2 && j<=2000% && get(handles.popupmenu_order,'Value')==1
            
            if mean(xdB_at_fx)==0
                  order = order + 32;
            elseif mean(xdB_at_fx)>-3 && mean(xdB_at_fx)<0
                  order = order + 8;
            else
                  order = order + 4;
            end
            
            [bt, at, labelf, v, frec3dB, xdB_at_fx, orderx] = filter_tf(typef, order, valuel, valueh, fs);
            
            if isempty(xdB_at_fx)
                  xdB_at_fx = 0;
            end
            
            if v
                  if orderx~=order
                        if mod(orderx,4)==0
                              order = orderx;
                        else
                              order = orderx + 2;
                        end
                        str = ['\nWARNING: Odd order symmetric FIR filters must have a gain of zero \n'...
                              'at the Nyquist frequency. The order has been increased to %g.\n'];
                        fprintf(str, order);
                  end
            end
      end
      
      if mean(xdB_at_fx)==-6
            orderlist{1} = ['automin:' num2str(order)];
            set(handles.popupmenu_order, 'String', orderlist)
            set(handles.popupmenu_order, 'Value', 1)
            disp('min order was found.')
            iswarnroff = 0;
      else
            orderlist{1} = 'automin';
            set(handles.popupmenu_order, 'String', orderlist)
            set(handles.popupmenu_order, 'Value', length(orderlist))
            handles.autorder = 0;
            iswarnroff = 1; % atenuation at frquency cutoff was impposible...
            
            % Update handles structure
            guidata(hObject, handles);
            disp('min order was not found...')
      end
      
      sliderson(hObject, eventdata, handles)
      drawnow
else
      if mean(xdB_at_fx)==-6
            iswarnroff =0;
      else
            iswarnroff =1;
      end
end

if ~v % something is wrong or turned off  (1 means everything is ok)
      if get(handles.radiobutton_freqr, 'Value') ||...
                  get(handles.radiobutton_impr, 'Value')  ||...
                  get(handles.radiobutton_fdatafr, 'Value')
            
            msgtx = '--NO FILTERING--';
            no_filter(hObject, handles, msgtx)
      end
      disp('Filter coefficient calculation failed....')
      handles.autorder = 0;
      % Update handles structure
      guidata(hObject, handles);
      return
end

%
% Final filter coefficients
%
if size(bt,1)==2
      if strcmpi(labelf,'Band-Pass')
            % cascade filter transfer function
            b = conv(bt(1,:),bt(2,:));
            a = conv(at(1,:),at(2,:));
      else
            % parallel filter transfer function
            b = conv(bt(1,:),at(2,:)) + conv(bt(2,:),at(1,:));
            a = conv(at(1,:),at(2,:));
      end
else
      b = bt;
      a = at;
end

%
% Half power cuttoff (-3 dB)  (ONLY FOR FILTFILT!)
%
if ~isempty(frec3dB)
      
      if strcmpi(labelf, 'Low-pass')
            f3str = sprintf('%7.2f', frec3dB);
            set(handles.edit2_highpass,'String','---')
            set(handles.edit2_lowpass,'String', f3str)
      elseif strcmpi(labelf, 'High-pass')
            f3str = sprintf('%7.2f', frec3dB);
            set(handles.edit2_highpass,'String',f3str)
            set(handles.edit2_lowpass,'String', '---')
      else
            try
                  f3str1 = sprintf('%7.2f', frec3dB(1));
                  f3str2 = sprintf('%7.2f', frec3dB(2));
                  set(handles.edit2_highpass,'String', f3str2)
                  set(handles.edit2_lowpass,'String', f3str1)
                  
            catch
                  set(handles.edit2_highpass,'String','---')
                  set(handles.edit2_lowpass,'String', '---')
            end
      end
else
      set(handles.edit2_highpass,'String','---')
      set(handles.edit2_lowpass,'String','---')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter responses.  Thanks to Sean Little from MathWorks Technical Support Department.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
% filtfilt frequency response
%
[hfr,f1]  = freqz(b,a,n,fs);
hfr       = abs(hfr).^2; % Filter responses is squared in order to fit with FILTFILT

% filtfilt impulse response
[hira,f3] = freqz(b,a,n,'whole',fs);
hir2      = abs(hira).^2;
hir       = ifft(hir2);

%
% Gain constraint. Gain should be close to 1 at the passband region.
%
gain_postL = 1-0.02;  %  2% criteria
gain_postU = 1+0.02;  %  2% criteria

if max(abs(hfr))>=gain_postL && max(abs(hfr))<=gain_postU && (max(abs(hfr))-min(abs(hfr)))>0.95
      
      iswarngain = 0; % gain is fine
      
      %
      % Slider memory
      %
      handles.memvaluel = round(valuel);
      handles.memvalueh = round(valueh);   
      handles.mem6dbl =  num2str(ceil(str2num(get(handles.edit_lowpass,'String'))));
      handles.mem6dbh =  num2str(floor(str2num(get(handles.edit_highpass,'String'))));
      handles.mem3dbl =  num2str(ceil(str2num(get(handles.edit2_lowpass,'String'))));
      handles.mem3dbh =  num2str(floor(str2num(get(handles.edit2_highpass,'String'))));
      
elseif max(abs(hfr))>=gain_postL && max(abs(hfr))<=gain_postU && (max(abs(hfr))-min(abs(hfr)))<=0.95
      iswarngain = 3;
      xdB_at_fx = [];
else
      if max(abs(hfr))<gain_postL
            iswarngain = 1;
      else
            iswarngain = 2;
      end
      
      xdB_at_fx = [];
end

if iswarnroff~=0
      
      if order>=4096
            BackERPLABcolor = [ 1 1 0];
            
            question =  ['Unable to achieve specified cutoff (-6dB). Higher filter order is needed,\n'...
                  'but order greater than 4096 is not allowed for  this ERPLAB version.\n'...
                  'You may either select a wider passband with automin (recommended),\n'...
                  'or turn off automin and leave with the reduced attenuation (not recommended)'];
            
            questionstr = sprintf(question);
            titlex = 'ERPLAB: Filter order';
            oldcolor = get(0,'DefaultUicontrolBackgroundColor');
            set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
            button = questdlg(questionstr, titlex,'OK','Reset filters','OK');
            set(0,'DefaultUicontrolBackgroundColor',oldcolor)
            
            %
            % reset order
            %
            orderlist  = cellstr(get(handles.popupmenu_order, 'String'));
            order      = str2num(strrep(orderlist{orderindx},'automin:',''));
            orderlist{1}= 'automin';
            [tfx posord] = ismember(order,[-1 2 4 6 8]);

            
            set(handles.popupmenu_order, 'String',orderlist)
            set(handles.popupmenu_order, 'Value',posord)
            set(handles.popupmenu_dboct, 'Value',posord-1)
            set(handles.popupmenu_dbdec, 'Value',posord-1)
            handles.autorder  = 0;
            
            if strcmpi(button,'OK')
                  
                  set(handles.slider_highpass, 'Value', handles.memvalueh);
                  set(handles.slider_lowpass,  'Value', handles.memvaluel);
                  chksliders(hObject, eventdata, handles)
                  set(handles.edit_highpass, 'String', handles.mem6dbh);
                  set(handles.edit_lowpass,  'String', handles.mem6dbl);
                  set(handles.edit2_highpass, 'String', handles.mem3dbh);
                  set(handles.edit2_lowpass,  'String', handles.mem3dbl);
                  sliderson(hObject, eventdata, handles)
                  % Update handles structure
                  guidata(hObject, handles);
                  
                  plotresponsefilter(hObject, eventdata, handles);
                  return
                  
            else
                  sliderson(hObject, eventdata, handles)
                  set(handles.slider_highpass, 'Value', 0);
                  set(handles.slider_lowpass,  'Value', fnyq/2);
                  chksliders(hObject, eventdata, handles)
                  handles.memvalueh = 0.1;
                  handles.mvalueh   = 0.1;             % memory value highpass
                  
                  % Update handles structure
                  guidata(hObject, handles);
                  plotresponsefilter(hObject, eventdata, handles);
                  return
            end
      end
      
elseif iswarngain~=0 && iswarnroff==0
      
      if autorder == 1 && typef==0
            
            slidersoff(hObject, eventdata, handles)
            orderindx  = get(handles.popupmenu_order, 'Value');               % where
            orderlist  = cellstr(get(handles.popupmenu_order, 'String'));     % whole list
            order      = str2num(strrep(orderlist{orderindx},'automin:','')); % get rid of auto (in case of)
            
            if isempty(order)
                  disp('Ops, I could not read the filter order...')
                  sliderson(hObject, eventdata, handles)
                  return
            end
            
            order     = order + 2; % increase the order
            ishopermission  = handles.ishopermission; % permission for higher order when high-pass filter cutoff is <=0.5
            
            if order>2 && order<=8 && valueh>0 && valueh<=0.5 && ~ishopermission
                  
                  question = ['We do not recommend a filter order greater than 2 for a Butterworth filter\n '...
                        'when the high-pass cutoff is <= 0.5 Hz\n'...
                        'Continue anyway?'];
                  titlex = 'ERPLAB: Filter order';
                  button      = askquest(sprintf(question), titlex);
                  
                  if ~strcmpi(button,'yes')
                        
                        set(handles.slider_highpass, 'Value', 0);
                        set(handles.slider_lowpass,  'Value', handles.memvaluel);
                        
                        if handles.memvaluel==0
                              set(handles.slider_lowpass, 'Enable', 'off');
                              set(handles.togglebutton_lowpass,'Value',0)
                              set(handles.edit_lowpass, 'Enable', 'off');
                              set(handles.edit2_lowpass, 'Enable', 'off');
                        end
                        
                        set(handles.edit_highpass, 'String', handles.mem6dbh);
                        set(handles.edit_lowpass,  'String', handles.mem6dbl);
                        set(handles.edit2_highpass, 'String', handles.mem3dbh);
                        set(handles.edit2_lowpass,  'String', handles.mem3dbl);
                        set(handles.popupmenu_order,  'Value', 2);
                        handles.autorder = 0;
                        handles.ishopermission =0;
                        chksliders(hObject, eventdata, handles)
                        
                        % Update handles structure
                        guidata(hObject, handles);
                        plotresponsefilter(hObject, eventdata, handles);
                        sliderson(hObject, eventdata, handles)
                        return
                  else
                        chksliders(hObject, eventdata, handles)
                        handles.ishopermission = 1;
                        % Update handles structure
                        guidata(hObject, handles);
                  end
                  
                  sliderson(hObject, eventdata, handles)
                  return
            end
            
            if order>8
                  
                  BackERPLABcolor = [ 1 1 0];
                  
                  if iswarngain==3
                        line01 = 'You are losing stopband attenuation!';
                  else
                        line01 = 'You are losing passband gain!';
                  end
                  
                  question = ['WARNING: %s \n\n'...
                        'In order to use the automin feature, a higher Butterworth filter order is needed, '...
                        'but an order greater than 8 is not allowed for this ERPLAB version. '...
                        'You may select a wider passband with automin (recommended), '...
                        'or turn off automin and leave with the reduced gain (not recommended).'];
                  %
                  %                   question =  ['WARNING: Losing passband gain, higher Butterworth filter order is needed,\n'...
                  %                         'but an order greater than 8 is not allowed for  this ERPLAB version.\n'...
                  %                         'You may either select a wider passband with automin (recommended),\n'...
                  %                         'or turn off automin and leave with the reduced gain (not recommended)'];
                  titlex = 'ERPLAB: Filter order';
                  
                  oldcolor = get(0,'DefaultUicontrolBackgroundColor');
                  set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
                  button = questdlg(sprintf(question, line01), titlex,'OK','Reset filters','OK');
                  set(0,'DefaultUicontrolBackgroundColor',oldcolor)
                  
                  %
                  % reset order
                  %
                  orderlist  = cellstr(get(handles.popupmenu_order, 'String'));
                  order      = str2num(strrep(orderlist{orderindx},'automin:',''));
                  orderlist{1}= 'automin';
                  [tfx posord] = ismember(order,[-1 2 4 6 8]);
                  
                  set(handles.popupmenu_order, 'String',orderlist)
                  set(handles.popupmenu_order, 'Value',posord)
                  set(handles.popupmenu_dboct, 'Value',posord-1)
                  set(handles.popupmenu_dbdec, 'Value',posord-1)
                  handles.autorder  = 0;
                  
                  if strcmpi(button,'OK')
                        
                        set(handles.slider_highpass, 'Value', handles.memvalueh);
                        set(handles.slider_lowpass,  'Value', handles.memvaluel);
                        chksliders(hObject, eventdata, handles)
                        set(handles.edit_highpass, 'String', handles.mem6dbh);
                        set(handles.edit_lowpass,  'String', handles.mem6dbl);
                        set(handles.edit2_highpass, 'String', handles.mem3dbh);
                        set(handles.edit2_lowpass,  'String', handles.mem3dbl);
                        
                        % Update handles structure
                        guidata(hObject, handles);
                        
                        sliderson(hObject, eventdata, handles)
                        plotresponsefilter(hObject, eventdata, handles);
                        return
                  else
                        sliderson(hObject, eventdata, handles)
                        set(handles.slider_highpass, 'Value', 0);
                        set(handles.slider_lowpass,  'Value', fnyq/2);
                        chksliders(hObject, eventdata, handles)
                        handles.memvalueh = 0.1;
                        handles.mvalueh   = 0.1;             % memory value highpass
                        
                        ordervector = 2:2:8;
                        set(handles.popupmenu_order,'String', char([{'automin'}; cellstr(num2str(ordervector'))])) % set order list
                        set(handles.popupmenu_order,'Value', 2);
                        
                        % Update handles structure
                        guidata(hObject, handles);
                        plotresponsefilter(hObject, eventdata, handles);
                        return
                  end
            else
                  rolloffindx = get(handles.popupmenu_dboct,'Value');
                  rolloffindx = rolloffindx + 1;
                  set(handles.popupmenu_dboct,'Value', rolloffindx);
                  set(handles.popupmenu_dbdec,'Value', rolloffindx);
            end
            
            orderlist{1} = ['automin:' num2str(order)];
            set(handles.popupmenu_order, 'String', orderlist)
            set(handles.popupmenu_order, 'Value', 1)
            sliderson(hObject, eventdata, handles)
            plotresponsefilter(hObject, eventdata, handles);
            return
      end
end

% hfig = axes(handles.axes1);

if get(handles.radiobutton_freqr,'Value')
      h       = hfr;
      f       = f1;
      color   = [0 0 0.75];
      FRscale = get(handles.popupmenu_FRscale, 'Value');
      
      if FRscale==1
            ymax  = 1.25;
            ymin  = -0.075;
            ymaxb = 1;
            yminb = 0;
            plot(f, h, 'linewidth', 2, 'LineSmoothing','on','Color', color)
            ylabel('passband gain')
      else
            ymax  = 10;
            ymin  = -65;
            ymaxb = 0;
            yminb = -90;
            plot(f, 20*log10(h), 'linewidth', 2, 'LineSmoothing','on','Color', color)
            ylabel('passband gain in dB')
      end
      
      xlabel('frequency (Hz)')
      
      %
      % draw ideal filter response
      %
      colorband = [0.9922    0.9176    0.7961];
      alphaval  = 0.7;
      
      if ismember(labelf, {'Low-pass','High-pass','Band-pass'})
            
            if strcmpi(labelf,'High-pass')
                  valuelx = fnyq;
            else
                  valuelx = valuel;
            end
            
            patch([valueh valueh valuelx valuelx],[yminb ymaxb ymaxb yminb],'r',...
                  'facecolor',colorband,...
                  'edgecolor',colorband,...
                  'facealpha',alphaval)
      elseif ismember(labelf,'Stop-band (Parks-McClellan Notch)')
            patch([0 0 valuel-1.5 valuel-1.5],[yminb ymaxb ymaxb yminb],'r',...
                  'facecolor',colorband,...
                  'edgecolor',colorband,...
                  'facealpha',alphaval)
            patch([valueh+1.5 valueh+1.5 fnyq fnyq],[yminb ymaxb ymaxb yminb],'r',...
                  'facecolor',colorband,...
                  'edgecolor',colorband,...
                  'facealpha',alphaval)
      else
            patch([0 0 valuel valuel],[yminb ymaxb ymaxb yminb],'r',...
                  'facecolor',colorband,...
                  'edgecolor',colorband,...
                  'facealpha',alphaval)
            patch([valueh valueh fnyq fnyq],[yminb ymaxb ymaxb yminb],'r',...
                  'facecolor',colorband,...
                  'edgecolor',colorband,...
                  'facealpha',alphaval)
      end
      
      if typef~=2
            if iswarngain==1
                  yym = max(hfr);
                  
                  if yym>1
                        yym=0.3;
                  end
                  
                  xxm = hpzoom/5;
                  text(xxm, yym+0.2,' Losing passband gain!','FontSize',10)
                  text(xxm, yym+0.1,' Increase the order of the filter or select automin.','FontSize',10)
                  set(gca,'Color', 'y')
                  
            elseif iswarngain==2
                  
                  yym = max(hfr);
                  
                  if yym>1
                        yym=0.3;
                  end
                  
                  xxm = hpzoom/5;
                  text(xxm, yym+0.2,' Passband gain of 1 was overpassed!','FontSize',10)
                  text(xxm, yym+0.1,' Increase the order of the filter or select automin.','FontSize',10)
                  set(gca,'Color', 'y')
                  
            elseif iswarngain==3
                  
                  yym = max(hfr);
                  
                  if yym>1
                        yym=0.3;
                  end
                  
                  xxm = hpzoom/5;
                  text(xxm, yym+0.2,' Losing stopband attenuation','FontSize',10)
                  text(xxm, yym+0.1,' Increase the order of the filter or select automin.','FontSize',10)
                  set(gca,'Color', 'y')
                  
            elseif iswarnroff~=0
                  
                  yym = max(hfr);
                  
                  if yym>1
                        yym=0.3;
                  end
                  
                  xxm = hpzoom/5;
                  text(xxm, yym+0.2,' Unable to achieve specified cutoff (-6dB)','FontSize',10)
                  text(xxm, yym+0.1,' with this filter order.','FontSize',10)
                  set(gca,'Color', 'y')
            elseif iswarnroff==0 &&  iswarngain==0
                  set(gca,'Color', 'w')
            end
      else
            set(gca,'Color', 'w')
      end
      
      %       %
      %       % Axis limits for frequency response
      %       %
      %       xmaxp = str2num(char(get(handles.edit_xmaxplot, 'String')));
      %
      %       if isempty(xmaxp)
      %             xmaxp = [0 max(f)];
      %             handles.xmaxfreqr = xmaxp;
      %       else
      %             xmaxp = handles.xmaxfreqr;
      %       end
      %
      %       set(handles.edit_xmaxplot, 'String', num2str(xmaxp));
      
elseif get(handles.radiobutton_impr,'Value')
      h = hir;  % impulse
      f = f3;   %1:length(h);
      ymax  = max(h)*1.2;
      ymin  = min(h)*1.2;
      color = [0.78 0 0.1];
      stem(f, h, 'linewidth', 2, 'Color', color);
      xlabel('time (msec)')
      ylabel('amplitude')
      
      %       %
      %       % Axis limits for impulse response
      %       %
      %       xmaxp = str2num(char(get(handles.edit_xmaxplot, 'String')));
      %       if isempty(xmaxp)
      %             xmaxp = [0 max(f)];
      %             handles.xmaxpimpz = xmaxp;
      %       else
      %             xmaxp = handles.xmaxpimpz;
      %       end
      %       set(handles.edit_xmaxplot, 'String', num2str(xmaxp));
else
      return
end

%
% True attenuation value at specified cutoff frequency (it must be -6db, otherwise...)
%
if ~isempty(xdB_at_fx)
      
      attvaldB = round(mean(xdB_at_fx));
      
      if attvaldB==-6 && typef==0
            string4HA = ['Half-Amp(' num2str(attvaldB) 'dB)'];
            coloratt = 'k';
      else
            if typef~=2
                  attvalgain = 10^(attvaldB/20);
                  string4HA = [sprintf('%.2f',attvalgain) '-Amp(' num2str(attvaldB) 'dB)'];
                  
                  if attvaldB==-6 && typef==1
                        coloratt = 'k';
                  else
                        coloratt = 'r';
                  end
            else
                  string4HA = 'Center frequency';
                  coloratt = 'k';
            end
      end
      set(handles.text_halfamp,'String', string4HA, 'ForegroundColor', coloratt)
      set(handles.text_halfpow,'String', 'Half-Power(-3dB)', 'ForegroundColor', 'k')
else
      set(handles.text_halfamp,'String', '--- ???dB ---', 'ForegroundColor', 'r')
      set(handles.text_halfpow,'String', '--- ???dB ---', 'ForegroundColor', 'r')
end

%
% Axis limits for frequency response
%
xmaxp = str2num(char(get(handles.edit_xmaxplot, 'String')));

if isempty(xmaxp)
      xmaxp = [0 max(f)];
      if get(handles.radiobutton_fdatafr,'Value') || get(handles.radiobutton_freqr,'Value')
            handles.xmaxfreqr = xmaxp;
      else
            handles.xmaxpimpz = xmaxp;
      end
else
      if get(handles.radiobutton_fdatafr,'Value') || get(handles.radiobutton_freqr,'Value')
            xmaxp = handles.xmaxfreqr;
      else
            xmaxp = handles.xmaxpimpz;
      end
end

set(handles.edit_xmaxplot, 'String', num2str(xmaxp));

%
% Axis limits
%
axis([xmaxp  ymin ymax])
hle = legend(labelf);
set(hle, 'Color', 'none', 'Box', 'off')
handles.memvalueh  = valueh;
handles.mvaluel    = valuel;
handles.morder     = order;
handles.iswarngain = iswarngain;
handles.iswarnroff = iswarnroff;
sliderson(hObject, eventdata, handles)
handles.datafr.yf  = hfr;

% Update handles structure
guidata(hObject, handles);


if typef==1 || typef==2
      minboundarysamdist = handles.minboundarysamdist;
      if get(handles.checkbox_boundary,'Value')
            if minboundarysamdist<3*order
                  BackERPLABcolor = [ 1 1 0];
                  question =  ['You have set the checkbox for filtering between boundary events.\n'...
                        'Event codes ''boundary'' or -99 were found in your dataset.\n\n'...
                        'However, at least one of the segments among boundaries \n'...
                        'has fewer samples than 3 times the filter order you are currently setting.\n\n'...
                        'You may either decrese the order of the filter - if it is possible - (recommended),\n'...
                        'or uncheck the option for filtering between boundary events.'];
                  questionstr = sprintf(question);
                  titlex = 'ERPLAB: Filter order vs number of samples';
                  oldcolor = get(0,'DefaultUicontrolBackgroundColor');
                  set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
                  button = questdlg(questionstr, titlex,'OK','OK');
                  set(0,'DefaultUicontrolBackgroundColor',oldcolor)
                  return
            end
      end
end

% -------------------------------------------------------------------------
function drawidealresp(hObject, eventdata, handles, labelf, fnyq, valuel, valueh, yminb, ymaxb)

axes(handles.axes1)
colorband = [0.9922    0.9176    0.7961];
alphaval  = 0.7;

if ismember(labelf, {'Low-pass','High-pass','Band-pass'})
      
      if strcmpi(labelf,'High-pass')
            valuelx = fnyq;
      else
            valuelx = valuel;
      end
      
      patch([valueh valueh valuelx valuelx],[yminb ymaxb ymaxb yminb],'r',...
            'facecolor',colorband,...
            'edgecolor',colorband,...
            'facealpha',alphaval)
elseif ismember(labelf,'Stop-band (Parks-McClellan Notch)')
      patch([0 0 valuel-1.5 valuel-1.5],[yminb ymaxb ymaxb yminb],'r',...
            'facecolor',colorband,...
            'edgecolor',colorband,...
            'facealpha',alphaval)
      patch([valueh+1.5 valueh+1.5 fnyq fnyq],[yminb ymaxb ymaxb yminb],'r',...
            'facecolor',colorband,...
            'edgecolor',colorband,...
            'facealpha',alphaval)
else
      patch([0 0 valuel valuel],[yminb ymaxb ymaxb yminb],'r',...
            'facecolor',colorband,...
            'edgecolor',colorband,...
            'facealpha',alphaval)
      patch([valueh valueh fnyq fnyq],[yminb ymaxb ymaxb yminb],'r',...
            'facecolor',colorband,...
            'edgecolor',colorband,...
            'facealpha',alphaval)
end

% -------------------------------------------------------------------------
function popupmenu_dboct_Callback(hObject, eventdata, handles)

dboct = get(handles.popupmenu_dboct,'Value');

if get(handles.radiobutton_butter,'Value')
      set(handles.popupmenu_order,'Value', dboct+1)
      set(handles.popupmenu_dbdec,'Value', dboct)
end

%
% Plot corresponding response
%
if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
      plotresponsefilter(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function popupmenu_dboct_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_dbdec_Callback(hObject, eventdata, handles)

dbdec = get(handles.popupmenu_dbdec,'Value');

if get(handles.radiobutton_butter,'Value')
      set(handles.popupmenu_order,'Value', dbdec+1);
      set(handles.popupmenu_dboct,'Value', dbdec);
end

%
% Plot corresponding response
%
if get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles)
elseif get(handles.radiobutton_freqr,'Value') || get(handles.radiobutton_impr,'Value')
      plotresponsefilter(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
function popupmenu_dbdec_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function radiobutton_butter_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      
      unsetnotchpm(hObject, eventdata, handles)
      
      if get(handles.togglebutton_lowpass,'Value')==1 && get(handles.togglebutton_highpass,'Value')==0
            set(handles.checkbox_removedc, 'Value', 0);
            set(handles.checkbox_removedc, 'Enable', 'off');
            set(handles.slider_highpass, 'Value', 0);
            set(handles.slider_highpass, 'Enable', 'off')
            set(handles.togglebutton_highpass, 'Value', 0)
            set(handles.edit_highpass,'String','0')
            set(handles.edit_highpass,'Enable','off')
            set(handles.edit_highpass, 'BackgroundColor', [0.75 0.75 0.75]);
            set(handles.togglebutton_highpass, 'BackgroundColor', [0.8 0.8 0.75]);
            
      elseif get(handles.togglebutton_lowpass,'Value')==0 && get(handles.togglebutton_highpass,'Value')==1
            colorband = [0.9922    0.9176    0.7961];
            set(handles.checkbox_removedc, 'Value', 1);
            set(handles.checkbox_removedc, 'Enable', 'on');
            set(handles.slider_highpass, 'Enable', 'on')
            set(handles.togglebutton_highpass, 'Value', 1)
            set(handles.edit_highpass, 'BackgroundColor', [1 1 1]);
      end
      
      set(handles.radiobutton_fir,'Value',0)
      ordervector = 2:2:8;
      set(handles.popupmenu_order,'Enable','on')
      set(handles.popupmenu_dboct,'Enable','on')
      set(handles.popupmenu_dbdec,'Enable','on')
      set(handles.popupmenu_order,'String', char([{'automin'}; cellstr(num2str(ordervector'))])) % set order list
      set(handles.popupmenu_dboct,'String', num2str(6*ordervector')) % set db/oct list
      set(handles.popupmenu_dbdec,'String', num2str(20*ordervector')) % set db/dec list
      set(handles.popupmenu_order,'Value',2)
      set(handles.popupmenu_dboct,'Value',1)
      set(handles.popupmenu_dbdec,'Value',1)
      if get(handles.radiobutton_ufdatafr,'Value')
            plotresponse_uf_data(hObject, eventdata, handles);
      else
            plotresponsefilter(hObject, eventdata, handles);
      end
else
      set(handles.radiobutton_butter,'Value',1)
end

%--------------------------------------------------------------------------
function radiobutton_fir_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      
      unsetnotchpm(hObject, eventdata, handles)
      
      if get(handles.togglebutton_lowpass,'Value')==1 && get(handles.togglebutton_highpass,'Value')==0
            set(handles.checkbox_removedc, 'Value', 0);
            set(handles.checkbox_removedc, 'Enable', 'off');
            set(handles.slider_highpass, 'Value', 0);
            set(handles.slider_highpass, 'Enable', 'off')
            set(handles.togglebutton_highpass, 'Value', 0)
            set(handles.edit_highpass,'String','0')
            set(handles.edit_highpass, 'BackgroundColor', [0.75 0.75 0.75]);
            set(handles.togglebutton_highpass, 'BackgroundColor', [0.8 0.8 0.75]);
      elseif get(handles.togglebutton_lowpass,'Value')==0 && get(handles.togglebutton_highpass,'Value')==1
            colorband = [0.9922    0.9176    0.7961];
            set(handles.checkbox_removedc, 'Value', 1);
            set(handles.checkbox_removedc, 'Enable', 'on');
            set(handles.slider_highpass, 'Enable', 'on')
            set(handles.togglebutton_highpass, 'Value', 1)
            set(handles.edit_highpass, 'BackgroundColor', [1 1 1])
      else
            %...
      end
      
      highpasscutoff = str2num(get(handles.edit_highpass, 'string'));
      %lowpasscutoff  = str2num(get(handles.edit_lowpass,  'string'));
      
      if highpasscutoff>0 && highpasscutoff<0.2
            set(handles.edit_highpass, 'string','0.4')
            set(handles.slider_highpass, 'Value', 0.4)
      end
      
      set(handles.radiobutton_butter,'Value',0)
      ordervector = 4:4:4096;
      set(handles.popupmenu_order,'String', char([{'automin'}; cellstr(num2str(ordervector'))])) % set order list
      set(handles.popupmenu_dboct,'String', '---') % set db/oct list
      set(handles.popupmenu_dbdec,'String', '---') % set db/dec list
      set(handles.popupmenu_order,'Value',10)
      set(handles.popupmenu_dboct,'Value',1)
      set(handles.popupmenu_dbdec,'Value',1)
      
      handles.ishopermission = 0;
      % Update handles structure
      guidata(hObject, handles);
      if get(handles.radiobutton_ufdatafr,'Value')
            plotresponse_uf_data(hObject, eventdata, handles);
      else
            plotresponsefilter(hObject, eventdata, handles);
      end
else
      set(handles.radiobutton_fir,'Value',1)
end

%--------------------------------------------------------------------------
function radiobutton_PM_notch_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      valhp = get(handles.edit_highpass,'String');
      vallp = get(handles.edit_lowpass,'String');
      handles.valhp = valhp;
      handles.vallp = vallp;
      
      % Update handles structure
      guidata(hObject, handles);
      setnotchpm(hObject, eventdata, handles)
      if get(handles.radiobutton_ufdatafr,'Value')
            plotresponse_uf_data(hObject, eventdata, handles);
      else
            plotresponsefilter(hObject, eventdata, handles);
      end
else
      set(handles.radiobutton_PM_notch,'Value',1)
end

%--------------------------------------------------------------------------
function radiobutton_gaussian_Callback(hObject, eventdata, handles)

%------------------------------------------------------------------------
function setnotchpm(hObject, eventdata, handles)

set(handles.radiobutton_butter,'Value',0)
set(handles.radiobutton_fir,'Value',0)
set(handles.slider_highpass, 'Enable', 'on')
set(handles.slider_highpass, 'Value', 60);
set(handles.slider_lowpass, 'Value', 60);
set(handles.slider_lowpass, 'Visible', 'off')
set(handles.togglebutton_highpass, 'Value', 0)
set(handles.togglebutton_lowpass, 'Value', 0)
set(handles.togglebutton_lowpass, 'Visible', 'off')
set(handles.togglebutton_highpass, 'Visible', 'off')
set(handles.edit_highpass,'Enable','on')
set(handles.edit_highpass,'String','60')
set(handles.edit_lowpass,'Visible','off')
set(handles.edit_lowpass,'String','60')
set(handles.edit2_lowpass,'Visible','off')
set(handles.edit2_highpass,'Visible','off')
set(handles.checkbox_removedc, 'Enable', 'on');
set(handles.text_hzlp,'Visible','off')
set(handles.edit_highpass, 'BackgroundColor', [1 1 1]);
set(handles.popupmenu_order,'String', '180') % set db/oct list
set(handles.popupmenu_dbdec,'String', '---') % set db/dec list
set(handles.popupmenu_dboct,'String', '---') % set db/oct list
set(handles.popupmenu_order,'Value',1)
set(handles.popupmenu_dboct,'Value',1)
set(handles.popupmenu_dbdec,'Value',1)
set(handles.popupmenu_dboct,'Enable','off')
set(handles.popupmenu_dbdec,'Enable','off')
set(handles.text_halfpow,'Visible','off')
return

%------------------------------------------------------------------------
function unsetnotchpm(hObject, eventdata, handles)

if strcmp(get(handles.slider_lowpass,'Visible'),'off')
      set(handles.togglebutton_highpass, 'Visible', 'on')
      set(handles.togglebutton_highpass,'Value',1)
      set(handles.togglebutton_highpass, 'BackgroundColor', [1 1 0.5]);
      set(handles.checkbox_removedc, 'Enable', 'on');
      set(handles.togglebutton_lowpass, 'BackgroundColor', [0.8 0.8 0.75]);
      vals = get(handles.slider_highpass, 'Value');
      set(handles.edit_highpass,'String',sprintf('%.1f',vals));
      set(handles.slider_lowpass, 'Visible', 'on')
      set(handles.slider_lowpass, 'Value', 0)
      set(handles.slider_lowpass, 'Enable', 'off')
      set(handles.togglebutton_lowpass, 'Visible', 'on')
      set(handles.togglebutton_lowpass,'Value',0)
      set(handles.edit_lowpass,'String','0');
      set(handles.edit_lowpass,'Enable','off');
      set(handles.edit_lowpass, 'BackgroundColor', [1 1 1]);
      set(handles.text_hzlp,'Visible','on')
else
      set(handles.togglebutton_highpass, 'Visible', 'on')
      set(handles.togglebutton_lowpass, 'Visible', 'on')
      set(handles.edit_lowpass, 'BackgroundColor', [1 1 1]);
      set(handles.text_hzlp,'Visible','on')
end

set(handles.edit_lowpass,'Visible','on');
set(handles.edit2_lowpass,'Visible','on');
set(handles.edit2_highpass,'Visible','on');
set(handles.text_halfpow,'Visible','on')

%--------------------------------------------------------------------------
function edit_boundary_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_boundary_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function a_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_xmaxplot_Callback(hObject, eventdata, handles)

xmaxpstr = strtrim(get(handles.edit_xmaxplot, 'String'));
xmaxp    = str2num(xmaxpstr);

if isempty(xmaxp)
      msgboxText{1} =  'Your must enter a positive number greater than 0.1!';
      title = 'ERPLAB: Basic Filter Error';
      errorfound(msgboxText, title);
      set(handles.edit_xmaxplot, 'String', num2str(handles.xmaxfreqr))
      
      if get(handles.radiobutton_ufdatafr,'Value')
            plotresponse_uf_data(hObject, eventdata, handles);
      elseif get(handles.radiobutton_fdatafr,'Value')
            plotresponse_fd_data(hObject, eventdata, handles);
      else
            plotresponsefilter(hObject, eventdata, handles);
      end
      return
elseif length(xmaxp)==1
      if xmaxp<0.1
            msgboxText{1} =  'Your must enter a positive number greater than 0.1!';
            title = 'ERPLAB: Basic Filter Error';
            errorfound(msgboxText, title);
            set(handles.edit_xmaxplot, 'String', num2str(handles.xmaxfreqr))
            
            if get(handles.radiobutton_ufdatafr,'Value')
                  plotresponse_uf_data(hObject, eventdata, handles);
            elseif get(handles.radiobutton_fdatafr,'Value')
                  plotresponse_fd_data(hObject, eventdata, handles);
            else
                  plotresponsefilter(hObject, eventdata, handles);
            end
            
            return
      end
      
      xmaxp = [0 xmaxp];
      
elseif length(xmaxp)==2
      
      if xmaxp(1)>=xmaxp(2)
            msgboxText{1} =  'Frenquency range must be sorted [minf maxf].';
            title = 'ERPLAB: Basic Filter Error';
            errorfound(msgboxText, title);
            set(handles.edit_xmaxplot, 'String', num2str(handles.xmaxfreqr))
            
            if get(handles.radiobutton_ufdatafr,'Value')
                  plotresponse_uf_data(hObject, eventdata, handles);
            elseif get(handles.radiobutton_fdatafr,'Value')
                  plotresponse_fd_data(hObject, eventdata, handles);
            else
                  plotresponsefilter(hObject, eventdata, handles);
            end
            
            return
      end
      if xmaxp(1)<0 || xmaxp(2)<0
            msgboxText{1} =  'Your must enter 1 or 2 positive numbers.';
            title = 'ERPLAB: Basic Filter Error';
            errorfound(msgboxText, title);
            set(handles.edit_xmaxplot, 'String', num2str(handles.xmaxfreqr))
            
            if get(handles.radiobutton_ufdatafr,'Value')
                  plotresponse_uf_data(hObject, eventdata, handles);
            elseif get(handles.radiobutton_fdatafr,'Value')
                  plotresponse_fd_data(hObject, eventdata, handles);
            else
                  plotresponsefilter(hObject, eventdata, handles);
            end
            
            return
      end
      if abs(xmaxp(2)-xmaxp(1))<0.1
            msgboxText{1} =  'Bandwidth for plotting must be greater than 0.1 Hz.';
            title = 'ERPLAB: Basic Filter Error';
            errorfound(msgboxText, title);
            set(handles.edit_xmaxplot, 'String', num2str(handles.xmaxfreqr))
            
            if get(handles.radiobutton_ufdatafr,'Value')
                  plotresponse_uf_data(hObject, eventdata, handles);
            elseif get(handles.radiobutton_fdatafr,'Value')
                  plotresponse_fd_data(hObject, eventdata, handles);
            else
                  plotresponsefilter(hObject, eventdata, handles);
            end
            
            return
      end
else
      msgboxText{1} =  'Wrong frenquency range!';
      title = 'ERPLAB: Basic Filter Error';
      errorfound(msgboxText, title);
      set(handles.edit_xmaxplot, 'String', num2str(handles.xmaxfreqr))
      return
end

if get(handles.radiobutton_impr,'Value')
      handles.xmaxpimpz = xmaxp;
else
      handles.xmaxfreqr = xmaxp;
end

% Update handles structure
guidata(hObject, handles);

if get(handles.radiobutton_ufdatafr,'Value')
      plotresponse_uf_data(hObject, eventdata, handles);
elseif get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles);
else
      plotresponsefilter(hObject, eventdata, handles);
end

return

%--------------------------------------------------------------------------
function edit_xmaxplot_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function noncausal_Callback(hObject, eventdata, handles)
if ~get(hObject,'Value')
      set(hObject,'Value',1)
end

%--------------------------------------------------------------------------
function causal_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_FRscale_Callback(hObject, eventdata, handles)

if get(handles.radiobutton_ufdatafr,'Value')
      plotresponse_uf_data(hObject, eventdata, handles);
elseif get(handles.radiobutton_fdatafr,'Value')
      plotresponse_fd_data(hObject, eventdata, handles);
else
      plotresponsefilter(hObject, eventdata, handles);
end

















%--------------------------------------------------------------------------
function chksliders(hObject, eventdata, handles)

sH = get(handles.slider_highpass,'Value');
sL = get(handles.slider_lowpass,'Value');

if sH<0.001
      set(handles.slider_highpass,'Value', 0)
      set(handles.edit_highpass,'String', '0')
      set(handles.edit2_highpass,'String', '---')
      set(handles.slider_highpass,'Enable', 'off')
      set(handles.edit_highpass,'Enable', 'off')
      set(handles.edit2_highpass,'Enable', 'off')
      set(handles.togglebutton_highpass,'Value', 0)
      set(handles.checkbox_removedc,'Value', 0)
else
      set(handles.edit_highpass, 'String', sprintf('%.1f',sH));
end

if sL<0.001
      set(handles.slider_lowpass,'Value', 0)
      set(handles.edit_lowpass,'String', '0')
      set(handles.edit2_lowpass,'String', '---')
      set(handles.slider_lowpass,'Enable', 'off')
      set(handles.edit_lowpass,'Enable', 'off')
      set(handles.edit2_lowpass,'Enable', 'off')
      set(handles.togglebutton_lowpass,'Value', 0)
else
      set(handles.edit_lowpass, 'String', sprintf('%.1f',sL));
end

if sL<0.001 && sH<0.001
      set(handles.popupmenu_order,'Value', 2)
end

drawnow
return

%--------------------------------------------------------------------------
function pushbutton_refresh_Callback(hObject, eventdata, handles)

sHstr = sprintf('%.1f',get(handles.slider_highpass,'Value'));
sLstr = sprintf('%.1f',get(handles.slider_lowpass,'Value'));
set(handles.edit_lowpass,'String', sLstr)
set(handles.edit_highpass,'String', sHstr)
drawnow

plotresponsefilter(hObject, eventdata, handles);

%--------------------------------------------------------------------------
function sliderson(hObject, eventdata, handles)

if get(handles.togglebutton_highpass,'value')
      set(handles.slider_highpass,'Enable','on')
end

if get(handles.togglebutton_lowpass,'value')
      set(handles.slider_lowpass,'Enable','on')
end
drawnow

%--------------------------------------------------------------------------
function slidersoff(hObject, eventdata, handles)

if get(handles.togglebutton_highpass,'value')
      set(handles.slider_highpass,'Enable','off')
end

if get(handles.togglebutton_lowpass,'value')
      set(handles.slider_lowpass,'Enable','off')
end
drawnow

%--------------------------------------------------------------------------
function uipanel8_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_tip_cutoff_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function [ym f ylim] = plotresponse_uf_data(hObject, eventdata, handles)

[ym f ylim] = deal([]);
frecp = str2num(get(handles.edit_xmaxplot,'String'));

if isempty(frecp)
      return
end

ch = str2num(get(handles.edit_channels,'String'));

if isempty(ch)
      return
end

axes(handles.axes1);

posaxes1 = get(gca,'YLim');
msgtx = 'Working, please wait...';
text(mean(frecp)/3, posaxes1(2)/2, msgtx,'FontSize',14, 'color', 'k')
drawnow

if isempty(setxor(ch, [handles.datafr.chan])) % are equal?
      ym =  handles.datafr.ym;
      f  =  handles.datafr.f;
else
      ERPLAB = handles.ERPLAB;
      np = round(ERPLAB.srate/2);
      
      if iserpstruct(ERPLAB) % for erpset
            %             [ym f]  = fourierp(ERPLAB,ch,frecp(1),np,np);
            [ym f]  = fourierp(ERPLAB,ch,0,np,np);
            
      elseif iseegstruct(ERPLAB) % for erpset
            %             [ym f] = fourieeg(ERPLAB,ch,frecp(1),np,np);
            [ym f] = fourieeg(ERPLAB,ch,0,np,np);
            
      else
            return
      end
end

% % text(mean(frecp), posaxes1(2)/2, msgtx,'FontSize',14, 'color', 'g')
% % drawnow

[frecpxx frecpsam2] = min(abs(f-frecp(2)));
[frecpxx frecpsam1] = min(abs(f-frecp(1)));

FRscale = get(handles.popupmenu_FRscale, 'Value');
color  = [0 0.2 0];

if FRscale==1
      ymax  = max(ym)+0.2;
      ymin  = -0.075;
      plot(f(frecpsam1:frecpsam2), ym(frecpsam1:frecpsam2), 'linewidth', 2, 'LineSmoothing','on','Color', color)
      ylabel('Data amplitude')
else
      ymax  = 20*log(max(ym))+0.2;
      ymin  = -65;
      plot(f(frecpsam1:frecpsam2), 20*log10(ym(frecpsam1:frecpsam2)), 'linewidth', 2, 'LineSmoothing','on','Color', color)
      ylabel('Data amplitude in dB')
end

ylim = [ymin ymax];
xlabel('frequency (Hz)')
axis([frecp  ymin ymax])
hle = legend('Unfiltered data');
set(hle, 'Color', 'none', 'Box', 'off')
drawnow
handles.datafr.chan = ch;
handles.datafr.ym   = ym;
handles.datafr.f    = f;
% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------------
function plotresponse_fd_data(hObject, eventdata, handles)

valueh = get(handles.slider_highpass, 'Value');
valuel = get(handles.slider_lowpass,  'Value');

if valueh==0 && valuel==0
            msgtx = '--NO FILTERING--';
            no_filter(hObject, handles, msgtx)
      return
end

frecp = str2num(get(handles.edit_xmaxplot,'String'));

if isempty(frecp)
      return
end
ch = str2num(get(handles.edit_channels,'String'));
if isempty(ch)
      return
end

axes(handles.axes1);
%posaxes1 = get(gca,'YLim');
%msgtx    = 'Working, please wait...';
%text(mean(frecp), posaxes1(2)/2, msgtx,'FontSize',14, 'color', 'k')
%drawnow

[ydata f ylim] =  plotresponse_uf_data(hObject, eventdata, handles);
yfilter        =  plotresponsefilter(hObject, eventdata, handles);
yfildata       =  ydata.*yfilter';

FRscale = get(handles.popupmenu_FRscale, 'Value');
color   = [0.2 0 0];
ymin = ylim(1);
ymax = ylim(2);

if FRscale==1
      %ymax  = max(yfildata)+0.2;
      %ymin  = -0.075;
      plot(f, yfildata, 'linewidth', 2, 'LineSmoothing','on','Color', color)
      ylabel('Data amplitude')
else
      %ymax  = 20*log(ymax)+0.2;
      %ymin  = -65;
      plot(f, 20*log10(yfildata), 'linewidth', 2, 'LineSmoothing','on','Color', color)
      ylabel('Data amplitude in dB')
end

% text(mean(frecp), posaxes1(2)/2, msgtx,'FontSize',14, 'color', 'w') % erase text...temporary...
xlabel('frequency (Hz)')
axis([frecp  ymin ymax])
hle = legend('Filtered data');
set(hle, 'Color', 'none', 'Box', 'off')
drawnow

%--------------------------------------------------------------------------
function minboundarysamdist = boundarydistance(EVENTSTRUCT)

%
% Minimum number of sample among boundaries
%

if ischar(EVENTSTRUCT(1).type)
      ecpos = strmatch('boundary', {EVENTSTRUCT.type});
else
      ecpos = find([EVENTSTRUCT.type]==-99);
end

if isempty(ecpos)
      minboundarysamdist = inf;
else
      minboundarysamdist = min(diff([EVENTSTRUCT(ecpos).latency]));
end