function [subscores,values] = scoreSurvey(score_in,survey)
    switch survey
        case 'ABC'
            [subscores,values] = scoreABC(score_in);
        case 'AI'
            [subscores,values] = scoreAI(score_in);
        case 'BVQ'
            [subscores,values] = scoreBVQ(score_in);
        case 'DHI'
            [subscores,values] = scoreDHI(score_in);    
        case {'EQ5D','EQ-5D'} 
            [subscores,values] = scoreEQ5D(score_in);
        case 'HUI3'
            [subscores,values] = scoreHUI3(score_in);
        case 'NHIS'
            [subscores,values] = scoreNHIS(score_in);
        case 'OVAS'
            [subscores,values] = scoreOVAS(score_in);
        case {'SF36','SF-36'}
            [subscores,values] = scoreSF36(score_in);
        case {'SF6D','SF-6D'}
            [subscores,values] = scoreSF6D(score_in); 
        case 'THI'
            [subscores,values] = scoreTHI(score_in);
        case 'VADL'
            [subscores,values] = scoreVADL(score_in);
        case 'VAS'
            [subscores,values] = scoreVAS(score_in);
        case 'VSS'
            [subscores,values] = scoreVSS(score_in);
        otherwise
            subscores = {};
            values = [];
    end
end
%% Functions that make Scores and Subscores

%% Activites-Specific Balance Confidence Scale
function [ABC_subscores,ABC_score] = scoreABC(scores)
    % Input handling and error handling
    % 16 items
    % array or cell array of numbers 0 to 100
    ABC_subscores = {'ABC Overall'};
    if iscell(scores)&&isnumeric(scores{1})
        scores = [scores{:}];
    elseif iscell(scores)
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=16||any(~ismember(scores,0:100))
        ABC_score = NaN; 
        return;
    end
    % Scores and subscores
    ABC_score = round(mean(scores)); %Minimum change in this score is 0.6250 (10/16) so rounding to nearest one
end
%% Autophony Index
function [AI_subscores,AI_score] = scoreAI(scores)
    % Input handling and error handling
    % 26 items
    % array or cell array of numbers 0 to 4
    AI_subscores = {'AI Overall'};
    if iscell(scores)&&isnumeric(scores{1})
        scores = [scores{:}];
    elseif iscell(scores)
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=26||any(~ismember(scores,0:4))
        AI_score = NaN; 
        return;
    end
    % Scores and subscores
    AI_score = sum(scores); 
end
%% Bilateral Vestibulopathy Questionnaire
% As of 2022-09-07, there is no scoring system yet for the BVQ.
% This script will NEED TO BE UPDATED once there is
function [BVQ_subscores,BVQ_tot] = scoreBVQ(scores)
s = scores;
BVQ_subscores = {};
BVQ_tot = [];
end
%% Dizziness Handicap Index
function [DHI_subscores,DHI_all] = scoreDHI(scores)    
    % Input handling and error handling
    % 25 items
    % array or cell array of numbers 0,2,4
    % cell array of characters n,s,y or 0,2,4
    DHI_subscores = strcat(repmat({'DHI '},1,4),...
        {'Overall','Physical','Emotional','Functional'})';
    if iscell(scores)&&isnumeric(scores{1}) %cell array of numbers
        num_scores = [scores{:}];
    elseif iscell(scores) %cell array of characters
        num_scores = NaN(1,length(scores));
        if all(ismember(scores,{'y','s','n'})) %lowercase letters
            num_scores(contains(scores,'y')) = 4;
            num_scores(contains(scores,'s')) = 2;
            num_scores(contains(scores,'n')) = 0;
        elseif all(ismember(scores,{'Y','S','N'})) %uppercase letters
            num_scores(contains(scores,'Y')) = 4;
            num_scores(contains(scores,'S')) = 2;
            num_scores(contains(scores,'N')) = 0;
        elseif all(ismember(scores,{'0','2','4'})) %numbers
            num_scores = cellfun(@str2double,scores);
        else %invalid inputs
            DHI_all = NaN(4,1);
            return;
        end
    else %was a numeric array
        num_scores = scores;
    end
    if length(num_scores)~=25||any(~ismember(num_scores,[0,2,4]))
        DHI_all = NaN(4,1);
        return;
    end
    % Scores and subscores
    DHI_tot = sum(num_scores);
    P = [1,4,8,11,13,17,25];
    E = [2,9,10,15,18,20,21,22,23];
    F = [3,5,6,7,12,14,16,19,24];
    DHI_P = sum(num_scores(P));
    DHI_E = sum(num_scores(E));
    DHI_F = sum(num_scores(F));
    DHI_all = [DHI_tot;DHI_P;DHI_E;DHI_F];
