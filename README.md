# QOL-PRO
This repositiory is intended to be used by the members of the Vestibular NeuroEngineering Laboratory at Johns Hopkins University and their approved collaborators for analysis of quality of life data.

This folder includes scripts and functions needed to take the output from the Multichannel Vestibular Implant (MVI) survey hosted on the Qualtrics website (https://jhmi.co1.qualtrics.com/jfe/form/SV_9QWv2hAGoxpoXcN). This survey may be given the applicants to the trial (referred to as candidates, will have subject name in the format R####) or individuals implanted with the MVI (referred to as  subjects, will have subject name in the format MVI###). 

The SOP in the MVI Trial details how to properly download the data from Qualtrics, including editting subject name and visit name when necessary. The .xlsx sheet should be updloaded the human server in the directory "Study Subjects\Qualtrics". The scripts in this directory will prompt the user to select the "Study Subjects" folder on the MVI server.

## Functionality and Example Commands

One the Qualtrics output file is in the appropriate path, there are a variety of commands that can be exectuted. 

### Summary of scores from all REDCAP candidates and MVI subjects

Make .xlsx/.mat files with the scores for all candidates (saved as "Study Subjects\Qualtrics\REDCAPCandidateScores") and subjects (saved as "Study Subjects\ALLMVI-SurveyResults"). MVI subjects are excluded from the set of candidates. The MVI subject summary is made by reading the "SubjectName_SurveyReponses.xlsx" present in each MVI subejct folder; make sure these files are up to date is in the next section of this document. The QOL function also returns the struct "REDCAP" with the relevant candidate data and cell "all_results" with the relevant MVI subject data. Demographics of the REDCAP candidates are displayed to the MATLAB command window.

##### Code:

QOL; % Select the "Remake REDCAP and MVI Summary Data" option when prompted

---or---

QOL(1);

---or---

[REDCAP,all_results] = QOL(1);

### Add Survey Responses to an MVI Subject's File

This should be run after *every* time an MVI subject fills out the Qualtrics surveys. The menu will prompt the experimenter to select the survey instance and confirm the appropriate visit name. If the survey is given outside of a visit, leave that field blank. It will locate the appropriate "SubjectName_SurveyReponses.xlsx" file to add the new survey to and rerun the MVI score summary (saved as "Study Subjects\ALLMVI-SurveyResults"). The QOL function will return the updated MVI summary "all_results" variable, as well as a cell called "scores" with the scores from the selected survey instance. The REDCAP candidate summary is *not* rerun in this step (see above section for how to do that) and the last created version will be returned if prompted.

##### Code:

QOL; % Select the "Add One Survey to MVI Excel File" option when prompted

---or---

QOL(2);

---or---

[REDCAP,all_results,scores] = QOL(2); %REDCAP can be replaced by a ~ if not needed

### Score a Single Survey

This can be run when an experimenter wants to quickly query the scores for one survey instance. The menu will prompt the experimenter to select the survey instance. The QOL function will return a cell called "scores" with the scores from the selected survey instance and display them to the MATLAB command window. The REDCAP candidate and MVI subject summary are *not* rerun in this step (see above sections for how to do that) and the last created versions of these files will be returned if prompted.

##### Code:

QOL; % Select the "Score One Survey" option when prompted

---or---

QOL(3);

---or---

[REDCAP,all_results,scores] = QOL(3); %REDCAP and all_reuslts can be replaced by a ~ if not needed

### Create Plots

Make sure the individual MVI subject survey documents ("SubjectName_SurveyReponses.xlsx") are up-to-date before running a plotting script. The plotting scripts will already internally rerun the QOL.m function to remake the summary MVI subject file and/or score a candidate.

#### plotQOL_MVI_EachSurvey.m

Allows the user to select which score/subscore to plot over time (panel A) and change from pre-op at 0.5, 1, and 2 years (panel B) for all MVI subjects. Plots one figure per score/subscore and saves .fig/.png files in "Study Subjects\Summary Figures" as the score name and date that the script was run.

##### Code:

plotQOL_MVI_EachSurvey.m;

#### plotQOL_MVI_Summary.m

This script was used to make the FDA 2021/2022 report figures, as well as sumary figures for the DSMB. The figures are generally suitable for PPT and word documents but resize as needed. Two .fig/.png files are saved in "Study Subjects\Summary Figures" as the date that the script was run on and the suffix of "SummaryQOLOverTime_AllSub" and "SummaryQOLPreOpChange_AllSub". As suggested by the names, the former shows the scores for all the subjects over time while the later plots the change from pre-operative baseline at 0.5, 1 and 2 years post-activation. For both figures the panels show overall scores for DHI (A), VADL (B), SF-36U (C), and HUI3 (D). Reference Chow et. al. 2021 in NEJM for information about these surveys.

Note: The sizing, YLim, and number of subjects is *hardcoded* and will need to be adjusted in the future.

##### Code:

plotQOL_MVI_Summary.m;

#### plotQOL_MVI_Candidate.m

This script is used to compare the DHI (panel A), VADL (panel B), SF-36U (panel C), and HUI3 (panel D) scores of one candidate (marker as a blue star) with the MVI subjects before implantation. Reference Chow et. al. 2021 in NEJM for information about these surveys. This script *does not* save the .fig file created, so it is up to the user to save it in the directory and format desired.

##### Code:

plotQOL_MVI_Candidate.m;

### Other Functions

#### QOL.m

[REDCAP,all_results,scores,MVI_path] = QOL;

The functionality of QOL.m has been described above. The function does have an additional "MVI_path" output term not shown in the coding examples that is fed into the plotting scripts so that the experimenter does not need to select the path a second time. 

Called by: plotQOL_MVI_EachSurvey.m, plotQOL_MVI_Summary.m, plotQOL_MVI_Candidate.m

Calls functions: scoreAllSurveys.m, REDCAP_Demographics.m

#### REDCAP_Demographics.m

surveys = REDCAP_Demographics(scores);

This function takes in the "ByDate" or "BySubject" tabs of the REDCAP struct and outputs the gender, ethnicity, racial, and age statistics. These categories are set by the NHIS survey.

Called by: QOL.m

#### scoreAllSurveys.m

[score_labs,all_scores,res] = scoreAllSurveys(surv,sub_row,surveys);

This function takes in the entire Qualtrics file loaded into MATLAB as a table "surv" and scores the surveys listed in input argment "surveys" for the survey instance in index "sub_row." It returns the score labels (score_labs), score values (all_scores) and alphanumerical reponses to each survey. Qualtrics outputs reponses as all numeric and this script will turn a number into the associated letter for surveys like DHI.

Called by: QOL.m

Calls functions: scoreSurvey.m

#### scoreSurvey.m

[subscores,values] = scoreSurvey(score_in,survey);

This function takes in the raw responses as "score_in" for the "survey" specified. It error handles for cells vs. text vs. numeric responses but may still need editting. *This is also the function to add new survey scoring protocols to (and update the survey list in QOL.m)*

Called by: scoreAllSurveys.m
