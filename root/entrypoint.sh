#!/bin/bash
conda init bash
source ~/.bashrc

if [ ! -d /root/miniconda/envs/vicuna ]; then
echo "=========================================" > /proc/1/fd/1
echo "CONDA CREATE vicuna" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
conda create -n vicuna python=3.9 -y > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
echo "CONDA ACTIVATE vicuna" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
conda activate vicuna
echo "=========================================" > /proc/1/fd/1
echo "INSTALLING DEPENDENCIES: Torch, cudatoolkit & protobuf (WILL TAKE A LONG TIME)" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117 > /proc/1/fd/1
conda install -c conda-forge cudatoolkit-dev -y > /proc/1/fd/1
pip install protobuf==3.20 > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
echo "DEPENDENCIES ALL INSTALLED" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
fi

echo "=========================================" > /proc/1/fd/1
echo "SETUP CUDA HOME & REACTIVATE vicuna" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
conda env config vars set CUDA_HOME="/root/miniconda/envs/vicuna" > /proc/1/fd/1
conda deactivate > /proc/1/fd/1
conda activate vicuna > /proc/1/fd/1

echo "=========================================" > /proc/1/fd/1
echo "INSTALLING REQUIREMENT for Fastchat" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
cd /root/FastChat
pip3 install -e . > /proc/1/fd/1

if [ ! -d /root/FastChat/repositories/GPTQ-for-LLaMa ]; then
echo "=========================================" > /proc/1/fd/1
echo "CREATING REPOSITORIES & DOWNLOADING GPTQ for LLaMa" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
mkdir repositories
cd repositories
git clone https://github.com/oobabooga/GPTQ-for-LLaMa.git -b cuda > /proc/1/fd/1
cd GPTQ-for-LLaMa
fi

if [ ! -f /root/miniconda/envs/vicuna/lib/python3.9/site-packages/quant_cuda-0.0.0-py3.9-linux-x86_64.egg ]; then
echo "=========================================" > /proc/1/fd/1
echo "COMPILING setup_cuda.py" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
cd /root/FastChat/repositories/GPTQ-for-LLaMa/
python setup_cuda.py install > /proc/1/fd/1
fi

if [ ! -f /root/FastChat/models/anon8231489123_vicuna-13b-GPTQ-4bit-128g ]; then
echo "=========================================" > /proc/1/fd/1
echo "DOWNLOADING anon8231489123/vicuna-13b-GPTQ-4bit-128g" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
cd /root/FastChat/
python download-model.py anon8231489123/vicuna-13b-GPTQ-4bit-128g > /proc/1/fd/1
fi

echo "=========================================" > /proc/1/fd/1
echo "FINISH INSTALLATION" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1

echo "=========================================" > /proc/1/fd/1
echo "EXECUTING FastChat controller" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
screen -S controller -dm python -m fastchat.serve.controller --host "127.0.0.1" > /proc/1/fd/1

echo "=========================================" > /proc/1/fd/1
echo "EXECUTING FastChat worker" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
screen -S model_worker -dm python -m fastchat.serve.model_worker --model-path anon8231489123/vicuna-13b-GPTQ-4bit-128g --model-name vicuna-gptq --wbits 4 --groupsize 128 --host "127.0.0.1" --worker-address "http://127.0.0.1:21002" --controller-address "http://127.0.0.1:21001" > /proc/1/fd/1

echo "=========================================" > /proc/1/fd/1
echo "EXECUTING FastChat worker" > /proc/1/fd/1
echo "=========================================" > /proc/1/fd/1
screen -S webgui -dm python -m fastchat.serve.gradio_web_server --controller-url "http://127.0.0.1:21001" --port 5175 > /proc/1/fd/1

exec "$@"
