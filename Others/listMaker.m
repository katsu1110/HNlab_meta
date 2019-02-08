function list = listMaker(animal, task_extension)
%%
% generate a list of ex-files 
% INPUT: animal ... 'kiwi', 'kaki', or 'mango': can be a cell array like
% {'kiwi', 'kaki', 'mango'}
%              task_extension ... for 2AFC disparity task, use 'rds.DXxDCxDC2xDX2'
%
% OUTPUT: list ... cell array of list of sessions
%
% NOTE that if there are multiple files on the same session, the ex-file
% with the largest size is taken
%

% path to data folder
if ispc
    datapath = '\\172.25.250.112\nienborg_group\data\';
else
    datapath = '/gpfs01/nienborg/group/data/';
end

% task extension
if nargin < 2; task_extension = 'rds.DXxDCxDC2xDX2'; end

% generate a list
lena = length(animal);
list = cell(1, lena);
for a = 1:lena
    c = 1; d = 0;
    cur_date = '1989.12.20';
    dirs = dir([datapath animal{a} '/**/*.mat']);
    for i = 1:length(dirs)
        % file name
        fname = [dirs(i).folder '/' dirs(i).name];
        fname = strrep(fname, '\', '/');
        
        % check whether it is a task of interest
        fname_date = {}; bytes = [];        
        if contains(fname, task_extension)
            try
                slash = strfind(fname, '/');
                date = fname(slash(end-1)+1:slash(end)-1);  
                d = d + 1;
                fname_date{d} = fname;
                bytes = [bytes, dirs(i).bytes];
                if ~strcmp(cur_date, date)
                    cur_date = date;
                    d = 0;
                    list{a}{c} = fname_date{bytes==max(bytes)};
                    disp([list{a}{c} ' added to the list!'])
                    c = c + 1;
                end
            catch
                continue
            end
        end
    end
end

% autosave
save([datapath 'ses_list.mat'], 'list')