end
%% Euroqol-5D-5L
function [EQ5D_subscores,EQ5D_all] = scoreEQ5D(scores)
    % Input handling and error handling
    % 7 items
    % array or cell array of numbers 0-100
    EQ5D_subscores = strcat(repmat({'EQ-5D '},1,7),...
        {'Overall','Mobility','Self-Care','Usual Activities','Pain/Discomfort','Anxiety/Depression','VAS'})';
    if iscell(scores)&&isnumeric(scores{1}) %cell array of numbers
        scores = reshape([scores{:}],[],1);
    elseif iscell(scores) %cell array of characters
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=7||any(~ismember(scores(1:5),1:5))||any(scores(6:7)<0|scores(6:7)>100)
        EQ5D_all = NaN(7,1); 
        return;
    end
    % Scores and subscores
    %Take from US Valudation of EQ-5D-5L Health States Using an Intermation Protocol
    %Pickard et al. 2019
    MO = [0,-0.096,-0.122,-0.237,-0.322];
    SC = [0,-0.089,-0.107,-0.220,-0.261];
    UA = [0,-0.068,-0.101,-0.255,-0.255];
    PD = [0,-0.060,-0.098,-0.318,-0.414];
    AD = [0,-0.057,-0.123,-0.299,-0.321];
    EQ5D_overall = 1+MO(scores(1))+SC(scores(2))+UA(scores(3))+PD(scores(4))+AD(scores(5));
    EQ5D_all = [EQ5D_overall;scores([1:5,7])];
