function edf = EDF_read_simple(FilePath)

% Created: 28 Jan 2013, by Jan Bukartyk
% Edited:

% INFO:
% Reading the whole EDF file. All headers are all exported in strings


%% ---------------------- EXAMPLES ----------------------------------------
% W_read_simple (FilePath);
% W_read_simple ('c:\...');

% FilePath: 'c:\folder\...\filename.edf' - path with filename and extension


%% ---------------------- Output variable Structure -----------------------
% edf.header = 
%        PatientID: [1x80 char]
%      RecordingID: [1x80 char]
%        StartDate: '07.03.09'
%        StartTime: '00.00.00'
%         Reserved: [1x44 char]
%      DataRecords: 90           % for EDF+ (how many recording parts)
%         Duration: 10           % rec. duration in seconds
%     ChannelCount: 20
     
% edf.ch(1:ChannelCount) =
%     label
%     transducer
%     unit              EDF name: physical_dimension
%     physical_min      EDF name: physical_minimum
%     physical_max      EDF name: physical_maximum
%     digital_min       EDF name: digital_minimum
%     digital_max       EDF name: digital_maximum
%     filters           EDF name: prefiltering
%     number_of_samples
%     reserved
%     data


%% check if the path is valid and it is a file, not folder
D = dir(FilePath);
if isempty(D) || D.isdir == 1
   disp('Input Error: The input needs to be Filepath to a EDF file');
   return;
end


%% OPEN FILE FOR READING
fid = fopen(FilePath);


%% READ FILE HEADER

% Load the whole File Header
FileHeader = fread(fid,256)';

% Create a "File" structure containing the File Header

% (x) 'My EDF description.docx' bullet point

% (2)
edf.header.PatientID = char(FileHeader(9:88));
% Local patient identification
% For example:
% 		‘MCR-1-555-666 F 05-JUN-1975 Haagse_Harry’
% 		‘X X X 012’ where 012 is de-ID for the patient name

% (3)
edf.header.RecordingID = char(FileHeader(89:168));
% Local recording identification
% For example:
% 		‘Startdate 06-NOV-2007 PSG-1234/2002 NN Telemetry_03’
% 		‘Startdate 06-NOV-2007 X X X’

% (4)
edf.header.StartDate = char(FileHeader(169:176));
% Start date of recording
% 'dd.mm.yy'
% possible years 1985 - 2084

% (5)
edf.header.StartTime = char(FileHeader(177:184));
% Start time of recording
% 'hh.mm.ss'

% (6)
HeadersSize = str2double(char(FileHeader(185:192)));
% Used just for verification!
% Number of bytes for all headers (file header + channels header) /header record
% In other words index of the header's last byte
% this can be easily calculated from the other information


% (7)
edf.header.Reserved = char(FileHeader(193:236));
% Reserved
% EDF+:
%  ‘EDF+C’	for EDF+ … recording is continuous, not interrupted (EDF compatible!)
%  ‘EDF+D’	for EDF+ … recording is interrupted, not continuous

% (8)
edf.header.DataRecords = str2double(char(FileHeader(237:244)));
% Number of data records in EDF+ - for neurology, number of interrupted parts (data records)
% [# of recording parts]

% (9)
edf.header.Duration = str2double(char(FileHeader(245:252)));
% duration of a data record, in seconds
% [sec]

% (10)
edf.header.ChannelCount = str2double(char(FileHeader(253:256)));
% Number of signals/channels (ns) in EDF file (continuous) or each data record (multiple parts, EDF+)
% [# of channels]

%%


nCh = edf.header.ChannelCount; % Number of channels(signals)


%% READ DATA HEADER
% The data header contain headers for all channels (data signals)

% Vector of one Channel header field lenght
% CAUSION, one channel info is not continuous!
% - it is sorted by the header information below
% - first will be labels for all changes, then transducer types for all channels, etc.
DataHeader_1Ch_Indexes = ...
   [16 ; ... % * nCh ... labels (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
    80 ; ... % * nCh ... transducer types (e.g. AgAgCl electrode)
    8 ; ...  % * nCh ... physical dimensions (e.g. uV or degreeC)
    8 ; ...  % * nCh ... physical minimums (e.g. -500 or 34)
    8 ; ...  % * nCh ... physical maximums (e.g. 500 or 40)
    8 ; ...  % * nCh ... digital minimums (e.g. -2048)
    8 ; ...  % * nCh ... digital maximums (e.g. 2047)
    80 ; ... % * nCh ... prefilterings (e.g. HP:0.1Hz LP:75Hz)
    8 ; ...  % * nCh ... # of samples in each data record
    32] ; ...% * nCh ... reserved
    
% indexes of field beginings for all channels counted for
DataHeader_Indexes = nCh * DataHeader_1Ch_Indexes;

DataHeader = fread(fid,sum(DataHeader_Indexes));

%% Create a record structure edf.ch.  Populate it with description for each signal

% struct "edf.ch" field labels
dhFields = {...
    'label',...
    'transducer',...
    'unit',...
    'physical_min',...
    'physical_max',...
    'digital_min',...
    'digital_max',...
    'filters',...
    'number_of_samples',...
    'reserved'};

% Fill the fields with the header data
for k = 1:length(DataHeader_Indexes)
    if k == 1      
       FieldChar = char(reshape(DataHeader(1:DataHeader_Indexes(1)),DataHeader_1Ch_Indexes(1),nCh)');
       edf.ch = struct(dhFields{1}, cellstr(FieldChar));
    else
       FieldChar = char(reshape(DataHeader(sum(DataHeader_Indexes(1:k-1))+1:sum(DataHeader_Indexes(1:k))),DataHeader_1Ch_Indexes(k),nCh)');
       FieldValue = cellstr(FieldChar);
       [edf.ch.(dhFields{k})] = deal(FieldValue{:});
    end
end

clear FieldChar FieldValue;

%%

% nRec = edf.header.DataRecords; % Number of data records in EDF+
% not used right now as I am interested only in continuous data!!!!


%% READ DATA

% Calculating the end of headers (one byte before the data starts)
HeaderEnd = 256 + sum(DataHeader_Indexes); % Index of All headers end
if HeaderEnd ~= HeadersSize
   disp('Warning: The Headers_Size noted in the file header is different from the one calculated from Channel_Count and other parameters.');
end


SamplesPerCh = cellfun(@str2double, {edf.ch.number_of_samples}); % # of samples per Channel per Data Record
ChannelsCount = edf.header.ChannelCount;
DataRecords = edf.header.DataRecords;


for ch = 1 : ChannelsCount
   
   % inicialization for samples of the whole signal in all Data Records
   data = zeros(0,'int16');
   data(SamplesPerCh(ch) * DataRecords) = 0;
   
   for DR = 1 : DataRecords
      % PreviousEnd -> one Byte before the data starts
      PreviousEnd = HeaderEnd + 2* (sum(SamplesPerCh(:))*(DR-1) +     sum(SamplesPerCh(1:ch-1)));
                                  % Shifts to the right Data Record  %Shift to the right channel
                              % times 2 because 2 bytes number
                                   
      status = fseek(fid,PreviousEnd,-1); % point one Byte before the actual start
      if status == -1
         error('Error while reading Channel Data from the file');
      end
      
      % Read DATA for each channel - it is read as 2 Bytes per number (int16)
      data(SamplesPerCh(ch)*(DR-1)+1:SamplesPerCh(ch)*DR) = fread(fid, SamplesPerCh(ch), '*int16');
                        
   end
   
   edf.ch(ch).data = data;

end

fclose(fid);