function L = find_corrupted_files(checkthispath)
%%
% find corrupted files in specified (absolute) path
%
% NOTE that only matlab files (.mat, .m, .fig) are checked
%

% % load list
% l = importdata('\\172.25.250.112\nienborg_group\nienborg_files_modified.out');
if nargin < 1
    if ispc        
        checkthispath = '\\172.25.250.112\nienborg_group\data';
    else
        checkthispath = '/gpfs01/nienborg/group/data';
    end
end

% list of matlab files
% checkfolder = {'kaki', 'kiwi', 'mango', 'Multichannel', 'human psychophysics'};
checkfolder = {'kaki', 'kiwi', 'mango', 'human psychophysics'};
L = {};
c = 1;
ext = {'.mat', '.fig', '.m'};
for f = 1:length(checkfolder)
    for i = 1:length(ext)
        try
            list = dir([checkthispath '/' checkfolder{f} '/**/*' ext{i}]);
            for j = 1:length(list)
                b = judgeCorrupted([list(j).folder '/' list(j).name], ext{i}, list(j).bytes);
                if b==1
                    L{c} = [list(j).folder '/' list(j).name];
                    disp(['corrupted? ' L{c}])
                    c = c + 1;
                else
                    disp(['Not corrupted: ' [list(j).folder '/' list(j).name]])
                end
            end
        catch
            continue
        end
    end
end
% 
% % check if the files are corrupted
% L = {};
% c = 1;
% for i = 1:length(list)
%     flist = list(i);
%     while flist.isdir==1
%         flist = dir([flist.folder '/' flist.name]);
%         flist = rmTemp(flist);
%     end
%     if judgeCorrupted(flist.name)==1
%         L{c} = [flist.folder '/' flist.name];
%         disp(['corrupted?: ' L{c}])
%         c = c + 1;
%     end
% end
%     folderlist = rmTemp(folderlist);
%     for a = 1:length(folderlist)
%         filelist = dir([folderlist(a).folder '/' folderlist(a).name]);
%         filelist = rmTemp(filelist);
%         for b = 1:length(filelist)
%             if filelist(b).isdir == 0
%                 if filelist(b).bytes > 0
%                     continue
%                 else
%                     L{c} = [filelist(b).folder '/' filelist(b).name];
%                     disp(['corrupted?: ' L{c}])
%                     c = c + 1;
%                 end
%             else
%                 sfilelist = dir([filelist(b).folder '/' filelist(b).name]);
%                 sfilelist = rmTemp(sfilelist);
%                 for d = 1:length(sfilelist)
%                     if sfilelist(d).isdir == 0
%                        if sfilelist(d).bytes > 0
%                             continue
%                        else
%                             L{c} = [sfilelist(d).folder '/' sfilelist(d).name];
%                             disp(['corrupted?: ' L{c}])
%                             c = c + 1;
%                        end 
%                     else
%                         ssfilelist = dir([sfilelist(d).folder '/' sfilelist(d).name]);
%                         ssfilelist = rmTemp(ssfilelist);
%                         for e = 1:length(ssfilelist)
%                             if ssfilelist(e).isdir == 0
%                                if ssfilelist(e).bytes > 0
%                                     continue
%                                else
%                                     L{c} = [ssfilelist(e).folder '/' ssfilelist(e).name];
%                                     disp(['corrupted?: ' L{c}])
%                                     c = c + 1;
%                                end  
%                             end
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end

% Convert cell to a table and use first row as variable names
T = cell2table(L);
 
% Write the table to a CSV file
writetable(T,[checkthispath '/corrupted_files_list.csv'])

% function flist = rmTemp(flist)
% flist = flist(3:end);
% out = zeros(1, length(flist));
% for f = 1:length(flist)
%     out(f) = contains(flist(f).name, '.') && contains(flist(f).name, '_');
% end
% flist(out==1) = [];

function b = judgeCorrupted(fname, ext, bytes)
b = 0;
% if bytes == 0
%     b = 1;
% end    
switch ext
    case '.mat'
        try
            a = load(fname);
            clear a
        catch
            b = 1;
        end
    case '.fig'
        try
            openfig(fname)
            close all
        catch
            b = 1;
        end
    case '.m'
        if bytes == 0
            b = 1;
        end
end