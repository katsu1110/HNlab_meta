function list = listMaker(animal, task_extension, out_extension)
%%
% generate a list of ex-files 
% INPUT: animal ... 'kiwi', 'kaki', or 'mango': can be a cell array like
% {'kiwi', 'kaki', 'mango'}
%              task_extension ... for 2AFC disparity task, use 'rds.DXxDCxDC2xDX2'
%              out_extension ... if this is in the file-name, excluded from
%              the list
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
if nargin < 2; task_extension = {'rds.DXxDCxDC2xDX2','rds.DCxDXxDC2xDX2'} ; end
if nargin < 3; out_extension = {'recording', 'orientation', 'fixation', 'sort'}; end
lent = length(task_extension);
leno = length(out_extension);

% generate a list
lena = length(animal);
list = cell(1, lena);
for a = 1:lena
    c = 1; d = 1;
    cur_date = '1989.12.20';
    dirs = dir([datapath animal{a} '/**/*.mat']);
    fname_date = {}; bytes = [];
    for i = 1:length(dirs) % file
        % file name
        fname = [dirs(i).folder '/' dirs(i).name];
        fname = strrep(fname, '\', '/');
        
        % check whether it is a task of interest
        strmatch = zeros(1, lent);
        for j = 1:lent
            if contains(dirs(i).name, task_extension(j))
                strmatch(j) = 1;
            end
            for k = 1:leno
               if contains(fname, out_extension(k))
                  strmatch(j) = 0;
                  break
               end
            end
        end            
        if sum(strmatch) > 0
            try
                slash = strfind(fname, '/');
                date = fname(slash(end-1)+1:slash(end)-1);
                fname_date{d} = fname;
                bytes = [bytes, dirs(i).bytes];
                if ~strcmp(cur_date, date)
                    cur_date = date;
                    list{a}{c} = fname_date{bytes==max(bytes)};
                    disp([list{a}{c} ' added to the list!'])
                    fname_date = {}; bytes = [];
                    c = c + 1; d = 1;
                else
                    d = d + 1;
                end
            catch
                continue
            end
        end
    end
end

% autosave
save([datapath 'ses_list.mat'], 'list')