end
%% Health Utilities Index Mark 3 
function [HUI3_subscores,HUI3_all] = scoreHUI3(scores)
    % Input handling and error handling
    % 15 items
    % array or cell array of numbers 1-6
    % cell array of characters a-f or 1-6
    HUI3_subscores = strcat(repmat({'HUI3 '},1,9),...
        {'Overall','Vision','Hearing','Speech','Ambulation','Dexterity','Emotion','Cognition','Pain'})';
    if iscell(scores)&&isnumeric(scores{1}) %cell array of numbers
        scores = [scores{:}];
    elseif iscell(scores) %cell array of characters
        if all(ismember(scores,{'a','b','c','d','e','f'})) %lowercase letters
            scores = double(char(scores))-double('a')+1;
        elseif all(ismember(scores,{'A','B','C','D','E','F'})) %uppercase letters
            scores = double(char(scores))-double('A')+1;
        elseif all(ismember(scores,{'1','2','3','4','5','6'})) %numbers
            scores = cellfun(@str2double,scores);
        else %invalid inputs
            HUI3_all = NaN(9,1); 
            return;
        end
    end
    if length(scores)~=15||any(~ismember(scores,1:6))
        HUI3_all = NaN(9,1); 
        return;
    else %Check response values, they should all be numbers now
        val = all(ismember(scores([1,2,5,6,11,13]),1:4))&...
            all(ismember(scores([3,4,7,8,12,14,15]),1:5))&...
            all(ismember(scores([9,10]),1:6));
        if ~val
            HUI3_all = NaN(9,1); 
            return;
        end
    end
    % Scores and subscores
    vision = [1,2,3,3;2,2,3,3;4,4,5,5;6,6,6,6];
    HUI3_vision = vision(scores(1),scores(2));
    hearing = [1,1,1,1,1;2,3,3,3,3;4,5,6,6,6;4,5,6,6,6;6,6,6,6,6];
    HUI3_hearing = hearing(scores(3),scores(4));
    speech = [1,1,1,1;2,3,5,5;4,4,5,5;4,4,5,5];
    HUI3_speech = speech(scores(5),scores(6));
    cognition = [1,2,2,5,6;3,4,4,5,6;5,5,5,5,6;6,6,6,6,6];
    HUI3_cognition = cognition(scores(11),scores(12));
    HUI3_ambulation = scores(9);
    HUI3_dexterity = scores(10);
    HUI3_emotion = scores(7);
    HUI3_pain = scores(8);
    %Main score calculation
    HUI3u_p(:,1) = [1.00;0.98;0.89;0.84;0.75;0.61]; %vision
    HUI3u_p(:,2) = [1.00;0.95;0.89;0.80;0.74;0.61]; %hearing
    HUI3u_p(:,3) = [1.00;0.94;0.89;0.81;0.68;NaN]; %speech
    HUI3u_p(:,4) = [1.00;0.93;0.86;0.73;0.65;0.58]; %ambulation
    HUI3u_p(:,5) = [1.00;0.95;0.88;0.76;0.65;0.56]; %dexterity
    HUI3u_p(:,6) = [1.00;0.95;0.85;0.64;0.46;NaN]; %emotion
    HUI3u_p(:,7) = [1.00;0.92;0.95;0.83;0.60;0.42]; %cognition
    HUI3u_p(:,8) = [1.00;0.96;0.90;0.77;0.55;NaN]; %pain
    HUI3pt(1,1) = HUI3u_p(HUI3_vision,1);
    HUI3pt(2,1) = HUI3u_p(HUI3_hearing,2);
    HUI3pt(3,1) = HUI3u_p(HUI3_speech,3);
    HUI3pt(4,1) = HUI3u_p(HUI3_ambulation,4);
    HUI3pt(5,1) = HUI3u_p(HUI3_dexterity,5);
    HUI3pt(6,1) = HUI3u_p(HUI3_emotion,6);
    HUI3pt(7,1) = HUI3u_p(HUI3_cognition,7);
    HUI3pt(8,1) = HUI3u_p(HUI3_pain,8);
    HUI3_overall = round(1.371*prod(HUI3pt) - 0.371,2); %same sig figs as subscores
    %Subscore calulation
    HUI3u_sub(:,1) = [1.00;0.95;0.73;0.59;0.38;0.00]; %vision
    HUI3u_sub(:,2) = [1.00;0.86;0.71;0.48;0.32;0.00]; %hearing
    HUI3u_sub(:,3) = [1.00;0.82;0.67;0.41;0.00;NaN]; %speech
    HUI3u_sub(:,4) = [1.00;0.83;0.67;0.36;0.16;0.00]; %ambulation
    HUI3u_sub(:,5) = [1.00;0.88;0.73;0.45;0.20;0.00]; %dexterity
    HUI3u_sub(:,6) = [1.00;0.91;0.73;0.33;0.00;NaN]; %emotion
    HUI3u_sub(:,7) = [1.00;0.86;0.92;0.70;0.32;0.00]; %cognition
    HUI3u_sub(:,8) = [1.00;0.92;0.77;0.48;0.00;NaN]; %pain
    HUI3pat(1,1) = HUI3u_sub(HUI3_vision,1);
    HUI3pat(2,1) = HUI3u_sub(HUI3_hearing,2);
    HUI3pat(3,1) = HUI3u_sub(HUI3_speech,3);
    HUI3pat(4,1) = HUI3u_sub(HUI3_ambulation,4);
    HUI3pat(5,1) = HUI3u_sub(HUI3_dexterity,5);
    HUI3pat(6,1) = HUI3u_sub(HUI3_emotion,6);
    HUI3pat(7,1) = HUI3u_sub(HUI3_cognition,7);
    HUI3pat(8,1) = HUI3u_sub(HUI3_pain,8);
    HUI3_all = [HUI3_overall;HUI3pat];
