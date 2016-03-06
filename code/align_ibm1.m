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
  for iter=1:maxIter,
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

  DDE = dir( [ mydir, filesep, '*', 'e'] );
  DDF = dir( [ mydir, filesep, '*', 'f'] );
  lineCounter = 0;

  for iFile = 1:length(DDE)
    eLines = textread([mydir, filesep, DDE(iFile).name], '%s','delimiter','\n');
    fLines = textread([mydir, filesep, DDF(iFile).name], '%s','delimiter','\n');
    for l = 1:length(eLines)
      ELine = eLines{l};
      FLine = fLines{l};
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

  % TODO: your code goes here
  for l = 1:length(eng)
    eSentence = eng{l};
    fSentence = fre{l};
    fCount = length(unique(fSentence));
    for e = 1:length(eSentence)
      for f = 1:length(fSentence)
        AM.(eSentence{e}).(fSentence{f}) = 1 / fCount;
      end
    end
  end
end

function t = em_step(t, eng, fre)
% 
% One step in the EM algorithm.
%
  
  % TODO: your code goes here
tCount = struct();
eTotal = struct();
% for i = 1:length(eng)
%   eSentence = unique(eng{i});
%   for e = 1:leng(eSentence)
%     eWord = eSentence{e};
%     eTotal.(eWord) = 0;
%     for j = 1:length(fre)
%       fSentence = unique(fre{j});
%       for f = 1:length(fSentence)
%         fWord = fSentence{f};
%         tCount.(eWord).(fWord) = 0;
%       end
%     end
%   end
% end
for l = length(fre)
  fSentence = unique(fre{l});
  eSentence = unique(eng{l});
  for f = 1:length(fSentence)
    fWord = fSentence{f};
    fCount = sum(ismember(fre{l}, fWord));
    denom_c = 0;
    for e = 1:length(eSentence)
      eWord = eSentence{e};
      eCount = sum(ismember(eng{l}, eWord));
      denom_c = denom_c + t.(eWord).(fWord) * fCount;
    end
    for e = 1:length(eSentence)
      if ~isfield(eTotal, eWord)
        eTotal.(eWord) = 0;
      end
      if ~isfield(tCount, eWord)
        tCount.(eWord) = struct();
      end
      if ~isfield(tCount.(eWord), fWord)
        tCount.(eWord).(fWord) = 0;
      end
      tCount.(eWord).(fWord) = tCount.(eWord).(fWord) + t.(eWord).(fWord) * fCount * eCount / denom_c;
      eTotal.(eWord) = eTotal.(eWord) + t.(eWord).(fWord) * fCount * eCount / denom_c;
    end
  end
eFields = fieldnames(tCount);
for i = 1:numel(eFields)
  eField = eFields{i};
  jFields = fieldnames(eField);
  for j = 1:numel(jFields)
    jField = jFields{j};
    AM.(eField).(jField) = tCount.(eField).(jField) / eTotal.(eField);
  end
end

end

