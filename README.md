# MT-Domain-Adaptation

### ENV SETUP
1) `conda env create --name mt_proj_dev --file=environment.yml`
2) `conda activate mt_proj_dev`
3) `pip install fairseq sacrebleu sentencepiece`

### Running scripts
1) To prepare, make sure you have created an `outs/` folder somewhere then run
```
./dev-tools/nmt/prepare.sh da da-en.txt/outs/ 
/Users/daniel/Documents/MT-Domain-Adaptation/dev-tools/floresv1
/Users/daniel/Documents/MT-Domain-Adaptation/da-en.txt/train_test_dev/train.da-en
/Users/daniel/Documents/MT-Domain-Adaptation/da-en.txt/train_test_dev/dev.da-en
/Users/daniel/Documents/MT-Domain-Adaptation/da-en.txt/train_test_dev/test.da-en
```
2) To train, run the following
   `./dev-tools/nmt/train.sh da`
3) To eval, run the following
   `./dev-tools/nmt/translate.sh da`