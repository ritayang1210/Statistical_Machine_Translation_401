function AM = align_ibm1(trainDir, numSentences, maxIter, fn_AM)
%
%  align_ibm1
% 
%  This function implements the training of the IBM-1 word alignment algorithm. 
%  We assume that we are implementing P(foreign|english)
%
%  INPUTS:
%
%       dataDir      : (directory name) The top-level directory containing 
%                                       data from which to train or decode
%                                       e.g., '/u/cs401/A2_SMT/data/Toy/'
%       numSentences : (integer) The maximum number of training sentences to
%                                consider. 
%       maxIter      : (integer) The maximum number of iterations of the EM 
%                                algorithm.
%       fn_AM        : (filename) the location to save the alignment model,
%                                 once trained.
%
%  OUTPUT:
%       AM           : (variable) a specialized alignment model structure
%
%
%  The file fn_AM must contain the data structure called 'AM', which is a 
%  structure of structures where AM.(english_word).(foreign_word) is the
%  computed expectation that foreign_word is produced by english_word
%
%       e.g., LM.house.maison = 0.5       % TODO
% 
% Template (c) 2011 Jackie C.K. Cheung and Frank Rudzicz
  
  global CSC401_A2_DEFNS
  
  AM = struct();
  
  % Read in the training data
  [eng, fre] = read_hansard(trainDir, numSentences);

  % Initialize AM uniformly 
  AM = initialize(eng, fre);

  % Iterate between E and M steps
  for iter = 1:maxIter
    AM = em_step(AM, eng, fre);
  end

  % Save the alignment model
  save( fn_AM, 'AM', '-mat'); 

  end





% --------------------------------------------------------------------------------
% 
%  Support functions
%
% --------------------------------------------------------------------------------

function [eng, fre] = read_hansard(mydir, numSentences)
%
% Read 'numSentences' parallel sentences from texts in the 'dir' directory.
%
% Important: Be sure to preprocess those texts!
%
% Remember that the i^th line in fubar.e corresponds to the i^th line in fubar.f
% You can decide what form variables 'eng' and 'fre' take, although it may be easiest
% if both 'eng' and 'fre' are cell-arrays of cell-arrays, where the i^th element of 
% 'eng', for example, is a cell-array of words that you can produce with
%
%         eng{i} = strsplit(' ', preprocess(english_sentence, 'e'));
%
  %eng = {};
  %fre = {};

  % TODO: your code goes here.
  eng = {};
  fre = {};

  % Read files
  DDE = dir( [ mydir, filesep, '*', 'e'] );
  DDF = dir( [ mydir, filesep, '*', 'f'] );
  lineCounter = 0;

  for iFile = 1:length(DDE)
    % Read each file and each sentence
    eLines = textread([mydir, filesep, DDE(iFile).name], '%s','delimiter','\n');
    fLines = textread([mydir, filesep, DDF(iFile).name], '%s','delimiter','\n');
    for l = 1:length(eLines)
      ELine = eLines{l};
      FLine = fLines{l};
      % Check if the max number of sentences is already reached
      if lineCounter >= numSentences
        return;
      end
      lineCounter = lineCounter + 1;
      eng{lineCounter} = preprocess(ELine, 'e');
      fre{lineCounter} = preprocess(FLine, 'f');
    end
  end
end


function AM = initialize(eng, fre)
%
% Initialize alignment model uniformly.
% Only set non-zero probabilities where word pairs appear in corresponding sentences.
%
  AM = {}; % AM.(english_word).(foreign_word)
  allAligns = {};

  % TODO: your code goes here
  for l = 1:length(eng)
    eSentence = strsplit(' ', eng{l});
    eSentence = eSentence(~cellfun(@isempty, eSentence));
    for eWordIndex = 1:length(eSentence)
      % Go through each word in each sentence and set up the alignments
      eWord = eSentence{eWordIndex};
      fSentence = strsplit(' ', fre{l});
      fSentence = fSentence(~cellfun(@isempty, fSentence));
      fSentence = fSentence(2:length(fSentence) - 1);
      if ~isfield(allAligns, eWord)
        allAligns.(eWord) = unique(fSentence);
      else
        allAligns.(eWord) = unique([fSentence, allAligns.(eWord)]);
      end
    end
  end

  % Set the probability for the alignment model
  alignFields = fieldnames(allAligns);
  for i = 1:numel(alignFields)
    alignField = alignFields{i};
    alignment = allAligns.(alignField);
    for j = 1:length(alignment)
      AM.(alignField).(alignment{j}) = 1 / length(alignment);
    end
  end

  AM.SENTSTART = {};
  AM.SENTEND = {};
  AM.SENTSTART.SENTSTART = 1;
  AM.SENTEND.SENTEND = 1;
end

function t = em_step(t, eng, fre)
% 
% One step in the EM algorithm.
%
  
  % TODO: your code goes here
  tCount = struct();
  eTotal = struct();

  for l = 1:length(fre)
    fSentence = fre{l};
    fSentence = strsplit(' ', fSentence);
    fSentence = fSentence(~cellfun(@isempty, fSentence));
    eSentence = eng{l};
    eSentence = strsplit(' ', eSentence);
    eSentence = eSentence(~cellfun(@isempty, eSentence));
    uniqueFSentence = unique(fSentence);
    uniqueESentence = unique(eSentence);
    for f = 1:length(uniqueFSentence)
      % Go through each unique french word in the sentence
      fWord = uniqueFSentence{f};
      fCount = sum(ismember(fSentence, fWord));
      denom_c = 0;
      for e = 1:length(uniqueESentence)
        % Go through each unique english word in the sentence and calculate denom_c
        eWord = uniqueESentence{e};
        if ~isfield(t, eWord) || ~isfield(t.(eWord), fWord)
          continue;
        end
        denom_c = denom_c + t.(eWord).(fWord) * fCount;
      end
      for e = 1:length(uniqueESentence)
        % Go through each unique english word in the sentence
        eWord = uniqueESentence{e};
        if ~isfield(t, eWord) || ~isfield(t.(eWord), fWord)
          continue;
        end
        if ~isfield(eTotal, eWord)
          eTotal.(eWord) = 0;
        end
        if ~isfield(tCount, eWord)
          tCount.(eWord) = struct();
        end
        if ~isfield(tCount.(eWord), fWord)
          tCount.(eWord).(fWord) = 0;
        end
        eCount = sum(ismember(eSentence, eWord));
        % Update tCound and eTotal
        toUpdate = (t.(eWord).(fWord) * fCount * eCount) / denom_c;
        tCount.(eWord).(fWord) = tCount.(eWord).(fWord) + toUpdate;
        eTotal.(eWord) = eTotal.(eWord) + toUpdate;
      end
    end
  end
  % Update the AM model
  eFields = fieldnames(eTotal);
  for i = 1:numel(eFields)
    eField = eFields{i};
    fFields = fieldnames(tCount.(eField));
    for j = 1:numel(fFields)
      fField = fFields{j};
      t.(eField).(fField) = tCount.(eField).(fField) / eTotal.(eField);
    end
  end
end