end
%% NHIS 8-group question to tell if BVH or not
function [NHIS_subscores,NHIS_score] = scoreNHIS(scores)
    % Input handling and error handling
    % 8 items
    % array or cell array of numbers 0-5
    % cell array of characters n,y and 0-5
    NHIS_subscores = {'NHIS Prediction'};
    if iscell(scores)&&isnumeric(scores{1}) %cell array of numbers
        num_scores = [scores{:}];
    elseif iscell(scores) %cell array of mostly characters
        num_scores = NaN(1,length(scores));
        scores(cellfun(@isnumeric,scores)) = {cellfun(@num2str,scores(cellfun(@isnumeric,scores)))};
        if all(ismember(scores,{'0','1','2','3','4','5'})) %numbers
            num_scores = cellfun(@str2double,scores);            
        elseif all(ismember(scores,{'y','n','0','1','2','3','4','5'})) %lowercase letters
            num_scores(contains(scores,'y')) = 1;
            num_scores(contains(scores,'n')) = 0;
            num_scores(7) = str2double(scores{7});
        elseif all(ismember(scores,{'Y','N','0','1','2','3','4','5'})) %uppercase letters
            num_scores(contains(scores,'Y')) = 1;
            num_scores(contains(scores,'N')) = 0;
            num_scores(7) = str2double(scores{7});
        else %invalid inputs
            NHIS_score = NaN;
            return;
        end
    else %was a numeric array
        num_scores = scores;
    end
    if length(num_scores)~=8||any(~ismember(num_scores([1:6,8]),0:1))||any(~ismember(num_scores(7),1:5))
        NHIS_score = NaN;
        return;
    else
        num_scores(7) = double(num_scores(7)>3);
    end
    % Scores and subscores
    if all(num_scores)
        NHIS_score = 1;
    else
        NHIS_score = 0;
    end
end
%% Oscillopsia and Disequilibrium Visual Analogue Scale
function [OVAS_subscores,OVAS_all] = scoreOVAS(scores)
    % Input handling and error handling
    % 4 items
    % array or cell array of numbers 0 to 11
    OVAS_subscores = {'OVAS Oscillopsia';'OVAS Disequilibrium'};
    if iscell(scores)&&isnumeric(scores{1})
        scores = [scores{:}];
    elseif iscell(scores)
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=4||any(~ismember(scores,0:11))
        OVAS_all = [NaN;NaN];
        return;
    else
        scores(scores==11) = NaN;
    end
    % Scores and subscores
    OVAS_all = [scores(2)-scores(1);scores(4)-scores(3)];
end
%% Short Form 6D
function [SF6D_subscores,SF6D_all] = scoreSF6D(scores)
    % Input handling and error handling
    % 6 items
    % array or cell array of numbers 1-6
    SF6D_subscores = strcat(repmat({'SF-6D '},1,7),...
        {'Utility','Physical Functioning','Role Limitations',...
        'Social Functioning','Bodily Pain','Mental Health','Vitality'})';
    %Indices that have the scoring pattern
    num6 = [1,4];
    num4 = 2;
    num5 = [3,5,6];
    if iscell(scores)&&isnumeric(scores{1}) %cell array of numbers
        scores = [scores{:}];
    elseif iscell(scores) %cell array of characters
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=6||any(~ismember(scores,1:6))
        SF6D_all = NaN(7,1);
        return;
    else %Check response values, they should all be numbers now
        val = all(ismember(scores(num4),1:4))&...
            all(ismember(scores(num5),1:5))&...
            all(ismember(scores(num6),1:6));
        if ~val
            SF6D_all = NaN(7,1); 
            return;
        end
    end    
    vec1 = [0,0.0069,0.0148,0.0572,0.0021,0.0731];
    vec2 = [0,0.0525,0.0447,0.0306];
    vec3 = [0,0.0228,0.0171,0.0507,0.0595];
    vec4 = [0,0.0240,0.0273,0.0408,0.0494,0.0796];
    vec5 = [0,0.0330,0.0309,0.0760,0.0743];
    vec6 = [0,0,0.0291,0.0269,0.0639];       
    % Scores and subscores
    %Utility
    SF6D_scores(1,1) = 1-sum(vec1(1:scores(1)))-sum(vec2(1:scores(2)))...
        -sum(vec3(1:scores(3)))-sum(vec4(1:scores(4)))...
        -sum(vec5(1:scores(5)))-sum(vec6(1:scores(6)));
    %Raw health states
    SF6D_scores(2:7,1) = scores;
    SF6D_all = SF6D_scores;
