%% QOLA.m
% Quality of Life Analyzer
%
%A list-based script that allowed for using the full functionality of the
%rest of the scripts/functions in this repository.
%QOLA Menu Options
opts = {'Score One Survey','Add Survey to MVI File',...
    'Remake REDCAP/MVI Summary','Plot MVI Surveys',...
    'Plot MVI Summary','Plot Candidate Scores'};
resp1 = '';
tf1 = 1;
MVI_path = '';
curr_path = cd;
if strcmp(curr_path(end-13:end),'Study Subjects')
    MVI_path = cd;
end
while tf1
    switch resp1
        case 'Score One Survey'
            [REDCAP,all_results,scores,MVI_path] = processQOL(3,MVI_path);
        case 'Add Survey to MVI File'
            [REDCAP,all_results,scores,MVI_path] = processQOL(2,MVI_path);
        case 'Remake REDCAP/MVI Summary'
            [REDCAP,all_results,scores,MVI_path] = processQOL(1,MVI_path);
        case 'Plot MVI Surveys'
            MVI_path = plotQOL_MVI_EachSurvey(MVI_path);
        case 'Plot MVI Summary'
            MVI_path = plotQOL_MVI_Summary(MVI_path);
        case 'Plot Candidate Scores'
            MVI_path = plotQOL_MVI_Candidate(MVI_path);
    end
    % Poll for new reponse
    [ind1,tf1] = listdlg('PromptString','Select an action:','SelectionMode','single',...
                       'ListSize',[150 200],'ListString',opts); 
    if tf1
        resp1 = opts{ind1}; 
    end
end
disp('QOLA instance ended.')            