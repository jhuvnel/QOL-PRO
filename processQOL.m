%% processQOL
%Processes the Excel file output from Qualtrics and provides user options
%for what to do.
%Assumes all the numeric responses were downloaded in accordance to the
%SOP on the MVI server under MVI/SOP
%No matter which option is selected, the .mat and .xlsx file with pooled
%REDCAP data will be saved in the respective folders.
%Opt 1 = just remake the REDCAP and MVI pooled .mat and .xlsx
%Opt 2 = add column to an MVI .xlsx file, AND remake MVI struct
%Opt 3 = return the scores for one instance of the survey being filled out
%(a quick score option) and load REDCAP/MVI files
%Outputs the REDCAP struct, pooled MVI data and one set of scores for opts
%2/3

function [REDCAP,all_results,scores,MVI_path] = processQOL(opt,MVI_path)
%% Figure out which version to run
opts = {'Remake REDCAP and MVI Summary Data','Add One Survey to MVI Excel File','Score One Survey'};
if nargin < 1
    [ind1,tf] = listdlg('PromptString','Select surveys to score.','ListString',opts,'SelectionMode','single','ListSize',[200 300]);
    if ~tf
        error('No process selected.')
    end
    opt = ind1;
end
if ~isnumeric(opt)||~ismember(opt,1:length(opts)) %Invalid input
    opt = 1; %Default option, happens regardless
end
if nargin < 2 || isempty(MVI_path)
    prompt = 'Select the MVI Study subject root folder.';
    MVI_path = uigetdir(prompt,prompt);
    if ~contains(MVI_path,'MVI')
        disp(['The selected path does not contain the text "MVI", so it may be wrong: ',MVI_path])
    end
end
%% Load in Qualtrics Excel File
surveys = {'HUI3','SF6D','SF36','EQ5D','DHI','VADL','ABC','VSS','VAS',...
    'OVAS','BVQ','THI','AI','NHIS'}; %Add as needed
% Load the raw, numeric survey data
Qualtrics_path = [MVI_path,filesep,'Qualtrics'];
files = dir([Qualtrics_path,filesep,'*Questionnaires*.xlsx']);
[~,t_ind] = sort(datetime({files.date}));
in_path = [Qualtrics_path,filesep,files(t_ind(end)).name];
%Load surveys
warning('off')
surv = readtable(in_path);
warning('on')
%REMOVE INCOMPLETE SURVEYS
if iscell(surv.Finished)
    surv.Finished = contains(surv.Finished,'True');
end
surv(~surv.Finished,:) = [];
if isdatetime(surv.EndDate(1))
    identity = strcat(surv.Q1_2,{' | '},surv.Q1_3,{' | '},datestr(surv.EndDate));
else
    identity = strcat(surv.Q1_2,{' | '},surv.Q1_3,{' | '},surv.EndDate);
