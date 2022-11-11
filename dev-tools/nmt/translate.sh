#!/bin/bash

SRC=$1

export CUDA_VISIBLE_DEVICES=0

fairseq-generate data-bin/ \
    --source-lang $SRC --target-lang en \
    --gen-subset test \
    --path checkpoints/checkpoint_best.pt \
    --beam 5 --lenpen 1.2 \
    --remove-bpe=sentencepiece \
    --sacrebleu