end
%% Short Form 36
function [SF36_subscores,SF36_all] = scoreSF36(scores)
    % Input handling and error handling
    % 36 items
    % array or cell array of numbers 1-6
    SF36_subscores = strcat(repmat({'SF-36 '},1,10),...
        {'Utility','Physical Functioning','Role Physical',...
        'Role Emotional','Vitality','Mental Health',...
        'Social Functioning','Bodily Pain','General Health','Health Change'})';
    %Indices that have the scoring pattern
    num5_hl = [1,2,20,22,34,36];
    num3 = 3:12;
    num2 = 13:19;
    num5_lh = [32,33,35];
    num6_hl = [21,23,26,27,30];
    num6_lh = [24,25,28,29,31];
    %Scoring Patterns
    vec5_hl = [100,75,50,25,0];
    vec3 = [0,50,100];
    vec2 = [0,100];
    vec5_lh = [0,25,50,75,100];
    vec6_hl = [100,80,60,40,20,0];
    vec6_lh = [0,20,40,60,80,100];
    if iscell(scores)&&isnumeric(scores{1}) %cell array of numbers
        scores = [scores{:}];
    elseif iscell(scores) %cell array of characters
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=36||any(~ismember(scores,1:6))
        SF36_all = NaN(10,1);
        return;
    else %Check response values, they should all be numbers now
        val = all(ismember(scores(num2),1:2))&...
            all(ismember(scores(num3),1:3))&...
            all(ismember(scores([num5_hl,num5_lh]),1:5))&...
            all(ismember(scores([num6_hl,num6_lh]),1:6));
        if ~val
            SF36_all = NaN(10,1); 
            return;
        end
    end    
    vals = NaN(36,1);
    vals(num2) = vec2(scores(num2));
    vals(num3) = vec3(scores(num3));
    vals(num5_hl) = vec5_hl(scores(num5_hl));
    vals(num5_lh) = vec5_lh(scores(num5_lh));
    vals(num6_hl) = vec6_hl(scores(num6_hl));
    vals(num6_lh) = vec6_lh(scores(num6_lh));    
    % Scores and subscores
    %Physical functioning
    SF36_scores(1,1) = mean(vals(3:12));
    %Role function/physical
    SF36_scores(2,1) = mean(vals(13:16));
    %Role function/emotional
    SF36_scores(3,1) = mean(vals(17:19));
    %Energy/Fatigue
    SF36_scores(4,1) = mean(vals([23,27,29,31]));
    %Emotional Well-being
    SF36_scores(5,1) = mean(vals([24,25,26,28,30]));
    %Social Functioning
    SF36_scores(6,1) = mean(vals([20,32]));
    %Pain
    SF36_scores(7,1) = mean(vals(21:22));
    %General Health
    SF36_scores(8,1) = mean(vals([1,33:36]));
    %Health Change
    SF36_scores(9,1) = vals(2);
    %Utility
    SF6D_score = round(SF36toSF6D(SF36_scores),2);
    SF36_all = [SF6D_score;SF36_scores];
end
%% Tinnitus Handicap Inventory
% 0-16, Grade 1, Slight
% 18-36, Grade 2, Mild
% 38-56, Grade 3, Moderate
% 58-76, Grade 4, Severe
% 78-100, Grade 5. Catastrophic
function [THI_subscores,THI_tot] = scoreTHI(scores)
    % Input handling and error handling
    % 25 items
    % array or cell array of numbers 0,2,4
    % cell array of characters n,s,y or 0,2,4
    THI_subscores = {'THI Overall'};
    if iscell(scores)&&isnumeric(scores{1}) %cell array of numbers
        num_scores = [scores{:}];
    elseif iscell(scores) %cell array of characters
        num_scores = NaN(1,length(scores));
        if all(ismember(scores,{'y','s','n'})) %lowercase letters
            num_scores(contains(scores,'y')) = 4;
            num_scores(contains(scores,'s')) = 2;
            num_scores(contains(scores,'n')) = 0;
        elseif all(ismember(scores,{'Y','S','N'})) %uppercase letters
            num_scores(contains(scores,'Y')) = 4;
            num_scores(contains(scores,'S')) = 2;
            num_scores(contains(scores,'N')) = 0;
        elseif all(ismember(scores,{'0','2','4'})) %numbers
            num_scores = cellfun(@str2double,scores);
        else %invalid inputs
            THI_tot = NaN;
            return;
        end
    else %was a numeric array
        num_scores = scores;
    end
    if length(num_scores)~=25||any(~ismember(num_scores,[0,2,4]))
        THI_tot = NaN;
        return;
    end
    % Scores and subscores
    THI_tot = sum(num_scores);