end
subs = surv.Q1_2;
%% Run the options for this script
if opt == 1
    %% Save files with REDCAP Candidates who are NOT yet in the MVI trial
    is_cand = find(cellfun(@(x) x(1),subs)=='R'&surv.Finished==1&~contains(subs,{'R141'})); %Is a candidate
    sub_labs = cell(length(is_cand),7);
    score_mat = NaN(length(is_cand),51); %change when surveys change
    for i = 1:length(is_cand)
        h = is_cand(i);
        %Get the date and other characteristics
        date = {datestr(surv.EndDate(h),'dd-mmm-yyyy')};
        age = {str2double(surv.Q1_4_2{h})};
        if isempty(surv.Q1_4_2{h})
            age = NaN;
        end
        if isempty(surv.Q1_4_3{h})
            gender = {'U'};
        else
            gender = {upper(surv.Q1_4_3{h}(1))};
        end
        if isempty(surv.Q1_6(h))
            eth = {'U'};
        elseif surv.Q1_6(h)==1
            eth = {'NH'};
        else
            eth = {'H'};
        end
        race = strrep(strrep(strrep(strrep(strrep(surv.Q1_7(h),'1','W'),'2','B'),'3','A'),'4','N'),'5','I');
        if isempty(race{:})
            race = {'U'};
        end
        symp_resp = surv.Q15_8(h);
        symp_vec = {'<3mo','3-12mo','1-3yr','3-5yr','5-10yr','10-15yr','>15yr'};
        if isnan(symp_resp)
            symp_dur = {'U'};
        else
            symp_dur = symp_vec(symp_resp);
        end
        [score_labs1,scores] = scoreAllSurveys(surv,h,surveys);
        score_mat(i,:) = cell2mat(scores)';
        sub_labs(i,:) = [subs(h),date,age,gender,eth,race,symp_dur];
    end
    score_labs = [{'Subject','Date','Age','Gender','Ethnicity','Race','SymptomDuration'},strrep(strrep(strrep(score_labs1',' ','_'),'-',''),'/','')];
    scores = [cell2table(sub_labs),array2table(score_mat)];
    scores.Properties.VariableNames = score_labs;
    fname = 'REDCAPCandidateScores';
    writetable(scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','ByDate');
    REDCAP.ByDate = scores;
    scores = sortrows(scores,'Subject','ascend');
    writetable(scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','BySubject');
    REDCAP.BySubject = scores;
    %Write table with unique subjects only (if repeat measurements, take the
    %most recent on)
    %Remove subjects who have had these symptoms for <1yr or who did not
    %say
    scores(contains(scores.SymptomDuration,{'mo','U'}),:) = [];
    %Now fill in missing demographics
    %Age
    scores.Date = datetime(scores.Date);
    missing = find(isnan(scores.Age));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~isnan(scores.Age(contains(scores.Subject,sub))))
            temp = scores.Age(contains(scores.Subject,sub));
            temp(isnan(temp)) = [];
            scores.Age(missing(i)) = temp(1);
        end
    end
    %Gender
    missing = find(contains(scores.Gender,'U'));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~contains(scores.Gender(contains(scores.Subject,sub)),'U'))
            temp = scores.Gender(contains(scores.Subject,sub));
            temp(contains(temp,'U')) = [];
            scores.Gender(missing(i)) = temp(1);
        end
    end
    %Hispanic v/ non-Hispanic ethnicity
    missing = find(contains(scores.Ethnicity,'U'));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~contains(scores.Ethnicity(contains(scores.Subject,sub)),'U'))
            temp = scores.Ethnicity(contains(scores.Subject,sub));
            temp(contains(temp,'U')) = [];
            scores.Ethnicity(missing(i)) = temp(1);
        end
    end
    %Race
    missing = find(contains(scores.Race,'U'));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~contains(scores.Race(contains(scores.Subject,sub)),'U'))
            temp = scores.Race(contains(scores.Subject,sub));
            temp(contains(temp,'U')) = [];
            scores.Race(missing(i)) = temp(1);
        end
    end
    % Too many surveys per subject
    unique_subs = unique(scores.Subject);
    %If a subject fills out the survey twice in the same week, use the later one
    for i = 1:length(unique_subs)
        sub_i = find(contains(scores.Subject,unique_subs(i)));
        dates = scores.Date(sub_i);
        if length(dates)>1 && any(days(diff(dates))<7)
            scores(sub_i([days(diff(dates))<7;false]),:) = [];
        end
    end
    [~,ind_uniq] = unique(scores.Subject);
    uniq_scores = scores(ind_uniq,:);
    %Now make the table with subjects scores before and after, assumming 1 or 2
    %surveys per person
    rep_scores = scores;
    rep_scores.SurvNum = NaN(size(scores,1),1);
    for i = 1:length(unique_subs)
        sub_i = find(strcmp(rep_scores.Subject,unique_subs(i)));
        rep_scores.SurvNum(sub_i) = 1:length(sub_i);
        if(length(sub_i)) == 1
            rep_scores.SurvNum(sub_i) = NaN;
        end
    end
    rep_scores(rep_scores.SurvNum > 2,:) = [];
    rep_scores(isnan(rep_scores.SurvNum),:) = [];
    date_diff = days(rep_scores.Date(2:2:end) - rep_scores.Date(1:2:end))/30;
    month_range = 2; %the maximum range for deviation from the 6month target
    rep_scores(reshape(repmat(abs(date_diff'-6) > month_range,2,1),[],1),:) = [];
    REDCAP.unique = uniq_scores;
    REDCAP.repeated = rep_scores;
    writetable(uniq_scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','unique');
    writetable(rep_scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','repeated');
    save([Qualtrics_path,filesep,fname,'.mat'],'REDCAP')
    REDCAP_Demographics(REDCAP.BySubject);
    % Make a new pooled MVI subject file
    MVI_fnames = strcat(extractfield(dir([MVI_path,filesep,'MVI*R*',filesep,'MVI*_SurveyResponses.xlsx']),'folder'),filesep,extractfield(dir([MVI_path,filesep,'MVI*R*',filesep,'MVI*_SurveyResponses.xlsx']),'name'));
    subjects = strrep(extractfield(dir([MVI_path,filesep,'MVI*R*',filesep,'MVI*_SurveyResponses.xlsx']),'name'),'_SurveyResponses.xlsx','');
    all_results = cell(length(MVI_fnames),1);
    %Assumes they all have the same score order
    for i = 1:length(MVI_fnames)
        %Reads the first sheet as the right sheet, thankfully
        [~,~,scores2] = xlsread(MVI_fnames{i});
        all_results{i} = [repmat(subjects(i),1,size(scores2,2)-1);scores2(:,2:end)]';
    end
    %Trim off the excess
    all_results = [[{'Subject'},scores2(:,1)'];vertcat(all_results{:})];
    all_results(cellfun(@isnumeric,all_results(:,3)),3) = {''}; %Replace NaN with empty cell for visit name
    save([MVI_path,filesep','ALLMVI-SurveyResults.mat'],'all_results')
    writecell(all_results,[MVI_path,filesep','ALLMVI-SurveyResults.xlsx'])
    scores = []; %Not used because it represents scores for the one person requested
elseif opt == 2 
    %% Add to MVI Excel document
    %Select which row to score
    [sub_indx,tf] = listdlg('PromptString','Select surveys to score.','ListString',identity(end:-1:1),'SelectionMode','single','ListSize',[200 300]);
    if tf==0
        error('No surveys selected. Try again.')
    end
    sub_row = size(surv,1)+1-sub_indx;
    sub_name = surv.Q1_2{sub_row};
    %Select the file to put it into
    MVI_dir = extractfield(dir([MVI_path,filesep,'MVI*_R*']),'name');
    MVI_fnames = strcat(extractfield(dir([MVI_path,filesep,'MVI*R*',filesep,'MVI*_SurveyResponses.xlsx']),'folder'),filesep,extractfield(dir([MVI_path,filesep,'MVI*R*',filesep,'MVI*_SurveyResponses.xlsx']),'name'));
    rel_file = MVI_fnames(contains(MVI_fnames,sub_name));
    rel_dir = MVI_dir(contains(strrep(MVI_dir,'_',''),sub_name));
    if length(rel_file)==1 %Unique file exists as expected
        out_path = rel_file{:};
    elseif isempty(rel_file)&&length(rel_dir)==1 %MVI directory made but no file exists yet
        disp('MVI directory for this subject has been made but no file exists yet. Creating .xlsx file.')
        out_path = [MVI_path,filesep,rel_dir{:},filesep,strrep(rel_dir{:},'_',''),'_SurveyResponses.xlsx'];
        writetable(table(),out_path);
    elseif length(rel_file)>1||length(rel_dir)>1
        error(['More than one directory found for the subject name: ',sub_name,'. Unclear which file to add scores to.'])
    elseif isempty(rel_file)&&isempty(rel_dir)
        error(['No directories found for the subject name: ',sub_name,'. Create one in the MVI***R*** format and retry.'])
    end
    % Properly format the visit name
    %Get the right visit name
    visit = surv.Q1_3{sub_row};
    if isnumeric(visit)
        visit = num2str(visit);
    end
    %Remove the text so it can be standardized
    if contains(visit,'Visit')
        visit = strrep(strrep(visit,'Visit',''),' ','');
    elseif contains(visit,'visit')
        visit = strrep(strrep(visit,'visit',''),' ','');
    end
    val_vis = questdlg({'Does this visit name below look right? This will be the Excel column label.',visit},'','Yes','No','Yes');
    if ~strcmp(val_vis,'Yes')
        visit = inputdlg('Enter the correct visit name');
        visit = visit{:};
    end
    % Score
    [score_labs,scores,res] = scoreAllSurveys(surv,sub_row,surveys);
    % Figure out what column to put the responses in
    %Works for Excel columns A - ZZ
    Alphabet = num2cell('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    col_names = [Alphabet,strcat(reshape(repmat(Alphabet,26,1),[],1)',repmat(Alphabet,1,26))];
    %Find where the visit should go
    dates = readcell(out_path);
    %Get the date
    date = cellstr(string(surv.EndDate(sub_row),'dd-MMM-yyyy'));
    if isempty(dates) %Empty sheet
        col = 'B';
    else
        dates = dates(1,:);
        [~,b] = ismember(dates,date);
        if any(b) %already a column label
            col_num = find(b);
        else %add to the end
            col_num = length(b)+1;
        end
        col = col_names{col_num};
    end
    %Make labels for column 1
    col_labs = [{'Date';'Visit'};strcat('Q',cellfun(@num2str,num2cell(1:100),'UniformOutput',false))'];
    % Write to MVI Excel file
    %Write Column 1 labels
    writetable(cell2table([{'Date'};{'Visit'};score_labs]),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet','Scores','Range',['A1:A',num2str(length(scores)+2)]);
    %Write new results
    writetable(cell2table([date;{visit};scores]),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet','Scores','Range',[col,'1:',col,num2str(length(scores)+2)]);
    disp(identity(sub_row))
    disp([[{'Date'};{'Visit'};score_labs],[date;{visit};scores]])
    %Individual Responses
    for i = 1:length(surveys)
        test = res.(strrep(surveys{i},'-',''));
        %Write Column 1 labels
        writetable(cell2table(col_labs(1:length(test)+2)),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet',surveys{i},'Range',['A1:A',num2str(length(test)+2)]);
        %Write new results
        writetable(cell2table([date;{visit};test]),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet',surveys{i},'Range',[col,'1:',col,num2str(length(test)+2)]);
    end
    % Make the CRF
    CRF_path = [MVI_path(1:(strfind(MVI_path,'Study')-1)),'CRFs',filesep];
    fig = figure(1);
    set(fig,'Units','inches','Position',[1 1 8.5 11],'Color','w');
    examiner = 'EOV';
    msg = 'Completed'; %Normal completed message
    subject = strrep(char(rel_dir),'_','');
    visit = ['Visit ',visit];
    source_path = [MVI_path,filesep,char(rel_dir),filesep,visit,filesep,'Questionnaires'];
    dateval = char(datetime(surv.EndDate(sub_row),'Format','yyyy-MM-dd HH:mm'));
    switch subject
        case {'MVI011R031','MVI012R897','MVI013R864'}
            fold = 'IRB00335294 NIDCD';
        case {'MVI014R1219','MVI015R1209','R164','R1054'}
            fold = 'IRB00346924 NIA';
        otherwise %old protocol for MVI1-10 and R205
            fold = 'NA_00051349';
    end
    protocol = strrep(strrep(fold,' NIA',''),' NIDCD','');
    visit_fold = extractfield(dir([CRF_path,fold,filesep,subject,filesep,visit,' *-*']),'name');
    if isempty(visit_fold) %Non typical visit name found
        visit_fold = 'Visit Nx - (Day XXX) Monitor - X yrs Post-Act - visit applicable only if device still act';
    end
    out_CRF = [CRF_path,fold,filesep,subject,filesep,char(visit_fold),filesep,...
        '14_13 Questionnaires',filesep,'14_13_CRF_Questionnaires_',subject,'_',visit];
    % Make text
    CRF_txt = ['Case Report Form Protocol: ',protocol,newline,...
        'Case Report Form Version: 2024-03-29',newline,...
        'Case Report Form Test: Patient Reported Outcomes',newline,...
        'Subject ID: ',subject,newline,'Visit: ',visit,newline,...
        'General Status and Adverse Events: ',msg,newline,...
        'Jacobsen Dizziness Handicap Inventory (DHI): ',msg,newline,...
        'Vestibular Disorders-Activities of Daily Living (VADL): ',msg,newline,...
        'Health Utilities Index-3 (HUI3): ',msg,newline,...
        'Short Form-36 (SF-36): ',msg,newline,...
        'Tinnitus Handicap Inventory (THI): ',msg,newline,...
        'Autophony Index (AI): ',msg,newline,...
        '2008 National Health Interview Survey Balance Questions: ',msg,newline,...
        'EuroQol-5D-5L (EQ5D): ',msg,newline,...
        'Activities of Balance Confidence (ABC): ',msg,newline,...
        'Vertigo Symptom Scale (VSS): ',msg,newline,...
        'Vertical Visual Analogue Scale (VAS): ',msg,newline,...
        'Oscillopsia Visual Analogue Scale (oVAS): ',msg,newline,...
        'Short Form-6D (SF-6D): ',msg,newline,...
        'Bilateral Vestibulopathy Questionnaire (BVQ): ',msg,newline,...
        'Examiners: ',examiner,newline,'Times: ',dateval,newline,'Source Data: ',source_path];
    %Save as pdf
    clf;
    annotation('textbox','Position',[0 0 1 1],'EdgeColor','none','String',CRF_txt,'FitBoxToText','on','Interpreter', 'none')
    saveas(fig,[out_CRF,'.pdf'])
    % Make a new pooled MVI subject file
    subjects = strrep(MVI_dir,'_','');
    all_results = cell(length(MVI_fnames),1);
    %Assumes they all have the same score order
    for i = 1:length(MVI_fnames)
        %Reads the first sheet as the right sheet, thankfully
        scores2 = readcell(MVI_fnames{i});
        all_results{i} = [repmat(subjects(i),1,size(scores2,2)-1);scores2(:,2:end)]';
    end
    %Trim off the excess
    all_results = [[{'Subject'},scores2(:,1)'];vertcat(all_results{:})];    
    if any(cellfun(@isnumeric,all_results(:,3))) %Old MATLAB version
        all_results(cellfun(@isnumeric,all_results(:,3)),3) = {''}; %Replace NaN with empty cell for visit name
    else %2024-06-26 AIA noticed that column titles were tagged as "missing" results 
        ind = cellfun(@(x) any(ismissing(x)),all_results);
        ind(1,:) = 0;
        all_results(ind) = {''}; %Replace NaN with empty cell for visit name
    end
    save([MVI_path,filesep','ALLMVI-SurveyResults.mat'],'all_results')
    writecell(all_results,[MVI_path,filesep','ALLMVI-SurveyResults.xlsx'])
    % Load REDCAP most recent file
    try
        load([Qualtrics_path,filesep,'REDCAPCandidateScores.mat'],'REDCAP')
    catch
        REDCAP = [];
    end
elseif opt==3 
    %% Score one survey instance
    %Select which row to score
    [indx,tf] = listdlg('PromptString','Select surveys to score.','ListString',identity(end:-1:1),...
        'SelectionMode','single','ListSize',[200 300]);
    if tf==0
        error('No surveys selected. Try again.')
    end
    sub_row = size(surv,1) + 1 - indx;
    [score_labs,all_scores] = scoreAllSurveys(surv,sub_row,surveys);
    scores = [{'Subject',identity{sub_row}};score_labs,all_scores];
    disp(scores)
    % Load REDCAP most recent file
    try
        load([Qualtrics_path,filesep,'REDCAPCandidateScores.mat'],'REDCAP')
    catch
        REDCAP = [];
    end
    % Load MVI most recent all_results file
    try
        load([MVI_path,filesep','ALLMVI-SurveyResults.mat'],'all_results')
    catch
        all_results = [];
    end
end
disp('Done!')
end