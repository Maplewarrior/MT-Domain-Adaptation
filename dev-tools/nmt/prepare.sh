# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#
#!/bin/bash

SRC=$1
RUN=$2
FLORES=$3
TRAIN_SET=$4
DEV_SET=$5
DEVTEST_SET=$6

TGT=en

BPESIZE=5000
TRAIN_MINLEN=1  # remove sentences with <1 BPE tokens
TRAIN_MAXLEN=1020  # remove sentences with >250 BPE tokens

SCRIPTS=$FLORES/scripts
SYSTEMBIN=$RUN
DATA=$SYSTEMBIN/data
DATABIN=$SYSTEMBIN/data-bin
mkdir -p $DATA $DATABIN

SRC_TOKENIZER="bash $SCRIPTS/indic_norm_tok.sh $SRC"
TGT_TOKENIZER="cat"  # learn target-side BPE over untokenized (raw) text
SPM_TRAIN=$SCRIPTS/spm_train.py
SPM_ENCODE=$SCRIPTS/spm_encode.py

#DEV_SET="$FLORES/data/wikipedia_en_ne_si_test_sets/wikipedia.dev.$SRC-en"
#DEVTEST_SET="$FLORES/data/wikipedia_en_ne_si_test_sets/wikipedia.devtest.$SRC-en"

cp $DEV_SET.$SRC $DATA/dev.$SRC
cp $DEV_SET.$TGT $DATA/dev.$TGT
cp $DEVTEST_SET.$SRC $DATA/devtest.$SRC
cp $DEVTEST_SET.$TGT $DATA/devtest.$TGT
cp $TRAIN_SET.$SRC $DATA/train.$SRC
cp $TRAIN_SET.$TGT $DATA/train.$TGT

echo "pre-processing dev/test/train data..."
$SRC_TOKENIZER $DATA/dev.$SRC     > $DATA/dev.tok.$SRC
$SRC_TOKENIZER $DATA/devtest.$SRC > $DATA/devtest.tok.$SRC
$SRC_TOKENIZER $DATA/train.$SRC   > $DATA/train.tok.$SRC
$TGT_TOKENIZER $DATA/dev.$TGT     > $DATA/dev.tok.$TGT
$TGT_TOKENIZER $DATA/devtest.$TGT > $DATA/devtest.tok.$TGT
$TGT_TOKENIZER $DATA/train.$TGT   > $DATA/train.tok.$TGT

# learn BPE with sentencepiece
python $SPM_TRAIN \
  --input=$DATA/train.tok.$SRC,$DATA/train.tok.$TGT \
  --model_prefix=$DATA/sentencepiece.bpe \
  --vocab_size=$BPESIZE \
  --character_coverage=1.0 \
  --model_type=bpe

# encode train/dv/test
python $SPM_ENCODE \
  --model $DATA/sentencepiece.bpe.model \
  --output_format=piece \
  --inputs $DATA/train.tok.$SRC $DATA/train.tok.$TGT \
  --outputs $DATA/train.bpe.$SRC $DATA/train.bpe.$TGT \
  --min-len $TRAIN_MINLEN --max-len $TRAIN_MAXLEN
for SPLIT in "dev" "devtest"; do \
  python $SPM_ENCODE \
    --model $DATA/sentencepiece.bpe.model \
    --output_format=piece \
    --inputs $DATA/$SPLIT.$SRC $DATA/$SPLIT.$TGT \
    --outputs $DATA/$SPLIT.bpe.$SRC $DATA/$SPLIT.bpe.$TGT
done

# binarize data
fairseq-preprocess \
  --source-lang $SRC --target-lang $TGT \
  --trainpref $DATA/train.bpe --validpref $DATA/dev.bpe --testpref $DATA/devtest.bpe \
  --destdir $DATABIN \
  --joined-dictionary \
  --workers 4