end
%% Vestibular Disorders Activities of Daily Living Scale 
function [VADL_subscores,VADL_all] = scoreVADL(scores)
    % Input handling and error handling
    % 28 items
    % array or cell array of numbers 0 to 12
    VADL_subscores = strcat(repmat({'VADL '},1,4),...
        {'Overall','Functional','Ambulation','Instrumental'})';
    if iscell(scores)&&isnumeric(scores{1})
        scores = [scores{:}];
    elseif iscell(scores)
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=28||any(~ismember(scores,0:12))
        VADL_all = NaN(4,1);
        return;
    else
        scores(scores<1|scores>10) = NaN;
    end
    % Scores and subscores
    VADL_tot = median(scores,'omitnan');
    VADL_F = median(scores(1:12),'omitnan');
    VADL_A = median(scores(13:21),'omitnan');
    VADL_I = median(scores(22:28),'omitnan');
    VADL_all = [VADL_tot;VADL_F;VADL_A;VADL_I];
end
%% Vertigo Visual Analogue Scale
function [VAS_subscores,VAS_all] = scoreVAS(scores)
    % Input handling and error handling
    % 9 items
    % array or cell array of numbers 0 to 11
    VAS_subscores = {'VAS Overall'};
    if iscell(scores)&&isnumeric(scores{1})
        scores = [scores{:}];
    elseif iscell(scores)
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=9||any(~ismember(scores,0:11))
        VAS_all = NaN;
        return;
    else
        scores(scores==11) = [];
    end
    % Scores and subscores
    VAS_all = round(mean(scores)*10);
end
%% Vertigo Symptom Scale
function [VSS_subscores,VSS_all] = scoreVSS(scores)
    % Input handling and error handling
    % 15 items
    % array or cell array of numbers 0 to 4
    VSS_subscores = strcat(repmat({'VSS '},1,3),...
        {'Overall','Vertigo','Autonomic'})';
    if iscell(scores)&&isnumeric(scores{1})
        scores = [scores{:}];
    elseif iscell(scores)
        scores = cellfun(@str2double,scores);
    end
    if length(scores)~=15||any(~ismember(scores,0:4))
        VSS_all = NaN(3,1);
        return;
    end
    % Scores and subscores   
    VSS_overall = sum(scores);
    VSS_vertigo = sum(scores([1,3,4,6,8,10,13,15]));
    VSS_anxiety = sum(scores([2,5,7,9,11,12,14]));
    VSS_all = [VSS_overall;VSS_vertigo;VSS_anxiety];
end
%% Functions Needed Within the Score Making

%% SF-36 Utility
function SF6D_score = SF36toSF6D(SF36_scores)
%Uses the coffecients from Model 1 in Ara et al. 2009 Predicting the Short
%Form-6D Preference-Baed Index Uing the Eight Mean Short Form-36 Health
%Dimension Scores
%SF36_scores input needs to be a column vector of SF-36 scores in this
%order (health change can be at the end and will be ignored):
%Physical Functioning
%Role Functioning/Physical
%Role Functioning/Emotional
%Energy/Fatigue
%Emotional Well-being
%Social Functioning
%Pain
%General Health
%[PF,RP,RE,VT,MH,SF,BP,GH]
SF36_scores = SF36_scores(1:8,:);
coeffs = [0.0994,0.0215,0.0394,0.0479,0.1269,0.1011,0.1083,0.014];
SF6D_score = (34.3814 + coeffs*SF36_scores)/100;
end

