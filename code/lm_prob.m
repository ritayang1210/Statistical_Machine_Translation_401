function logProb = lm_prob(sentence, LM, type, delta, vocabSize)
%
%  lm_prob
% 
%  This function computes the LOG probability of a sentence, given a 
%  language model and whether or not to apply add-delta smoothing
%
%  INPUTS:
%
%       sentence  : (string) The sentence whose probability we wish
%                            to compute
%       LM        : (variable) the LM structure (not the filename)
%       type      : (string) either '' (default) or 'smooth' for add-delta smoothing
%       delta     : (float) smoothing parameter where 0<delta<=1 
%       vocabSize : (integer) the number of words in the vocabulary
%
% Template (c) 2011 Frank Rudzicz

  logProb = -Inf;

  % some rudimentary parameter checking
  if (nargin < 2)
    disp( 'lm_prob takes at least 2 parameters');
    return;
  elseif nargin == 2
    type = '';
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  end
  if (isempty(type))
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  elseif strcmp(type, 'smooth')
    if (nargin < 5)  
      disp( 'lm_prob: if you specify smoothing, you need all 5 parameters');
      return;
    end
    if (delta <= 0) or (delta > 1.0)
      disp( 'lm_prob: you must specify 0 < delta <= 1.0');
      return;
    end
  else
    disp( 'type must be either '''' or ''smooth''' );
    return;
  end

  words = strsplit(' ', sentence);

  % TODO: the student implements the following
  % Remove empty string from the array
  words = words(~cellfun(@isempty, words));
  res = 0;
  for i = 2:length(words)
    delta_to_use = 0;
    if strcmp(type, 'smooth')
      % If type is set to smooth, use the passed in value for delta
      delta_to_use = delta;
    end
    word = words{i};
    bi_count = 0;
    uni_count = 0;
    if ~isfield(LM.bi, words{i - 1}) || ~isfield(getfield(LM.bi, words{i - 1}), word)
      % In the case where corresponding bigram is not found
      if ~strcmp(type, 'smooth')
        return;
      end
    else
      bi_count = getfield(LM.bi, words{i - 1}, word);
    end

    if isfield(LM.uni, words{i - 1})
      % In the case where corresponding unigram is not found
      uni_count = getfield(LM.uni, words{i - 1});
    elseif ~strcmp(type, 'smooth')
      return;
    end

    % Calculate the log probability
    res = res + log2((bi_count + delta_to_use) / (uni_count + delta_to_use * vocabSize));
  end

  logProb = res;
  % TODO: once upon a time there was a curmudgeonly orangutan named Jub-Jub.
return