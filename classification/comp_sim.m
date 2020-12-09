% Parameters
fast_mode = true; % (yes/no) only fit affine parameters not strokes?
inputfile;

%if fast_mode && ~use_precomputed
%    fprintf(1,'Fast mode refits a model using only an affine transformation, rather than fitting the motor proram.\n');
%    warning_mode('Fast mode is for demo purposes only and was not used in paper results.')
%end

load('items_classification','cell_train','cell_test');
lib = loadlib;

prior_scores = zeros(num_train,5);
%[rows,column] = size(prior_scores);
fit_scores = zeros(num_test, 5, num_train);

%img_train = cell_train{irun}{itrain}.img;
%img_test = cell_test{irun}{itest}.img;

for train_iter = 1:num_train
    itrain = train_row(train_iter);

    
% load previous model fit
fn_fit_train = fullfile('model_fits',makestr('run',irun,'_train',itrain,'_G'));
load(fn_fit_train,'G');
K = length(G.models); % add image to model class (removed to save memory)
    for i=1:K
    G.models{i}.I = G.img; 
    end

prior_scores(train_iter,:) = G.scores;

for test_iter = 1:num_test
    itest = test_row(test_iter);
    % refit models to new image
    Mbest = cell(K,1);
    fit_score = nan(K,1);
%    size(G.scores)
%    size(prior_scores(iter,:))
    
%    prior_scores(iter,:)
    
    %fn_fit_test = fullfile('model_fits',makestr('run',irun_other,'_test',itest,'_G'));
    %load(fn_fit_test,'G');
    img_test = cell_test{irun_other}{itest}.img;
    

    for i=1:K
        fprintf(1,'re-fitting parse %d of %d\n',i,K);
        [Mbest{i},fscore] = FitNewExemplar(img_test,G.samples_type{i},lib,true,fast_mode);
        fit_score(i) = fscore;
    end
    
    % save output structure
    %pair = struct;
    %pair.Mbest = Mbest;
    %pair.fit_score = fit_score;
    %pair.prior_scores = prior_scores;
    fit_scores(test_iter,:,train_iter) = fit_score;
 
    mean_scores = zeros(num_test, 1, num_train)
    mean_fit_scores = mean2(fit_scores(test_iter,:,train_iter))
    all_mean_fit_scores(test_iter,:,train_iter) = mean_fit_scores
    
%    fit_scores(:,:)
end  

end

fitwmean_scores = [fit_scores,all_mean_fit_scores]
save('outputfile2.mat', 'prior_scores', 'fit_scores');
