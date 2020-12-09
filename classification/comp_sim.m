% Parameters
fast_mode = true; % (yes/no) only fit affine parameters not strokes?
compute_posterior = true; % multiply fit score by prior score

inputfile;

%if fast_mode && ~use_precomputed
%    fprintf(1,'Fast mode refits a model using only an affine transformation, rather than fitting the motor proram.\n');
%    warning_mode('Fast mode is for demo purposes only and was not used in paper results.')
%end

load('items_classification','cell_train','cell_test');
lib = loadlib;


num_runs = length(runs_to_fit);

Alphabet_Comparisons = cell(num_runs, num_runs);

for run_iter = 1:num_runs
for run_iter2 = 1:num_runs
	irun = runs_to_fit(run_iter);
	irun_other = runs_to_fit(run_iter2);


	irun
	irun_other

	all_prior_scores = cell(num_train,5);
	all_mean_fit_scores = cell(num_train, num_test);
	all_mean_posterior_scores = cell(num_train, num_test);
	all_max_fit_scores = cell(num_train, num_test);
	all_max_posterior_scores = cell(num_train, num_test);


	all_fit_scores = repmat(struct('Name', '', 'Datacell', []), 1, num_train);
	all_posterior_scores = repmat(struct('Name', '', 'Datacell', []), 1, num_train);

	num_train = length(train_row);
	num_test = length(test_row);

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

		prior_scores = G.scores;
		all_prior_scores(train_iter,:) = num2cell(prior_scores);

		fits_for_1_train = cell(num_test, 5);
		post_for_1_train = cell(num_test, 5);



		for test_iter = 1:num_test
		    itest = test_row(test_iter);

		    % refit models to new image
		    Mbest = cell(K,1);

		    fit_scores = nan(K,1);
		    
		    %fn_fit_test = fullfile('model_fits',makestr('run',irun_other,'_test',itest,'_G'));
		    %load(fn_fit_test,'G');
		    img_test = cell_test{irun_other}{itest}.img;
		    
		    for i=1:K
		        fprintf(1,'re-fitting parse %d of %d\n',i,K);
		        [Mbest{i},fscore] = FitNewExemplar(img_test,G.samples_type{i},lib,true,fast_mode);
		        fit_scores(i) = fscore;
		    end
		    

		    mean_fit_scores = mean2(fit_scores);	
			fits_for_1_train(itest,:) = num2cell(fit_scores);
		    all_mean_fit_scores(train_iter, test_iter) = num2cell(mean_fit_scores);
		    all_max_fit_scores(train_iter, test_iter) = num2cell(max(fit_scores));

		    if compute_posterior == true
		    	posterior_scores = prior_scores.*fit_scores;
		    	all_mean_posterior_scores(train_iter, test_iter) = num2cell(mean2(posterior_scores));
				post_for_1_train(itest,:) = num2cell(posterior_scores);
				all_max_posterior_scores(train_iter, test_iter) = num2cell(max(posterior_scores));
		    end

		    % save output structure
		    %pair = struct;
		    %pair.Mbest = Mbest;
		    %pair.fit_score = fit_score;
		    %pair.prior_scores = prior_scores;
	%	    fit_scores(test_iter,:,train_iter) = fit_score;

	%	    mean_scores = zeros(num_test, 1, num_train);
	%	    mean_fit_scores = mean2(all_fit_scores(test_iter,:,train_iter));

	%	    all_fit_scores(test_iter,:,train_iter) = fit_scores;	 

	%	    all_mean_fit_scores(test_iter,:,train_iter) = mean_fit_scores
		    
		end  

		all_fit_scores(train_iter).Name = strcat('T: ', int2str(itrain));
		all_fit_scores(train_iter).Datacell = fits_for_1_train;

		if compute_posterior == true
			all_posterior_scores(train_iter).Name = strcat('T: ', int2str(itrain));
			all_posterior_scores(train_iter).Datacell = post_for_1_train;
		end

	end
	results = struct;
	results.prior_scores = all_prior_scores;
	results.fit_scores = all_fit_scores;
	results.mean_fit_scores = all_mean_fit_scores;
	results.max_fit_Scores = all_max_fit_scores;


	results.posterior_scores = all_posterior_scores;
	results.mean_posterior_scores = all_mean_posterior_scores;
	results.all_max_posterior_scores = all_max_posterior_scores;

	Alphabet_Comparisons{irun, irun_other} = results;
end
end



%fitwmean_scores = [all_fit_scores,all_mean_fit_scores]

%save('outputfile.mat', 'results');
save('outputfile.mat', 'Alphabet_Comparisons');

%save('outputfile2.mat', 'all_prior_scores', 'all_fit_scores', 'all_posterior_scores');
