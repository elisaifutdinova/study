function [channels,tag_pos,tag_type,channel_name,fsamp]=easy2matlab(name_file);
%easy2matlab - convert BrainScope file format to matlab matrix representation
%
%function [channels,tag_pos_time,tag_type,channel_name,fsamp]=easy2matlab(name_file);
%
%channels 		 	- each row is one channel
%tag_pos_time			- tag time position
%tag_type			- tag type, 0 -> start of the event, 5 -> the end 
%channel_name			- channel name according to international 10-20 system
%fsamp				- sampling frequency
%name_file			- name of the file to be proccesed in the current directory
%
%EXAMPLE:
%[channels,tag_pos_time,tag_type,channel_name,fsamp]=easy2matlab('kp4.d');

%open d file
fid=fopen(name_file,'r');

%Read standard header information
sign=fread(fid,1,'schar');			%version of software record program
sign=fscanf(fid,'%15s',1);

status = fseek(fid,15,'bof');
ftype=fscanf(fid,'%c',1);			%file type ('d' or 'r' file)

status = fseek(fid,16,'bof');
nchan=fread(fid,1,'uchar');		%number of channels

status = fseek(fid,17,'bof');
naux=fread(fid,1,'uchar');			%number of auxiliary channels

status = fseek(fid,18,'bof');
fsamp=fread(fid,1,'ushort');		%sampling frequency

status = fseek(fid,20,'bof');
nsamp=fread(fid,1,'ulong');		%number of samples

status = fseek(fid,24,'bof');
dval=fread(fid,1,'uchar');			%validation field

status = fseek(fid,25,'bof');
unit=fread(fid,1,'uchar');			%scaling factor in the data recalibration

status = fseek(fid,26,'bof');
zero=fread(fid,1,'short');			%numerical code to physical zero

status = fseek(fid,28,'bof');
data_org=fread(fid,1,'ushort');	%data offset

status = fseek(fid,30,'bof');
xhdr_org=fread(fid,1,'ushort');	%extended header offset

%Read extended header information
offset_xhdr=xhdr_org*16;			%16 - one paragraph
TT='5454';								%ID of Tag Table
CN='4E43';								%Channels name ID
idhexa='';
offset_x=offset_xhdr;				%The begining of xhdr
lenid=-2;								%For the first run go to the begining of xhdr


%Find channels name
while ~strcmp(idhexa,CN);
   	offset_x=offset_x+lenid+2;
      status = fseek(fid,offset_x,'bof');
	   id=fread(fid,1,'ushort');
      idhexa=dec2hex(id);
      if strcmp(idhexa,'0') break;end;			%There is no channel name field, we reach the end of extended header
      offset_x=offset_x+2;			
		status = fseek(fid,offset_x,'bof');		%Read length
      lenid=fread(fid,1,'ushort');	
end;

offset_x=offset_x+2;									%Skip length
channel_name=zeros(lenid/4,4);					%One channel name has 4 bytes
%Read chnnels name
for i=1:lenid/4;
   channel_name(i,1:4)=fscanf(fid,'%4s',1);
end;

%Find Tag Table
idhexa='';
offset_x=offset_xhdr;				%The begining of xhdr
lenid=-2;								%For the first run go to the begining of xhdr

while ~strcmp(idhexa,TT);
      	
      offset_x=offset_x+lenid+2;
      status = fseek(fid,offset_x,'bof');
	   id=fread(fid,1,'ushort');
      idhexa=dec2hex(id);
      if strcmp(idhexa,'0') break;end;
      offset_x=offset_x+2;			
		status = fseek(fid,offset_x,'bof');		%Read length
      lenid=fread(fid,1,'ushort');	
		
end;

%Read offsets of Tag Table and lengths  
offset_x=offset_x+2;									%Skip length
def_len_TT=fread(fid,1,'ushort');
status = fseek(fid,offset_x+2,'bof');
list_len_TT=fread(fid,1,'ushort');
status = fseek(fid,offset_x+2+2,'bof');
def_off_TT=fread(fid,1,'ulong');
status = fseek(fid,offset_x+2+2+4,'bof');
list_off_TT=fread(fid,1,'ulong');

%Read Tag Table
%Tags are saved as 3 bytes unsigned integers
%The tag position is 3 bytes, hence ve disgard the uppermost byte - mask1
mask1=16777215;					%FFFFFF in hexa (6F*4=24)
%Tag type is the uppermost byte - mask2
mask2=15*16^7+15*16^6;			%FF000000;
number_tag=floor(list_len_TT/4);			%the Tag Table is 4 byte structure
%tags=zeros(1,number_tag);tag_pos=tags;tag_type=tags;
offset_tag=list_off_TT;

status = fseek(fid,list_off_TT,'bof');

for i=1:number_tag
   
   tags(i)=fread(fid,1,'ulong');
   offset_tag=offset_tag+4;
   status = fseek(fid,offset_tag,'bof');

end;

tag_pos=bitand(mask1,tags);					%Get tag position
%Get tag type
tag_type=bitand(mask2,tags);					
tag_type=bitshift(tag_type,-24);		%Right shift to get 8bit number

status = fseek(fid,offset_xhdr,'bof');

%Prepare time axis
duration=nsamp/fsamp;
duration_min=duration/60;
timebit=1/fsamp;
time=timebit:timebit:duration;

%Read data
offset_data=data_org*16;
status = fseek(fid,offset_data,'bof');
channels=fread(fid,[nchan,nsamp],'short');

%Scale data to microVolts
channels=channels/unit;

%Scale tag position to time
tag_pos_time=tag_pos*timebit;



   








